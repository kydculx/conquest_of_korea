import 'dart:ui';
import 'package:flame/components.dart';
import '../../core/constants/colors.dart';
import '../conquest_game.dart';
import '../../services/hex_service.dart';

/// 요원의 본부 기지(HQ) 지리적 좌표 상에 홈(Home) 모양 아이콘 마커를 렌더링하여 전술 본부를 시각화하는 Flame 컴포넌트
class HQBaseMarker extends PositionComponent with HasGameReference<ConquestGame> {
  /// 본부 기지 타일의 H3 q축 좌표값
  final int q;
  /// 본부 기지 타일의 H3 r축 좌표값
  final int r;
  /// 본부 기지 요원의 식별 색상 코드 (Hex)
  String? colorHex;
  
  /// 스크린 기준으로 변환 투영된 헥사곤 거점의 꼭짓점 픽셀 좌표 리스트
  List<Offset> _screenCorners = [];
  
  /// HQBaseMarker 생성자로 H3 좌표 및 진영 색상을 설정받고 렌더링 레이어 우선순위(Priority)를 조율합니다.
  HQBaseMarker({required this.q, required this.r, this.colorHex}) {
    priority = 15; // 플레이어(20)보다는 아래, 일반 타일(0)보다는 위
  }

  /// 본부 기지 요원의 전술 식별 색상 정보를 외부에서 갱신합니다.
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

  /// 지정된 화면 중앙(cx, cy) 좌표를 기준으로 전술 본부의 집 형태 비트맵 외곽선을 직접 연출하여 드로잉합니다.
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
