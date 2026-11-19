# Flutter Application ProGuard / R8 Rules for Release Build (Pertemuan 10)

# Flutter Engine & Plugin Registrants
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.**  { *; }

# Preservation of annotations and signatures for serialization
-keepattributes *Annotation*,EnclosingMethod,Signature,InnerClasses

# Supabase, HTTP Client, and WebSockets
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**
-keepnames class okhttp3.internal.publicsuffix.PublicSuffixDatabase

# Biometric & Local Authentication
-keep class androidx.biometric.** { *; }
-dontwarn androidx.biometric.**

# Flutter Local Notifications & Alarm Manager
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class androidx.core.app.NotificationCompat** { *; }

# Sqflite & SQLite Persistence
-keep class com.tekartik.sqflite.** { *; }

# Image Picker & Media Gallery
-keep class io.flutter.plugins.imagepicker.** { *; }

# Google Play Core & Deferred Components (R8 missing rules)
-dontwarn com.google.android.play.core.**
