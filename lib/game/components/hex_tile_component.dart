import 'dart:ui';
import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Color;
import '../../core/constants.dart';
import '../../models/tile_model.dart';
import '../conquest_game.dart';

/// 헥사곤 점령 타일 렌더링 컴포넌트 (성능 최적화 버전)
class HexTileComponent extends PositionComponent with HasGameReference<ConquestGame> {
  TileOwner owner;
  List<Offset> corners;
  bool isCapturing;
  double progress;
  TileOwner? capturingTeam;

  late Paint _fillPaint;
  late Paint _capturePaint;
  Path? _cachedPath;
  double _timer = 0;

  HexTileComponent({
    required this.owner,
    required this.corners,
    this.isCapturing = false,
    this.progress = 0.0,
    this.capturingTeam,
  });

  void updateData({
    TileOwner? owner,
    List<Offset>? corners,
    bool? isCapturing,
    double? progress,
    TileOwner? capturingTeam,
  }) {
    if (owner != null && this.owner != owner) {
      this.owner = owner;
      if (isMounted) _updateStyles();
    }
    if (corners != null) {
      this.corners = corners;
      _cachedPath = null; // 좌표 변경 시 패시 캐시 무효화
    }
    if (isCapturing != null) this.isCapturing = isCapturing;
    if (progress != null) this.progress = progress;
    if (capturingTeam != null) this.capturingTeam = capturingTeam;
  }

  @override
  void onMount() {
    super.onMount();
    _updateStyles();
  }

  void _updateStyles() {
    final baseColor = owner == TileOwner.blue
        ? GameConstants.colorBlue
        : GameConstants.colorRed;

    _fillPaint = Paint()
      ..color = baseColor.withAlpha(80)
      ..style = PaintingStyle.fill;

    _capturePaint = Paint()
      ..color = GameConstants.accentNeon.withAlpha(150)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isCapturing) _timer += dt * 5;
  }

  @override
  void render(Canvas canvas) {
    if (corners.isEmpty) return;

    // 1. 프러스텀 컬링
    final gameSize = game.size;
    final isVisible = corners.any((c) =>
        c.dx >= -50 && c.dx <= gameSize.x + 50 &&
        c.dy >= -50 && c.dy <= gameSize.y + 50);
    if (!isVisible) return;

    // 2. Path 캐싱 로직
    if (_cachedPath == null) {
      _cachedPath = Path()..moveTo(corners[0].dx, corners[0].dy);
      for (int i = 1; i < corners.length; i++) {
        _cachedPath!.lineTo(corners[i].dx, corners[i].dy);
      }
      _cachedPath!.close();
    }

    // 3. 점령된 타일 채우기
    if (owner != TileOwner.none) {
      canvas.drawPath(_cachedPath!, _fillPaint);
    }

    // 4. 점령 애니메이션 최적화
    if (isCapturing) {
      final pulse = (0.5 + 0.5 * math.sin(_timer)).clamp(0.0, 1.0);
      final captureColor = capturingTeam == TileOwner.blue
          ? GameConstants.colorBlue
          : GameConstants.colorRed;

      // 외곽선 펄스 효과
      _capturePaint.color = captureColor.withAlpha((100 + 100 * pulse).toInt());
      _capturePaint.strokeWidth = 1.5 + (2.5 * pulse);
      canvas.drawPath(_cachedPath!, _capturePaint);

      // 채우기 애니메이션 (clipPath는 무거우므로 필요할 때만 사용하거나 단순 Rect로 대체 가능하지만, 
      // 헥사곤 모양 유지를 위해 clipPath를 쓰되 최소화함)
      canvas.save();
      canvas.clipPath(_cachedPath!);
      
      double minY = corners[0].dy, maxY = corners[0].dy;
      for (final c in corners) {
        if (c.dy < minY) minY = c.dy;
        if (c.dy > maxY) maxY = c.dy;
      }
      final height = maxY - minY;
      
      final fillRect = Rect.fromLTRB(
        corners.map((e) => e.dx).reduce((a, b) => a < b ? a : b),
        maxY - (height * progress),
        corners.map((e) => e.dx).reduce((a, b) => a > b ? a : b),
        maxY,
      );
      
      canvas.drawRect(
        fillRect,
        Paint()
          ..color = captureColor.withAlpha(130)
          ..style = PaintingStyle.fill,
      );
      canvas.restore();
    }
  }
}
