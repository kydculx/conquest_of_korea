import 'dart:ui';
import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Color;
import '../../core/constants.dart';
import '../../models/tile_model.dart';
import '../conquest_game.dart';

/// 헥사곤 점령 타일 렌더링 컴포넌트
class HexTileComponent extends PositionComponent
    with HasGameReference<ConquestGame> {
  TileOwner owner;
  List<Offset> corners;
  bool isCapturing;
  double progress;
  TileOwner? capturingTeam;

  late Paint _fillPaint;
  late Paint _borderPaint;
  late Paint _capturePaint;
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
    if (corners != null) this.corners = corners;
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

    _borderPaint = Paint()
      ..color = baseColor.withAlpha(180)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    _capturePaint = Paint()
      ..color = GameConstants.accentNeon.withAlpha(150)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isCapturing) _timer += dt * 5;
  }

  @override
  void render(Canvas canvas) {
    if (corners.isEmpty) return;

    // 화면 밖 타일 컬링
    final gameSize = game.size;
    final isVisible = corners.any((c) =>
        c.dx >= -100 &&
        c.dx <= gameSize.x + 100 &&
        c.dy >= -100 &&
        c.dy <= gameSize.y + 100);
    if (!isVisible) return;

    final path = Path()..moveTo(corners[0].dx, corners[0].dy);
    for (int i = 1; i < corners.length; i++) {
      path.lineTo(corners[i].dx, corners[i].dy);
    }
    path.close();

    if (owner != TileOwner.none) {
      canvas.drawPath(path, _fillPaint);
      canvas.drawPath(path, _borderPaint);
    }

    if (isCapturing) {
      final pulse = (0.5 + 0.5 * math.sin(_timer)).clamp(0.0, 1.0);
      final captureColor = capturingTeam == TileOwner.blue
          ? GameConstants.colorBlue
          : GameConstants.colorRed;

      _capturePaint.color =
          captureColor.withAlpha((100 + 100 * pulse).toInt().clamp(0, 255));
      _capturePaint.strokeWidth = 2.0 + (3.0 * pulse);
      canvas.drawPath(path, _capturePaint);

      // 아래에서 위로 차오르는 채우기 애니메이션
      canvas.save();
      canvas.clipPath(path);
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
          ..color = captureColor.withAlpha(150)
          ..style = PaintingStyle.fill,
      );
      canvas.restore();
    }
  }
}
