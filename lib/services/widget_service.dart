import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

/// 홈/잠금화면 위젯에 표시할 값(영토·일일 이동·걸음 수)을 공유 저장소에 기록한다.
class WidgetService {
  static const String appGroupId = 'group.com.watercherry.conquestofkorea';
  static const String iOSWidgetName = 'ConquestWidget';
  static const String androidProvider =
      'com.watercherry.conquestofkorea.ConquestWidgetProvider';

  static const String _keyTerritory = 'territory';
  static const String _keyDailyMoved = 'dailyMoved';
  static const String _keySteps = 'steps';

  static int _territory = 0;
  static int _dailyMoved = 0;
  static int _steps = 0;
  static bool _ready = false;

  static Future<void> initialize() async {
    if (_ready) return;
    await HomeWidget.setAppGroupId(appGroupId);
    _ready = true;
  }

  static Future<void> update({
    int? territory,
    int? dailyMoved,
    int? steps,
  }) async {
    if (territory == null && dailyMoved == null && steps == null) return;
    if (territory != null) _territory = territory < 0 ? 0 : territory;
    if (dailyMoved != null) _dailyMoved = dailyMoved < 0 ? 0 : dailyMoved;
    if (steps != null) _steps = steps < 0 ? 0 : steps;

    try {
      await initialize();
      await HomeWidget.saveWidgetData<int>(_keyTerritory, _territory);
      await HomeWidget.saveWidgetData<int>(_keyDailyMoved, _dailyMoved);
      await HomeWidget.saveWidgetData<int>(_keySteps, _steps);
      await HomeWidget.updateWidget(
        iOSName: iOSWidgetName,
        androidName: 'ConquestWidgetProvider',
        qualifiedAndroidName: androidProvider,
      );
    } catch (e) {
      debugPrint('⚠️ 위젯 데이터 갱신 실패: $e');
    }
  }
}
