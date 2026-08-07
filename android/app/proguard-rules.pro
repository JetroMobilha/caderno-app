# Flutter Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Drift / SQLite Rules
-keep class net.sqlcipher.** { *; }
-keep class org.sqlite.** { *; }

# Pusher / WebSockets Rules
-keep class com.pusher.client.** { *; }

# Support for Google Fonts
-keep class com.google.fonts.** { *; }

# Prevent shrinking of important assets
-keepclassmembers class **.R$* {
    public static <fields>;
}
