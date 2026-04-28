import 'dart:ui';
import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Color;
import '../../core/constants.dart';
import '../conquest_game.dart';

class HexTileComponent extends PositionComponent with HasGameReference<ConquestGame> {
  String owner;
  List<Offset> corners;
  bool isCapturing;
  double progress;
  String? capturingTeam;
  
  late Paint _fillPaint;
  late Paint _borderPaint;
  late Paint _capturePaint;

  HexTileComponent({
    required this.owner,
    required this.corners,
    this.isCapturing = false,
    this.progress = 0.0,
    this.capturingTeam,
  });

  /// 객체 재생성을 방지하기 위한 데이터 업데이트 메서드
  void updateData({String? owner, List<Offset>? corners, bool? isCapturing, double? progress, String? capturingTeam}) {
    if (owner != null && this.owner != owner) {
      this.owner = owner;
      _updateStyles();
    }
    if (corners != null) {
      this.corners = corners;
    }
    if (isCapturing != null) {
      this.isCapturing = isCapturing;
    }
    if (progress != null) {
      this.progress = progress;
    }
    if (capturingTeam != null) {
      this.capturingTeam = capturingTeam;
    }
  }

  @override
  void onMount() {
    super.onMount();
    _updateStyles();
  }

  void _updateStyles() {
    final baseColor = owner == GameConstants.teamBlueId 
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

  double _timer = 0;

  @override
  void update(double dt) {
    super.update(dt);
    if (isCapturing) {
      _timer += dt * 5; // 펄스 속도 조절
    }
  }

  @override
  void render(Canvas canvas) {
    if (corners.isEmpty) return;

    // 0. 프러스텀 컬링: 화면 밖의 타일은 렌더링 생략
    final gameSize = game.size;
    bool isVisible = false;
    for (var corner in corners) {
      if (corner.dx >= -100 && corner.dx <= gameSize.x + 100 &&
          corner.dy >= -100 && corner.dy <= gameSize.y + 100) {
        isVisible = true;
        break;
      }
    }
    if (!isVisible) return;

    final path = Path()..moveTo(corners[0].dx, corners[0].dy);
    for (int i = 1; i < corners.length; i++) {
      path.lineTo(corners[i].dx, corners[i].dy);
    }
    path.close();

    // 1. 기본 타일 배경 (점령 완료된 타일인 경우)
    if (owner != 'none') {
      canvas.drawPath(path, _fillPaint);
    }

    // 2. 점령 중인 경우 특수 효과
    if (isCapturing) {
      // 2-1. 외부 펄스 테두리 (sin 함수를 이용한 부드러운 깜빡임)
      final pulse = (0.5 + 0.5 * math.sin(_timer)).clamp(0.0, 1.0);
      
      final captureColor = capturingTeam == GameConstants.teamBlueId 
          ? GameConstants.colorBlue 
          : GameConstants.colorRed;

      // 실제 펄스 페인트 계산
      _capturePaint.color = captureColor.withAlpha((100 + 100 * pulse).toInt().clamp(0, 255));
      _capturePaint.strokeWidth = 2.0 + (3.0 * pulse);

      // 테두리 강조
      canvas.drawPath(path, _capturePaint);

      // 2-2. 내부 채우기 애니메이션 (아래에서 위로 progress만큼 차오름)
      canvas.save();
      canvas.clipPath(path);
      
      // 타일의 전체 높이 계산
      double minY = corners[0].dy;
      double maxY = corners[0].dy;
      for (var c in corners) {
        if (c.dy < minY) minY = c.dy;
        if (c.dy > maxY) maxY = c.dy;
      }
      final height = maxY - minY;
      final fillY = maxY - (height * progress);

      final fillRect = Rect.fromLTRB(
        corners.map((e) => e.dx).reduce((a, b) => a < b ? a : b),
        fillY,
        corners.map((e) => e.dx).reduce((a, b) => a > b ? a : b),
        maxY,
      );

      final fillPaint = Paint()
        ..color = captureColor.withAlpha(150)
        ..style = PaintingStyle.fill;
      
      canvas.drawRect(fillRect, fillPaint);
      canvas.restore();
      
      // 2-3. 중심 텍스트 (옵션)
      // TextPainter 등 사용 가능하지만 성능 위해 생략
    }
  }
}
