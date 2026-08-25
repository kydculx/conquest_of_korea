import 'dart:async';
import 'package:flutter/foundation.dart';

/// UTC 자정까지의 남은 시간을 1초 주기로 계산하는 카운트다운 컨트롤러.
/// GameProvider로부터 카운트다운 타이머 책임을 분리합니다.
class UtcCountdownController {
  final VoidCallback _notifyListeners;
  Timer? _timer;
  String _timeString = '00:00:00';

  /// UTC 00시까지 남은 시간 문자열 (HH:MM:SS)
  String get timeString => _timeString;

  UtcCountdownController({required VoidCallback notifyListeners})
      : _notifyListeners = notifyListeners;

  /// 카운트다운 타이머를 시작합니다. 즉시 1회 갱신 후 1초 주기로 반복합니다.
  void start() {
    _update();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _update());
  }

  void _update() {
    final nowUtc = DateTime.now().toUtc();
    final targetUtc = DateTime.utc(nowUtc.year, nowUtc.month, nowUtc.day + 1);
    final diff = targetUtc.difference(nowUtc);

    final hours = diff.inHours.toString().padLeft(2, '0');
    final minutes = (diff.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (diff.inSeconds % 60).toString().padLeft(2, '0');

    _timeString = '$hours:$minutes:$seconds';
    _notifyListeners();
  }

  /// 리소스 해제
  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
