package io.beldex.belnet_lib

import android.annotation.SuppressLint
import android.app.Activity
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.net.TrafficStats
import android.net.VpnService
import android.os.IBinder
import android.os.SystemClock
import android.util.Log
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.Observer
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.PluginRegistry
import network.beldex.belnet.BelnetDaemon
import network.beldex.belnet.ConnectionTools
import kotlin.math.roundToLong



import android.content.BroadcastReceiver
import android.content.IntentFilter


import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.util.Base64
import java.io.ByteArrayOutputStream
import android.content.pm.ApplicationInfo

import kotlinx.coroutines.*
import android.os.Handler
import android.os.Looper


import android.graphics.drawable.AdaptiveIconDrawable
import android.net.ConnectivityManager
import android.os.Build
import android.app.usage.NetworkStats
import android.app.usage.NetworkStatsManager
import androidx.core.content.ContextCompat
import androidx.core.graphics.drawable.toBitmap
import android.graphics.drawable.BitmapDrawable
import org.json.JSONObject

/** BelnetLibPlugin */
class BelnetLibPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    private var shouldUnbind: Boolean = false
    private var boundService: BelnetDaemon? = null
    private var lastTimestamp = 0L
    private lateinit var activityBinding: ActivityPluginBinding
    private var sessionDownloaded = 0L
    private var sessionUploaded = 0L
    private var lastTotalDownload = 0L
    private var lastTotalUpload = 0L
    private var sessionStart = 0L
    private lateinit var methodChannel: MethodChannel
    private lateinit var isConnectedEventChannel: EventChannel
    private var eventSink: EventChannel.EventSink? = null
    private lateinit var notificationDisconnectEventChannel: EventChannel
    private var disconnectEventSink: EventChannel.EventSink? = null
     private lateinit var notificationDisconnectReceiver: BroadcastReceiver
    private lateinit var networkChangeEventChannel: EventChannel
    private var networkChangeEventSink: EventChannel.EventSink? = null
    private var networkChangeReceiver: BroadcastReceiver? = null
    private lateinit var statusEventChannel: EventChannel
    private var statusEventSink: EventChannel.EventSink? = null
    private var statusHandler: Handler? = null
    private var statusRunnable: Runnable? = null
    private val speedMeter = SpeedMeter()


    // Observe the isConnected LiveData
    private val isConnectedObserver = Observer<Boolean> { isConnected ->
        eventSink?.success(isConnected)
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        System.loadLibrary("belnet-android")

        methodChannel = MethodChannel(binding.binaryMessenger, "belnet_lib_method_channel")
        methodChannel.setMethodCallHandler(this)

        isConnectedEventChannel = EventChannel(binding.binaryMessenger, "belnet_lib_is_connected_event_channel")
        isConnectedEventChannel.setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                    // Start observing isConnected when the stream is listened to
                    boundService?.isConnected()?.observe(activityBinding.activity as LifecycleOwner, isConnectedObserver)
                }

                override fun onCancel(arguments: Any?) {
                    eventSink?.endOfStream()
                    eventSink = null
                    // Stop observing when the stream is canceled
                    boundService?.isConnected()?.removeObserver(isConnectedObserver)
                }
            }
        )





        notificationDisconnectEventChannel = EventChannel(binding.binaryMessenger, "belnet_lib_notification_disconnect_event_channel")
        notificationDisconnectEventChannel.setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    disconnectEventSink = events
                    notificationDisconnectReceiver = object : BroadcastReceiver() {
                        override fun onReceive(context: Context?, intent: Intent?) {
                            if (intent?.action == "com.belnet.NOTIFICATION_DISCONNECTED") {
                                Log.d("BelnetLibPlugin", "Received notification disconnect broadcast")
                                disconnectEventSink?.success("notification_disconnect")
                            }
                        }
                    }
                    val filter = IntentFilter("com.belnet.NOTIFICATION_DISCONNECTED")
                    activityBinding.activity.registerReceiver(notificationDisconnectReceiver, filter)
                }

                override fun onCancel(arguments: Any?) {
                    disconnectEventSink = null
                    try {
                        notificationDisconnectReceiver?.let {
                            activityBinding.activity.unregisterReceiver(it)
                        }
                    } catch (e: Exception) {
                        Log.e("BelnetLibPlugin", "Receiver already unregistered: ${e.message}")
                    }
                }
            }
        )

        // Underlying-network change events from BelnetDaemon (Wi-Fi <-> mobile
        // handover). The Flutter side uses this to run an immediate tunnel
        // health probe instead of waiting for the next periodic one.
        networkChangeEventChannel = EventChannel(binding.binaryMessenger, "belnet_lib_network_change_event_channel")
        networkChangeEventChannel.setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    networkChangeEventSink = events
                    networkChangeReceiver = object : BroadcastReceiver() {
                        override fun onReceive(context: Context?, intent: Intent?) {
                            if (intent?.action == BelnetDaemon.ACTION_NETWORK_CHANGED) {
                                Log.d("BelnetLibPlugin", "Received network change broadcast")
                                networkChangeEventSink?.success("network_changed")
                            }
                        }
                    }
                    val filter = IntentFilter(BelnetDaemon.ACTION_NETWORK_CHANGED)
                    ContextCompat.registerReceiver(
                        activityBinding.activity,
                        networkChangeReceiver,
                        filter,
                        ContextCompat.RECEIVER_NOT_EXPORTED
                    )
                }

                override fun onCancel(arguments: Any?) {
                    networkChangeEventSink = null
                    try {
                        networkChangeReceiver?.let {
                            activityBinding.activity.unregisterReceiver(it)
                        }
                    } catch (e: Exception) {
                        Log.e("BelnetLibPlugin", "network change receiver already unregistered: ${e.message}")
                    }
                    networkChangeReceiver = null
                }
            }
        )

        // Consolidated status feed: one 1 Hz tick doing ONE GetStatus() JNI
        // call and ONE TrafficStats sample, pushed to Dart. Replaces the six
        // independent Dart timers that each crossed the platform channel
        // every 1-2 seconds.
        statusEventChannel = EventChannel(binding.binaryMessenger, "belnet_lib_status_event_channel")
        statusEventChannel.setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    statusEventSink = events
                    statusHandler = Handler(Looper.getMainLooper())
                    statusRunnable = object : Runnable {
                        override fun run() {
                            emitStatus()
                            statusHandler?.postDelayed(this, 1000)
                        }
                    }
                    statusHandler?.post(statusRunnable!!)
                }

                override fun onCancel(arguments: Any?) {
                    statusRunnable?.let { statusHandler?.removeCallbacks(it) }
                    statusRunnable = null
                    statusHandler = null
                    statusEventSink = null
                }
            }
        )
    }

    private fun emitStatus() {
        val sink = statusEventSink ?: return
        val speeds = speedMeter.sample()
        val payload = JSONObject()
        try {
            val raw = boundService?.GetStatus()
            payload.put(
                "status",
                if (raw.isNullOrEmpty()) JSONObject.NULL else JSONObject(raw)
            )
        } catch (e: Exception) {
            payload.put("status", JSONObject.NULL)
        }
        payload.put("upload", speeds.first)
        payload.put("download", speeds.second)
        payload.put("isRunning", boundService?.IsRunning() ?: false)
        sink.success(payload.toString())
    }

    /**
     * Device-level throughput sampling shared by the status feed and the
     * legacy getUploadSpeed/getDownloadSpeed handlers. Values are halved
     * because with the VPN active TrafficStats counts every payload byte
     * twice (once on the tun device, once on the physical interface).
     */
    private class SpeedMeter {
        private var lastTimestamp = 0L
        private var lastRx = 0L
        private var lastTx = 0L

        /** Returns Pair(uploadBytesPerSec, downloadBytesPerSec). */
        fun sample(): Pair<Long, Long> {
            val now = SystemClock.elapsedRealtime()
            val rx = TrafficStats.getTotalRxBytes()
            val tx = TrafficStats.getTotalTxBytes()
            if (lastTimestamp == 0L) {
                lastTimestamp = now
                lastRx = rx
                lastTx = tx
                return Pair(0L, 0L)
            }
            val dt = (now - lastTimestamp) / 1000f
            if (dt <= 0f) return Pair(0L, 0L)
            val up = (((tx - lastTx).coerceAtLeast(0) / 2) / dt).roundToLong()
            val down = (((rx - lastRx).coerceAtLeast(0) / 2) / dt).roundToLong()
            lastTimestamp = now
            lastRx = rx
            lastTx = tx
            return Pair(up, down)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
         try {
            notificationDisconnectReceiver?.let {
                activityBinding.activity.unregisterReceiver(it)
            }
        } catch (e: Exception) {
            Log.e("BelnetLibPlugin", "Failed to unregister receiver: ${e.message}")  
        }
        doUnbindService()
    }

    @SuppressLint("NewApi")
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "prepare" -> {
                val intent = VpnService.prepare(activityBinding.activity.applicationContext)
                if (intent != null) {
                    val listener = object : PluginRegistry.ActivityResultListener {
                        override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
                            activityBinding.removeActivityResultListener(this)
                            result.success(requestCode == 0 && resultCode == Activity.RESULT_OK)
                            return true
                        }
                    }
                    activityBinding.addActivityResultListener(listener)
                    activityBinding.activity.startActivityForResult(intent, 0)
                } else {
                    result.success(true)
                }
            }
            "isPrepared" -> {
                val intent = VpnService.prepare(activityBinding.activity.applicationContext)
                result.success(intent == null)
            }
            "connect" -> {
                val intent = VpnService.prepare(activityBinding.activity.applicationContext)
                if (intent != null) {
                    result.success(false)
                    return
                }

                val exitNode = call.argument<String>("exit_node")
                val upstreamDNS = call.argument<String>("upstream_dns")
                val packageNames = call.argument<List<String>>("package_names")
                val logLevel = call.argument<String>("log_level")
                val mtu = call.argument<Int>("mtu")
                val routeIpv6 = call.argument<Boolean>("route_ipv6")

                val belnetIntent = Intent(activityBinding.activity.applicationContext, BelnetDaemon::class.java).apply {
                    action = BelnetDaemon.ACTION_CONNECT
                    putExtra(BelnetDaemon.EXIT_NODE, exitNode)
                    putExtra(BelnetDaemon.UPSTREAM_DNS, upstreamDNS)
                    putExtra(BelnetDaemon.LOG_LEVEL, logLevel ?: "warn")
                    putExtra(BelnetDaemon.MTU, mtu ?: 1500)
                    putExtra(BelnetDaemon.ROUTE_IPV6, routeIpv6 ?: true)
                    packageNames?.let {
                        putStringArrayListExtra(BelnetDaemon.ALLOWED_APPS, ArrayList(it))
                    }
                }

                activityBinding.activity.applicationContext.startService(belnetIntent)
                doBindService()
                result.success(true)
            }
            "disconnect" -> {
                // val intent = VpnService.prepare(activityBinding.activity.applicationContext)
                // if (intent != null) {
                //     result.success(false)
                //     return
                // }
                // val belnetIntent = Intent(activityBinding.activity.applicationContext, BelnetDaemon::class.java).apply {
                //     action = BelnetDaemon.ACTION_DISCONNECT
                // }
                // activityBinding.activity.applicationContext.startService(belnetIntent)
                // doBindService()
                // Log.d("BelnetLibPlugin", "Disconnect called")
                // result.success(true)
                val ctx = activityBinding.activity.applicationContext
                val belnetIntent = Intent(ctx, BelnetDaemon::class.java).apply {
                    action = BelnetDaemon.ACTION_DISCONNECT
                }
                ctx.startService(belnetIntent)
                doBindService()
                Log.d("BelnetLibPlugin", "Disconnect called")
                result.success(true)
            }
            "isRunning" -> {
                result.success(boundService?.IsRunning() ?: false)
            }
            "getStatus" -> {
                // Return null (not false) when unbound, and do NOT call
                // DumpStatus() a second time just for logging - it serializes
                // the full daemon status through JNI on every poll.
                result.success(boundService?.DumpStatus())
            }
            "getUploadSpeed" -> {
                val timestamp = SystemClock.elapsedRealtime()
                val elapsedMillis = timestamp - lastTimestamp
                val elapsedSeconds = elapsedMillis / 1000f

                val totalUpload = TrafficStats.getTotalTxBytes()
                val uploaded = (totalUpload - lastTotalUpload).coerceAtLeast(0) / 2
                val uploadSpeed = (uploaded / elapsedSeconds).roundToLong()

                sessionUploaded += uploaded
                val uploadString = ConnectionTools.bytesToSize(uploadSpeed) + "ps"
                result.success(uploadString)

                lastTotalUpload = totalUpload
                lastTimestamp = timestamp
            }
            "getDownloadSpeed" -> {
                val timestamp = SystemClock.elapsedRealtime()
                val elapsedMillis = timestamp - lastTimestamp
                val elapsedSeconds = elapsedMillis / 1000f

                val totalDownload = TrafficStats.getTotalRxBytes()
                val totalUpload = TrafficStats.getTotalTxBytes()
                val downloaded = (totalDownload - lastTotalDownload).coerceAtLeast(0) / 2
                val uploaded = (totalUpload - lastTotalUpload).coerceAtLeast(0) / 2
                val downloadSpeed = (downloaded / elapsedSeconds).roundToLong()

                sessionDownloaded += downloaded
                sessionUploaded += uploaded

                val downloadString = ConnectionTools.bytesToSize(downloadSpeed) + "ps"
                Log.d("BelnetLibPlugin", "Download speed: $downloadString")
                result.success(downloadString)

                lastTotalDownload = totalDownload
                lastTotalUpload = totalUpload
                lastTimestamp = timestamp
            }
            "getDataStatus" -> {
                // Used by the Dart-side connection status polling. Must return
                // null (never `false`) when the service is not bound so the
                // Dart layer keeps polling instead of crashing on a cast.
                val service = boundService
                if (service == null) {
                    Log.w("BelnetLibPlugin", "getDataStatus: Service not bound yet")
                    result.success(null)
                    return
                }
                try {
                    result.success(service.GetStatus())
                } catch (e: Exception) {
                    Log.e("BelnetLibPlugin", "Exception in getDataStatus", e)
                    result.success(null)
                }
            }

       "getMap" -> {
                // Exit-node remap. The native call is asynchronous; only
                // reply once the JNI Unmap completes (delivered on the main
                // thread). Reply null when the service is not bound so the
                // Dart side treats it as "not confirmed" and keeps polling.
                val swapNode = call.argument<String>("swap_node")
                val service = boundService
                if (service == null || swapNode == null) {
                    Log.w("BelnetLibPlugin", "getMap: service not bound or no swap_node")
                    result.success(null)
                    return
                }
                var replied = false
                service.unmappingNode(swapNode) { value ->
                    if (!replied) {
                        replied = true
                        result.success(value)
                    }
                }
            }



            "getInstalledAppsWithInternetPermission" -> {
               CoroutineScope(Dispatchers.Default).launch {
                val pm = activityBinding.activity.packageManager
    val apps = pm.getInstalledApplications(PackageManager.GET_META_DATA)
    val resultList = mutableListOf<Map<String, Any?>>()

    for (app in apps) {
        try {
            // Skip background-only services
            val launchIntent = pm.getLaunchIntentForPackage(app.packageName)
            if (launchIntent == null) continue

            // Check if app explicitly requested INTERNET permission
            val packageInfo = pm.getPackageInfo(app.packageName, PackageManager.GET_PERMISSIONS)
            val requestedPermissions = packageInfo.requestedPermissions?.toList() ?: emptyList()

            val explicitlyRequestedInternet = "android.permission.INTERNET" in requestedPermissions
            val hasInternetPermission = pm.checkPermission(
                android.Manifest.permission.INTERNET, app.packageName
            ) == PackageManager.PERMISSION_GRANTED

            if (!explicitlyRequestedInternet || !hasInternetPermission) continue

            val appName = pm.getApplicationLabel(app).toString()
            val packageName = app.packageName
            val isSystemApp = (app.flags and ApplicationInfo.FLAG_SYSTEM) != 0

            val drawable = pm.getApplicationIcon(app)

            // Ensure sharp icons (avoid blurry upscaling)
            val bitmap = when (drawable) {
                is BitmapDrawable -> drawable.bitmap
                else -> drawable.toBitmap(
                    width = drawable.intrinsicWidth.takeIf { it > 0 } ?: 192,
                    height = drawable.intrinsicHeight.takeIf { it > 0 } ?: 192,
                    config = Bitmap.Config.ARGB_8888
                )
            }

            val stream = ByteArrayOutputStream()
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
            val iconBase64 = Base64.encodeToString(stream.toByteArray(), Base64.NO_WRAP)

            resultList.add(
                mapOf(
                    "appName" to appName,
                    "packageName" to packageName,
                    "isSystemApp" to isSystemApp,
                    "icon" to iconBase64
                )
            )
        } catch (e: Exception) {
            e.printStackTrace()
            continue
        }
    }

    withContext(Dispatchers.Main) {
        result.success(resultList)
    }
        }
           }
            "disconnectForNotification" -> {
                result.success(boundService != null)
            }
            else -> result.notImplemented()
        }
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityBinding = binding
        doBindService()

        //         // Register for notification disconnect broadcast
        // notificationDisconnectReceiver = object : BroadcastReceiver() {
        //     override fun onReceive(context: Context?, intent: Intent?) {
        //         if (intent?.action == "com.belnet.NOTIFICATION_DISCONNECTED") {
        //             Log.d("BelnetLibPlugin", "Received notification disconnect broadcast")
        //             eventSink?.success("notification_clicked")
        //         }
        //     }
        // }
        // val filter = IntentFilter("com.belnet.NOTIFICATION_DISCONNECTED")
        // activityBinding.activity.registerReceiver(notificationDisconnectReceiver, filter)
    }

    override fun onDetachedFromActivity() {
        doUnbindService()
        //activityBinding.activity.unregisterReceiver(notificationDisconnectReceiver)
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activityBinding = binding
        doBindService()
    }

    override fun onDetachedFromActivityForConfigChanges() {
        doUnbindService()
        //activityBinding.activity.unregisterReceiver(notificationDisconnectReceiver)
    }

    private val connection: ServiceConnection = object : ServiceConnection {
        override fun onServiceConnected(className: ComponentName, service: IBinder) {
            boundService = (service as BelnetDaemon.LocalBinder).getService()
            // Observe isConnected LiveData when service is bound
            boundService?.isConnected()?.observe(activityBinding.activity as LifecycleOwner, isConnectedObserver)
        }

        override fun onServiceDisconnected(className: ComponentName) {
            boundService = null
        }
    }

    private fun doBindService() {
        if (activityBinding.activity.applicationContext.bindService(
                Intent(activityBinding.activity.applicationContext, BelnetDaemon::class.java),
                connection,
                Context.BIND_AUTO_CREATE
            )
        ) {
            shouldUnbind = true
        } else {
            Log.e(BelnetDaemon.LOG_TAG, "Failed to bind service: Service doesn't exist or access denied")
        }
    }

    private fun doUnbindService() {
        if (shouldUnbind) {
            boundService?.isConnected()?.removeObserver(isConnectedObserver)
            activityBinding.activity.applicationContext.unbindService(connection)
            shouldUnbind = false
        }
    }

    fun logDataToFrontend(sampleData: String): String {
        Log.d("BelnetLibPlugin", "logDataToFrontend: $sampleData")
        return sampleData
    }

    fun disConnectButtonCall() {
        Log.d("BelnetLibPlugin", "disConnectButtonCall invoked")
        val intent = VpnService.prepare(activityBinding.activity.applicationContext) ?: run {
            val belnetIntent = Intent(activityBinding.activity.applicationContext, BelnetDaemon::class.java).apply {
                action = BelnetDaemon.ACTION_DISCONNECT
            }
            activityBinding.activity.applicationContext.startService(belnetIntent)
            doBindService()
            return
        }
        Log.w("BelnetLibPlugin", "VPN not prepared for disconnect")
    }
}