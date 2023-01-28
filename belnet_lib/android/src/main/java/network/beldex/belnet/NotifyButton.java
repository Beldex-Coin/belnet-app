package network.beldex.belnet;

import android.content.Intent;
import android.util.Log;

import java.util.Timer;

public class NotifyButton extends BelnetDaemon {
    @Override
    public void onCreate() {
        Log.d("NOTIFY","Oncreate function call");
        disconnectNotificationButton();
        super.onCreate();
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startID) {

        return super.onStartCommand(intent, flags, startID);
    }
}
