package network.beldex.belnet;
//
//import static io.beldex.belnet_lib.BelnetLibPluginKt.buildStatusForNotification;

import android.annotation.SuppressLint;
import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.net.TrafficStats;
import android.net.Uri;
import android.net.VpnService;
import android.os.Binder;
import android.os.Build;
import android.os.Handler;
import android.os.IBinder;
import android.os.ParcelFileDescriptor;
import android.os.SystemClock;
import android.text.TextUtils;
import android.util.Log;

import androidx.annotation.RequiresApi;
import androidx.core.app.NotificationCompat;
import androidx.core.app.NotificationManagerCompat;
import androidx.lifecycle.LiveData;
import androidx.lifecycle.MutableLiveData;
import java.nio.ByteBuffer;
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

import io.beldex.belnet_lib.R;
import io.beldex.belnet_lib.UpdateNetwork;


public class BelnetDaemon extends VpnService{

  public static final String ACTION_CONNECT = "network.beldex.belnet.START";
  public static final String ACTION_DISCONNECT = "network.beldex.belnet.STOP";
  public static final String LOG_TAG = "BelnetDaemon";
  public static final String MESSAGE_CHANNEL = "BELNET_DAEMON";
  public static final String EXIT_NODE = "EXIT_NODE";
  public static final String UPSTREAM_DNS = "UPSTREAM_DNS";
  public static final String NOTIFICATION_ID = "NOTIFICATION_ID";
  private static final String DEFAULT_EXIT_NODE = "7a4cpzri7qgqen9a3g3hgfjrijt9337qb19rhcdmx5y7yttak33o.bdx";
  private static final String DEFAULT_UPSTREAM_DNS = "1.1.1.1";
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
    Log.d(LOG_TAG, "Connected timer is "+ mUpdateIsConnectedTimer.toString());
    //if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
      //createNotificationChannel();

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
    disconnect();
    super.onDestroy();

  }



  public void updateTheData(Boolean isRunning){
    updateNotify = new UpdateNetwork(isRunning).myData;
  }





  private void clearNotifications() {
    if (mNotificationManager != null)
      mNotificationManager.cancelAll();

  }


//
//  @RequiresApi(api = Build.VERSION_CODES.O)
//  private void createNotificationChannel() {
//    NotificationManager mNotificationManager = null;
//    //if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
//    mNotificationManager = (NotificationManager) getSystemService(Context.NOTIFICATION_SERVICE);
//    //}
//    String name = "Belnet";
//    NotificationChannel mChannel = new NotificationChannel(NOTIFICATION_CHANNEL_ID, name, NotificationManager.IMPORTANCE_LOW);
//    mChannel.setDescription("Belnet is Connected");
//    mChannel.enableLights(false);
//    mChannel.enableVibration(false);
//    mChannel.setShowBadge(false);
//    mChannel.setLockscreenVisibility(Notification.VISIBILITY_SECRET);
//    mNotificationManager.createNotificationChannel(mChannel);
//  }
//
//
//  @SuppressLint({"RestrictedApi", "SuspiciousIndentation"})
//  public void showToolbarNotification(String notifyMsg, int notifyType,int icon) {
////    Log.d("NotifyNet",networkSpeeds);
//    Log.d("showToolbarNotification","notifymsg"+notifyMsg);
//    Intent intent = getPackageManager().getLaunchIntentForPackage(getPackageName());
//    PendingIntent pendIntent = PendingIntent.getActivity(BelnetDaemon.this, 0, intent, PendingIntent.FLAG_IMMUTABLE);
//
//
//
//
//    if (mNotifyBuilder == null) {
//      mNotificationManager = (NotificationManager) getSystemService(Context.NOTIFICATION_SERVICE);
//      mNotifyBuilder = new NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
//              .setSmallIcon(R.drawable.ic_stat)
//              .setContentIntent(pendIntent)
//              .setCategory(Notification.CATEGORY_SERVICE);
//    }
//    mNotifyBuilder.setOngoing(true);
//
////    String title ;
////
////  title= notifyMsg;
//    mNotifyBuilder.addAction(R.drawable.ic_stat,"Disconnect",pendIntent);
//    mNotifyBuilder.setContentTitle("Belnet");
//    mNotifyBuilder.setContentText(notifyMsg);
//    mNotifyBuilder.mActions.clear();
//    mNotifyBuilder.setOnlyAlertOnce(true);
//
//    mNotificationManager.notify(notifyType,mNotifyBuilder.build());
//    startForeground(NOTIFY_ID, mNotifyBuilder.build());
//  }
//


//
//public Notification buildStatusForNotification(String trafficUpdate,Context context){
//  String notificationContentString = trafficUpdate;
//
//  Log.e("Build","buildStatus"+ trafficUpdate);
//   NotificationCompat.Builder builder =
//          new NotificationCompat.Builder(context, BelnetDaemon.NOTIFICATION_ID)
//                  .setSmallIcon(R.drawable.ic_stat)
//                  .setContentTitle("Belnet")
//                  .setContentText(notificationContentString)
//                  .setOngoing(true)
//                  .setOnlyAlertOnce(true)
//                  .setCategory(NotificationCompat.CATEGORY_SERVICE);
//
//   Log.d("NotificationObject", String.valueOf(builder.build()));
//  return builder.build();
//
//}


  public void sendNotification(String notificationString,Context context){


//    Log.d("sendNotificationCall","sendNotify");
//    if(mNotifyBuilder == null){
//      Log.d("sendNotificationCall","if notify builder is empty");
//      mNotifyBuilder = new NotificationCompat.Builder(context,NOTIFICATION_CHANNEL_ID)
//              .setContentTitle("belnet")
//              .setContentText(notificationString)
//              .setSmallIcon(R.drawable.ic_stat);
//    }
//    mNotifyBuilder.setOnlyAlertOnce(true);
////  NotificationCompat.Builder notificationBuilder =
////          new NotificationCompat.Builder(getApplicationContext())
////                  .setContentTitle("Belnet")
////                  .setContentText(notificationString)
////                  .setSmallIcon(R.drawable.ic_stat);
////  NotificationManagerCompat notificationManager =
////          NotificationManagerCompat.from(this);
//  // Build the notification and issues it with notification manager.
//  mNotificationManager.notify(NOTIFY_ID, mNotifyBuilder.build());

  }


//public void getStringForNotify(String data){
//
//    updateNotify = data;
//  Log.d("getStringFornotify","data "+updateNotify);
//  jstUpdate(data);
//}

//public void jstUpdate(String data){
//    mNotifyBuilder.setContentText(data);
//    mNotificationManager.notify(NOTIFY_ID, mNotifyBuilder.build());
//}


//
//  public void notificationFunctionCall(String actionState,String data){
//
//    Intent intent = getPackageManager().getLaunchIntentForPackage(getPackageName());
//    PendingIntent pendIntent = PendingIntent.getActivity(BelnetDaemon.this, 0, intent, PendingIntent.FLAG_IMMUTABLE);
////                   long sessionDownloaded = 0L;
////                   long sessionUploaded = 0L;
////                   long lastTotalDownload = 0L;
////                   long lastTotalUpload = 0L;
////                   long sessionStart = 0L;
////                   long lastTimestamp = 0L;
////                   long timestamp = SystemClock.elapsedRealtime();
////                   long elapsedMillis = timestamp - lastTimestamp;
////                   float elapsedSeconds = elapsedMillis / 1000f;
////
////                   // Speeds need to be divided by two due to TrafficStats calculating both phone and VPN
////                   // interfaces which leads to doubled data. NetworkStatsManager may have solved this
////                   // problem but is only available from marshmallow.
////                   long totalDownload = TrafficStats.getTotalRxBytes();
////                   Log.d("rxbyte","byes"+totalDownload);
////
////                   long totalUpload = TrafficStats.getTotalTxBytes();
////                   Log.d("txbyte","byes"+totalUpload);
////                   long downloaded = (totalDownload - lastTotalDownload) / 2;
////                   long uploaded = (totalUpload - lastTotalUpload) / 2;
////                   long downloadSpeed = Math.round(downloaded / elapsedSeconds);
////                   long uploadSpeed = Math.round(uploaded / elapsedSeconds);
////                   String sessionUploadString = ConnectionTools.bytesToSize(sessionUploaded);
////                   String downloadSpeedString =ConnectionTools.bytesToSize(downloadSpeed) +"ps";
////                   String  sessionDownloadString = ConnectionTools.bytesToSize(sessionDownloaded);
////                   String uploadSpeedString = ConnectionTools.bytesToSize(uploadSpeed) +"ps";
////                   String notificationString = "↓ "+downloadSpeedString + " ↑ "+ uploadSpeedString;
//
//    //updata = notificationString;
//
//
//    if(BelnetDaemon.ACTION_CONNECT.equals(actionState)){
//      mNotifyBuilder.setContentText(data);
//      mNotifyBuilder.addAction(R.drawable.ic_stat,"Disconnect",pendIntent);
//      mNotificationManager.notify(NOTIFY_ID,mNotifyBuilder.build());
//    }else{
//      clearNotifications();
//    }
//
//
//
//  }






  @Override
  public int onStartCommand(Intent intent, int flags, int startID) {
    Log.d(LOG_TAG, "onStartCommand()");
    new BelnetLibPlugin().logDataToFrontend("onstart");
    String action = intent != null ? intent.getAction() : "";


    if (ACTION_DISCONNECT.equals(action)) {
      Log.d("callingbelnetDeamon","true");
      isCalling = false;
      disconnect();
      stopSelf();
      clearNotifications();

      String disconData = ": TurnExitOFF =>\n" +
              "TurnExitOFF OK result <= OK\n" +
              "exitNode set by daemon:";




//      updateTheData(false);
      //  notificationFunctionCall(false);

      return START_NOT_STICKY;
    } else {
      ArrayList<ConfigValue> configVals = new ArrayList<ConfigValue>();

      String exitNode = "7a4cpzri7qgqen9a3g3hgfjrijt9337qb19rhcdmx5y7yttak33o.bdx";
      String upstreamDNS = null;

      SharedPreferences sharedPreferences = getSharedPreferences("belnet_lib", MODE_PRIVATE);

      if (ACTION_CONNECT.equals(action)) {


        // started by the app
        exitNode = intent.getStringExtra(EXIT_NODE);
        upstreamDNS = intent.getStringExtra(UPSTREAM_DNS);
        isCalling = true;
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
        new BelnetLibPlugin().logDataToFrontend("No upstream DNS configured! Proceeding with default."); //i
      }

      Log.e(LOG_TAG, "Using " + upstreamDNS + " as upstream DNS.");
      configVals.add(new ConfigValue("dns", "upstream", upstreamDNS));

      // set log level to info
      configVals.add(new ConfigValue("logging", "level", "info"));
      // sendNotification("belnet started", this);
      //updateTheData(true);
      // showToolbarNotification(updateNotify,NOTIFY_ID,R.drawable.ic_stat);

      boolean connectedSuccessfully = connect(configVals);
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
      new BelnetLibPlugin().logDataToFrontend("started successfully!"); //i new BelnetLibPlugin().logDataToFrontend("started successfully!"); //i added
    } else {
      Log.d(LOG_TAG, "already running");
      new BelnetLibPlugin().logDataToFrontend("already running");
    }

    updateIsConnected();
    Intent browserI = new Intent(Intent.ACTION_VIEW,Uri.parse("https://whatismyipaddress.com/"));
    startActivity(browserI);
    return true;

  }

  private void disconnect() {
    if (IsRunning()) {
      Stop();
      // stopSelf();
      stopForeground(true);
    }
    if (impl != null) {
      //Free(impl);
      impl = null;
    }

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



















