import 'dart:ui';
import 'package:flame/components.dart';
import '../../core/constants.dart';
import '../conquest_game.dart';
import '../../services/hex_service.dart';

/// 메인 기지(HQ) 타일의 위치에 전술 시각 효과 및 마커를 렌더링하는 컴포넌트
class HQBaseMarker extends PositionComponent with HasGameReference<ConquestGame> {
  final int q;
  final int r;
  String? colorHex;
  
  List<Offset> _screenCorners = [];
  
  HQBaseMarker({required this.q, required this.r, this.colorHex}) {
    priority = 15; // 플레이어(20)보다는 아래, 일반 타일(0)보다는 위
  }

  void updateColor(String? newColorHex) {
    if (colorHex != newColorHex) {
      colorHex = newColorHex;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    
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

    // 중심 좌표 계산
    double cx = 0, cy = 0;
    for (final c in _screenCorners) {
      cx += c.dx;
      cy += c.dy;
    }
    cx /= _screenCorners.length;
    cy /= _screenCorners.length;

    // 중심에 홈 모양만 그리기 (테마 컬러 적용 및 2배 크기)
    _drawHQHome(canvas, cx, cy, GameColors.colorAccent);
  }

  void _drawHQHome(Canvas canvas, double cx, double cy, Color color) {
    final paint = Paint()
      ..color = GameColors.colorAccent
      ..style = PaintingStyle.fill;

    // 1. 지붕 그리기 (삼각형) - 2배 크기로 확장
    final roofPath = Path()
      ..moveTo(cx, cy - 14)
      ..lineTo(cx - 16, cy - 2)
      ..lineTo(cx + 16, cy - 2)
      ..close();
    canvas.drawPath(roofPath, paint);

    // 2. 집 몸체 그리기 (사각형) - 2배 크기로 확장
    final housePath = Path()
      ..moveTo(cx - 11, cy - 2)
      ..lineTo(cx + 11, cy - 2)
      ..lineTo(cx + 11, cy + 12)
      ..lineTo(cx - 11, cy + 12)
      ..close();
    canvas.drawPath(housePath, paint);

    // 3. 문 그리기 (어두운 색으로 채워 입체감 부여) - 2배 크기로 확장
    final doorPaint = Paint()
      ..color = GameColors.tacticalBlack
      ..style = PaintingStyle.fill;
    
    final doorPath = Path()
      ..moveTo(cx - 4, cy + 4)
      ..lineTo(cx + 4, cy + 4)
      ..lineTo(cx + 4, cy + 12)
      ..lineTo(cx - 4, cy + 12)
      ..close();
    canvas.drawPath(doorPath, doorPaint);
  }
}
