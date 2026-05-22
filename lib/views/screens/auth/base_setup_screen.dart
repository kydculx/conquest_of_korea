import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/map_config.dart';
import '../../../core/constants/strings.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/location_provider.dart';
import '../../../providers/game_provider.dart';
import '../../../services/hex_service.dart';
import '../../../core/utils/error_translator.dart';

/// 메인 기지(HQ) 초기 설정 화면 (GPS 수신 기반)
/// 요원의 실제 GPS 물리 위치를 식별하여, 게임 플레이의 시작점이 될
/// 최초 본부 기지(HQ) 헥사곤 구역을 확인하고 설정하는 지도 화면 클래스입니다.
class BaseSetupScreen extends StatefulWidget {
  /// 본부 기지 설정 화면의 생성자입니다.
  const BaseSetupScreen({super.key});

  @override
  State<BaseSetupScreen> createState() => _BaseSetupScreenState();
}

/// [BaseSetupScreen]의 레이더 효과 애니메이션 및 서버 통신 처리 상태를 관리하는 상태 클래스입니다.
class _BaseSetupScreenState extends State<BaseSetupScreen>
    with SingleTickerProviderStateMixin {
  /// 지도 줌 및 카메라 포커싱을 제어하기 위한 지도 컨트롤러 캐시 객체입니다.
  final MapController _mapController = MapController();

  /// GPS 조준 시각화 링의 펄스 효과를 제어하는 애니메이션 컨트롤러입니다.
  late AnimationController _pulseController;

  /// 펄스 반경 스펙트럼(크기 변화)을 보간하는 애니메이션 객체입니다.
  late Animation<double> _pulseAnimation;

  /// 서버에 본부 기지 설정 처리를 요청 중인 동안 로딩 상태를 보여주는 플래그입니다.
  bool _isSubmitting = false;

  /// 최초 GPS 감지 후 지도의 포커스를 해당 위치로 1회 강제 이동시켰는지에 대한 상태 플래그입니다.
  bool _hasMovedToInitialLocation = false;

  @override
  void initState() {
    super.initState();

    // 레이더 펄스 애니메이션 설정
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  /// 사용자가 확인한 물리 헥사곤 타일 ID([tileId])를 요원의 공식 본부 기지(HQ)로 설정하도록 서버 API를 호출합니다.
  Future<void> _setupMainBase(String tileId) async {
    setState(() => _isSubmitting = true);
    try {
      final authProvider = context.read<AuthProvider>();
      await authProvider.updateMainBase(tileId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(GameStrings.baseSetupCompleteAlert),
            backgroundColor: GameColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorTranslator.translate(e)),
            backgroundColor: GameColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocationProvider>();
    final game = context.read<GameProvider>();
    final currentLocation = loc.currentLocation;

    // GPS 미수신 시 레이더 스캔 대기 화면 렌더링
    if (currentLocation == null) {
      return Scaffold(
        backgroundColor: GameColors.tacticalBlack,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                GameColors.tacticalGray.withValues(alpha: 0.8),
                GameColors.tacticalBlack,
              ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: GameColors.accentNeon.withValues(alpha: 0.7),
                              width: 2.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: GameColors.accentNeon.withValues(alpha: 0.25),
                                blurRadius: 20.0,
                                spreadRadius: 5.0,
                              )
                            ],
                          ),
                          child: Icon(
                            Icons.satellite_alt_rounded,
                            color: GameColors.accentNeon,
                            size: 48,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                  Text(
                    GameStrings.baseSetupSearchingSignal,
                    style: TextStyle(
                      color: GameColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    GameStrings.baseSetupInstruction,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: GameColors.textMuted,
                      fontSize: 12,
                      height: 1.6,
                    ),
                  ),
                  if (!loc.isGpsActive) ...[
                    const SizedBox(height: 24),
                    Text(
                      GameStrings.gpsDisabled,
                      style: TextStyle(
                        color: GameColors.error,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ]
                ],
              ),
            ),
          ),
        ),
      );
    }

    // GPS 좌표가 수신되었을 경우 메인 기지 후보 계산
    final hex = HexService.latLngToHex(currentLocation);
    final tileId = 'hex_${hex['q']}_${hex['r']}';
    final corners = HexService.getHexCorners(hex['q']!, hex['r']!);

    // 화면 진입 시 지도를 사용자의 현재 위치로 서서히 이동 (1회 제한)
    if (!_hasMovedToInitialLocation) {
      _hasMovedToInitialLocation = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(currentLocation, MapConfig.focusZoom);
      });
    }

    return Scaffold(
      backgroundColor: GameColors.tacticalBlack,
      body: Stack(
        children: [
          // 1. 지도 렌더링
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: currentLocation,
              initialZoom: MapConfig.focusZoom,
              minZoom: MapConfig.minZoom,
              maxZoom: MapConfig.maxZoom,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              // 배경 지도 스타일
              if (game.showMap && game.currentMapStyle.url.isNotEmpty)
                Builder(
                  builder: (context) {
                    final style = game.currentMapStyle;
                    final tileLayer = TileLayer(
                      urlTemplate: style.url,
                      subdomains: const ['a', 'b', 'c', 'd'],
                      userAgentPackageName: 'com.watercherry.conquestofkorea',
                    );

                    if (style.colorMatrix != null) {
                      return ColorFiltered(
                        colorFilter: ColorFilter.matrix(style.colorMatrix!),
                        child: tileLayer,
                      );
                    }
                    return tileLayer;
                  },
                ),

              // 2. 기지 헥사곤 강조 표시
              PolygonLayer(
                polygons: [
                  Polygon(
                    points: corners,
                    color: GameColors.accentNeon.withValues(alpha: 0.15),
                    borderColor: GameColors.accentNeon,
                    borderStrokeWidth: 2.5,
                  ),
                ],
              ),

              // 3. 기지 위치 마커 (HQ 깃발)
              MarkerLayer(
                markers: [
                  Marker(
                    point: currentLocation,
                    width: 60,
                    height: 60,
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 40 * _pulseAnimation.value,
                              height: 40 * _pulseAnimation.value,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: GameColors.accentNeon.withValues(alpha: 0.2),
                                border: Border.all(
                                  color: GameColors.accentNeon,
                                  width: 1.0,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.flag_circle_rounded,
                              color: GameColors.accentNeon,
                              size: 36,
                              shadows: [
                                Shadow(
                                  color: GameColors.accentNeon.withValues(alpha: 0.8),
                                  blurRadius: 8,
                                )
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),

          // 4. 전술 격자 프레임 데코레이션
          IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: GameColors.accentNeon.withValues(alpha: 0.3),
                  width: 2.0,
                ),
              ),
            ),
          ),

          // 5. 상단 위성 정찰 상태 HUD
          Positioned(
            top: 60,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: ShapeDecoration(
                color: GameColors.backgroundMedium.withValues(alpha: 0.9),
                shape: BeveledRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: GameColors.accentNeon.withValues(alpha: 0.5),
                    width: 1.0,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.security_rounded,
                    color: GameColors.accentNeon,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          GameStrings.satellitePositionOk,
                          style: TextStyle(
                            color: GameColors.accentNeon,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          GameStrings.currentLatitudeLongitude(
                            currentLocation.latitude.toStringAsFixed(5),
                            currentLocation.longitude.toStringAsFixed(5),
                          ),
                          style: TextStyle(
                            color: GameColors.textSecondary,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 6. 하단 기지 설정 동작 패널
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: ShapeDecoration(
                color: GameColors.backgroundMedium.withValues(alpha: 0.95),
                shape: BeveledRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: GameColors.accentNeon,
                    width: 1.5,
                  ),
                ),
                shadows: [
                  BoxShadow(
                    color: GameColors.accentNeon.withValues(alpha: 0.25),
                    blurRadius: 15.0,
                    spreadRadius: 1.0,
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.radar_rounded,
                        color: GameColors.accentNeon,
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        GameStrings.baseSetupTitle,
                        style: TextStyle(
                          color: GameColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Divider(color: GameColors.dividerColor, height: 1),
                  const SizedBox(height: 16),
                  Text(
                    GameStrings.baseSetupDescription(tileId),
                    style: TextStyle(
                      color: GameColors.textPrimary.withValues(alpha: 0.85),
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : () => _setupMainBase(tileId),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GameColors.accentNeon,
                      foregroundColor: GameColors.tacticalBlack,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: BeveledRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: _isSubmitting
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: GameColors.tacticalBlack,
                            ),
                          )
                        : Text(
                            GameStrings.baseSetupConfirmButton,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
