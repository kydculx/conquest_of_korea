import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// 게임 내 알림 및 점령 이벤트 시 공통 효과음 재생을 담당하는 서비스 클래스
class AudioService {
  static final AudioService _instance = AudioService._internal();

  /// AudioService 싱글톤 인스턴스 팩토리 생성자
  factory AudioService() => _instance;

  final AudioPlayer _player = AudioPlayer();

  AudioService._internal() {
    _initAudioContext();
  }

  /// 매너 모드/무음 스위치 상태에서도 사운드가 스피커로 출력되도록 오디오 컨텍스트 설정
  void _initAudioContext() {
    try {
      _player.setAudioContext(AudioContext(
        android: const AudioContextAndroid(
          isSpeakerphoneOn: true,
          stayAwake: true,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.assistanceSonification,
          audioFocus: AndroidAudioFocus.gainTransientMayDuck,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: const {
            AVAudioSessionOptions.mixWithOthers,
            AVAudioSessionOptions.defaultToSpeaker,
          },
        ),
      ));
      debugPrint('✅ AudioPlayer 세션 컨텍스트(playback 카테고리) 설정 완료');
    } catch (e) {
      debugPrint('⚠️ AudioPlayer 세션 컨텍스트 설정 실패: $e');
    }
  }

  /// 공통 알림 효과음을 재생합니다. (assets/sounds/notification.mp3)
  Future<void> playNotification() async {
    try {
      await _player.stop();
      await _player.setSource(AssetSource('sounds/notification.mp3'));
      await _player.resume();
      debugPrint('🎵 알림 효과음 재생 완료');
    } catch (e) {
      debugPrint('⚠️ 알림 효과음 재생 실패: $e');
    }
  }
}
