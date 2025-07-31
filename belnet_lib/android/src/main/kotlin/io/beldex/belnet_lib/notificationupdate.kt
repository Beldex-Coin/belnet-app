package io.beldex.belnet_lib

import android.net.TrafficStats
import android.os.SystemClock
import android.util.Log
import network.beldex.belnet.ConnectionTools
import kotlin.math.roundToLong

class UpdateNetwork {
    private var lastTimestamp = 0L
    private var sessionDownloaded = 0L
    private var sessionUploaded = 0L
    private var lastTotalDownload = 0L
    private var lastTotalUpload = 0L
    private var sessionStart = 0L

    fun calculateNetworkSpeed(): String {
        val timestamp = SystemClock.elapsedRealtime()
        val elapsedMillis = timestamp - lastTimestamp
        val elapsedSeconds = elapsedMillis / 1000f

        val totalDownload = TrafficStats.getTotalRxBytes()
        val totalUpload = TrafficStats.getTotalTxBytes()
        val downloaded = (totalDownload - lastTotalDownload).coerceAtLeast(0) / 2
        val uploaded = (totalUpload - lastTotalUpload).coerceAtLeast(0) / 2
        val downloadSpeed = (downloaded / elapsedSeconds).roundToLong()
        val uploadSpeed = (uploaded / elapsedSeconds).roundToLong()

        sessionDownloaded += downloaded
        sessionUploaded += uploaded

        val downloadSpeedString = ConnectionTools.bytesToSize(downloadSpeed) + "ps"
        val uploadSpeedString = ConnectionTools.bytesToSize(uploadSpeed) + "ps"
        val notificationString = "↓ $downloadSpeedString ↑ $uploadSpeedString"

        Log.d("UpdateNetwork", "Network speed: $notificationString")

        lastTotalDownload = totalDownload
        lastTotalUpload = totalUpload
        lastTimestamp = timestamp

        return notificationString
    }
}