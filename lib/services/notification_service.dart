import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/constants/strings.dart';
import 'preferences_service.dart';

/// 포그라운드 FCM 메시지 수신 시 인게임 알림 UI로 라우팅 처리하기 위한 커스텀 콜백 핸들러 타입
typedef ForegroundMessageCallback =
    void Function(String title, String body, String type, String? tileId);

/// 알림 탭(백그라운드/종료 상태 포함) 시 FCM 데이터 페이로드를 전달하기 위한 콜백 타입
typedef NotificationOpenedCallback = void Function(Map<String, dynamic> data);

/// Firebase Cloud Messaging(FCM) 및 로컬 푸시 알림(FlutterLocalNotifications)을 총괄하여 처리하는 알림 관리 서비스 클래스
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  /// NotificationService 싱글톤 인스턴스 팩토리 생성자
  factory NotificationService() => _instance;

  NotificationService._internal();

  /// 포그라운드 알림 수신 시 인게임 UI 연동을 위한 외부 콜백 홀더
  ForegroundMessageCallback? onForegroundMessageReceived;

  /// 알림 탭 시 게임 화면 이동 처리를 위한 외부 콜백 홀더
  NotificationOpenedCallback? _onNotificationOpened;

  /// 콜백 등록 전에 알림 탭으로 전달된 데이터를 보관하는 대기 버퍼
  Map<String, dynamic>? _pendingOpenedData;

  /// 동일 알림이 초기 메시지와 스트림 양쪽으로 중복 전달되는 것을 막기 위한 ID 캐시
  final Set<String> _handledOpenedMessageIds = {};

  FirebaseMessaging? _fcm;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// 중복 구독 호출 차단을 위한 로컬 구독 토픽 캐시 집합
  final Set<String> _subscribedTopics = {};

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
          _handleLocalNotificationPayload(details.payload);
        },
      );

      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        try {
          if (!await PreferencesService.isNotificationEnabled()) {
            debugPrint('🔔 [알림 차단] 마스터 알림이 비활성화 상태이므로 포그라운드 노출 스킵.');
            return;
          }

          final String? type = message.data['type'] as String?;
          final String? tileId = message.data['tile_id'] is String
              ? message.data['tile_id'] as String
              : null;
          RemoteNotification? notification = message.notification;
          if (notification != null && !kIsWeb) {
            // 포그라운드 상태에서는 OS 단말기 시스템 상단 알림 배너를 띄우지 않고, 인게임 알림 UI 팝업으로 라우팅
            onForegroundMessageReceived?.call(
              notification.title ?? '',
              notification.body ?? '',
              type ?? 'system_notice',
              tileId,
            );
          }
        } catch (e) {
          debugPrint('⚠️ 포그라운드 푸시 필터링 중 오류: $e');
        }
      }, onError: (e) => debugPrint('⚠️ FCM onMessage 스트림 에러: $e'));

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('백그라운드 알림 클릭됨: ${message.data}');
        _dispatchOpenedMessage(message);
      }, onError: (e) => debugPrint('⚠️ FCM onMessageOpenedApp 스트림 에러: $e'));

      // 앱이 종료된 상태에서 알림을 눌러 실행된 경우 최초 메시지를 확인한다.
      try {
        final RemoteMessage? initialMessage = await _fcm?.getInitialMessage();
        if (initialMessage != null) {
          debugPrint('종료 상태 알림으로 앱 실행됨: ${initialMessage.data}');
          _dispatchOpenedMessage(initialMessage);
        }
      } catch (e) {
        debugPrint('⚠️ 최초 알림 메시지 확인 실패: $e');
      }

      // FCM 토큰이 갱신되거나 최초 발급되는 시점에 토픽 구독 상태를 알림 설정과 동기화
      _fcm?.onTokenRefresh.listen((token) async {
        debugPrint('🔑 FCM 토큰 최초/갱신 취득 완료 (길이: ${token.length})');
        if (_currentUserId != null) {
          final isEnabled = await PreferencesService.isNotificationEnabled();
          if (isEnabled) {
            await subscribeToTopic('user_$_currentUserId');
          } else {
            await unsubscribeFromTopic('user_$_currentUserId');
          }
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
    if (_currentUserId != userId) {
      _currentUserId = userId;
      _subscribedTopics.clear(); // 사용자 세션이 변경되면 캐시된 토픽 목록 무효화
    }
  }

  /// 알림 탭 처리 핸들러를 등록합니다.
  ///
  /// 핸들러 등록 전에 알림 탭 데이터가 도착했다면 보관해 두었다가
  /// 등록 즉시 한 번 전달합니다.
  void setNotificationOpenedHandler(NotificationOpenedCallback? handler) {
    _onNotificationOpened = handler;
    if (handler == null) return;

    final pending = _pendingOpenedData;
    if (pending != null) {
      _pendingOpenedData = null;
      handler(pending);
    }
  }

  /// 로컬 푸시 알림을 즉시 화면에 노출시킵니다.
  Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
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
      payload: payload,
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

    // [중복 구독 차단 가드] 이미 해당 토픽을 성공적으로 구독 중이라면 스킵하여 무한 반복 호출 차단
    if (_subscribedTopics.contains(topic)) {
      return;
    }

    try {
      await _fcm?.subscribeToTopic(topic);
      _subscribedTopics.add(topic);
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
      _subscribedTopics.remove(topic);
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

  static const MethodChannel _systemNotificationChannel = MethodChannel(
    'com.watercherry.conquest_mobile/notification',
  );

  /// OS 시스템 레벨의 알림 권한 허용 여부를 조회합니다.
  Future<bool> checkSystemNotificationPermission() async {
    if (kIsWeb) return true;

    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final bool? enabled = await _systemNotificationChannel
            .invokeMethod<bool>('areNotificationsEnabled');
        return enabled ?? true;
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final fcm = _fcm ?? FirebaseMessaging.instance;
        final settings = await fcm.getNotificationSettings();
        return settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional;
      }
    } catch (e) {
      debugPrint('⚠️ OS 알림 권한 확인 실패: $e');
    }
    return true;
  }

  /// OS 시스템 알림 권한을 사용자에게 요청합니다.
  Future<bool> requestSystemNotificationPermission() async {
    if (kIsWeb) return true;

    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final granted = await _localNotifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.requestNotificationsPermission();
        return granted ?? await checkSystemNotificationPermission();
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final fcm = _fcm ?? FirebaseMessaging.instance;
        final settings = await fcm.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
        return settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional;
      }
    } catch (e) {
      debugPrint('⚠️ OS 알림 권한 요청 실패: $e');
    }
    return false;
  }

  /// 스마트폰의 OS 앱 알림 설정 화면으로 이동합니다.
  Future<bool> openSystemNotificationSettings() async {
    if (kIsWeb) return false;

    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final bool? opened = await _systemNotificationChannel
            .invokeMethod<bool>('openNotificationSettings');
        if (opened == true) return true;
      }

      // iOS 및 Android 폴백: app-settings: 스킴 시도
      final Uri appSettingsUri = Uri.parse('app-settings:');
      if (await canLaunchUrl(appSettingsUri)) {
        return await launchUrl(appSettingsUri);
      }
    } catch (e) {
      debugPrint('⚠️ OS 알림 설정 화면 이동 실패: $e');
    }
    return false;
  }

  /// FCM 알림 탭 메시지를 중복 없이 한 번만 처리합니다.
  void _dispatchOpenedMessage(RemoteMessage message) {
    final messageId = message.messageId;
    if (messageId != null && !_handledOpenedMessageIds.add(messageId)) {
      return;
    }
    _dispatchOpenedData(message.data);
  }

  /// 알림 탭 데이터를 핸들러에 전달하고, 핸들러가 없으면 보관합니다.
  void _dispatchOpenedData(Map<String, dynamic> data) {
    if (data.isEmpty) return;

    final handler = _onNotificationOpened;
    if (handler == null) {
      _pendingOpenedData = data;
      return;
    }
    handler(data);
  }

  /// 로컬 알림 응답에 포함된 JSON payload를 해석해 탭 데이터로 전달합니다.
  void _handleLocalNotificationPayload(String? payload) {
    if (payload == null || payload.isEmpty) return;

    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map) {
        _dispatchOpenedData(Map<String, dynamic>.from(decoded));
      }
    } catch (e) {
      debugPrint('⚠️ 로컬 알림 payload 파싱 실패: $e');
    }
  }
}

/// 백그라운드 구동 상태에서 FCM 메시지를 수신했을 때 구동되는 최상위 백그라운드 핸들러 함수
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("백그라운드 메시지 처리 중: ${message.messageId}");
}
