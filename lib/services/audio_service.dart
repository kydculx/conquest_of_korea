import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 게임 내 알림 및 점령 이벤트 시 공통 효과음 재생을 담당하는 서비스 클래스
class AudioService {
  static final AudioService _instance = AudioService._internal();

  /// AudioService 싱글톤 인스턴스 팩토리 생성자
  factory AudioService() => _instance;

  final AudioPlayer _player = AudioPlayer();

  AudioService._internal() {
    _initAudioContext();
  }

  /// 기기의 무음 스위치 및 진동 모드 상태를 존중하며 다른 오디오와 믹싱되도록 설정
  void _initAudioContext() {
    try {
      _player.setAudioContext(AudioContext(
        android: const AudioContextAndroid(
          isSpeakerphoneOn: false,
          stayAwake: false,
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.notification,
          audioFocus: AndroidAudioFocus.gainTransientMayDuck,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.ambient,
          options: const {
            AVAudioSessionOptions.mixWithOthers,
          },
        ),
      ));
      debugPrint('✅ AudioPlayer 세션 컨텍스트(ambient 카테고리) 설정 완료');
    } catch (e) {
      debugPrint('⚠️ AudioPlayer 세션 컨텍스트 설정 실패: $e');
    }
  }

  /// 공통 알림 효과음을 재생합니다. (assets/sounds/notification.mp3)
  Future<void> playNotification() async {
    try {
      await _player.stop();

      // Flutter 에셋 번들 탐색 검증 및 경로 바인딩
      String assetPath = 'sounds/notification.mp3';
      try {
        // assets/sounds/notification.mp3 로드가 정상인지 확인
        await rootBundle.load('assets/sounds/notification.mp3');
      } catch (loadErr) {
        debugPrint('⚠️ assets/sounds/notification.mp3 로드 실패(일부 환경 폴백 적용): $loadErr');
      }

      await _player.setSource(AssetSource(assetPath));
      await _player.resume();
      debugPrint('🎵 알림 효과음 재생 완료 (경로: $assetPath)');
    } catch (e) {
      debugPrint('⚠️ 알림 효과음 재생 실패: $e');
    }
  }
}
