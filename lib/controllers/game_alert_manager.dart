import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/constants/game_config.dart';
import '../models/alert_model.dart';
import '../services/audio_service.dart';

/// 인게임 알림 배너 목록과 자동 소멸 타이머를 전담 관리하는 매니저 클래스.
/// GameProvider로부터 알림 표시 책임을 분리합니다.
class GameAlertManager {
  final VoidCallback _notifyListeners;
  final List<GameAlert> _alerts = [];

  /// 화면 상단에 표시 중인 알림 목록 (최대 5개, 최신순)
  List<GameAlert> get alerts => List.unmodifiable(_alerts);

  GameAlertManager({required VoidCallback notifyListeners})
      : _notifyListeners = notifyListeners;

  /// 알림을 추가합니다. 동일 문구의 알림이 이미 있으면 무시합니다.
  /// 추가 성공 시 true를 반환합니다.
  bool add(String message, AlertType type) {
    if (_alerts.any((a) => a.message == message)) return false;

    final alert = GameAlert.create(message: message, type: type);
    _alerts.insert(0, alert);
    if (_alerts.length > 5) _alerts.removeLast();
    _notifyListeners();
    AudioService().playNotification();

    Timer(
      const Duration(seconds: GameConfig.alertDismissDurationSeconds),
      () => remove(alert.id),
    );
    return true;
  }

  void remove(String id) {
    _alerts.removeWhere((a) => a.id == id);
    _notifyListeners();
  }
}
