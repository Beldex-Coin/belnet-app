package network.beldex.belnet;

import android.content.Intent;
import android.content.SharedPreferences;
import android.content.SharedPreferences.Editor;
import android.net.VpnService;
import android.os.Binder;
import android.os.IBinder;
import android.os.ParcelFileDescriptor;
import android.util.Log;
import androidx.lifecycle.MutableLiveData;
import java.nio.ByteBuffer;
import java.util.ArrayList;
import java.util.Timer;
import java.util.TimerTask;

public class BelnetDaemon extends VpnService {

  public static final String ACTION_CONNECT = "network.beldex.belnet.START";
  public static final String ACTION_DISCONNECT = "network.beldex.belnet.STOP";
  public static final String LOG_TAG = "BelnetDaemon";
  public static final String MESSAGE_CHANNEL = "BELNET_DAEMON";
  public static final String EXIT_NODE = "EXIT_NODE";
  public static final String UPSTREAM_DNS = "UPSTREAM_DNS";

  private static final String DEFAULT_EXIT_NODE = "7a4cpzri7qgqen9a3g3hgfjrijt9337qb19rhcdmx5y7yttak33o.bdx";
  private static final String DEFAULT_UPSTREAM_DNS = "1.1.1.1";

  static {
    System.loadLibrary("belnet-android");
  }

  private static native ByteBuffer Obtain();

  private static native void Free(ByteBuffer buf);

  public native boolean Configure(BelnetConfig config);

  public native int Mainloop();

  public native boolean IsRunning();

  public native String DumpStatus();

  public native boolean Stop();

  public native void InjectVPNFD();

  public native int GetUDPSocket();

  private static native String DetectFreeRange();

  ByteBuffer impl = null;
  ParcelFileDescriptor iface;
  int m_FD = -1;
  int m_UDPSocket = -1;

  private Timer mUpdateIsConnectedTimer;
  private MutableLiveData<Boolean> isConnected = new MutableLiveData<Boolean>();

  @Override
  public void onCreate() {
    isConnected.postValue(false);
    mUpdateIsConnectedTimer = new Timer();
    mUpdateIsConnectedTimer.schedule(new UpdateIsConnectedTask(), 0, 500);
    super.onCreate();
  }

  @Override
  public void onDestroy() {
    if (mUpdateIsConnectedTimer != null) {
      mUpdateIsConnectedTimer.cancel();
      mUpdateIsConnectedTimer = null;
    }

    super.onDestroy();
    disconnect();
  }

  @Override
  public int onStartCommand(Intent intent, int flags, int startID) {
    Log.d(LOG_TAG, "onStartCommand()");

    String action = intent != null ? intent.getAction() : "";

    if (ACTION_DISCONNECT.equals(action)) {
      disconnect();
      return START_NOT_STICKY;
    } else {
      ArrayList<ConfigValue> configVals = new ArrayList<ConfigValue>();

      String exitNode = "7a4cpzri7qgqen9a3g3hgfjrijt9337qb19rhcdmx5y7yttak33o.bdx";
      String upstreamDNS = null;

      SharedPreferences sharedPreferences = getSharedPreferences("belnet_lib", MODE_PRIVATE);

      if (ACTION_CONNECT.equals(action)) { // started by the app
        exitNode = intent.getStringExtra(EXIT_NODE);
        upstreamDNS = intent.getStringExtra(UPSTREAM_DNS);
        // save values
        SharedPreferences.Editor editor = sharedPreferences.edit();
        editor.putString(EXIT_NODE, exitNode);
        editor.putString(UPSTREAM_DNS, upstreamDNS);
        editor.commit();
      } else { // if started by the system because Always-on VPN setting is enabled
        // use the latest values
        exitNode = sharedPreferences.getString(EXIT_NODE, null);
        upstreamDNS = sharedPreferences.getString(UPSTREAM_DNS, null);
      }

      if (exitNode == null || exitNode.isEmpty()) {
        exitNode = DEFAULT_EXIT_NODE;
        Log.e(LOG_TAG, "No exit-node configured! Proceeding with default.");
      }

      Log.e(LOG_TAG, "Using " + exitNode + " as exit-node.");
      configVals.add(new ConfigValue("network", "exit-node", exitNode));

      if (upstreamDNS == null || upstreamDNS.isEmpty()) {
        upstreamDNS = DEFAULT_UPSTREAM_DNS;
        Log.e(LOG_TAG, "No upstream DNS configured! Proceeding with default.");
      }

      Log.e(LOG_TAG, "Using " + upstreamDNS + " as upstream DNS.");
      configVals.add(new ConfigValue("dns", "upstream", upstreamDNS));

      // set log leve to info
      configVals.add(new ConfigValue("logging", "level", "info"));

      boolean connectedSuccessfully = connect(configVals);
      if (connectedSuccessfully)
        return START_STICKY;
      else
        return START_NOT_STICKY;
    }
  }

  @Override
  public void onRevoke() {
    Log.d(LOG_TAG, "onRevoke()");
    disconnect();
    super.onRevoke();
  }

  private class ConfigValue {
    final String Section;
    final String Key;
    final String Value;

    public ConfigValue(String section, String key, String value) {
      Section = section;
      Key = key;
      Value = value;
    }

    public boolean Valid() {
      if (Section == null || Key == null || Value == null)
        return false;
      if (Section.isEmpty() || Key.isEmpty() || Value.isEmpty())
        return false;
      return true;
    }
  }

  private boolean connect(ArrayList<ConfigValue> configVals) {
    if (!IsRunning()) {
      if (impl != null) {
        Free(impl);
        impl = null;
      }
      impl = Obtain();
      if (impl == null) {
        Log.e(LOG_TAG, "got nullptr when creating llarp::Context in jni");
        return false;
      }

      String dataDir = getFilesDir().toString();
      BelnetConfig config;
      try {
        config = new BelnetConfig(dataDir);
      } catch (RuntimeException ex) {
        Log.e(LOG_TAG, ex.toString());
        return false;
      }

      String ourRange = DetectFreeRange();

      if (ourRange.isEmpty()) {
        Log.e(LOG_TAG, "cannot detect free range");
        return false;
      }

      String upstreamDNS = DEFAULT_UPSTREAM_DNS;

      // set up config values
      if (configVals != null) {
        configVals.add(new ConfigValue("network", "ifaddr", ourRange));
        for (ConfigValue conf : configVals) {

          if (conf.Valid()) {
            config.AddDefaultValue(conf.Section, conf.Key, conf.Value);
            if (conf.Section.equals("dns") && conf.Key.equals("upstream"))
              upstreamDNS = conf.Value;
          }
        }
      }

      if (!config.Load()) {
        Log.e(
            LOG_TAG,
            "failed to load (or create) config file at: "
                + dataDir
                + "/beldex.network.beldex.belnet.ini");
        return false;
      }

      VpnService.Builder builder = new VpnService.Builder();

      builder.setMtu(1500);

      String[] parts = ourRange.split("/");
      String ourIP = parts[0];
      int ourMask = Integer.parseInt(parts[1]);

      builder.addAddress(ourIP, ourMask);
      builder.addRoute("0.0.0.0", 0);
      builder.addRoute("::", 0);
      builder.addDnsServer(upstreamDNS);
      builder.setSession("Belnet");
      builder.setConfigureIntent(null);

      iface = builder.establish();
      if (iface == null) {
        Log.e(LOG_TAG, "VPN Interface from builder.establish() came back null");
        return false;
      }

      m_FD = iface.detachFd();

      InjectVPNFD();
      new Thread(
          () -> {
            Configure(config);
            m_UDPSocket = GetUDPSocket();
            protect(m_UDPSocket);
            Mainloop();
          })
          .start();

      Log.d(LOG_TAG, "started successfully!");
    } else {
      Log.d(LOG_TAG, "already running");
    }
    updateIsConnected();
    return true;
  }

  private void disconnect() {
    if (IsRunning()) {
      Stop();
    }
    // if (impl != null) {
    // Free(impl);
    // impl = null;
    // }
    updateIsConnected();
  }

  public MutableLiveData<Boolean> isConnected() {
    return isConnected;
  }

  private void updateIsConnected() {
    isConnected.postValue(IsRunning() && VpnService.prepare(BelnetDaemon.this) == null);
  }

  /**
   * Class for clients to access. Because we know this service always runs in the
   * same process as its clients, we don't need to deal with IPC.
   */
  public class LocalBinder extends Binder {
    public BelnetDaemon getService() {
      return BelnetDaemon.this;
    }
  }

  @Override
  public IBinder onBind(Intent intent) {
    String action = intent != null ? intent.getAction() : "";

    if (VpnService.SERVICE_INTERFACE.equals(action)) {
      return super.onBind(intent);
    }

    return mBinder;
  }

  private final IBinder mBinder = new LocalBinder();

  private class UpdateIsConnectedTask extends TimerTask {
    public void run() {
      updateIsConnected();
    }
  }
}