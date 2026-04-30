import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// 푸시 알림 관리 서비스
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  FirebaseMessaging? _fcm;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool get isInitialized => _initialized;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'conquest_notifications',
    '한국정복 알림',
    description: '점령 및 전투 관련 중요 알림입니다.',
    importance: Importance.max,
  );

  /// 초기화
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      _fcm = FirebaseMessaging.instance;

      // 1. 알림 권한 요청 (iOS/Android 13+)
      NotificationSettings? settings = await _fcm?.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings?.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('푸시 알림 권한 승인됨');
      }

      // 2. 로컬 알림 채널 설정 (Android)
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);

      // 3. 로컬 알림 초기화
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (details) {
          // 알림 클릭 시 로직 (필요시 구현)
        },
      );

      // 4. 포그라운드 메시지 핸들링
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        RemoteNotification? notification = message.notification;

        if (notification != null && !kIsWeb) {
          showLocalNotification(
            id: notification.hashCode,
            title: notification.title ?? '',
            body: notification.body ?? '',
          );
        }
      });

      // 5. 백그라운드에서 앱 실행 시 메시지 핸들링
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('백그라운드 알림 클릭됨: ${message.data}');
      });

      _initialized = true;
    } catch (e) {
      debugPrint('NotificationService 초기화 실패: $e');
      // 초기화 실패 시에도 _initialized는 false로 남으므로 안전합니다.
    }
  }

  /// 로컬 알림 직접 발송 (테스트 및 즉각적 피드백용)
  Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    // 로컬 알림은 Firebase 없이도 작동 가능
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

  /// FCM 토큰 가져오기 (서버 저장용)
  Future<String?> getToken() async {
    if (!_initialized) return null;
    return await _fcm?.getToken();
  }

  /// 특정 주제 구독 (예: 팀별 알림)
  Future<void> subscribeToTopic(String topic) async {
    if (!_initialized) return;

    try {
      // iOS에서는 APNS 토큰이 있어야 구독 가능
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final apnsToken = await _fcm?.getAPNSToken();
        if (apnsToken == null) {
          debugPrint('⚠️ iOS APNS 토큰이 아직 준비되지 않아 주제 구독($topic)을 보류합니다.');
          return;
        }
      }

      await _fcm?.subscribeToTopic(topic);
      debugPrint('✅ 주제 구독 성공: $topic');
    } catch (e) {
      debugPrint('⚠️ 주제 구독 실패($topic): $e');
    }
  }

  /// 특정 주제 구독 해제
  Future<void> unsubscribeFromTopic(String topic) async {
    if (!_initialized) return;

    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final apnsToken = await _fcm?.getAPNSToken();
        if (apnsToken == null) return;
      }

      await _fcm?.unsubscribeFromTopic(topic);
      debugPrint('✅ 주제 구독 해제 성공: $topic');
    } catch (e) {
      debugPrint('⚠️ 주제 구독 해제 실패($topic): $e');
    }
  }
}

/// 백그라운드 메시지 핸들러 (최상위 함수여야 함)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("백그라운드 메시지 처리 중: ${message.messageId}");
}
