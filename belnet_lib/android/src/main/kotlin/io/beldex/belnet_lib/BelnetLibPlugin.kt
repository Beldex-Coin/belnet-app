package io.beldex.belnet_lib


//import android.R.attr.name

//import android.R.attr.name


//import android.content.Context



import android.app.Activity.RESULT_OK
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.net.*
import android.os.IBinder
import android.util.Log
import androidx.annotation.NonNull
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.Observer
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.embedding.engine.plugins.lifecycle.HiddenLifecycleReference
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.PluginRegistry
import network.beldex.belnet.BelnetDaemon



//import android.R.attr.name




//import android.R.attr.name
//import android.R.attr.name








/** BelnetLibPlugin */
class BelnetLibPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    private var mShouldUnbind: Boolean = false
    private var mBoundService: BelnetDaemon? = null

    private lateinit var activityBinding: ActivityPluginBinding

    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private lateinit var mMethodChannel: MethodChannel
    private lateinit var mIsConnectedEventChannel: EventChannel

    private var mEventSink: EventChannel.EventSink? = null
    private var mIsConnectedObserver =
            Observer<Boolean> { newIsConnected ->
                // Propagate to the dart package.
                mEventSink?.success(newIsConnected)
            }

    private var mLifecycleOwner =
            object : LifecycleOwner {
                override fun getLifecycle(): Lifecycle {
                    return (activityBinding.lifecycle as HiddenLifecycleReference).lifecycle
                }
            }

    override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        System.loadLibrary("belnet-android")

        mMethodChannel = MethodChannel(binding.binaryMessenger, "belnet_lib_method_channel")
        mMethodChannel.setMethodCallHandler(this)

        mIsConnectedEventChannel =
                EventChannel(binding.binaryMessenger, "belnet_lib_is_connected_event_channel")
        mIsConnectedEventChannel.setStreamHandler(
                object : EventChannel.StreamHandler {
                    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                        mEventSink = events
                    }

                    override fun onCancel(arguments: Any?) {
                        mEventSink?.endOfStream()
                        mEventSink = null
                    }
                }
        )
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        mMethodChannel.setMethodCallHandler(null)

        doUnbindService()
    }


    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: MethodChannel.Result) {
        when (call.method) {
            "prepare" -> {
                val intent = VpnService.prepare(activityBinding.activity.applicationContext)
                if (intent != null) {
                    var listener: PluginRegistry.ActivityResultListener? = null
                    listener =
                            PluginRegistry.ActivityResultListener { req, res, _ ->
                                if (req == 0 && res == RESULT_OK) {
                                    result.success(true)
                                } else {
                                    result.success(false)
                                }
                                listener?.let { activityBinding.removeActivityResultListener(it) }
                                true
                            }
                    activityBinding.addActivityResultListener(listener)
                    activityBinding.activity.startActivityForResult(intent, 0)
                } else {
                    // If intent is null, already prepared
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
                    // Not prepared yet
                    result.success(false)
                    return
                }

                val exitNode = call.argument<String>("exit_node")
                val upstreamDNS = call.argument<String>("upstream_dns")

                val belnetIntent =
                        Intent(
                                activityBinding.activity.applicationContext,
                                BelnetDaemon::class.java
                        )
                belnetIntent.action = BelnetDaemon.ACTION_CONNECT
                belnetIntent.putExtra(BelnetDaemon.EXIT_NODE, exitNode)
                belnetIntent.putExtra(BelnetDaemon.UPSTREAM_DNS, upstreamDNS)

                activityBinding.activity.applicationContext.startService(belnetIntent)
                doBindService()

                result.success(true)
            }
            "disconnect" -> {
                var intent = VpnService.prepare(activityBinding.activity.applicationContext)
                if (intent != null) {
                    // Not prepared yet
                    result.success(false)
                    return
                }
                val belnetIntent =
                        Intent(
                                activityBinding.activity.applicationContext,
                                BelnetDaemon::class.java
                        )
               belnetIntent.action = BelnetDaemon.ACTION_DISCONNECT

                activityBinding.activity.applicationContext.startService(belnetIntent)

            doBindService()
                Log.d("Test","inside disconnect function")

                result.success(true)
            }
            "isRunning" -> {
                if (mBoundService != null) {
                    result.success(mBoundService!!.IsRunning())
                } else {
                    result.success(false)
                }
            }
            "getStatus" -> {
                if (mBoundService != null) {
                    result.success(mBoundService!!.DumpStatus())
                    Log.d("Test","mBoundService is " + mBoundService)
                } else {
                    result.success(false)
                }
            }


            else -> result.notImplemented()
        }
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityBinding = binding
        doBindService()
    }

    override fun onDetachedFromActivity() {
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activityBinding = binding
        doBindService()
    }

    override fun onDetachedFromActivityForConfigChanges() {}

    private val mConnection: ServiceConnection =
            object : ServiceConnection {
                override fun onServiceConnected(className: ComponentName, service: IBinder) {
                    mBoundService = (service as BelnetDaemon.LocalBinder).getService()

                    mBoundService?.isConnected()?.observe(mLifecycleOwner, mIsConnectedObserver)
                }

                override fun onServiceDisconnected(className: ComponentName) {
                    mBoundService = null

                }
            }

    fun doBindService() {
        if (activityBinding.activity.applicationContext.bindService(
                        Intent(
                                activityBinding.activity.applicationContext,
                                BelnetDaemon::class.java
                        ),
                        mConnection,
                        Context.BIND_AUTO_CREATE
                )
        ) {
            mShouldUnbind = true
        } else {
            Log.e(
                    BelnetDaemon.LOG_TAG,
                    "Error: The requested service doesn't exist, or this client isn't allowed access to it."
            )
        }
    }

    fun doUnbindService() {
        if (mShouldUnbind) {
            activityBinding.activity.applicationContext.unbindService(mConnection)
            mShouldUnbind = false
        }
    }






}
