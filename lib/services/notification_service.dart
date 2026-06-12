import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:app_badge_plus/app_badge_plus.dart';
import '../core/constants/strings.dart';
import 'preferences_service.dart';

/// 포그라운드 FCM 메시지 수신 시 인게임 알림 UI로 라우팅 처리하기 위한 커스텀 콜백 핸들러 타입
typedef ForegroundMessageCallback =
    void Function(String title, String body, String type);

/// Firebase Cloud Messaging(FCM) 및 로컬 푸시 알림(FlutterLocalNotifications)을 총괄하여 처리하는 알림 관리 서비스 클래스
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  /// NotificationService 싱글톤 인스턴스 팩토리 생성자
  factory NotificationService() => _instance;

  NotificationService._internal();

  /// 포그라운드 알림 수신 시 인게임 UI 연동을 위한 외부 콜백 홀더
  ForegroundMessageCallback? onForegroundMessageReceived;

  FirebaseMessaging? _fcm;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// 서비스 초기화 완료 여부를 반환합니다.
  bool get isInitialized => _initialized;

  /// 안드로이드 OS 전용 알림 채널 정의 객체
  static final AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'conquest_notifications',
    GameStrings.notificationChannelName,
    description: GameStrings.notificationChannelDescription,
    importance: Importance.max,
  );

  /// FCM 및 로컬 알림 플러그인을 활성화하고 채널 및 포그라운드 리스너를 초기 등록합니다.
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      _fcm = FirebaseMessaging.instance;

      NotificationSettings? settings = await _fcm?.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings?.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('푸시 알림 권한 승인됨');
      }

      // iOS/macOS 포그라운드 상태에서는 시스템 OS 알림 팝업 배너 노출 차단 (인게임 알림 UI 위젯으로 우회 노출)
      await _fcm?.setForegroundNotificationPresentationOptions(
        alert: false,
        badge: true,
        sound: false,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(_channel);

      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/launcher_icon');
      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings();

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      if (defaultTargetPlatform == TargetPlatform.android) {
        await _localNotifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.requestNotificationsPermission();
      }

      await _localNotifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (details) {
          // 알림 클릭 시 로직
        },
      );

      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        try {
          if (!await PreferencesService.isNotificationEnabled()) {
            debugPrint('🔔 [알림 차단] 마스터 알림이 비활성화 상태이므로 포그라운드 노출 스킵.');
            return;
          }

          // 개별 알림 항목별 수신 동의 여부 필터링
          final String? type = message.data['type'] as String?;
          if (type == 'territory_attack' &&
              !await PreferencesService.isNotifTerritoryAttackEnabled()) {
            debugPrint('🔔 [알림 차단] 영토 변경 알림이 비활성화 상태이므로 노출 스킵.');
            return;
          }
          if (type == 'satellite_complete' &&
              !await PreferencesService.isNotifSatelliteCompleteEnabled()) {
            debugPrint('🔔 [알림 차단] 위성 점령 완료 알림이 비활성화 상태이므로 노출 스킵.');
            return;
          }
          if (type == 'system_notice' &&
              !await PreferencesService.isNotifSystemNoticeEnabled()) {
            debugPrint('🔔 [알림 차단] 시스템 공지 알림이 비활성화 상태이므로 노출 스킵.');
            return;
          }

          RemoteNotification? notification = message.notification;
          if (notification != null && !kIsWeb) {
            // 포그라운드 상태에서는 OS 단말기 시스템 상단 알림 배너를 띄우지 않고, 인게임 알림 UI 팝업으로 라우팅
            onForegroundMessageReceived?.call(
              notification.title ?? '',
              notification.body ?? '',
              type ?? 'system_notice',
            );
          }
        } catch (e) {
          debugPrint('⚠️ 포그라운드 푸시 필터링 중 오류: $e');
        }
      }, onError: (e) => debugPrint('⚠️ FCM onMessage 스트림 에러: $e'));

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('백그라운드 알림 클릭됨: ${message.data}');
      }, onError: (e) => debugPrint('⚠️ FCM onMessageOpenedApp 스트림 에러: $e'));

      // FCM 토큰이 갱신되거나 최초 발급되는 시점에 토픽 자동 재구독 연동
      _fcm?.onTokenRefresh.listen((token) {
        debugPrint('🔑 FCM 토큰 최초/갱신 취득 완료 (길이: ${token.length})');
        if (_currentUserId != null) {
          subscribeToTopic('user_$_currentUserId');
        }
      }, onError: (e) => debugPrint('⚠️ FCM 토큰 갱신 스트림 에러: $e'));

      await _clearBadge();

      _initialized = true;
    } catch (e) {
      debugPrint('NotificationService 초기화 실패: $e');
    }
  }

  String? _currentUserId;

  /// 현재 로그인된 사용자 ID를 셋업합니다.
  void setCurrentUserId(String? userId) {
    _currentUserId = userId;
  }

  /// 로컬 푸시 알림을 즉시 화면에 노출시킵니다.
  Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    try {
      if (!await PreferencesService.isNotificationEnabled()) {
        debugPrint('🔔 [알림 차단] 마스터 알림이 비활성화 상태이므로 로컬 알림 노출 스킵.');
        return;
      }
    } catch (e) {
      debugPrint('⚠️ PreferencesService 알림 설정 조회 실패: $e');
    }

    await _localNotifications.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  /// 서버에 등록하여 개별 푸시 발송 시 사용할 FCM 토큰값을 반환합니다.
  Future<String?> getToken() async {
    if (!_initialized) return null;
    return await _fcm?.getToken();
  }

  /// 특정 팀 채널 또는 관심사 채널을 구독 설정하여 단체 푸시를 수신하도록 합니다.
  Future<void> subscribeToTopic(String topic) async {
    if (!_initialized) return;

    try {
      await _fcm?.subscribeToTopic(topic);
      debugPrint('✅ 주제 구독 성공: $topic');
    } catch (e) {
      debugPrint('⚠️ 주제 구독 실패($topic): $e');
    }
  }

  /// 지정한 채널(토픽)의 단체 푸시 수신 구독을 해제합니다.
  Future<void> unsubscribeFromTopic(String topic) async {
    if (!_initialized) return;

    try {
      await _fcm?.unsubscribeFromTopic(topic);
      debugPrint('🔔 주제 구독 해제 완료: $topic');
    } catch (e) {
      debugPrint('⚠️ 주제 구독 해제 실패($topic): $e');
    }
  }

  /// 런처 아이콘 상의 미확인 배지 숫자를 0으로 리셋하고 현재 알림 목록을 클리어합니다.
  Future<void> _clearBadge() async {
    try {
      if (kIsWeb) return;

      await AppBadgePlus.updateBadge(0);

      await _localNotifications.cancelAll();

      debugPrint('✅ 앱 아이콘 배지 초기화 완료');
    } catch (e) {
      debugPrint('⚠️ 배지 초기화 실패: $e');
    }
  }
}

/// 백그라운드 구동 상태에서 FCM 메시지를 수신했을 때 구동되는 최상위 백그라운드 핸들러 함수
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("백그라운드 메시지 처리 중: ${message.messageId}");
}
