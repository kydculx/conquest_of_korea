import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:app_badge_plus/app_badge_plus.dart';
import '../core/constants/strings.dart';

/// Firebase Cloud Messaging(FCM) 및 로컬 푸시 알림(FlutterLocalNotifications)을 총괄하여 처리하는 알림 관리 서비스 클래스
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  /// NotificationService 싱글톤 인스턴스 팩토리 생성자
  factory NotificationService() => _instance;

  NotificationService._internal();

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

      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(_channel);

      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings(
            '@mipmap/launcher_icon',
          );
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

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('백그라운드 알림 클릭됨: ${message.data}');
      });

      await _clearBadge();

      _initialized = true;
    } catch (e) {
      debugPrint('NotificationService 초기화 실패: $e');
    }
  }

  /// 로컬 푸시 알림을 즉시 화면에 노출시킵니다.
  Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
  }) async {
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

  /// 지정한 채널(토픽)의 단체 푸시 수신 구독을 해제합니다.
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
