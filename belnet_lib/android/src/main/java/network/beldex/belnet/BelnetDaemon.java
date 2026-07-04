package network.beldex.belnet;
//
//import static io.beldex.belnet_lib.BelnetLibPluginKt.buildStatusForNotification;

import static android.content.Intent.getIntent;

import android.annotation.SuppressLint;
import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.net.ConnectivityManager;
import android.net.Network;
import android.net.NetworkCapabilities;
import android.net.NetworkRequest;
import android.net.TrafficStats;
import android.net.Uri;
import android.net.VpnService;
import android.os.Binder;
import android.os.Build;
import android.os.Handler;
import android.os.IBinder;
import android.os.Looper;
import android.os.ParcelFileDescriptor;
import android.os.SystemClock;
import android.text.TextUtils;
import android.util.Log;

import androidx.annotation.RequiresApi;
import androidx.core.app.NotificationCompat;
import androidx.core.app.NotificationManagerCompat;
import androidx.lifecycle.LiveData;
import androidx.lifecycle.MutableLiveData;

import org.json.JSONException;
import org.json.JSONObject;

import java.nio.ByteBuffer;
import java.text.DecimalFormat;
import java.text.NumberFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.LinkedHashSet;
import java.util.Locale;
import java.util.Set;
import java.util.Timer;
import java.util.TimerTask;
import java.util.stream.Stream;

import io.beldex.belnet_lib.BelnetLibPlugin;

// import io.beldex.belnet_lib.DisconActionReceiver;
//import io.beldex.belnet_lib.R;
//import io.beldex.belnet_lib.UpdateNetwork;


public class BelnetDaemon extends VpnService{

  public static final String ACTION_CONNECT = "network.beldex.belnet.START";
  public static final String ACTION_DISCONNECT = "network.beldex.belnet.STOP";
  public static final String LOG_TAG = "BelnetDaemon";
  public static final String MESSAGE_CHANNEL = "BELNET_DAEMON";
  public static final String EXIT_NODE = "EXIT_NODE";
  public static final String UPSTREAM_DNS = "UPSTREAM_DNS";
  public static final String ALLOWED_APPS = "allowed_apps";
  public static final String NOTIFICATION_ID = "NOTIFICATION_ID";
  public static final String LOG_LEVEL = "LOG_LEVEL";
  public static final String MTU = "MTU";
  public static final String ROUTE_IPV6 = "ROUTE_IPV6";
  private static final String DEFAULT_EXIT_NODE = "7a4cpzri7qgqen9a3g3hgfjrijt9337qb19rhcdmx5y7yttak33o.bdx";
  // Keep in sync with the Dart-side default in belnet_lib.dart (was 1.1.1.1
  // here and 9.9.9.9 in Dart, which made DNS issues confusing to debug).
  private static final String DEFAULT_UPSTREAM_DNS = "9.9.9.9";
  private static final String DEFAULT_LOG_LEVEL = "warn";
  private static final int DEFAULT_MTU = 1500;
  public static Boolean isCalling =false;
  public static final int NOTIFY_ID = 1;
  private static final int ERROR_NOTIFY_ID = 3;
  private final static String NOTIFICATION_CHANNEL_ID = "belnet_channel_1";
  public NotificationManager mNotificationManager = null;
  public NotificationCompat.Builder mNotifyBuilder;
  public String updateNotify;

  // Stream<String> myStream;

  private String actionState = "network.beldex.belnet.STOP";
  public String updata ="empty" ;
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

  //public final void stopSelf();
  public native String GetStatus();

   public native String Unmap(String exitvalue);
  public native String Status();

  ByteBuffer impl = null;
  ParcelFileDescriptor iface;
  int m_FD = -1;
  int m_UDPSocket = -1;

  private Timer mUpdateIsConnectedTimer;
  private MutableLiveData<Boolean> isConnected = new MutableLiveData<Boolean>();

  public static final String ACTION_NETWORK_CHANGED = "network.beldex.belnet.NETWORK_CHANGED";
  private ConnectivityManager.NetworkCallback mNetworkCallback;
  private long mLastNetworkChangeMs = 0;

  private int mMtu = DEFAULT_MTU;
  private boolean mRouteIpv6 = true;

  @Override
  public void onCreate() {
    isConnected.postValue(false);
    mUpdateIsConnectedTimer = new Timer();
    mUpdateIsConnectedTimer.schedule(new UpdateIsConnectedTask(), 0, 500);
    Log.d(LOG_TAG, "Connected timer is "+ mUpdateIsConnectedTimer.toString());
    registerNetworkCallback();
   // createNotific();
//    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
//      createNotificationChannel();

    // new UpdateNetwork().callfunctionContinuesly();
    // callSpeedFunction(actionState);
    // showToolbarNotification("Connect to belnet",NOTIFY_ID,R.drawable.ic_stat);
    super.onCreate();
  }

  @Override
  public void onDestroy() {
    if (mUpdateIsConnectedTimer != null) {
      mUpdateIsConnectedTimer.cancel();
      mUpdateIsConnectedTimer = null;
    }
    unregisterNetworkCallback();
    // clearNotifications();
    disconnect();

    super.onDestroy();

  }

  /**
   * Watch the underlying (non-VPN) network. On a Wi-Fi <-> mobile handover
   * the daemon's UDP flows to its first hop break silently: the daemon keeps
   * "running" but paths are dead - users see "Connected" with no internet.
   * When the underlying network changes we re-protect the daemon's UDP
   * socket against the new network and broadcast an event so the Flutter
   * layer can run an immediate tunnel health probe.
   */
  private void registerNetworkCallback() {
    ConnectivityManager cm = (ConnectivityManager) getSystemService(CONNECTIVITY_SERVICE);
    if (cm == null)
      return;
    mNetworkCallback = new ConnectivityManager.NetworkCallback() {
      @Override
      public void onAvailable(Network network) {
        handleNetworkChange("available");
      }

      @Override
      public void onLost(Network network) {
        handleNetworkChange("lost");
      }
    };
    try {
      NetworkRequest request = new NetworkRequest.Builder()
          .addCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
          .addCapability(NetworkCapabilities.NET_CAPABILITY_NOT_VPN)
          .build();
      cm.registerNetworkCallback(request, mNetworkCallback);
    } catch (Exception e) {
      Log.w(LOG_TAG, "could not register network callback: " + e);
      mNetworkCallback = null;
    }
  }

  private void unregisterNetworkCallback() {
    if (mNetworkCallback == null)
      return;
    ConnectivityManager cm = (ConnectivityManager) getSystemService(CONNECTIVITY_SERVICE);
    if (cm != null) {
      try {
        cm.unregisterNetworkCallback(mNetworkCallback);
      } catch (Exception e) {
        Log.w(LOG_TAG, "could not unregister network callback: " + e);
      }
    }
    mNetworkCallback = null;
  }

  private void handleNetworkChange(String why) {
    // Debounce: handovers produce a burst of callbacks.
    long now = SystemClock.elapsedRealtime();
    if (now - mLastNetworkChangeMs < 3000)
      return;
    mLastNetworkChangeMs = now;
    Log.d(LOG_TAG, "underlying network change (" + why + ")");
    if (IsRunning()) {
      new Thread(
          () -> {
            try {
              m_UDPSocket = GetUDPSocket();
              protect(m_UDPSocket);
              Log.d(LOG_TAG, "re-protected UDP socket after network change");
            } catch (Throwable t) {
              Log.w(LOG_TAG, "re-protect after network change failed: " + t);
            }
          },
          "belnet-netchange")
          .start();
    }
    sendBroadcast(new Intent(ACTION_NETWORK_CHANGED));
  }



  public void disconnectNotificationButton(){
    Log.d("callingbelnetDeamon","true");
   // isCalling = false;
    disconnect();

    stopSelf();
    //clearNotifications();

  }







  @Override
  public int onStartCommand(Intent intent, int flags, int startID) {
    Log.d(LOG_TAG, "onStartCommand()");
    String action = intent != null ? intent.getAction() : "";

    if (ACTION_DISCONNECT.equals(action)) {
      Log.d("callingbelnetDeamon","true");
     // isCalling = false;
      disconnect();
      stopSelf();
     //clearNotifications();

      return START_NOT_STICKY;
    } else {
      ArrayList<ConfigValue> configVals = new ArrayList<ConfigValue>();

      String exitNode = "7a4cpzri7qgqen9a3g3hgfjrijt9337qb19rhcdmx5y7yttak33o.bdx";
      String upstreamDNS = null;
      String logLevel = DEFAULT_LOG_LEVEL;
      ArrayList<String> allowedApps = new ArrayList<>();
      SharedPreferences sharedPreferences = getSharedPreferences("belnet_lib", MODE_PRIVATE);

      if (ACTION_CONNECT.equals(action)) {

       // Belnet is connected
    // showToolbarNotification("↑ 60.0Kb/s ↓12.3Kb/s", NOTIFY_ID,1);

        // started by the app
        exitNode = intent.getStringExtra(EXIT_NODE);
        upstreamDNS = intent.getStringExtra(UPSTREAM_DNS);
        allowedApps = intent.getStringArrayListExtra(ALLOWED_APPS);
        logLevel = intent.getStringExtra(LOG_LEVEL);
        mMtu = intent.getIntExtra(MTU, DEFAULT_MTU);
        mRouteIpv6 = intent.getBooleanExtra(ROUTE_IPV6, true);
       // isCalling = true;
        // save values
        SharedPreferences.Editor editor = sharedPreferences.edit();
        editor.putString(EXIT_NODE, exitNode);
        editor.putString(UPSTREAM_DNS, upstreamDNS);
        editor.putString(LOG_LEVEL, logLevel);
        editor.putInt(MTU, mMtu);
        editor.putBoolean(ROUTE_IPV6, mRouteIpv6);
        editor.commit();
      } else { // if started by the system because Always-on VPN setting is enabled
        // use the latest values
        exitNode = sharedPreferences.getString(EXIT_NODE, null);
        upstreamDNS = sharedPreferences.getString(UPSTREAM_DNS, null);
        logLevel = sharedPreferences.getString(LOG_LEVEL, DEFAULT_LOG_LEVEL);
        mMtu = sharedPreferences.getInt(MTU, DEFAULT_MTU);
        mRouteIpv6 = sharedPreferences.getBoolean(ROUTE_IPV6, true);
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
        new BelnetLibPlugin().logDataToFrontend("No upstream DNS configured! Proceeding with default."); //i
      }

      Log.e(LOG_TAG, "Using " + upstreamDNS + " as upstream DNS.");
      configVals.add(new ConfigValue("dns", "upstream", upstreamDNS));

      // Daemon log level: "warn" by default so logging stays off the packet
      // path in release builds; callers may pass "info"/"debug" explicitly.
      if (logLevel == null || logLevel.isEmpty())
        logLevel = DEFAULT_LOG_LEVEL;
      Log.d(LOG_TAG, "Using daemon log level " + logLevel);
      configVals.add(new ConfigValue("logging", "level", logLevel));

      boolean connectedSuccessfully = connect(configVals,allowedApps);
      if (connectedSuccessfully){
        return START_STICKY;
      }

      else{
        return START_NOT_STICKY;
      }

    }
  }

  @Override
  public void onRevoke() {
    Log.d(LOG_TAG, "onRevoke()");
       // Send broadcast to notify plugin
        Intent intent = new Intent("com.belnet.NOTIFICATION_DISCONNECTED");
        sendBroadcast(intent);
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

  private boolean connect(ArrayList<ConfigValue> configVals,ArrayList<String> allowedApps) {
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

      // MTU is configurable for benchmarking: onion-encryption overhead can
      // fragment full-size packets inside the tunnel; 1280-1400 may perform
      // better on some networks. Default stays 1500.
      int mtu = mMtu;
      if (mtu < 1280 || mtu > 1500)
        mtu = DEFAULT_MTU;
      Log.d(LOG_TAG, "Using MTU " + mtu);
      builder.setMtu(mtu);

      String[] parts = ourRange.split("/");
      String ourIP = parts[0];
      int ourMask = Integer.parseInt(parts[1]);

      builder.addAddress(ourIP, ourMask);
      builder.addRoute("0.0.0.0", 0);
      if (mRouteIpv6) {
        // Claiming ::/0 prevents IPv6 leaks, but NOTE: if the exit path does
        // not actually carry IPv6, apps that prefer IPv6 will pay a
        // Happy-Eyeballs fallback delay per connection (or fail on
        // IPv6-only setups). Disable via connectToBelnet(routeIpv6: false)
        // to benchmark the difference.
        builder.addRoute("::", 0);
      } else {
        Log.w(LOG_TAG, "IPv6 route NOT claimed (route_ipv6=false): IPv6 traffic will bypass the tunnel!");
      }
      builder.addDnsServer(upstreamDNS);
      builder.setSession("Belnet");
      builder.setConfigureIntent(null);
        try{
      if (allowedApps != null) {
    for (String packageName : allowedApps) {
        builder.addAllowedApplication(packageName);
    }
}
        //builder.addAllowedApplication("com.android.chrome");
      }catch(Exception e){
        Log.e(LOG_TAG,"error"+ e);
      }

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
      new BelnetLibPlugin().logDataToFrontend("started successfully!"); //i new BelnetLibPlugin().logDataToFrontend("started successfully!"); //i added
    } else {
      Log.d(LOG_TAG, "already running");
      new BelnetLibPlugin().logDataToFrontend("already running");
    }

    updateIsConnected();
//    Intent browserI = new Intent(Intent.ACTION_VIEW,Uri.parse("https://whatismyipaddress.com/"));
//    startActivity(browserI);
    return true;

  }

  private void disconnect() {
    if (IsRunning()) {
      Stop();
      // stopSelf();
      stopForeground(true);
    }
    cancelSpeedNotification();
    // if (impl != null) {
    //   //Free(impl);
    //   impl = null;
    // }

    updateIsConnected();

  }

  public MutableLiveData<Boolean> isConnected() {
    return isConnected;
  }

  private void updateIsConnected() {
    // "Connected" must mean the tunnel can actually carry traffic, not just
    // that the daemon process is alive. A daemon that is running but has no
    // built paths / mapped exit blackholes ALL device traffic (we route
    // 0.0.0.0/0 and ::/0 into the tun), which users experience as
    // "Connected but no internet".
    boolean running = IsRunning() && VpnService.prepare(BelnetDaemon.this) == null;
    boolean ready = false;
    if (running) {
      try {
        String raw = GetStatus();
        if (raw != null && !raw.isEmpty()) {
          JSONObject status = new JSONObject(raw);
          boolean flag = status.optBoolean("isconnected", false);
          int pathsBuilt = status.optInt("numPathsBuilt", 0);
          JSONObject exitMap = status.optJSONObject("exitMap");
          ready = flag && pathsBuilt > 0 && exitMap != null && exitMap.length() > 0;
        }
      } catch (JSONException e) {
        Log.w(LOG_TAG, "updateIsConnected: could not parse daemon status: " + e);
      }
    }
    isConnected.postValue(running && ready);
  }

  
  /** Callback for async exit-node remapping results. */
  public interface UnmapCallback {
    void onResult(String result);
  }

  /**
   * Remap the exit to {@code newNode} asynchronously.
   *
   * The old version of this method started a thread and immediately returned
   * a shared field the thread had not written yet (always null/stale), so
   * failed swaps were reported as successes. The result is now delivered on
   * the main thread via {@link UnmapCallback} once the JNI call completes.
   */
  public void unmappingNode(String newNode, UnmapCallback cb) {
    final Handler mainHandler = new Handler(Looper.getMainLooper());
    new Thread(
        () -> {
          String unmapResult;
          try {
            unmapResult = Unmap(newNode);
          } catch (Throwable t) {
            Log.e(LOG_TAG, "Unmap(" + newNode + ") threw: " + t);
            unmapResult = null;
          }
          final String value = unmapResult;
          mainHandler.post(() -> cb.onResult(value));
        },
        "belnet-unmap")
        .start();
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
      maybeUpdateSpeedNotification();
    }
  }

  // ---------------------------------------------------------------------
  // Speed notification (native).
  //
  // Previously the Flutter layer re-CREATED the notification once per
  // second via awesome_notifications - a cross-channel + system-service
  // call every second for the whole session, with visible flicker on some
  // OEM ROMs. It is now updated here, from the service's existing timer,
  // throttled to every 3 seconds with setOnlyAlertOnce, and survives even
  // if the Flutter engine is killed.
  //
  // NOTE: this intentionally does not call startForeground() - the service
  // semantics are unchanged from the shipped version. Promoting to a true
  // foreground service (with android:foregroundServiceType in the manifest)
  // is a recommended follow-up.
  // ---------------------------------------------------------------------
  private static final int SPEED_NOTIFY_ID = 10; // same id the Dart layer used
  private static final String SPEED_CHANNEL_ID = "belnets_channel"; // created by the app at startup
  private long mLastNotifyMs = 0;
  private long mNotifyLastTs = 0;
  private long mNotifyLastRx = 0;
  private long mNotifyLastTx = 0;

  private void maybeUpdateSpeedNotification() {
    if (!IsRunning())
      return;
    long now = SystemClock.elapsedRealtime();
    if (now - mLastNotifyMs < 3000)
      return;
    mLastNotifyMs = now;

    long rx = TrafficStats.getTotalRxBytes();
    long tx = TrafficStats.getTotalTxBytes();
    String body = "↑ 0.0 bps ↓ 0.0 bps";
    if (mNotifyLastTs != 0) {
      float dt = (now - mNotifyLastTs) / 1000f;
      if (dt > 0f) {
        // Halved: TrafficStats counts tunneled bytes twice (tun + physical).
        long up = (long) (Math.max(0, tx - mNotifyLastTx) / 2 / dt);
        long down = (long) (Math.max(0, rx - mNotifyLastRx) / 2 / dt);
        body = "↑ " + ConnectionTools.bytesToSize(up) + "ps ↓ "
            + ConnectionTools.bytesToSize(down) + "ps";
      }
    }
    mNotifyLastTs = now;
    mNotifyLastRx = rx;
    mNotifyLastTx = tx;

    try {
      Intent launch = getPackageManager().getLaunchIntentForPackage(getPackageName());
      PendingIntent contentIntent = launch == null ? null
          : PendingIntent.getActivity(this, 0, launch,
              PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);

      NotificationCompat.Builder builder =
          new NotificationCompat.Builder(this, SPEED_CHANNEL_ID)
              .setSmallIcon(io.beldex.belnet_lib.R.drawable.belnet_svg)
              .setContentTitle("Belnet dVPN")
              .setContentText(body)
              .setOngoing(true)
              .setOnlyAlertOnce(true)
              .setSilent(true)
              .setCategory(NotificationCompat.CATEGORY_SERVICE);
      if (contentIntent != null)
        builder.setContentIntent(contentIntent);
      NotificationManagerCompat.from(this).notify(SPEED_NOTIFY_ID, builder.build());
    } catch (Throwable t) {
      // Missing channel or notification permission: never let the
      // notification path take down the VPN timer.
      Log.w(LOG_TAG, "speed notification update failed: " + t);
    }
  }

  private void cancelSpeedNotification() {
    try {
      NotificationManagerCompat.from(this).cancel(SPEED_NOTIFY_ID);
    } catch (Throwable t) {
      Log.w(LOG_TAG, "speed notification cancel failed: " + t);
    }
    mNotifyLastTs = 0;
    mLastNotifyMs = 0;
  }


}




//class LogDisplayForUi{
//  String myLog ;
//
//  public LogDisplayForUi(String data){
//    myLog = data;
//  }
//
//  public String displayData(){
//    long timeStamp = SystemClock.elapsedRealtime();
//    String logging = timeStamp + myLog;
//
//    return logging;
//  }
//}



















