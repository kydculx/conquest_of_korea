import 'package:conquest_mobile/views/screens/game_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'services/notification_service.dart';
import 'core/theme.dart';
import 'core/constants.dart';
import 'game/conquest_game.dart';
import 'providers/game_provider.dart';
import 'providers/location_provider.dart';
import 'services/geo_service.dart';
import 'services/supabase_service.dart';
import 'views/screens/auth/login_screen.dart';

import 'views/screens/profile_screen.dart';
import 'providers/auth_provider.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 환경 변수 로드
  await dotenv.load(fileName: ".env");

  // Kakao SDK 초기화
  final kakaoNativeKey = dotenv.env['KAKAO_NATIVE_APP_KEY'];
  if (kakaoNativeKey != null) {
    KakaoSdk.init(nativeAppKey: kakaoNativeKey);
  }

  // 화면 자동 꺼짐 방지
  WakelockPlus.enable();

  // Supabase 초기화
  await SupabaseService.initialize();

  // Firebase 초기화
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 알림 서비스 초기화
    await NotificationService().initialize();
    debugPrint('✅ Firebase & Notification 초기화 완료');
  } catch (e) {
    debugPrint('⚠️ Firebase 초기화 실패 (알림 기능 제한): $e');
  }

  // 세로 모드 고정
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(
    MultiProvider(
      providers: [
        // 순수 서비스 레이어
        Provider(create: (_) => GeoService()),
        Provider(create: (_) => SupabaseService()),

        // Auth Provider
        ChangeNotifierProvider(create: (_) => AuthProvider()),

        // Location Provider — GPS + 나침반 상태
        ChangeNotifierProxyProvider<GeoService, LocationProvider>(
          create: (_) => LocationProvider(),
          update: (_, geo, loc) => loc!..setGeoService(geo),
        ),

        // Game Provider — 게임 핵심 상태
        ChangeNotifierProxyProvider2<LocationProvider, AuthProvider, GameProvider>(
          create: (ctx) => GameProvider(supabase: ctx.read<SupabaseService>()),
          update: (_, loc, auth, game) {
            game!.setLocationProvider(loc);
            game.setAuthProvider(auth);
            return game;
          },
        ),

        // Flame 게임 엔진 인스턴스
        Provider(create: (_) => ConquestGame()),
      ],
      child: const _ConquestApp(),
    ),
  );
}

class _ConquestApp extends StatelessWidget {
  const _ConquestApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: GameConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: TacticalTheme.darkTheme,
      home: const AuthWrapper(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // 로그인 여부와 무관하게 항상 맵 화면 표시
    // 로그인은 HUD의 버튼을 통해 접근
    return const GameScreen();
  }
}
