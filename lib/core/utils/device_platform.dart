import 'package:flutter/foundation.dart';

/// 가입 시 DB에 저장할 현재 디바이스 플랫폼 식별자를 반환합니다.
/// (ios, android, web, other)
String detectDevicePlatform() {
  if (kIsWeb) return 'web';
  switch (defaultTargetPlatform) {
    case TargetPlatform.iOS:
      return 'ios';
    case TargetPlatform.android:
      return 'android';
    default:
      return 'other';
  }
}
