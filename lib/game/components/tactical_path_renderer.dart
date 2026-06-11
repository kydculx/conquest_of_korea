import 'dart:collection';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import '../../models/tile_model.dart';
import '../../services/hex_service.dart';
import '../conquest_game.dart';

/// 본진에서 조준 타겟까지의 전술 경로(BFS + 점선/화살표) 렌더링을 전담하는 클래스.
/// ScanTargetMarker에서 경로 탐색 및 드로잉 로직을 분리합니다.
class TacticalPathRenderer {
  final ConquestGame game;
  final int targetQ;
  final int targetR;

  TacticalPathRenderer({
    required this.game,
    required this.targetQ,
    required this.targetR,
  });

  /// BFS 경로 산출 연산 캐시
  List<Map<String, int>>? _cachedPath;

  /// 캐시 기준이 되는 본부 기지 타일 ID
  String? _cachedHQTileId;

  /// 캐시 기준이 되는 점령 영토 맵
  Map<String, HexTile>? _cachedCapturedTiles;

  /// 본진에서 타겟 타일까지의 전술적 최단 경로를 렌더링합니다.
  void draw(
    Canvas canvas,
    Color themeColor,
    MapController mapController,
    double timer,
    double smoothProgress,
    bool isSatelliteCapturing,
  ) {
    if (game.currentHQTileId == null) return;

    final shortestPath = _findShortestPathToHQ();
    if (shortestPath == null || shortestPath.length < 2) return;

    final List<Offset> points = [];
    for (final tile in shortestPath) {
      final latlng = HexService.hexToLatLng(tile['q']!, tile['r']!);
      final offset = mapController.camera.latLngToScreenOffset(latlng);
      points.add(Offset(offset.dx, offset.dy));
    }

    // Frustum Culling
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

    // 위성 점령 대기 상태 → 전술 점선
    if (!isSatelliteCapturing) {
      _drawDashedPath(canvas, path, themeColor, timer);
    }

    // 위성 점령 실행 중 → 이동 화살표
    if (isSatelliteCapturing && smoothProgress > 0.0) {
      _drawArrowAlongPath(
        canvas,
        path,
        themeColor,
        smoothProgress,
        timer,
      );
    }
  }

  /// BFS(너비 우선 탐색)로 본진 → 조준 타일 최단 연결 경로를 산출합니다 (캐싱 적용).
  List<Map<String, int>>? _findShortestPathToHQ() {
    final hqId = game.currentHQTileId;
    if (hqId == null) {
      _cachedPath = null;
      _cachedHQTileId = null;
      _cachedCapturedTiles = null;
      return null;
    }

    final tiles = game.lastCapturedTiles;

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

    if (hqQ == targetQ && hqR == targetR) return null;

    final queue = Queue<List<Map<String, int>>>()
      ..add([{'q': hqQ, 'r': hqR}]);
    final visited = <String>{HexService.tileId(hqQ, hqR)};

    List<Map<String, int>>? resultPath;

    while (queue.isNotEmpty) {
      final path = queue.removeFirst();
      final current = path.last;
      final cq = current['q']!;
      final cr = current['r']!;

      if (cq == targetQ && cr == targetR) {
        resultPath = path;
        break;
      }

      for (final dir in HexService.hexDirections) {
        final nq = cq + dir[0];
        final nr = cr + dir[1];
        final neighborId = HexService.tileId(nq, nr);

        if (visited.contains(neighborId)) continue;

        if (nq == targetQ && nr == targetR) {
          queue.add(
            List<Map<String, int>>.from(path)..add({'q': nq, 'r': nr}),
          );
          visited.add(neighborId);
          continue;
        }

        final tile = tiles[neighborId];
        final isMine = tile != null && tile.userId == game.currentUserId;

        if (isMine) {
          queue.add(
            List<Map<String, int>>.from(path)..add({'q': nq, 'r': nr}),
          );
          visited.add(neighborId);
        }
      }
    }

    _cachedPath = resultPath;
    _cachedHQTileId = hqId;
    _cachedCapturedTiles = tiles;

    return resultPath;
  }

  /// 흐르는 전술 점선 렌더링
  void _drawDashedPath(
    Canvas canvas,
    Path path,
    Color themeColor,
    double timer,
  ) {
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
    final double startOffset = (timer * 35.0) % totalDash;

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

  /// 전술 경로를 따라 이동하는 삼각형 레이저 화살표 렌더링
  void _drawArrowAlongPath(
    Canvas canvas,
    Path path,
    Color themeColor,
    double smoothProgress,
    double timer,
  ) {
    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;

    final metric = metrics.first;
    final currentDistance = metric.length * smoothProgress;
    final tangent = metric.getTangentForOffset(currentDistance);
    if (tangent == null) return;

    final pos = tangent.position;
    final vec = tangent.vector;
    final angle = math.atan2(vec.dy, vec.dx);

    // 마지막 세그먼트 진입 시 페이드아웃
    final shortestPath = _findShortestPathToHQ();
    double fadeStartProgress = 0.8;
    if (shortestPath != null && shortestPath.length >= 2) {
      final int segmentCount = shortestPath.length - 1;
      fadeStartProgress = (segmentCount - 1) / segmentCount;
    }

    double opacity = 1.0;
    if (smoothProgress > fadeStartProgress) {
      final double range = 1.0 - fadeStartProgress;
      opacity = range > 0.0
          ? ((1.0 - smoothProgress) / range).clamp(0.0, 1.0)
          : 0.0;
    }
    if (opacity <= 0.0) return;

    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(angle);

    final arrowPaint = Paint()
      ..color = themeColor.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;

    final arrowGlow = Paint()
      ..color = themeColor.withValues(alpha: 0.5 * opacity)
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
}
