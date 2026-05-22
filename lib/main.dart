import 'package:conquest_mobile/views/screens/splash_screen.dart';
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
import 'core/constants/strings.dart';
import 'game/conquest_game.dart';
import 'providers/game_provider.dart';
import 'providers/location_provider.dart';
import 'services/geo_service.dart';
import 'services/supabase_service.dart';
import 'views/screens/auth/login_screen.dart';
import 'views/screens/auth/terms_agreement_screen.dart';
import 'views/screens/auth/signup_screen.dart';
import 'views/screens/profile_screen.dart';
import 'providers/auth_provider.dart';

import 'package:easy_localization/easy_localization.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

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
    EasyLocalization(
      supportedLocales: const [Locale('ko'), Locale('en')],
      path: 'assets/translations',
      fallbackLocale: const Locale('ko'),
      child: MultiProvider(
        providers: [
          // 순수 서비스 레이어
          Provider(create: (_) => GeoService()),
          Provider(create: (_) => SupabaseService()),

          // Auth Provider
          ChangeNotifierProvider(create: (_) => AuthProvider()),

          // Location Provider — GPS + 나침반 상태
          ChangeNotifierProxyProvider2<GeoService, AuthProvider, LocationProvider>(
            create: (_) => LocationProvider(),
            update: (_, geo, auth, loc) => loc!
              ..setGeoService(geo)
              ..setAuthProvider(auth),
          ),

          // Game Provider — 게임 핵심 상태
          ChangeNotifierProxyProvider2<
            LocationProvider,
            AuthProvider,
            GameProvider
          >(
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
    ),
  );
}

class _ConquestApp extends StatelessWidget {
  const _ConquestApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: GameStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: TacticalTheme.darkTheme,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      home: const AuthWrapper(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/terms-agreement': (context) => const TermsAgreementScreen(),
        '/signup': (context) => const SignupScreen(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // 앱 기동 시 스플래시 화면을 먼저 노출하고, 위성 동기화 완료 후 GameScreen으로 이행
    return const SplashScreen();
  }
}
