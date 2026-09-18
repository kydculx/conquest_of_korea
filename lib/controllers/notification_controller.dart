import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';
import '../services/preferences_service.dart';
import '../services/notification_service.dart';

/// 플레이어의 알림 수신 동의(FCM 구독 + 로컬 저장소 + 원격 동기화)를 전담 제어하는 컨트롤러 클래스.
/// 메인 단일 푸시 알림 설정 및 개인 토픽 구독을 관리합니다.
class NotificationController {
  // --- 콜백 (GameProvider에서 주입) ---

  /// 상태 변경 시 UI 갱신을 지시하는 콜백
  final VoidCallback onStateChanged;

  /// 현재 로그인된 플레이어의 ID를 반환하는 접근자 (개인 FCM 토픽 구독용)
  final String? Function() getUserId;

  /// 마스터 알림 동의 상태를 원격 DB 프로필에 동기화하는 콜백
  final Future<void> Function({required bool isMasterEnabled}) onSyncToRemote;

  // --- 알림 수신 동의 상태 ---

  bool _isNotificationEnabled = true;

  // --- Getter (Provider에서 위임) ---

  bool get isNotificationEnabled => _isNotificationEnabled;

  NotificationController({
    required this.onStateChanged,
    required this.getUserId,
    required this.onSyncToRemote,
  });

  /// 로그인된 사용자의 DB 프로필 설정값으로 알림 상태를 동기화합니다.
  Future<void> syncFromProfile(UserProfile profile) async {
    _isNotificationEnabled = profile.isNotificationsEnabled;

    // 로컬 저장소도 해당 사용자의 프로필 설정값으로 갱신
    await PreferencesService.setNotificationEnabled(_isNotificationEnabled);

    onStateChanged();
    await _updateFcmSubscriptions();
  }

  /// 로그아웃 시 알림 설정을 기본값으로 초기화합니다.
  Future<void> resetToDefault() async {
    _isNotificationEnabled = true;
    await PreferencesService.setNotificationEnabled(true);
    onStateChanged();
  }

  /// PreferencesService에서 알림 설정을 불러오고 FCM 구독을 동기화합니다.
  Future<void> loadFromPrefs() async {
    _isNotificationEnabled =
        await PreferencesService.isNotificationEnabled();
    // 로드 직후 FCM 구독 상태 동기화
    await _updateFcmSubscriptions();
  }

  /// OS 시스템 레벨의 알림 권한을 확인하고,
  /// OS 설정 상태와 앱 내 알림 상태를 양방향으로 자동 동기화합니다.
  Future<bool> checkAndSyncSystemPermission() async {
    final ns = NotificationService();
    final isSystemPermitted = await ns.checkSystemNotificationPermission();

    if (_isNotificationEnabled != isSystemPermitted) {
      debugPrint('🔔 [OS 연동] 시스템 알림 상태($isSystemPermitted) 감지 -> 앱 내 알림 상태 동기화');
      _isNotificationEnabled = isSystemPermitted;
      await PreferencesService.setNotificationEnabled(isSystemPermitted);
      onStateChanged();
      await _syncToRemoteAndUpdateFcm();
    }
    return isSystemPermitted;
  }

  /// 알림 수신 동의 여부를 전환합니다.
  /// - 꺼질 때는 즉시 끄고 동기화 (true 반환)
  /// - 켜질 때는 OS 시스템 알림 권한을 검사하여, 권한이 없으면 요청하거나 false를 반환하여
  ///   호출부에서 설정 화면 이동 다이얼로그를 표시할 수 있도록 합니다.
  Future<bool> toggleNotifications() async {
    if (_isNotificationEnabled) {
      _isNotificationEnabled = false;
      await PreferencesService.setNotificationEnabled(false);
      onStateChanged();
      await _syncToRemoteAndUpdateFcm();
      return true;
    } else {
      final ns = NotificationService();
      bool isPermitted = await ns.checkSystemNotificationPermission();

      if (!isPermitted) {
        // 시스템 권한 팝업 요청 시도
        isPermitted = await ns.requestSystemNotificationPermission();
      }

      if (!isPermitted) {
        // 권한이 최종 거부/차단된 경우 스위치를 켜지 않고 false 반환
        return false;
      }

      _isNotificationEnabled = true;
      await PreferencesService.setNotificationEnabled(true);
      onStateChanged();
      await _syncToRemoteAndUpdateFcm();
      return true;
    }
  }

  /// OS 시스템 알림 설정 화면으로 이동합니다.
  Future<bool> openSystemNotificationSettings() async {
    return await NotificationService().openSystemNotificationSettings();
  }

  // --- 내부 헬퍼 ---

  /// 로컬 저장 후 원격 동기화 및 FCM 구독을 순차 처리합니다.
  Future<void> _syncToRemoteAndUpdateFcm() async {
    await _syncNotificationsToRemote();
    await _updateFcmSubscriptions();
  }

  /// 마스터 알림 동의 상태를 원격 DB 프로필에 실시간 동기화합니다.
  Future<void> _syncNotificationsToRemote() async {
    await onSyncToRemote(isMasterEnabled: _isNotificationEnabled);
  }

  /// FCM 토픽 동기화 디바운스 타이머
  Timer? _fcmSyncDebounce;

  /// 현재 알림 설정 상태에 맞춰 FCM 구독 토픽을 최신화합니다.
  Future<void> _updateFcmSubscriptions() async {
    _fcmSyncDebounce?.cancel();
    _fcmSyncDebounce = null;
    await _runFcmSync();
  }

  Future<void> _runFcmSync() async {
    final ns = NotificationService();
    if (!ns.isInitialized) {
      await ns.initialize();
    }

    // 레거시 세부 토픽 일괄 해제 (기존 구독자 클린업)
    const String legacyTopicTerritory = 'conquest_territory_attack';
    const String legacyTopicSatellite = 'conquest_satellite_complete';
    const String legacyTopicNotice = 'conquest_system_notice';
    await _applyIfChanged(legacyTopicTerritory, false);
    await _applyIfChanged(legacyTopicSatellite, false);
    await _applyIfChanged(legacyTopicNotice, false);

    final userId = getUserId();
    final String? topicPersonal = userId != null ? 'user_$userId' : null;

    if (!_isNotificationEnabled) {
      // 마스터 알림이 꺼진 경우 개인 토픽 구독 해제
      if (topicPersonal != null) {
        await _applyIfChanged(topicPersonal, false);
      }
      debugPrint('🔔 [FCM 구독] 마스터 알림 해제로 인한 모든 토픽 구독 해제 완료.');
      return;
    }

    // 마스터 알림이 켜져 있는 경우 개인 토픽 구독
    if (topicPersonal != null) {
      await _applyIfChanged(topicPersonal, true);
      debugPrint('🔔 [FCM 구독] 개인 토픽($topicPersonal) 구독 완료.');
    }
  }

  /// 토픽 구독 상태 캐시
  final Map<String, bool> _topicState = {};

  Future<void> _applyIfChanged(String topic, bool desiredSubscribed) async {
    if (_topicState[topic] == desiredSubscribed) return;
    final ns = NotificationService();
    if (desiredSubscribed) {
      await ns.subscribeToTopic(topic);
    } else {
      await ns.unsubscribeFromTopic(topic);
    }
    _topicState[topic] = desiredSubscribed;
  }
}
