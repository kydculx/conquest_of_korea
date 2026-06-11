import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/preferences_service.dart';
import '../services/notification_service.dart';

/// 요원의 알림 수신 동의(FCM 구독 + 로컬 저장소 + 원격 동기화)를 전담 제어하는 컨트롤러 클래스.
/// GameProvider로부터 알림 설정 관련 상태와 로직을 분리합니다.
class NotificationController {
  // --- 콜백 (GameProvider에서 주입) ---

  /// 상태 변경 시 UI 갱신을 지시하는 콜백
  final VoidCallback onStateChanged;

  /// 현재 로그인된 요원의 ID를 반환하는 접근자 (개인 FCM 토픽 구독용)
  final String? Function() getUserId;

  /// 4대 알림 동의 상태를 원격 DB 프로필에 동기화하는 콜백
  final Future<void> Function({
    required bool isMasterEnabled,
    required bool territoryAttack,
    required bool satelliteComplete,
    required bool systemNotice,
  }) onSyncToRemote;

  // --- 알림 수신 동의 상태 ---

  bool _isNotificationEnabled = true;
  bool _isNotifTerritoryAttack = true;
  bool _isNotifSatelliteComplete = true;
  bool _isNotifSystemNotice = true;

  // --- Getter (Provider에서 위임) ---

  bool get isNotificationEnabled => _isNotificationEnabled;
  bool get isNotifTerritoryAttack => _isNotifTerritoryAttack;
  bool get isNotifSatelliteComplete => _isNotifSatelliteComplete;
  bool get isNotifSystemNotice => _isNotifSystemNotice;

  NotificationController({
    required this.onStateChanged,
    required this.getUserId,
    required this.onSyncToRemote,
  });

  /// PreferencesService에서 알림 설정을 불러오고 FCM 구독을 동기화합니다.
  Future<void> loadFromPrefs() async {
    _isNotificationEnabled =
        await PreferencesService.isNotificationEnabled();
    _isNotifTerritoryAttack =
        await PreferencesService.isNotifTerritoryAttackEnabled();
    _isNotifSatelliteComplete =
        await PreferencesService.isNotifSatelliteCompleteEnabled();
    _isNotifSystemNotice =
        await PreferencesService.isNotifSystemNoticeEnabled();
    // 로드 직후 FCM 구독 상태 동기화
    await _updateFcmSubscriptions();
  }

  /// 알림 수신 동의 여부를 전환하고 변경 설정을 로컬 저장소, 원격 DB, FCM 구독에 반영합니다.
  Future<void> toggleNotifications() async {
    _isNotificationEnabled = !_isNotificationEnabled;
    await PreferencesService.setNotificationEnabled(_isNotificationEnabled);
    onStateChanged();
    await _syncToRemoteAndUpdateFcm();
  }

  /// 영토 침공 알림 여부를 토글합니다.
  Future<void> toggleNotifTerritoryAttack() async {
    _isNotifTerritoryAttack = !_isNotifTerritoryAttack;
    await PreferencesService.setNotifTerritoryAttackEnabled(
        _isNotifTerritoryAttack);
    onStateChanged();
    await _syncToRemoteAndUpdateFcm();
  }

  /// 위성 점령 완료 알림 여부를 토글합니다.
  Future<void> toggleNotifSatelliteComplete() async {
    _isNotifSatelliteComplete = !_isNotifSatelliteComplete;
    await PreferencesService.setNotifSatelliteCompleteEnabled(
        _isNotifSatelliteComplete);
    onStateChanged();
    await _syncToRemoteAndUpdateFcm();
  }

  /// 시스템 공지 알림 여부를 토글합니다.
  Future<void> toggleNotifSystemNotice() async {
    _isNotifSystemNotice = !_isNotifSystemNotice;
    await PreferencesService.setNotifSystemNoticeEnabled(
        _isNotifSystemNotice);
    onStateChanged();
    await _syncToRemoteAndUpdateFcm();
  }

  // --- 내부 헬퍼 ---

  /// 로컬 저장 후 원격 동기화 및 FCM 구독을 순차 처리합니다.
  Future<void> _syncToRemoteAndUpdateFcm() async {
    await _syncNotificationsToRemote();
    await _updateFcmSubscriptions();
  }

  /// 4대 알림 동의 상태를 원격 DB 프로필에 실시간 동기화합니다.
  Future<void> _syncNotificationsToRemote() async {
    await onSyncToRemote(
      isMasterEnabled: _isNotificationEnabled,
      territoryAttack: _isNotifTerritoryAttack,
      satelliteComplete: _isNotifSatelliteComplete,
      systemNotice: _isNotifSystemNotice,
    );
  }

  /// 현재 알림 설정 상태에 맞춰 FCM 구독 토픽을 최신화합니다.
  Future<void> _updateFcmSubscriptions() async {
    final ns = NotificationService();
    if (!ns.isInitialized) {
      await ns.initialize();
    }

    const String topicTerritory = 'conquest_territory_attack';
    const String topicSatellite = 'conquest_satellite_complete';
    const String topicNotice = 'conquest_system_notice';
    final userId = getUserId();
    final String? topicPersonal = userId != null ? 'user_$userId' : null;

    if (!_isNotificationEnabled) {
      // 마스터 알림이 꺼진 경우 모든 개별 및 개인 토픽 일제 구독 해제
      await ns.unsubscribeFromTopic(topicTerritory);
      await ns.unsubscribeFromTopic(topicSatellite);
      await ns.unsubscribeFromTopic(topicNotice);
      if (topicPersonal != null) {
        await ns.unsubscribeFromTopic(topicPersonal);
      }
      debugPrint('🔔 [FCM 구독 통제] 마스터 해제로 인한 모든 토픽 구독 해제 완료.');
      return;
    }

    // 마스터 알림이 켜져 있는 경우 개인 토픽 다시 구독
    if (topicPersonal != null) {
      await ns.subscribeToTopic(topicPersonal);
    }

    // 영토 침공 알림
    if (_isNotifTerritoryAttack) {
      await ns.subscribeToTopic(topicTerritory);
    } else {
      await ns.unsubscribeFromTopic(topicTerritory);
    }

    // 위성 점령 완료 알림
    if (_isNotifSatelliteComplete) {
      await ns.subscribeToTopic(topicSatellite);
    } else {
      await ns.unsubscribeFromTopic(topicSatellite);
    }

    // 시스템 공지 알림
    if (_isNotifSystemNotice) {
      await ns.subscribeToTopic(topicNotice);
    } else {
      await ns.unsubscribeFromTopic(topicNotice);
    }
  }
}
