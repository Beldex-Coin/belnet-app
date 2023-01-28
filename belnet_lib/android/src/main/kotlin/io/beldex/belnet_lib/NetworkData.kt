package io.beldex.belnet_lib

import android.os.Parcel
import android.os.Parcelable
import android.os.SystemClock

class NetworkData {

    private var m_dataTransferStatsForService: DataTransferStatsForService? = null
    private var m_dataTransferStatsForUI: DataTransferStatsForUI? = null

    @Throws(CloneNotSupportedException::class)
    fun clone(): Any? {
        throw CloneNotSupportedException()
    }

    @Synchronized
    fun getDataTransferStatsForService(): DataTransferStatsForService? {
        if (m_dataTransferStatsForService == null) {
            m_dataTransferStatsForService = DataTransferStatsForService()
        }
        return m_dataTransferStatsForService
    }

    @Synchronized
    fun getDataTransferStatsForUI(): DataTransferStatsForUI? {
        if (m_dataTransferStatsForUI == null) {
            m_dataTransferStatsForUI = DataTransferStatsForUI()
        }
        return m_dataTransferStatsForUI
    }

    abstract class DataTransferStatsBase() {
        protected class Bucket : Parcelable {
            var m_bytesSent: Long = 0
            var m_bytesReceived: Long = 0

            constructor() {}
            protected constructor(`in`: Parcel) {
                m_bytesSent = `in`.readLong()
                m_bytesReceived = `in`.readLong()
            }

            override fun describeContents(): Int {
                return 0
            }

            override fun writeToParcel(dest: Parcel, flags: Int) {
                dest.writeLong(m_bytesSent)
                dest.writeLong(m_bytesReceived)
            }

            companion object {
                @JvmField
                val CREATOR: Parcelable.Creator<Bucket?> = object : Parcelable.Creator<Bucket?> {
                    override fun createFromParcel(`in`: Parcel): Bucket? {
                        return Bucket(`in`)
                    }

                    override fun newArray(size: Int): Array<Bucket?> {
                        return arrayOfNulls(size)
                    }
                }
            }
        }

        protected var m_connectedTime: Long = 0

        @get:Synchronized
        var totalBytesSent: Long = 0
            protected set

        @get:Synchronized
        var totalBytesReceived: Long = 0
            protected set
        protected var m_slowBuckets: ArrayList<Bucket>? = null
        protected var m_slowBucketsLastStartTime: Long = 0
        protected var m_fastBuckets: ArrayList<Bucket>? = null
        protected var m_fastBucketsLastStartTime: Long = 0

        init {
            stop()
        }

        @Synchronized
        fun stop() {
            m_connectedTime = 0
            resetBytesTransferred()
        }

        protected fun resetBytesTransferred() {
            val now = SystemClock.elapsedRealtime()
            m_slowBucketsLastStartTime = bucketStartTime(now, SLOW_BUCKET_PERIOD_MILLISECONDS)
            m_slowBuckets = newBuckets()
            m_fastBucketsLastStartTime = bucketStartTime(now, FAST_BUCKET_PERIOD_MILLISECONDS)
            m_fastBuckets = newBuckets()
        }

        private fun bucketStartTime(now: Long, period: Long): Long {
            return period * (now / period)
        }

        private fun newBuckets(): ArrayList<Bucket> {
            val buckets = ArrayList<Bucket>()
            for (i in 0 until MAX_BUCKETS) {
                buckets.add(Bucket())
            }
            return buckets
        }

        private fun shiftBuckets(diff: Long, period: Long, buckets: ArrayList<Bucket>?) {
            for (i in 0 until diff / period + 1) {
                buckets!!.add(buckets.size, Bucket())
                if (buckets.size >= MAX_BUCKETS) {
                    buckets.removeAt(0)
                }
            }
        }

        protected fun manageBuckets() {
            val now = SystemClock.elapsedRealtime()
            var diff = now - m_slowBucketsLastStartTime
            if (diff >= SLOW_BUCKET_PERIOD_MILLISECONDS) {
                shiftBuckets(diff, SLOW_BUCKET_PERIOD_MILLISECONDS, m_slowBuckets)
                m_slowBucketsLastStartTime = bucketStartTime(now, SLOW_BUCKET_PERIOD_MILLISECONDS)
            }
            diff = now - m_fastBucketsLastStartTime
            if (diff >= FAST_BUCKET_PERIOD_MILLISECONDS) {
                shiftBuckets(diff, FAST_BUCKET_PERIOD_MILLISECONDS, m_fastBuckets)
                m_fastBucketsLastStartTime = bucketStartTime(now, FAST_BUCKET_PERIOD_MILLISECONDS)
            }
        }

        companion object {
            private const val SLOW_BUCKET_PERIOD_MILLISECONDS = (5 * 60 * 1000).toLong()
            private const val FAST_BUCKET_PERIOD_MILLISECONDS: Long = 1000
            private const val MAX_BUCKETS = 24 * 60 / 5
        }
    }

    class DataTransferStatsForService constructor() : DataTransferStatsBase() {
        @Synchronized
        fun startSession() {
            resetBytesTransferred()
        }

        @Synchronized
        fun startConnected() {
            m_connectedTime = SystemClock.elapsedRealtime()
        }

        @Synchronized
        fun addBytesSent(bytes: Long) {
            totalBytesSent += bytes
            manageBuckets()
            addSentToBuckets(bytes)
        }

        @Synchronized
        fun addBytesReceived(bytes: Long) {
            totalBytesReceived += bytes
            manageBuckets()
            addReceivedToBuckets(bytes)
        }

        private fun addSentToBuckets(bytes: Long) {
            m_slowBuckets!![m_slowBuckets!!.size - 1].m_bytesSent += bytes
            m_fastBuckets!![m_fastBuckets!!.size - 1].m_bytesSent += bytes
        }

        private fun addReceivedToBuckets(bytes: Long) {
            m_slowBuckets!![m_slowBuckets!!.size - 1].m_bytesReceived += bytes
            m_fastBuckets!![m_fastBuckets!!.size - 1].m_bytesReceived += bytes
        }
    }

    class DataTransferStatsForUI() : DataTransferStatsBase() {
        private fun getSentSeries(buckets: ArrayList<Bucket>): ArrayList<Long> {
            val series = ArrayList<Long>()
            for (i in buckets.indices) {
                series.add(buckets[i].m_bytesSent)
            }
            return series
        }

        private fun getReceivedSeries(buckets: ArrayList<Bucket>): ArrayList<Long> {
            val series = ArrayList<Long>()
            for (i in buckets.indices) {
                series.add(buckets[i].m_bytesReceived)
            }
            return series
        }

        @get:Synchronized
        val elapsedTime: Long
            get() {
                val now = SystemClock.elapsedRealtime()
                return now - m_connectedTime
            }

        @get:Synchronized
        val slowSentSeries: ArrayList<Long>
            get() {
                manageBuckets()
                return getSentSeries(m_slowBuckets!!)
            }

        @get:Synchronized
        val slowReceivedSeries: ArrayList<Long>
            get() {
                manageBuckets()
                return getReceivedSeries(m_slowBuckets!!)
            }

        @get:Synchronized
        val fastSentSeries: ArrayList<Long>
            get() {
                manageBuckets()
                return getSentSeries(m_fastBuckets!!)
            }

        @get:Synchronized
        val fastReceivedSeries: ArrayList<Long>
            get() {
                manageBuckets()
                return getReceivedSeries(m_fastBuckets!!)
            }
    }

}