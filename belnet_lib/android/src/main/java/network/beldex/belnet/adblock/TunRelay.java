package network.beldex.belnet.adblock;

import java.io.IOException;

/**
 * Moves packets between the VPN's TUN interface and the BelNet daemon,
 * filtering DNS on the way out.
 *
 * <pre>
 *   apps ──▶ TUN ──read──▶ [PacketFilter] ──FORWARD──▶ daemon socket ──▶ BelNet network
 *                               │ REPLY (NXDOMAIN / TCP RST)
 *            TUN ◀──write───────┘
 *   apps ◀── TUN ◀──write── daemon socket ◀── BelNet network
 * </pre>
 *
 * Two threads, one per direction: each only reads one side and writes the
 * other, so neither can deadlock waiting on the other. Reads wait at most
 * {@link #POLL_MS} so {@link #stop()} is honoured promptly.
 */
final class TunRelay {

  /** One packet-oriented endpoint (the TUN, or the daemon's socket). */
  interface PacketPipe {
    /**
     * Reads one packet into {@code buf}, waiting at most {@code timeoutMs}.
     * Returns its length, 0 on timeout. Throws when the endpoint is closed.
     */
    int read(byte[] buf, int timeoutMs) throws IOException;

    /** Writes one packet. */
    void write(byte[] buf, int off, int len) throws IOException;
  }

  interface Log {
    void info(String msg);

    void warn(String msg);
  }

  static final int POLL_MS = 250;
  static final int MAX_PACKET = 65535;

  private final PacketPipe tun;
  private final PacketPipe daemon;
  private final PacketFilter filter;
  private final Log log;
  private volatile boolean running;
  private Thread upThread;
  private Thread downThread;

  TunRelay(PacketPipe tun, PacketPipe daemon, PacketFilter filter, Log log) {
    this.tun = tun;
    this.daemon = daemon;
    this.filter = filter;
    this.log = log;
  }

  synchronized void start() {
    if (running) return;
    running = true;
    upThread = new Thread(this::upLoop, "belnet-adblock-up");
    downThread = new Thread(this::downLoop, "belnet-adblock-down");
    upThread.setDaemon(true);
    downThread.setDaemon(true);
    upThread.start();
    downThread.start();
    log.info("Ad Blocker relay started");
  }

  boolean isRunning() {
    return running;
  }

  PacketFilter filter() {
    return filter;
  }

  /** Stops both threads (within about {@link #POLL_MS}). Does not close the pipes. */
  void stop() {
    Thread up;
    Thread down;
    synchronized (this) {
      if (!running) return;
      running = false;
      up = upThread;
      down = downThread;
    }
    join(up);
    join(down);
    log.info("Ad Blocker relay stopped");
  }

  private static void join(Thread t) {
    if (t == null || t == Thread.currentThread()) return;
    try {
      t.join(POLL_MS * 4L);
    } catch (InterruptedException e) {
      Thread.currentThread().interrupt();
    }
  }

  /** Apps -> daemon, with filtering. */
  private void upLoop() {
    byte[] buf = new byte[MAX_PACKET];
    while (running) {
      int n;
      try {
        n = tun.read(buf, POLL_MS);
      } catch (IOException e) {
        if (running) log.warn("Ad Blocker relay: TUN closed (" + e.getMessage() + ")");
        break;
      }
      if (n <= 0) continue;
      int action;
      try {
        action = filter.process(buf, n);
      } catch (RuntimeException e) {
        action = PacketFilter.FORWARD; // never lose traffic to a filter bug
      }
      try {
        if (action == PacketFilter.FORWARD) {
          daemon.write(buf, 0, n);
        } else if (action == PacketFilter.REPLY) {
          byte[] r = filter.reply;
          tun.write(r, 0, r.length);
        }
      } catch (IOException e) {
        if (!running) break;
        // A full or briefly unavailable endpoint loses this one packet only;
        // TCP retransmits and DNS retries.
      }
    }
  }

  /** Daemon -> apps, unchanged. */
  private void downLoop() {
    byte[] buf = new byte[MAX_PACKET];
    while (running) {
      int n;
      try {
        n = daemon.read(buf, POLL_MS);
      } catch (IOException e) {
        if (running) log.warn("Ad Blocker relay: daemon side closed (" + e.getMessage() + ")");
        break;
      }
      if (n <= 0) continue;
      try {
        tun.write(buf, 0, n);
      } catch (IOException e) {
        if (!running) break;
      }
    }
  }
}
