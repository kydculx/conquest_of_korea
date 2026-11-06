import 'dart:io';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:conquest_mobile/views/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'services/notification_service.dart';
import 'core/theme.dart';
import 'core/constants/app_routes.dart';
import 'core/constants/strings.dart';
import 'core/navigation/app_navigator.dart';
import 'game/conquest_game.dart';
import 'providers/game_provider.dart';
import 'providers/game_tile_provider.dart';
import 'providers/location_provider.dart';
import 'services/geo_service.dart';
import 'services/health_service.dart';
import 'services/preferences_service.dart';
import 'services/supabase_service.dart';
import 'views/screens/auth/login_screen.dart';
import 'views/screens/auth/terms_agreement_screen.dart';
import 'views/screens/auth/signup_screen.dart';
import 'views/screens/profile_screen.dart';
import 'views/screens/ranking_screen.dart';
import 'views/screens/achievement_screen.dart';
import 'views/screens/daily_records_screen.dart';
import 'views/screens/pattern_guide_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/ranking_provider.dart';
import 'providers/achievement_provider.dart';

import 'package:easy_localization/easy_localization.dart';

/// Flutter 앱의 메인 진입점 함수로, 각종 타사 서비스(SDK) 초기화와 화면 상태 잠금 및 의존성 주입 구조를 형성합니다.
void main() async {
  // 릴리즈 빌드 모드일 때 콘솔 로그(debugPrint) 출력을 원천 침묵(Silence)시킵니다.
  if (kReleaseMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }

  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  // 환경 변수 로드
  await dotenv.load(fileName: ".env");

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

  // 위치 권한은 GameScreen 진입 시 1회만 요청 (중복 다이얼로그 방지)

  // 걸음 수 권한 요청.
  // - Android: 앱 시작 시 1회만 자동 요청 (Health Connect가 없는 기기에서는
  //   Play Store 리다이렉트가 매번 발생할 수 있어 1회 가드 적용).
  // - iOS: 시작 시 자동 요청 없음. HealthKit이 허용 여부를 알려주지 않으므로
  //   미연동 시 "걸음수 연결" 버튼을 노출하고, 사용자가 탭할 때 시스템 허용
  //   화면을 띄운다 (Android 거부 후 버튼 흐름과 동일).
  try {
    if (!Platform.isIOS) {
      final stepAsked = await PreferencesService.isStepPermissionAsked();
      if (!stepAsked) {
        await PreferencesService.setStepPermissionAsked();
        if (!await HealthService.instance.hasStepPermissions()) {
          await HealthService.instance.requestStepPermissions();
        }
      }
    }
  } catch (e) {
    debugPrint('⚠️ 걸음 수 권한 확인 실패: $e');
  }

  await applyOrientationPolicy();

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('ko'),
        Locale('en'),
        Locale('zh'),
        Locale('zh', 'TW'),
        Locale('ja'),
        Locale('es'),
        Locale('fr'),
        Locale('de'),
        Locale('pt'),
        Locale('it'),
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      useOnlyLangCode: false,
      child: MultiProvider(
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

          // Achievement Provider
          ChangeNotifierProxyProvider<AuthProvider, AchievementProvider>(
            create: (ctx) =>
                AchievementProvider(supabase: ctx.read<SupabaseService>()),
            update: (_, auth, ach) => ach!..setAuthProvider(auth),
          ),

          // Game Tile Provider — 타일 데이터 저장소 (GameProvider에서 분리)
          ChangeNotifierProxyProvider2<SupabaseService, AuthProvider,
              GameTileProvider>(
            create: (ctx) =>
                GameTileProvider(supabase: ctx.read<SupabaseService>()),
            update: (_, supabase, auth, tileProv) =>
                tileProv!..setAuthProvider(auth),
          ),

          // Game Provider — 게임 핵심 상태 및 오케스트레이션
          ChangeNotifierProxyProvider4<
            LocationProvider,
            AuthProvider,
            AchievementProvider,
            GameTileProvider,
            GameProvider
          >(
            create: (ctx) => GameProvider(
              supabase: ctx.read<SupabaseService>(),
              tileProvider: ctx.read<GameTileProvider>(),
            ),
            update: (_, loc, auth, ach, tileProv, game) {
              game!.setLocationProvider(loc);
              game.setAuthProvider(auth);
              game.setAchievementProvider(ach);
              return game;
            },
          ),

          // Ranking Provider — 플레이어 랭킹 상태
          ChangeNotifierProxyProvider<AuthProvider, RankingProvider>(
            create: (ctx) =>
                RankingProvider(supabase: ctx.read<SupabaseService>()),
            update: (_, auth, ranking) => ranking!..setAuthProvider(auth),
          ),

          // Flame 게임 엔진 인스턴스
          Provider(create: (_) => ConquestGame()),
        ],
        child: const _OrientationPolicy(child: _ConquestApp()),
      ),
    ),
  );
}

/// 앱의 최상위 UI 레이아웃, 다국어 처리, 테마 정보 및 모바일 화면 라우터 목록을 정의하는 비공개 루트 위젯
class _ConquestApp extends StatelessWidget {
  /// _ConquestApp 생성자
  const _ConquestApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: GameStrings.appName,
      navigatorKey: appNavigatorKey,
      debugShowCheckedModeBanner: false,
      theme: TacticalTheme.darkTheme,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      home: const AuthWrapper(),
      routes: {
        AppRoutes.login: (context) => const LoginScreen(),
        AppRoutes.profile: (context) => const ProfileScreen(),
        AppRoutes.termsAgreement: (context) => const TermsAgreementScreen(),
        AppRoutes.signup: (context) => const SignupScreen(),
        AppRoutes.ranking: (context) => const RankingScreen(),
        AppRoutes.achievement: (context) => const AchievementScreen(),
        AppRoutes.patternGuide: (context) => const PatternGuideScreen(),
        AppRoutes.dailyRecords: (context) => const DailyRecordsScreen(),
      },
    );
  }
}

bool? _iPhoneDuoCache;

Future<bool> _detectIPhoneDuo() async {
  final cached = _iPhoneDuoCache;
  if (cached != null) return cached;
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) {
    _iPhoneDuoCache = false;
    return false;
  }
  try {
    final iosInfo = await DeviceInfoPlugin().iosInfo;
    final simulatorModel = Platform.environment['SIMULATOR_MODEL_IDENTIFIER'];
    final isDuo = iosInfo.utsname.machine == 'iPhone19,4' ||
        simulatorModel == 'iPhone19,4';
    _iPhoneDuoCache = isDuo;
    return isDuo;
  } catch (e) {
    debugPrint('⚠️ 기기 모델 확인 실패: $e');
    _iPhoneDuoCache = false;
    return false;
  }
}

/// 앱이 실제로 렌더링 중인 FlutterView.
/// `views.first`는 Duo처럼 디스플레이가 여러 개인 기기에서 접힌 쪽(외부) 뷰를
/// 집을 수 있으므로, runApp이 사용하는 implicitView를 우선한다.
ui.FlutterView? _activeFlutterView() {
  final dispatcher = WidgetsBinding.instance.platformDispatcher;
  final implicit = dispatcher.implicitView;
  if (implicit != null) return implicit;
  final views = dispatcher.views;
  if (views.isEmpty) return null;
  return views.reduce((a, b) {
    final aArea = a.physicalSize.width * a.physicalSize.height;
    final bArea = b.physicalSize.width * b.physicalSize.height;
    return aArea >= bArea ? a : b;
  });
}

/// 디스플레이 자체의 논리 크기. 회전/접힘 전환 중에도 외부/내부 화면을
/// 구분할 수 있어 Duo 접힘 판정에 더 안정적이다.
Size _displayLogicalSize(ui.FlutterView? view) {
  if (view == null) return Size.zero;
  try {
    final display = view.display;
    return display.size / display.devicePixelRatio;
  } catch (_) {
    return Size.zero;
  }
}

List<DeviceOrientation>? _lastAppliedOrientations;

Future<void> applyOrientationPolicy() async {
  final isDuo = await _detectIPhoneDuo();
  final view = _activeFlutterView();
  final viewSize = view == null
      ? Size.zero
      : view.physicalSize / view.devicePixelRatio;
  final displaySize = _displayLogicalSize(view);

  final folds = view?.displayFeatures ?? const <ui.DisplayFeature>[];
  final hasFold = folds.any(
    (feature) =>
        feature.type == ui.DisplayFeatureType.fold ||
        feature.type == ui.DisplayFeatureType.hinge,
  );

  // Duo는 디스플레이 크기로 내부/외부를 구분한다.
  final referenceSize =
      isDuo && displaySize.width > 0 && displaySize.height > 0
      ? displaySize
      : viewSize;
  final isDuoInner = isDuo && referenceSize.shortestSide >= 600;
  final isAndroidFoldOpen =
      !kIsWeb &&
      defaultTargetPlatform == TargetPlatform.android &&
      hasFold &&
      viewSize.shortestSide >= 600;

  final target = isDuoInner || isAndroidFoldOpen
      ? const [
          DeviceOrientation.portraitUp,
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]
      : const [DeviceOrientation.portraitUp];

  debugPrint(
    '🧭 orientation: duo=$isDuo inner=$isDuoInner '
    'view=$viewSize display=$displaySize target=${target.length}',
  );

  // 같은 값을 반복 적용하면 iOS가 회전/리사이즈를 다시 평가하며
  // 접힘 전환 중 레이아웃이 흔들릴 수 있으므로 변경 시에만 적용한다.
  if (listEquals(_lastAppliedOrientations, target)) return;
  _lastAppliedOrientations = List<DeviceOrientation>.of(target);
  await SystemChrome.setPreferredOrientations(target);
}

class _OrientationPolicy extends StatefulWidget {
  final Widget child;

  const _OrientationPolicy({required this.child});

  @override
  State<_OrientationPolicy> createState() => _OrientationPolicyState();
}

class _OrientationPolicyState extends State<_OrientationPolicy>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(applyOrientationPolicy());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    // 메트릭 콜백 시점에는 뷰 크기가 아직 갱신 전일 수 있어
    // 다음 프레임에서 새 크기를 읽어 판정한다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(applyOrientationPolicy());
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(applyOrientationPolicy());
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// 플레이어의 로그인 세션 여부와 계정 등록 절차를 판정하기 전 최초의 인게임 연출(스플래시 화면)을 실행하기 위한 Wrapper 위젯
class AuthWrapper extends StatelessWidget {
  /// AuthWrapper 생성자
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // 앱 기동 시 타이틀 화면을 먼저 노출하고, 초기화 완료 후 GameScreen으로 이행
    return const SplashScreen();
  }
}
