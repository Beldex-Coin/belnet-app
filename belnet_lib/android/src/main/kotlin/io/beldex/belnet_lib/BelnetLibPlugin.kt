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

                val belnetIntent = Intent(activityBinding.activity.applicationContext, BelnetDaemon::class.java).apply {
                    action = BelnetDaemon.ACTION_CONNECT
                    putExtra(BelnetDaemon.EXIT_NODE, exitNode)
                    putExtra(BelnetDaemon.UPSTREAM_DNS, upstreamDNS)
                    packageNames?.let {
                        putStringArrayListExtra(BelnetDaemon.ALLOWED_APPS, ArrayList(it))
                    }
                }

                activityBinding.activity.applicationContext.startService(belnetIntent)
                doBindService()
                result.success(true)
            }
            "disconnect" -> {
                val intent = VpnService.prepare(activityBinding.activity.applicationContext)
                if (intent != null) {
                    result.success(false)
                    return
                }
                val belnetIntent = Intent(activityBinding.activity.applicationContext, BelnetDaemon::class.java).apply {
                    action = BelnetDaemon.ACTION_DISCONNECT
                }
                activityBinding.activity.applicationContext.startService(belnetIntent)
                doBindService()
                Log.d("BelnetLibPlugin", "Disconnect called")
                result.success(true)
            }
            "isRunning" -> {
                result.success(boundService?.IsRunning() ?: false)
            }
            "getStatus" -> {
                result.success(boundService?.DumpStatus() ?: false)
                Log.d("BelnetLibPlugin", "getStatus: ${boundService?.DumpStatus()}")
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
                if (boundService == null) {
        Log.w("BelnetLibPlugin", "getDataStatus: Service not bound")
        result.success(false)
        return
    }

    try {
        val status = boundService?.GetStatus()
        Log.d("BelnetLibPlugin", "getDataStatus: $status")
        result.success(status)
    } catch (e: Exception) {
        Log.e("BelnetLibPlugin", "Exception in getDataStatus", e)
        result.success(false)
    }
               // result.success(boundService?.GetStatus() ?: false)
               // Log.d("BelnetLibPlugin", "getDataStatus: ${boundService?.GetStatus()}")
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