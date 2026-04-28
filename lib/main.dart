import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'core/constants.dart';
import 'core/theme.dart';
import 'game/conquest_game.dart';
import 'map/game_map_widget.dart';
import 'services/geo_service.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'services/supabase_service.dart';
import 'ui/hud_overlay.dart';
import 'ui/team_selection_screen.dart';
import 'providers/game_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 화면 자동 꺼짐 방지 활성화
  WakelockPlus.enable();

  await SupabaseService.initialize();
  
  // 세로 모드 고정
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  
  runApp(
    MultiProvider(
      providers: [
        Provider(create: (_) => GeoService()),
        ChangeNotifierProxyProvider<GeoService, GameProvider>(
          create: (_) => GameProvider(),
          update: (_, geo, game) => game!..setGeoService(geo),
        ),
        Provider(create: (_) => ConquestGame()),
      ],
      child: const ConquestApp(),
    ),
  );
}

class ConquestApp extends StatelessWidget {
  const ConquestApp({super.key});

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

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final geo = Provider.of<GeoService>(context, listen: false);
      geo.checkPermissions().then((ok) async {
        if (ok) await geo.startTracking();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final gameProvider = Provider.of<GameProvider>(context);
    
    // 1. 팀을 선택하지 않았으면 팀 선택 화면 표시
    if (gameProvider.selectedTeam == null) {
      return const TeamSelectionScreen();
    }

    final game = Provider.of<ConquestGame>(context, listen: false);
    final geo = Provider.of<GeoService>(context, listen: false);

    // 엔진에 데이터 전달 (점령 목록 및 현재 점령 중인 애니메이션 상태 포함)
    game.updateCapturedTiles(gameProvider);

    return Scaffold(
      backgroundColor: GameConstants.tacticalBlack, // 배경색 명시적 지정
      body: StreamBuilder<Position>(
        stream: geo.locationStream,
        builder: (context, snapshot) {
          // 신호가 없으면 기본 위치(서울) 사용, 있으면 실시간 위치 사용
          final LatLng location = snapshot.hasData 
              ? LatLng(snapshot.data!.latitude, snapshot.data!.longitude)
              : GameConstants.defaultPosition;
          
          // 게임 엔진 위치 및 방향 업데이트 (UI 동기화용)
          Future.microtask(() {
            if (context.mounted) {
              game.updatePlayerLocation(location);
              game.updatePlayerHeading(gameProvider.heading);
            }
          });

          return Stack(
            children: [
              // 1. 지도 + Flame 레이어
              GameMapWidget(
                initialLocation: location,
                game: game,
              ),

              // GPS 수신 상태 안내 표시
              if (!gameProvider.isGpsActive)
                Positioned(
                  top: 100,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.red.withAlpha(200),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.black26, blurRadius: 10)
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.location_off, color: Colors.white, size: 16),
                          SizedBox(width: 8),
                          Text('GPS 신호 없음 - 점령 불가', 
                            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),

              // 2. HUD UI 레이어 (점령 진행도 포함)
              HudOverlay(
                scores: gameProvider.score,
                teamName: gameProvider.selectedTeam?.toUpperCase() ?? 'NONE',
                isCapturing: gameProvider.isCapturing,
                captureProgress: gameProvider.captureProgress,
              ),

              // 3. 전술 알림 레이어
              _buildAlerts(gameProvider.alerts),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAlerts(List<Map<String, dynamic>> alerts) {
    if (alerts.isEmpty) return const SizedBox.shrink();
    return Positioned(
      top: 150,
      left: 20,
      right: 20,
      child: Column(
        children: alerts.map((alert) => _AlertItem(alert: alert)).toList(),
      ),
    );
  }
}

class _AlertItem extends StatelessWidget {
  final Map<String, dynamic> alert;
  const _AlertItem({required this.alert});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: alert['type'] == 'success' 
            ? Colors.green.withAlpha(200) 
            : alert['type'] == 'warn' 
                ? Colors.orange.withAlpha(200)
                : Colors.red.withAlpha(200),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withAlpha(100)),
      ),
      child: Text(
        alert['message'],
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }
}
