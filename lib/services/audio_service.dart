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

  /// 기기의 무음 스위치 및 진동 모드 상태를 존중하며 항상 메인 스피커로 출력되도록 설정
  void _initAudioContext() {
    try {
      _player.setAudioContext(AudioContext(
        android: const AudioContextAndroid(
          isSpeakerphoneOn: true,
          stayAwake: false,
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.notification,
          audioFocus: AndroidAudioFocus.gainTransientMayDuck,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.ambient,
          options: const {
            AVAudioSessionOptions.mixWithOthers,
            AVAudioSessionOptions.defaultToSpeaker,
          },
        ),
      ));
      debugPrint('✅ AudioPlayer 세션 컨텍스트(ambient + defaultToSpeaker) 설정 완료');
    } catch (e) {
      debugPrint('⚠️ AudioPlayer 세션 컨텍스트 설정 실패: $e');
    }
  }

  /// 공통 알림 효과음을 재생합니다. (assets/sounds/notification.mp3)
  Future<void> playNotification() async {
    try {
      // 재생 상태 초기화
      await _player.stop();

      // Flutter 에셋 번들 탐색 검증
      const String assetPath = 'sounds/notification.mp3';
      try {
        await rootBundle.load('assets/sounds/notification.mp3');
      } catch (loadErr) {
        debugPrint('⚠️ assets/sounds/notification.mp3 로드 실패: $loadErr');
      }

      // audioplayers 표준 재생 API 단일 호출로 네이티브 재생 오류 방지
      await _player.play(AssetSource(assetPath));
      debugPrint('🎵 알림 효과음 재생 완료 (경로: $assetPath)');
    } catch (e, stack) {
      debugPrint('⚠️ 알림 효과음 재생 실패 예외: $e\n$stack');
    }
  }
}
