# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

-dontwarn io.flutter.**
-dontwarn com.google.android.play.core.**

# local_auth plugin
-keep class io.flutter.plugins.localauth.** { *; }

# freeRASP / Talsec
-keep class com.aheaditec.talsec_security.models.** { *; }
-keep class com.aheaditec.talsec_security.threats.** { *; }
-keep class com.aheaditec.talsec_security.talsec.** { *; }
-keep class com.aheaditec.talsec.FreeRasp.** { *; }
-keep class com.aheaditec.talsec.** { *; }
-keep interface com.aheaditec.talsec_security.talsec.ThreatListener.ThreatDetected { *; }
-keep class com.thalesgroup.talsec.** { *; }

# flutter_secure_storage
-keep class com.it_nomads.fluttersecurestorage.** { *; }
