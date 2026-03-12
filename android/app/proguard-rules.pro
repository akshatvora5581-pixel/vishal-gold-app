## Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class com.google.firebase.** { *; }

# Standard Firebase rules
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn com.google.firebase.**
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-keep class com.google.android.library.firebase.** { *; }

# Flutter Specific
-keep class io.flutter.embedding.engine.FlutterJNI {
    native <methods>;
}

# Image Handling (CachedNetworkImage/etc)
-keep class com.bumptech.glide.** { *; }
-dontwarn com.bumptech.glide.**
-dontwarn okio.**
-dontwarn javax.annotation.**

# Play Core missing classes
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }
