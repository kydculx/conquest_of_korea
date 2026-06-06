import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// 게임 내 알림 및 점령 이벤트 시 공통 효과음 재생을 담당하는 서비스 클래스
class AudioService {
  static final AudioService _instance = AudioService._internal();

  /// AudioService 싱글톤 인스턴스 팩토리 생성자
  factory AudioService() => _instance;

  AudioService._internal();

  final AudioPlayer _player = AudioPlayer();

  /// 공통 알림 효과음을 재생합니다. (assets/sounds/notification.mp3)
  Future<void> playNotification() async {
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/notification.mp3'));
      debugPrint('🎵 알림 효과음 재생 완료');
    } catch (e) {
      debugPrint('⚠️ 알림 효과음 재생 실패: $e');
    }
  }
}
