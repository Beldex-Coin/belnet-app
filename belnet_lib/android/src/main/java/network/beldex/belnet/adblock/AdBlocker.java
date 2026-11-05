package network.beldex.belnet.adblock;

import android.content.ContentResolver;
import android.content.Context;
import android.content.SharedPreferences;
import android.net.ConnectivityManager;
import android.net.LinkProperties;
import android.net.Network;
import android.os.Build;
import android.os.ParcelFileDescriptor;
import android.provider.Settings;
import android.system.ErrnoException;
import android.system.Os;
import android.system.OsConstants;
import android.system.StructPollfd;
import android.util.Log;

import java.io.File;
import java.io.FileDescriptor;
import java.io.IOException;

/**
 * Android entry point to the ad blocker: one {@link AdBlockEngine} per
 * process, shared by the VPN service ({@code BelnetDaemon}) and the Flutter
 * plugin, so a toggle in Settings reaches a running relay directly.
 *
 * <p>The preference lives in the plugin's own {@code belnet_lib}
 * SharedPreferences (next to the exit node and DNS settings the service
 * already persists), so it is available when Android restarts the service
 * on its own (Always-on VPN, process death) without the Flutter engine.
 */
public final class AdBlocker {
  private AdBlocker() {}

  static final String TAG = "BelnetAdBlocker";
  static final String PREFS = "belnet_lib";
  static final String KEY_ENABLED = "AD_BLOCKER_ENABLED";
  /** Socket buffers between the relay and the daemon (bursts of full-size packets). */
  private static final int SOCKET_BUFFER = 1 << 20;

  private static AdBlockEngine sEngine;

  public static synchronized AdBlockEngine get(Context context) {
    if (sEngine == null) {
      final Context app = context.getApplicationContext();
      final SharedPreferences prefs = app.getSharedPreferences(PREFS, Context.MODE_PRIVATE);
      sEngine =
          new AdBlockEngine(
              new File(app.getFilesDir(), "adblock"),
              new AdBlockEngine.Settings() {
                @Override
                public boolean loadEnabled() {
                  return prefs.getBoolean(KEY_ENABLED, false);
                }

                @Override
                public void saveEnabled(boolean enabled) {
                  // commit(): the value must be on disk before the toggle
                  // returns, so a process kill right after cannot lose it.
                  prefs.edit().putBoolean(KEY_ENABLED, enabled).commit();
                }
              },
              new AdBlockEngine.Log() {
                @Override
                public void info(String msg) {
                  Log.i(TAG, msg);
                }

                @Override
                public void warn(String msg) {
                  Log.w(TAG, msg);
                }
              });
    }
    return sEngine;
  }

  // ---------------------------------------------------------------------
  // TUN relay

  /**
   * A running relay between the VPN's TUN interface and the BelNet daemon.
   *
   * <p>The daemon is given {@link #daemonFd}, one end of a packet-preserving
   * Unix socket pair, in place of the TUN fd. It only ever reads, writes,
   * polls and closes that fd, so it cannot tell the difference. The relay
   * owns the real TUN and the other socket end.
   */
  public static final class TunSession {
    /** Hand this to the daemon instead of the TUN fd. The daemon owns it. */
    public final int daemonFd;

    private final String daemonFdLink;
    private final ParcelFileDescriptor tun;
    private final FileDescriptor relayEnd;
    private final TunRelay relay;
    private final AdBlockEngine engine;
    private boolean closed;

    private TunSession(
        int daemonFd,
        String daemonFdLink,
        ParcelFileDescriptor tun,
        FileDescriptor relayEnd,
        TunRelay relay,
        AdBlockEngine engine) {
      this.daemonFd = daemonFd;
      this.daemonFdLink = daemonFdLink;
      this.tun = tun;
      this.relayEnd = relayEnd;
      this.relay = relay;
      this.engine = engine;
    }

    /**
     * Stops the relay and closes the TUN (taking the VPN interface down)
     * and the relay's socket end. Safe to call more than once.
     */
    public synchronized void close() {
      if (closed) return;
      closed = true;
      relay.stop();
      engine.endSession(relay.filter());
      try {
        tun.close();
      } catch (IOException e) {
        Log.w(TAG, "closing TUN failed: " + e);
      }
      try {
        Os.close(relayEnd);
      } catch (ErrnoException e) {
        Log.w(TAG, "closing relay socket failed: " + e);
      }
    }

    /**
     * Closes {@link #daemonFd} if it still refers to our socket (the daemon
     * normally closes it on a clean shutdown; after that the number may be
     * reused by something else, which must not be touched).
     */
    public void closeDaemonFdIfStillOpen() {
      try {
        String link = Os.readlink("/proc/self/fd/" + daemonFd);
        if (link == null || !link.equals(daemonFdLink)) return;
        ParcelFileDescriptor.adoptFd(daemonFd).close();
      } catch (ErrnoException | IOException e) {
        // Already closed.
      }
    }
  }

  /**
   * Puts the ad-blocking relay between {@code tun} and the daemon. On
   * success the caller hands {@link TunSession#daemonFd} to the daemon and
   * must not detach or close {@code tun} (the session owns it). Returns null
   * if the relay cannot be set up; the caller then uses the TUN directly,
   * exactly as without the Ad Blocker.
   */
  public static TunSession startTunSession(Context context, ParcelFileDescriptor tun) {
    AdBlockEngine engine = get(context);
    FileDescriptor relayEnd = new FileDescriptor();
    FileDescriptor daemonEnd = new FileDescriptor();
    try {
      Os.socketpair(OsConstants.AF_UNIX, OsConstants.SOCK_SEQPACKET, 0, relayEnd, daemonEnd);
    } catch (Exception e) { // ErrnoException (and SocketException on some API levels)
      Log.w(TAG, "socketpair failed, running without the Ad Blocker: " + e);
      return null;
    }
    int daemonFd;
    String link;
    try {
      for (FileDescriptor fd : new FileDescriptor[] {relayEnd, daemonEnd}) {
        Os.setsockoptInt(fd, OsConstants.SOL_SOCKET, OsConstants.SO_SNDBUF, SOCKET_BUFFER);
        Os.setsockoptInt(fd, OsConstants.SOL_SOCKET, OsConstants.SO_RCVBUF, SOCKET_BUFFER);
      }
      // A plain int fd for the native daemon (it closes it itself).
      daemonFd = ParcelFileDescriptor.dup(daemonEnd).detachFd();
      Os.close(daemonEnd);
      link = Os.readlink("/proc/self/fd/" + daemonFd);
    } catch (ErrnoException | IOException e) {
      Log.w(TAG, "relay setup failed, running without the Ad Blocker: " + e);
      closeQuietly(relayEnd);
      closeQuietly(daemonEnd);
      return null;
    }
    PacketFilter filter = engine.beginSession();
    TunRelay relay =
        new TunRelay(
            new FdPipe(tun.getFileDescriptor(), false),
            new FdPipe(relayEnd, true),
            filter,
            new TunRelay.Log() {
              @Override
              public void info(String msg) {
                Log.i(TAG, msg);
              }

              @Override
              public void warn(String msg) {
                Log.w(TAG, msg);
              }
            });
    relay.start();
    return new TunSession(daemonFd, link, tun, relayEnd, relay, engine);
  }

  private static void closeQuietly(FileDescriptor fd) {
    try {
      if (fd.valid()) Os.close(fd);
    } catch (ErrnoException ignored) {
    }
  }

  /** Packet pipe over a TUN fd or a SOCK_SEQPACKET socket (one packet per read/write). */
  private static final class FdPipe implements TunRelay.PacketPipe {
    private final FileDescriptor fd;
    private final boolean eofIsClosed;
    private final StructPollfd[] pfds = {new StructPollfd()};

    FdPipe(FileDescriptor fd, boolean eofIsClosed) {
      this.fd = fd;
      this.eofIsClosed = eofIsClosed;
      pfds[0].fd = fd;
      pfds[0].events = (short) OsConstants.POLLIN;
    }

    @Override
    public int read(byte[] buf, int timeoutMs) throws IOException {
      try {
        pfds[0].revents = 0;
        if (Os.poll(pfds, timeoutMs) <= 0) return 0;
        int rev = pfds[0].revents;
        if ((rev & OsConstants.POLLIN) == 0) {
          if ((rev & (OsConstants.POLLHUP | OsConstants.POLLERR | OsConstants.POLLNVAL)) != 0) {
            throw new IOException("closed (revents=" + rev + ")");
          }
          return 0;
        }
        int n = Os.read(fd, buf, 0, buf.length);
        if (n == 0 && eofIsClosed) throw new IOException("peer closed");
        return Math.max(n, 0);
      } catch (ErrnoException e) {
        if (e.errno == OsConstants.EINTR || e.errno == OsConstants.EAGAIN) return 0;
        throw new IOException(e.getMessage());
      }
    }

    @Override
    public void write(byte[] buf, int off, int len) throws IOException {
      try {
        Os.write(fd, buf, off, len);
      } catch (ErrnoException e) {
        throw new IOException(e.getMessage());
      }
    }
  }

  // ---------------------------------------------------------------------
  // Status

  /** Status JSON for Flutter, including Android Private DNS state. */
  public static String statusJson(Context context) {
    AdBlockEngine engine = get(context);
    StringBuilder extra = new StringBuilder();
    AdBlockEngine.field(extra, "privateDnsMode", privateDnsMode(context)).append(',');
    AdBlockEngine.field(extra, "privateDnsActive", isPrivateDnsActive(context));
    return engine.statusJson(extra.toString());
  }

  /**
   * "off", "opportunistic" (Automatic) or "hostname" (Strict), or null when
   * unknown. Strict mode always encrypts DNS to the chosen provider, which
   * bypasses any DNS-level filter inside a VPN.
   */
  static String privateDnsMode(Context context) {
    if (Build.VERSION.SDK_INT < 28) return "off";
    try {
      ContentResolver cr = context.getContentResolver();
      return Settings.Global.getString(cr, "private_dns_mode");
    } catch (RuntimeException e) {
      return null;
    }
  }

  /** True when the default network (the VPN while connected) uses encrypted DNS. */
  static boolean isPrivateDnsActive(Context context) {
    if (Build.VERSION.SDK_INT < 28) return false;
    try {
      ConnectivityManager cm =
          (ConnectivityManager) context.getSystemService(Context.CONNECTIVITY_SERVICE);
      if (cm == null) return false;
      Network n = cm.getActiveNetwork();
      if (n == null) return false;
      LinkProperties lp = cm.getLinkProperties(n);
      return lp != null && lp.isPrivateDnsActive();
    } catch (RuntimeException e) {
      return false;
    }
  }
}
