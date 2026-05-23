import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'package:latlong2/latlong.dart' hide Path;
import '../../core/constants/colors.dart';
import '../conquest_game.dart';
import '../../services/hex_service.dart';
import '../../models/tile_model.dart';

/// 위성 스캔 모드에서 사용자가 선택한 타일의 조준선 프리뷰를 렌더링하는 컴포넌트
/// 위성 궤도 정밀 조준 스캔 및 위성 원격 점령 모드에서 조준선, 본부로부터의 전술적 BFS 최단 경로 안내선, 점령 완료 시 보간 화살표 이동 애니메이션을 그리는 Flame 컴포넌트
class ScanTargetMarker extends PositionComponent with HasGameReference<ConquestGame> {
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
  
  /// ScanTargetMarker 생성자로 조준 대상 좌표를 설정받고 렌더링 우선순위(Priority)를 조율합니다.
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
    
    // 위성 점령 중일 때 progress 보간 (전체 점령 시간 중 '이동시간(타일당 1초)' 비율을 비행 구간으로 동적 배정)
    if (game.isSatelliteCapturing && game.satelliteCapturingTileId != null) {
      final hqId = game.currentHQTileId;
      final targetId = game.satelliteCapturingTileId;
      
      double travelRatio = 0.8; // 기본 폴백값
      if (hqId != null && targetId != null) {
        try {
          final partsBase = hqId.split('_');
          final bq = int.tryParse(partsBase[1]) ?? 0;
          final br = int.tryParse(partsBase[2]) ?? 0;
          final partsTarget = targetId.split('_');
          final tq = int.tryParse(partsTarget[1]) ?? 0;
          final tr = int.tryParse(partsTarget[2]) ?? 0;
          final dist = HexService.hexDistance(bq, br, tq, tr);
          final travelSeconds = dist.toDouble();
          const captureSeconds = 1.0;
          final total = travelSeconds + captureSeconds;
          if (total > 0.0) {
            travelRatio = travelSeconds / total;
          }
        } catch (_) {}
      }

      final target = (game.satelliteCaptureProgress / travelRatio).clamp(0.0, 1.0);
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

    // 4. 중심 조준 타겟 그리기 (위성 스캔 모드이고, 위성 점령 송신 중이 아니며, 화면에 보일 때만 노출)
    if (game.isScanMode && !game.isSatelliteCapturing && isTargetVisible) {
      _drawCrosshair(canvas, cx, cy, themeColor);
    }
  }

  /// 목적지 헥사곤 타일 내부 맥동 및 글로우 테두리 렌더링
  void _drawDestinationBorder(Canvas canvas, Path path, Color themeColor) {
    // 본진과 목적지의 거리를 기반으로 이동 비율 산출
    double travelRatio = 0.8;
    final hqId = game.currentHQTileId;
    final targetId = game.isSatelliteCapturing ? game.satelliteCapturingTileId : 'hex_${q}_$r';
    
    if (hqId != null && targetId != null) {
      try {
        final partsBase = hqId.split('_');
        final bq = int.tryParse(partsBase[1]) ?? 0;
        final br = int.tryParse(partsBase[2]) ?? 0;
        final partsTarget = targetId.split('_');
        final tq = int.tryParse(partsTarget[1]) ?? 0;
        final tr = int.tryParse(partsTarget[2]) ?? 0;
        final dist = HexService.hexDistance(bq, br, tq, tr);
        final travelSeconds = dist.toDouble();
        const captureSeconds = 1.0;
        final total = travelSeconds + captureSeconds;
        if (total > 0.0) {
          travelRatio = travelSeconds / total;
        }
      } catch (_) {}
    }

    final bool isActuallyCapturingTile = game.isSatelliteCapturing && game.satelliteCaptureProgress >= travelRatio;

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
        final Color beaconColor = const Color(0xFFFF9900); // 위성 점마 주황색

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
              distance + dashWidth > pathMetric.length ? pathMetric.length : distance + dashWidth,
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

  /// BFS 경로 산출 연산을 최소화하기 위해 마지막으로 정상 계산된 전술 경로를 보관하는 캐시 리스트
  List<Map<String, int>>? _cachedPath;
  /// 캐시 경로가 산출된 기준이 되는 본부 기지 타일 ID 캐시
  String? _cachedHQTileId;
  /// 캐시 경로 산출에 기여한 요원의 점령 영토 목록 맵 캐시
  Map<String, HexTile>? _cachedCapturedTiles;

  /// BFS(너비 우선 탐색) 알고리즘을 수행하여 요원의 본진(HQ) 위치에서 조준 대상 타일까지의 최단 연결 점령 경로를 산출합니다.
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

  /// 본진에서 조준 타겟까지 계산된 최단 궤적을 연결하여 흐르는 형태의 전술 점선으로 드로잉합니다.
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

  /// 위성 점령이 활성화되어 송신 중일 때, 전술 경로를 따라 이동하며 위치와 진행 각도로 정렬되는 삼각형 레이저 화살표를 드로잉합니다.
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

    // [개선] 화살표가 마지막 목적지 타일에 진입하는 시점부터 자연스럽게 페이드아웃되도록 임계값 동적 산출
    final shortestPath = _findShortestPathToHQ();
    double fadeStartProgress = 0.8; // 폴백값
    if (shortestPath != null && shortestPath.length >= 2) {
      final int segmentCount = shortestPath.length - 1;
      fadeStartProgress = (segmentCount - 1) / segmentCount;
    }

    double opacity = 1.0;
    if (_smoothProgress > fadeStartProgress) {
      final double range = 1.0 - fadeStartProgress;
      opacity = range > 0.0
          ? ((1.0 - _smoothProgress) / range).clamp(0.0, 1.0)
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

  /// 스캔 모드 상의 선택 타일의 정중앙 좌표에 회전 십자 헤어라인과 펄싱 타겟 락온 도트 이미지를 드로잉합니다.
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
