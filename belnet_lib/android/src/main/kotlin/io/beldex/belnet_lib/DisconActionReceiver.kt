package io.beldex.belnet_lib

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import network.beldex.belnet.BelnetDaemon

class DisconActionReceiver : BroadcastReceiver() {
    private var mDaemon: BelnetDaemon? = null
    private var bPlug: BelnetLibPlugin? = null;
    override fun onReceive(p0: Context?, p1: Intent?) {

        when(p1?.action){
            DISCONNECT_ACTION -> {
                mDaemon?.disconnectNotificationButton()
               // bPlug!!.disConnectButtonCall();
            }
        }
    }
    companion object {
        const val DISCONNECT_ACTION = "DISCONNECT_ACTION"
        fun createIntent (context : Context,action : String) =
            Intent(context, DisconActionReceiver::class.java).apply { this.action = action }
    }
}