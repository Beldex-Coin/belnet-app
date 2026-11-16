package io.beldex.belnet

import android.os.Bundle
import androidx.activity.enableEdgeToEdge
import io.flutter.embedding.android.FlutterFragmentActivity

// FlutterFragmentActivity is a ComponentActivity, so it can call AndroidX
// enableEdgeToEdge(). That gives edge-to-edge on Android 14 and older too,
// which clears Play's "Edge-to-edge may not display for all users" warning.
// Plugins are registered automatically (GeneratedPluginRegistrant).
class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)
    }
}
