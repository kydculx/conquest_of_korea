import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import '../../core/constants.dart';
import '../conquest_game.dart';
import '../../services/hex_service.dart';

/// 위성 스캔 모드에서 사용자가 선택한 타일의 조준선 프리뷰를 렌더링하는 컴포넌트
class ScanTargetMarker extends PositionComponent with HasGameReference<ConquestGame> {
  final int q;
  final int r;
  
  List<Offset> _screenCorners = [];
  double _timer = 0;
  double _smoothProgress = 0.0; // 신규: 계단식 수치를 보간하여 60fps로 매끄럽게 만들기 위한 수치
  
  ScanTargetMarker({
    required this.q,
    required this.r,
  }) {
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
      final corners = HexService.getHexCorners(q, r);
      _screenCorners = corners.map((latlng) {
        final offset = game.mapController!.camera.latLngToScreenOffset(latlng);
        return Offset(offset.dx, offset.dy);
      }).toList();
    }
  }

  @override
  void render(Canvas canvas) {
    if (_screenCorners.isEmpty) return;

    final gameSize = game.size;
    final isVisible = _screenCorners.any(
      (c) =>
          c.dx >= -100 &&
          c.dx <= gameSize.x + 100 &&
          c.dy >= -100 &&
          c.dy <= gameSize.y + 100,
    );
    if (!isVisible) return;

    // 조준선 테마 색상 결정 (네온 청록색으로 통일)
    final themeColor = GameColors.accentNeon;

    // 1. 헥사곤 경로 설정
    final path = Path();
    for (int i = 0; i < _screenCorners.length; i++) {
      if (i == 0) {
        path.moveTo(_screenCorners[i].dx, _screenCorners[i].dy);
      } else {
        path.lineTo(_screenCorners[i].dx, _screenCorners[i].dy);
      }
    }
    path.close();

    if (game.isSatelliteCapturing) {
      // [요구사항] 점령하러 가는 동안 목적지 타일에 애니메이션 효과 부여
      // 내부 맥동(펄싱) 채우기 효과 (0.20 ~ 0.35 알파 불투명도로 빠르게 맥동)
      final double fillPulse = 0.20 + 0.15 * math.sin(_timer * 8.0);
      final fillPaint = Paint()
        ..color = themeColor.withValues(alpha: fillPulse)
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, fillPaint);

      // 테두리 펄싱 글로우 효과
      final double borderPulse = 0.5 + 0.4 * math.sin(_timer * 8.0);
      final borderGlow = Paint()
        ..color = themeColor.withValues(alpha: borderPulse)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
      canvas.drawPath(path, borderGlow);

      // 테두리 두꺼운 실선
      final borderPaint = Paint()
        ..color = themeColor.withValues(alpha: 0.95)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawPath(path, borderPaint);
    } else {
      final pulse = 0.6 + 0.4 * math.sin(_timer * 5); // 빠른 펄스 효과

      // 테두리 글로우 효과
      final borderGlow = Paint()
        ..color = themeColor.withValues(alpha: (100 * pulse) / 255)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);
      canvas.drawPath(path, borderGlow);

      // 테두리 실선
      final borderPaint = Paint()
        ..color = themeColor.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawPath(path, borderPaint);

      // 내부 약한 투명 채우기
      final fillPaint = Paint()
        ..color = themeColor.withValues(alpha: 0.05)
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, fillPaint);
    }

    // 2. 중심 계산
    double cx = 0, cy = 0;
    for (final c in _screenCorners) {
      cx += c.dx;
      cy += c.dy;
    }
    cx /= _screenCorners.length;
    cy /= _screenCorners.length;

    // 3. 본진에서 타겟 타일까지의 헥사곤 경로 그리기 (위성 점령 중에는 내부에서 점선은 숨기고 화살표만 그려짐)
    _drawPathLineToHQ(canvas, themeColor);

    // 4. 중심 조준 타겟 그리기 (위성 스캔 모드일 때만 노출)
    if (game.isScanMode) {
      _drawCrosshair(canvas, cx, cy, themeColor);
    }
  }

  void _drawPathLineToHQ(Canvas canvas, Color themeColor) {
    if (game.currentHQTileId == null || game.mapController == null) return;

    final parts = game.currentHQTileId!.split('_');
    if (parts.length != 3 || parts[0] != 'hex') return;
    final hqQ = int.tryParse(parts[1]);
    final hqR = int.tryParse(parts[2]);
    if (hqQ == null || hqR == null) return;

    if (hqQ == q && hqR == r) return;

    // BFS를 사용하여 본진(hqQ, hqR)에서 타겟(q, r)까지 내 점령지만 경유하는 실제 최단 경로 탐색
    final queue = <List<Map<String, int>>>[
      [
        {'q': hqQ, 'r': hqR}
      ]
    ];
    final visited = <String>{'hex_${hqQ}_$hqR'};

    const directions = [
      [1, 0],
      [1, -1],
      [0, -1],
      [-1, 0],
      [-1, 1],
      [0, 1],
    ];

    List<Map<String, int>>? shortestPath;

    while (queue.isNotEmpty) {
      final path = queue.removeAt(0);
      final current = path.last;
      final cq = current['q']!;
      final cr = current['r']!;

      if (cq == q && cr == r) {
        shortestPath = path;
        break;
      }

      for (final dir in directions) {
        final nq = cq + dir[0];
        final nr = cr + dir[1];
        final neighborId = 'hex_${nq}_$nr';

        if (visited.contains(neighborId)) continue;

        // 인웃 타일이 최종 목적지 타겟 타일인 경우
        if (nq == q && nr == r) {
          final nextPath = List<Map<String, int>>.from(path)..add({'q': nq, 'r': nr});
          queue.add(nextPath);
          visited.add(neighborId);
          continue;
        }

        // 중간 경유지는 반드시 내 점령지여야 함
        final tile = game.lastCapturedTiles[neighborId];
        final isMine = tile != null && tile.userId == game.currentUserId;

        if (isMine) {
          final nextPath = List<Map<String, int>>.from(path)..add({'q': nq, 'r': nr});
          queue.add(nextPath);
          visited.add(neighborId);
        }
      }
    }

    if (shortestPath == null || shortestPath.length < 2) return;

    final List<Offset> points = [];
    for (final tile in shortestPath) {
      final tq = tile['q']!;
      final tr = tile['r']!;
      final latlng = HexService.hexToLatLng(tq, tr);
      final offset = game.mapController!.camera.latLngToScreenOffset(latlng);
      points.add(Offset(offset.dx, offset.dy));
    }

    final path = Path();
    for (int i = 0; i < points.length; i++) {
      if (i == 0) {
        path.moveTo(points[i].dx, points[i].dy);
      } else {
        path.lineTo(points[i].dx, points[i].dy);
      }
    }

    if (!game.isSatelliteCapturing) {
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
      // 양수 값으로 증가시켜 홈(본진)에서 타겟으로 뻗어나가는 흐름으로 오프셋 방향 수정
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

    // [신규] 위성 점령 실행 중일 때 점선을 따라 이동하는 전술 화살표 드로잉
    if (game.isSatelliteCapturing && _smoothProgress > 0.0) {
      final metrics = path.computeMetrics().toList();
      if (metrics.isNotEmpty) {
        final metric = metrics.first;
        final currentDistance = metric.length * _smoothProgress;
        final tangent = metric.getTangentForOffset(currentDistance);
        if (tangent != null) {
          final pos = tangent.position;
          final vec = tangent.vector;
          final angle = math.atan2(vec.dy, vec.dx);

          canvas.save();
          canvas.translate(pos.dx, pos.dy);
          canvas.rotate(angle);

          // 네온 청록색 화살표 그리기
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
      }
    }
  }

  void _drawCrosshair(Canvas canvas, double cx, double cy, Color color) {
    final linePaint = Paint()
      ..color = color.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final circlePaint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // 펄스에 의한 줌인-줌아웃 느낌의 스케일 계산
    final double scale = 1.0 + 0.1 * math.sin(_timer * 4);
    final double r1 = 12.0 * scale;
    final double r2 = 18.0 * scale;
    final double crossLen = 6.0;

    // 조준 서클
    canvas.drawCircle(Offset(cx, cy), r1, circlePaint);
    canvas.drawCircle(Offset(cx, cy), r2, circlePaint);

    // 조준선 십자 틱스 (상, 하, 좌, 우)
    canvas.drawLine(Offset(cx, cy - r2 - crossLen), Offset(cx, cy - r1), linePaint);
    canvas.drawLine(Offset(cx, cy + r1), Offset(cx, cy + r2 + crossLen), linePaint);
    canvas.drawLine(Offset(cx - r2 - crossLen, cy), Offset(cx - r1, cy), linePaint);
    canvas.drawLine(Offset(cx + r1, cy), Offset(cx + r2 + crossLen, cy), linePaint);

    // 중앙 깜빡이는 도트
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final double dotPulse = 0.3 + 0.7 * (0.5 + 0.5 * math.sin(_timer * 8));
    canvas.drawCircle(Offset(cx, cy), 2.5, dotPaint..color = color.withValues(alpha: dotPulse));
  }
}
