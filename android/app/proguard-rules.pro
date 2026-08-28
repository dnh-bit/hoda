# ---------------------------------------------------------------------------
# Hoda — R8 / ProGuard keep rules for release builds
# ---------------------------------------------------------------------------
# Why this file exists:
# flutter_local_notifications stores the queue of scheduled notifications in
# SharedPreferences as JSON and reads it back with Gson + TypeToken. R8 strips
# generic type signatures during minification, so on a release APK Gson throws
#
#   java.lang.RuntimeException: Missing type parameter.
#
# from loadScheduledNotifications(), which surfaces in Dart as
# PlatformException(error, Missing type parameter., ...) on every
# cancel()/zonedSchedule() call. Debug builds are not shrunk, hence the bug is
# release-only. The rules below are the ones documented by the plugin and by
# Gson itself.
# ---------------------------------------------------------------------------

# --- Gson: keep generic signatures and annotations (the actual fix) ---------
# Signature is required for Gson to read the <T> of TypeToken at runtime.
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# --- flutter_local_notifications --------------------------------------------
# The plugin's model classes are (de)serialized reflectively by Gson.
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class com.dexterous.** { *; }
-dontwarn com.dexterous.flutterlocalnotifications.**

# --- Gson core --------------------------------------------------------------
-keep class com.google.gson.** { *; }
-keep class sun.misc.Unsafe { *; }
-dontwarn sun.misc.**

# TypeToken and every anonymous/named subclass of it must keep its generic
# signature, otherwise `new TypeToken<ArrayList<Foo>>(){}` loses its parameter.
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-keep public class * implements java.lang.reflect.Type

# Gson-annotated fields must survive shrinking to stay (de)serializable.
-keepclassmembers,allowobfuscation class * {
  @com.google.gson.annotations.SerializedName <fields>;
  @com.google.gson.annotations.Expose <fields>;
}

# Gson TypeAdapters / JsonSerializers registered by reflection.
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Enum values are looked up by name during deserialization.
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# --- Scheduling / boot receivers referenced only from AndroidManifest.xml ---
-keep class androidx.core.app.CoreComponentFactory { *; }
-keep class * extends android.content.BroadcastReceiver { *; }
-keep class * extends android.app.Service { *; }

# --- Plugins used by Hoda ---------------------------------------------------
-dontwarn com.baseflow.permissionhandler.**
-keep class com.baseflow.permissionhandler.** { *; }

# --- Flutter engine / embedding --------------------------------------------
-keep class io.flutter.** { *; }
-dontwarn io.flutter.embedding.**
