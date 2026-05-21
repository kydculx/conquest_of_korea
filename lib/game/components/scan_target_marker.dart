import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'package:latlong2/latlong.dart' hide Path;
import '../../core/constants.dart';
import '../conquest_game.dart';
import '../../services/hex_service.dart';
import '../../models/tile_model.dart';

/// 위성 스캔 모드에서 사용자가 선택한 타일의 조준선 프리뷰를 렌더링하는 컴포넌트
class ScanTargetMarker extends PositionComponent with HasGameReference<ConquestGame> {
  final int q;
  final int r;
  
  final List<LatLng> _latLngCorners;
  List<Offset> _screenCorners = [];
  double _timer = 0;
  double _smoothProgress = 0.0; // 신규: 계단식 수치를 보간하여 60fps로 매끄럽게 만들기 위한 수치
  
  ScanTargetMarker({
    required this.q,
    required this.r,
  }) : _latLngCorners = HexService.getHexCorners(q, r) {
    priority = 18; // 플레이어(20)보다는 아래, 일반 타일(0)이나 메인기지(15)보다는 위
  }

  @override
  void update(double dt) {
    super.update(dt);
    _timer += dt;
    
    // 위성 점령 중일 때 progress 보간
    if (game.isSatelliteCapturing) {
      final target = game.satelliteCaptureProgress;
      // 매 프레임 dt 비중에 맞춰 목표치로 부드럽게 Lerp
      _smoothProgress += (target - _smoothProgress) * (dt * 10.0).clamp(0.0, 1.0);
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

    // 1. 헥사곤 경로 및 중심 계산
    final path = Path();
    double cx = 0, cy = 0;
    for (int i = 0; i < _screenCorners.length; i++) {
      cx += _screenCorners[i].dx;
      cy += _screenCorners[i].dy;
      if (i == 0) {
        path.moveTo(_screenCorners[i].dx, _screenCorners[i].dy);
      } else {
        path.lineTo(_screenCorners[i].dx, _screenCorners[i].dy);
      }
    }
    path.close();
    cx /= _screenCorners.length;
    cy /= _screenCorners.length;

    // 2. 목적지 타일 애니메이션 그리기 (화면에 보일 때만 드로잉)
    if (isTargetVisible) {
      _drawDestinationBorder(canvas, path, themeColor);
    }

    // 3. 본진에서 타겟 타일까지의 전술 경로(점선/화살표) 그리기 (자체적인 경로 가시성 판정 적용)
    _drawTacticalPath(canvas, themeColor);

    // 4. 중심 조준 타겟 그리기 (위성 스캔 모드이고, 화면에 보일 때만 노출)
    if (game.isScanMode && isTargetVisible) {
      _drawCrosshair(canvas, cx, cy, themeColor);
    }
  }

  /// 목적지 헥사곤 타일 내부 맥동 및 글로우 테두리 렌더링
  void _drawDestinationBorder(Canvas canvas, Path path, Color themeColor) {
    if (game.isSatelliteCapturing) {
      // [요구사항] 점령하러 가는 동안 목적지 타일에 애니메이션 효과 부여
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

  /// 본진에서 타겟 타일까지의 전술적 최단 경로(점선 또는 화살표) 렌더링 총괄
  void _drawTacticalPath(Canvas canvas, Color themeColor) {
    if (game.currentHQTileId == null || game.mapController == null) return;

    final shortestPath = _findShortestPathToHQ();
    if (shortestPath == null || shortestPath.length < 2) return;

    final List<Offset> points = [];
    for (final tile in shortestPath) {
      final latlng = HexService.hexToLatLng(tile['q']!, tile['r']!);
      final offset = game.mapController!.camera.latLngToScreenOffset(latlng);
      points.add(Offset(offset.dx, offset.dy));
    }

    // [개선] 경로 좌표 중 단 하나라도 화면 내에 표시되고 있는지 판정 (Frustum Culling)
    final gameSize = game.size;
    final isPathVisible = points.any(
      (p) =>
          p.dx >= -100 &&
          p.dx <= gameSize.x + 100 &&
          p.dy >= -100 &&
          p.dy <= gameSize.y + 100,
    );
    if (!isPathVisible) return;

    final path = Path();
    for (int i = 0; i < points.length; i++) {
      if (i == 0) {
        path.moveTo(points[i].dx, points[i].dy);
      } else {
        path.lineTo(points[i].dx, points[i].dy);
      }
    }

    // 1. 위성 점령 대기 상태에서는 뻗어 나가는 전술 점선 렌더링
    if (!game.isSatelliteCapturing) {
      _drawDashedPath(canvas, path, themeColor);
    }

    // 2. 위성 점령 실행 중일 때 점선을 따라 이동하는 전술 화살표 렌더링
    if (game.isSatelliteCapturing && _smoothProgress > 0.0) {
      _drawArrowAlongPath(canvas, path, themeColor);
    }
  }

  List<Map<String, int>>? _cachedPath;
  String? _cachedHQTileId;
  Map<String, HexTile>? _cachedCapturedTiles;

  /// BFS 알고리즘을 사용한 본진(HQ)에서 현재 타겟 타일까지의 최단 경로 계산
  List<Map<String, int>>? _findShortestPathToHQ() {
    final hqId = game.currentHQTileId;
    if (hqId == null) {
      _cachedPath = null;
      _cachedHQTileId = null;
      _cachedCapturedTiles = null;
      return null;
    }

    final tiles = game.lastCapturedTiles;

    // 캐시된 경로가 유효한 경우 기존 결과를 즉시 반환
    if (_cachedPath != null &&
        _cachedHQTileId == hqId &&
        identical(_cachedCapturedTiles, tiles)) {
      return _cachedPath;
    }

    final parts = hqId.split('_');
    if (parts.length != 3 || parts[0] != 'hex') return null;
    final hqQ = int.tryParse(parts[1]);
    final hqR = int.tryParse(parts[2]);
    if (hqQ == null || hqR == null) return null;

    if (hqQ == q && hqR == r) return null;

    final queue = <List<Map<String, int>>>[
      [
        {'q': hqQ, 'r': hqR}
      ]
    ];
    final visited = <String>{'hex_${hqQ}_$hqR'};

    const directions = [
      [1, 0], [1, -1], [0, -1], [-1, 0], [-1, 1], [0, 1]
    ];

    List<Map<String, int>>? resultPath;

    while (queue.isNotEmpty) {
      final path = queue.removeAt(0);
      final current = path.last;
      final cq = current['q']!;
      final cr = current['r']!;

      if (cq == q && cr == r) {
        resultPath = path;
        break;
      }

      for (final dir in directions) {
        final nq = cq + dir[0];
        final nr = cr + dir[1];
        final neighborId = 'hex_${nq}_$nr';

        if (visited.contains(neighborId)) continue;

        if (nq == q && nr == r) {
          queue.add(List<Map<String, int>>.from(path)..add({'q': nq, 'r': nr}));
          visited.add(neighborId);
          continue;
        }

        final tile = tiles[neighborId];
        final isMine = tile != null && tile.userId == game.currentUserId;

        if (isMine) {
          queue.add(List<Map<String, int>>.from(path)..add({'q': nq, 'r': nr}));
          visited.add(neighborId);
        }
      }
    }

    _cachedPath = resultPath;
    _cachedHQTileId = hqId;
    _cachedCapturedTiles = tiles;

    return resultPath;
  }

  /// 경로를 따르는 애니메이션 전술 점선 드로잉
  void _drawDashedPath(Canvas canvas, Path path, Color themeColor) {
    final linePaint = Paint()
      ..color = themeColor.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final glowPaint = Paint()
      ..color = themeColor.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);

    const double dashWidth = 8.0;
    const double dashSpace = 6.0;
    const double totalDash = dashWidth + dashSpace;
    final double startOffset = (_timer * 35.0) % totalDash;

    for (final paint in [glowPaint, linePaint]) {
      for (final pathMetric in path.computeMetrics()) {
        double distance = startOffset;
        while (distance < pathMetric.length) {
          final double start = distance < 0.0 ? 0.0 : distance;
          final double end = distance + dashWidth;
          if (end > 0.0) {
            final Path extractPath = pathMetric.extractPath(
              start,
              end > pathMetric.length ? pathMetric.length : end,
            );
            canvas.drawPath(extractPath, paint);
          }
          distance += totalDash;
        }
      }
    }
  }

  /// 경로상 진행률에 따라 회전각을 맞춰 이동하는 삼각형 화살표 드로잉
  void _drawArrowAlongPath(Canvas canvas, Path path, Color themeColor) {
    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;

    final metric = metrics.first;
    final currentDistance = metric.length * _smoothProgress;
    final tangent = metric.getTangentForOffset(currentDistance);
    if (tangent == null) return;

    final pos = tangent.position;
    final vec = tangent.vector;
    final angle = math.atan2(vec.dy, vec.dx);

    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(angle);

    final arrowPaint = Paint()
      ..color = themeColor
      ..style = PaintingStyle.fill;

    final arrowGlow = Paint()
      ..color = themeColor.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

    final arrowPath = Path()
      ..moveTo(8.0, 0.0)
      ..lineTo(-8.0, -6.0)
      ..lineTo(-4.0, 0.0)
      ..lineTo(-8.0, 6.0)
      ..close();

    canvas.drawPath(arrowPath, arrowGlow);
    canvas.drawPath(arrowPath, arrowPaint);
    canvas.restore();
  }

  /// 조준선 십자 타겟 드로잉
  void _drawCrosshair(Canvas canvas, double cx, double cy, Color color) {
    final linePaint = Paint()
      ..color = color.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final circlePaint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final double scale = 1.0 + 0.1 * math.sin(_timer * 4);
    final double r1 = 12.0 * scale;
    final double r2 = 18.0 * scale;
    final double crossLen = 6.0;

    canvas.drawCircle(Offset(cx, cy), r1, circlePaint);
    canvas.drawCircle(Offset(cx, cy), r2, circlePaint);

    canvas.drawLine(Offset(cx, cy - r2 - crossLen), Offset(cx, cy - r1), linePaint);
    canvas.drawLine(Offset(cx, cy + r1), Offset(cx, cy + r2 + crossLen), linePaint);
    canvas.drawLine(Offset(cx - r2 - crossLen, cy), Offset(cx - r1, cy), linePaint);
    canvas.drawLine(Offset(cx + r1, cy), Offset(cx + r2 + crossLen, cy), linePaint);

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final double dotPulse = 0.3 + 0.7 * (0.5 + 0.5 * math.sin(_timer * 8));
    canvas.drawCircle(Offset(cx, cy), 2.5, dotPaint..color = color.withValues(alpha: dotPulse));
  }
}
