# ---------------------------------------------------------------------------
# R8 keep rules for Belnet. Flutter adds its own engine/plugin rules
# automatically; these cover what R8 cannot see on its own.
# ---------------------------------------------------------------------------

-keep class androidx.lifecycle.DefaultLifecycleObserver

# --- belnet_lib native daemon (libbelnet-android.so) ---
# The C++ JNI code looks up these classes, their native methods and fields
# (e.g. ByteBuffer "impl") by name, so their names and members must not change.
# Keep the whole top-level package (BelnetDaemon, BelnetConfig, receivers...)
# but not .adblock, which is pure Java and safe to obfuscate.
-keep class network.beldex.belnet.* { *; }
-keepclasseswithmembernames,includedescriptorclasses class * {
    native <methods>;
}

# --- awesome_notifications ---
# Builds its notification models via reflection; stripping them makes
# notifications silently fail in release builds.
-keep class me.carda.awesome_notifications.** { *; }

# --- Flutter deferred components reference Play Core, which this app doesn't ship ---
-dontwarn com.google.android.play.core.**

# Keep line numbers for readable Play Console crash reports
# (mapping.txt is uploaded automatically inside the .aab).
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
