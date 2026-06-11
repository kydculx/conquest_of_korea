import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'package:latlong2/latlong.dart' hide Path;
import '../../core/constants/colors.dart';
import '../../controllers/satellite_capture_controller.dart';
import '../../services/hex_service.dart';
import '../conquest_game.dart';
import 'tactical_path_renderer.dart';
import 'scan_crosshair.dart';

/// 위성 스캔 모드에서 사용자가 선택한 타일의 조준선 프리뷰를 렌더링하는 컴포넌트
/// 위성 궤도 정밀 조준 스캔 및 위성 원격 점령 모드에서 조준선, 본부로부터의 전술적 BFS 최단 경로 안내선, 점령 완료 시 보간 화살표 이동 애니메이션을 그리는 Flame 컴포넌트
class ScanTargetMarker extends PositionComponent
    with HasGameReference<ConquestGame> {
  /// 스캔 조준된 대상 타일의 H3 q축 좌표값
  final int q;

  /// 스캔 조준된 대상 타일의 H3 r축 좌표값
  final int r;

  /// 대상 헥사곤 거점의 지리적 위경도(LatLng) 꼭짓점 좌표 리스트
  final List<LatLng> _latLngCorners;

  /// 화면 스크린 기준으로 투영 계산된 헥사곤 꼭짓점의 픽셀 좌표 리스트
  List<Offset> _screenCorners = [];

  /// 펄싱 및 애니메이션 주기를 결정하기 위한 시간 누적 값
  double _timer = 0;

  /// 계단식 점령 진행률을 매끄러운 60 FPS 흐름으로 표현하기 위해 보간 가미한 진행률 변수
  double _smoothProgress = 0.0;

  /// 전술 경로(BFS + 점선/화살표) 렌더러
  late final TacticalPathRenderer _pathRenderer;

  /// ScanTargetMarker 생성자로 조준 대상 좌표를 설정받고 렌더링 우선순위(Priority)를 조율합니다.
  ScanTargetMarker({required this.q, required this.r})
    : _latLngCorners = HexService.getHexCorners(q, r) {
    priority = 18; // 플레이어(20)보다는 아래, 일반 타일(0)이나 메인기지(15)보다는 위
  }

  @override
  void onLoad() {
    super.onLoad();
    _pathRenderer = TacticalPathRenderer(
      game: game,
      targetQ: q,
      targetR: r,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    _timer += dt;

    // 위성 점령 중일 때 progress 보간 (비행 중일 때는 _satelliteTravelProgress를 따르고, 점령 상태로 전환되면 도착 완료인 1.0 고정)
    if (game.isSatelliteCapturing && game.satelliteCapturingTileId != null) {
      final target = game.satelliteCapturePhase == SatelliteCapturePhase.flying
          ? game.satelliteTravelProgress
          : 1.0;
      // 매 프레임 dt 비중에 맞춰 목표치로 부드럽게 Lerp
      _smoothProgress +=
          (target - _smoothProgress) * (dt * 10.0).clamp(0.0, 1.0);
    } else {
      _smoothProgress = 0.0;
    }

    if (game.mapController != null) {
      _screenCorners = _latLngCorners.map((latlng) {
        final offset = game.mapController!.camera.latLngToScreenOffset(latlng);
        return Offset(offset.dx, offset.dy);
      }).toList();
    }
  }

  @override
  void render(Canvas canvas) {
    if (_screenCorners.isEmpty) return;

    final gameSize = game.size;

    // [개선] 목적지 타일 자체의 화면 노출 여부를 판단
    final isTargetVisible = _screenCorners.any(
      (c) =>
          c.dx >= -100 &&
          c.dx <= gameSize.x + 100 &&
          c.dy >= -100 &&
          c.dy <= gameSize.y + 100,
    );

    final themeColor = GameColors.accentNeon;

    // 1. 헥사곤 경로 및 중심 계산 (아기자기한 둥근 헥사곤 패스 생성)
    double cx = 0, cy = 0;
    for (final c in _screenCorners) {
      cx += c.dx;
      cy += c.dy;
    }
    cx /= _screenCorners.length;
    cy /= _screenCorners.length;

    // 헥사곤 반지름 계산
    double radSum = 0;
    for (final c in _screenCorners) {
      final dx = c.dx - cx;
      final dy = c.dy - cy;
      radSum += math.sqrt(dx * dx + dy * dy);
    }
    final double radius = radSum / _screenCorners.length;

    // 아기자기한 둥글기 수준 및 타일 간 갭 생성
    final double cornerRadius = math.min(6.5, radius * 0.22);
    const double padding = 1.2;

    // 1) 패딩이 적용된 수축 꼭짓점 산출
    final List<Offset> insetCorners = [];
    for (int i = 0; i < _screenCorners.length; i++) {
      final c = _screenCorners[i];
      final dx = cx - c.dx;
      final dy = cy - c.dy;
      final dist = math.sqrt(dx * dx + dy * dy);

      final double insetX = dist > padding ? c.dx + (dx / dist) * padding : c.dx;
      final double insetY = dist > padding ? c.dy + (dy / dist) * padding : c.dy;
      insetCorners.add(Offset(insetX, insetY));
    }

    // 2) 베지에 곡선 기반 둥근 육각형 그리기 패스 생성
    final path = Path();
    for (int i = 0; i < insetCorners.length; i++) {
      final current = insetCorners[i];
      final prev = insetCorners[(i - 1 + insetCorners.length) % insetCorners.length];
      final next = insetCorners[(i + 1) % insetCorners.length];

      final vPrevX = prev.dx - current.dx;
      final vPrevY = prev.dy - current.dy;
      final lenPrev = math.sqrt(vPrevX * vPrevX + vPrevY * vPrevY);

      final vNextX = next.dx - current.dx;
      final vNextY = next.dy - current.dy;
      final lenNext = math.sqrt(vNextX * vNextX + vNextY * vNextY);

      final double r = math.min(cornerRadius, math.min(lenPrev / 2, lenNext / 2));

      final startX = current.dx + (vPrevX / lenPrev) * r;
      final startY = current.dy + (vPrevY / lenPrev) * r;

      final endX = current.dx + (vNextX / lenNext) * r;
      final endY = current.dy + (vNextY / lenNext) * r;

      if (i == 0) {
        path.moveTo(startX, startY);
      } else {
        path.lineTo(startX, startY);
      }
      path.quadraticBezierTo(current.dx, current.dy, endX, endY);
    }
    path.close();

    // 2. 목적지 타일 애니메이션 그리기 (화면에 보일 때만 드로잉)
    if (isTargetVisible) {
      _drawDestinationBorder(canvas, path, themeColor);
    }

    // 3. 본진에서 타겟 타일까지의 전술 경로(점선/화살표) 그리기
    if (game.mapController != null) {
      _pathRenderer.draw(
        canvas,
        themeColor,
        game.mapController!,
        _timer,
        _smoothProgress,
        game.isSatelliteCapturing,
      );
    }

    // 4. 중심 조준 타겟 그리기 (위성 스캔 모드이고, 위성 점령 송신 중이 아니며, 화면에 보일 때만 노출)
    if (game.isScanMode && !game.isSatelliteCapturing && isTargetVisible) {
      drawScanCrosshair(canvas, cx, cy, themeColor, _timer);
    }
  }

  /// 목적지 헥사곤 타일 내부 맥동 및 글로우 테두리 렌더링
  void _drawDestinationBorder(Canvas canvas, Path path, Color themeColor) {
    // 비행 완료 후 실제 타일 채우기 점령 상태에 진입했는지 여부
    final bool isActuallyCapturingTile =
        game.isSatelliteCapturing &&
        game.satelliteCapturePhase == SatelliteCapturePhase.capturing;

    if (isActuallyCapturingTile) {
      // 화살표가 도달한 이후 점령이 시작되었을 때의 펄싱 테두리 애니메이션
      final double fillPulse = 0.20 + 0.15 * math.sin(_timer * 8.0);
      final fillPaint = Paint()
        ..color = themeColor.withValues(alpha: fillPulse)
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, fillPaint);

      final double borderPulse = 0.5 + 0.4 * math.sin(_timer * 8.0);
      final borderGlow = Paint()
        ..color = themeColor.withValues(alpha: borderPulse)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
      canvas.drawPath(path, borderGlow);

      final borderPaint = Paint()
        ..color = themeColor.withValues(alpha: 0.95)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawPath(path, borderPaint);
    } else {
      // 점령 전(화살표 이동 중이거나 단순 조준 프리뷰 상태인 경우)
      // 위성 점령 실행 중(이동 중)에는 목적지 타일에 은은한 점선 테두리와 비콘 수신 펄스 링 신호 효과를 그립니다.
      if (game.isSatelliteCapturing) {
        final Color beaconColor = themeColor;

        // 1. 은은한 점선 헥사곤 테두리 그리기
        final borderPaint = Paint()
          ..color = beaconColor.withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;

        const double dashWidth = 6.0;
        const double dashSpace = 4.0;
        const double totalDash = dashWidth + dashSpace;

        for (final pathMetric in path.computeMetrics()) {
          double distance = 0.0;
          while (distance < pathMetric.length) {
            final Path extractPath = pathMetric.extractPath(
              distance,
              distance + dashWidth > pathMetric.length
                  ? pathMetric.length
                  : distance + dashWidth,
            );
            canvas.drawPath(extractPath, borderPaint);
            distance += totalDash;
          }
        }

        // 2. 중심 비콘 도트 및 맥동하는 레이더 링 시각화
        final double pulse = 0.5 + 0.5 * math.sin(_timer * 6.0); // 펄스 주기 속도 조정

        // 중심 좌표 계산
        double cx = 0, cy = 0;
        for (final c in _screenCorners) {
          cx += c.dx;
          cy += c.dy;
        }
        cx /= _screenCorners.length;
        cy /= _screenCorners.length;

        // 중심 고정 비콘 점
        final dotPaint = Paint()
          ..color = beaconColor.withValues(alpha: 0.75)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(cx, cy), 2.5, dotPaint);

        // 부드럽게 방출되며 사라지는 레이저 원형 파동 링
        final ringPaint = Paint()
          ..color = beaconColor.withValues(alpha: 0.5 * (1.0 - pulse))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2;
        canvas.drawCircle(Offset(cx, cy), 4.0 + (16.0 * pulse), ringPaint);

        return;
      }

      final pulse = 0.6 + 0.4 * math.sin(_timer * 5);

      final borderGlow = Paint()
        ..color = themeColor.withValues(alpha: (100 * pulse) / 255)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);
      canvas.drawPath(path, borderGlow);

      final borderPaint = Paint()
        ..color = themeColor.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawPath(path, borderPaint);

      final fillPaint = Paint()
        ..color = themeColor.withValues(alpha: 0.05)
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, fillPaint);
    }
  }

}
