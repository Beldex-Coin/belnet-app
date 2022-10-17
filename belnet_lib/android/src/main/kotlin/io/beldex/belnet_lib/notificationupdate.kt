package io.beldex.belnet_lib

import android.net.TrafficStats
import android.os.SystemClock
import android.util.Log
import network.beldex.belnet.BelnetDaemon
import network.beldex.belnet.ConnectionTools
import kotlin.math.roundToLong

class UpdateNetwork(private var isDownload:Boolean){
    private var lastTimestamp = 0L
    private var sessionDownloaded = 0L
    private var sessionUploaded = 0L
    private var lastTotalDownload = 0L
    private var lastTotalUpload = 0L
    private var sessionStart = 0L
    lateinit var uploadSpeedString: String
    lateinit var downloadSpeedString: String
    lateinit var  notificationString: String
    lateinit var myData: String
    var bools = true
    fun callfunctionContinuesly(displayValue: String): String{
//       if(isDownload) {
        myData = displayValue
        Log.e("myDataWorking",myData)
        val timestamp = SystemClock.elapsedRealtime()
        val elapsedMillis = timestamp - lastTimestamp
        val elapsedSeconds = elapsedMillis / 1000f

        // Speeds need to be divided by two due to TrafficStats calculating both phone and VPN
        // interfaces which leads to doubled data. NetworkStatsManager may have solved this
        // problem but is only available from marshmallow.
        val totalDownload = TrafficStats.getTotalRxBytes()
        val totalUpload = TrafficStats.getTotalTxBytes()
        val downloaded = (totalDownload - lastTotalDownload).coerceAtLeast(0) / 2
        val uploaded = (totalUpload - lastTotalUpload).coerceAtLeast(0) / 2
        val downloadSpeed = (downloaded / elapsedSeconds).roundToLong()
        val uploadSpeed = (uploaded / elapsedSeconds).roundToLong()

        sessionDownloaded += downloaded
        sessionUploaded += uploaded

        val sessionTimeSeconds = (timestamp - sessionStart).toInt() / 1000
        val downloadString = ConnectionTools.bytesToSize(downloadSpeed) + "ps"
        Log.d("TagDownload", "This is downloadString$downloadString")

        //String sessionUploadString = ConnectionTools.bytesToSize(sessionUploaded);
        downloadSpeedString = ConnectionTools.bytesToSize(downloadSpeed) + "ps"
        // String  sessionDownloadString = ConnectionTools.bytesToSize(sessionDownloaded);
        // String  sessionDownloadString = ConnectionTools.bytesToSize(sessionDownloaded);
        uploadSpeedString = ConnectionTools.bytesToSize(uploadSpeed) + "ps"
        notificationString = "↓ $downloadSpeedString ↑ $uploadSpeedString"

        lastTotalDownload = totalDownload
        lastTotalUpload = totalUpload
        lastTimestamp = timestamp


        notificationUpdate(displayValue)


        //  Thread.sleep(7000);
        // }
        return displayValue
    }


    fun notificationUpdate(displayValue : String){
        BelnetDaemon().mNotifyBuilder.setContentText(displayValue)
        BelnetDaemon().mNotificationManager.notify(BelnetDaemon.NOTIFY_ID,BelnetDaemon().mNotifyBuilder.build())
    }

}