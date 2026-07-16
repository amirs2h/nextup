# Flutter General
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Google Play Core (referenced by Flutter but not included as dependency)
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**
-keep class com.google.android.play.core.** { *; }

# Supabase
-keep class io.supabase.** { *; }
-keep class com.supabase.** { *; }
-keepclassmembers class io.supabase.** { *; }

# BLoC / Equatable (pure Dart, but keep for safety)
-keep class bloc.** { *; }

# Cached Network Image / Glide / OkHttp
-keep class com.bumptech.glide.** { *; }
-keep class okhttp3.** { *; }
-keep class okio.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**

# Image Picker
-keep class io.flutter.plugins.imagepicker.** { *; }

# Share Plus
-keep class io.flutter.plugins.share.** { *; }

# URL Launcher
-keep class io.flutter.plugins.urllauncher.** { *; }

# Shared Preferences
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# App Links
-keep class com.llfbandit.app_links.** { *; }

# Keep enum values
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}
