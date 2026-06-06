import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// 게임 내 점령 성공 및 피탈(영토 침공) 등 다양한 이벤트에 따른 효과음 재생을 담당하는 서비스 클래스
class AudioService {
  static final AudioService _instance = AudioService._internal();

  /// AudioService 싱글톤 인스턴스 팩토리 생성자
  factory AudioService() => _instance;

  AudioService._internal();

  final AudioPlayer _player = AudioPlayer();

  /// 점령 성공 효과음을 재생합니다. (assets/sounds/capture_success.mp3)
  Future<void> playCaptureSuccess() async {
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/capture_success.mp3'));
      debugPrint('🎵 점령 성공 효과음 재생 완료');
    } catch (e) {
      debugPrint('⚠️ 점령 성공 효과음 재생 실패: $e');
    }
  }

  /// 피탈(영토 침공당함) 효과음을 재생합니다. (assets/sounds/territory_attack.mp3)
  Future<void> playTerritoryAttack() async {
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/territory_attack.mp3'));
      debugPrint('🎵 영토 피탈 효과음 재생 완료');
    } catch (e) {
      debugPrint('⚠️ 영토 피탈 효과음 재생 실패: $e');
    }
  }
}
