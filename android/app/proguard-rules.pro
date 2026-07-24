# Flutter 기본 난독화 방어 규칙
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Kakao SDK 난독화 예외 지정
-keep class com.kakao.sdk.** { *; }
-keepclassmembers class * implements com.kakao.sdk.common.model.KeepToSdk { *; }

# Health Connect 및 AndroidX Health Client 예외 지정
-keep class androidx.health.connect.client.** { *; }
-keep class androidx.health.platform.client.** { *; }
-dontwarn androidx.health.connect.client.**

# Supabase / HTTP 통신 라이브러리 (OkHttp, Okio) 예외 지정
-keepattributes Signature, InnerClasses, AnnotationList, EnclosingMethod
-keep class okhttp3.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**

# Firebase / Google Play Services 예외 지정
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# 구글 플레이 코어 / Deferred Components 미사용에 따른 RNR 누락 경고 무시
-dontwarn com.google.android.play.core.**

