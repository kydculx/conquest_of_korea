import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'core/theme.dart';
import 'core/constants.dart';
import 'game/conquest_game.dart';
import 'providers/game_provider.dart';
import 'providers/location_provider.dart';
import 'services/geo_service.dart';
import 'services/supabase_service.dart';
import 'views/screens/game_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 화면 자동 꺼짐 방지
  WakelockPlus.enable();

  // Supabase 초기화
  await SupabaseService.initialize();

  // 세로 모드 고정
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(
    MultiProvider(
      providers: [
        // 순수 서비스 레이어
        Provider(create: (_) => GeoService()),
        Provider(create: (_) => SupabaseService()),

        // Location Provider — GPS + 나침반 상태
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProxyProvider<GeoService, LocationProvider>(
          create: (_) => LocationProvider(),
          update: (_, geo, loc) => loc!..setGeoService(geo),
        ),

        // Game Provider — 게임 핵심 상태
        ChangeNotifierProxyProvider<LocationProvider, GameProvider>(
          create: (ctx) =>
              GameProvider(supabase: ctx.read<SupabaseService>()),
          update: (_, loc, game) => game!..setLocationProvider(loc),
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
      home: const GameScreen(),
    );
  }
}
