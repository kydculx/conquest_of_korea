import 'dart:ui' as ui;
import 'dart:ui';
import 'package:flame/components.dart';
import '../../core/constants/colors.dart';
import '../conquest_game.dart';
import '../../services/hex_service.dart';

/// 요원의 본부 기지(HQ) 지리적 좌표 상에 홈(Home) 모양 아이콘 마커를 렌더링하여 전술 본부를 시각화하는 Flame 컴포넌트
class HQBaseMarker extends PositionComponent
    with HasGameReference<ConquestGame> {
  /// 본부 기지 타일의 H3 q축 좌표값
  final int q;

  /// 본부 기지 타일의 H3 r축 좌표값
  final int r;

  /// 본부 기지 요원의 식별 색상 코드 (Hex)
  String? colorHex;

  /// 스크린 기준으로 투영된 본진 중심 좌표
  Offset? _screenCenter;

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
      final centerLatLng = HexService.hexToLatLng(q, r);
      final offset = game.mapController!.camera.latLngToScreenOffset(
        centerLatLng,
      );
      _screenCenter = Offset(offset.dx, offset.dy);
    }
  }

  @override
  void render(Canvas canvas) {
    if (_screenCenter == null) return;

    final gameSize = game.size;
    final isVisible =
        _screenCenter!.dx >= -100 &&
        _screenCenter!.dx <= gameSize.x + 100 &&
        _screenCenter!.dy >= -100 &&
        _screenCenter!.dy <= gameSize.y + 100;
    if (!isVisible) return;

    // 중심에 홈 모양만 그리기 (테마 컬러 적용 및 2배 크기)
    _drawHQHome(
      canvas,
      _screenCenter!.dx,
      _screenCenter!.dy,
      GameColors.colorAccent,
    );
  }

  /// 지정된 화면 중앙(cx, cy) 좌표를 기준으로 현대적인 군사 지휘부 본관 건물(HQ Building Complex)을 캔버스 벡터로 직접 드로잉합니다.
  void _drawHQHome(Canvas canvas, double cx, double cy, Color color) {
    // 1. 하부 기초 기단 패드 (Base Foundation Pad)
    final foundationPaint = Paint()
      ..color = GameColors.dividerColor.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;
    final foundationPath = Path()
      ..moveTo(cx - 20, cy + 14)
      ..lineTo(cx - 16, cy + 11)
      ..lineTo(cx + 16, cy + 11)
      ..lineTo(cx + 20, cy + 14)
      ..close();
    canvas.drawPath(foundationPath, foundationPaint);

    // 2. 후방 부속 타워 건물 (Back Annex Block - 좌측 배후에 입체감 부여)
    final annexPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(cx - 12, cy - 14),
        Offset(cx - 12, cy + 11),
        [
          GameColors.colorAccent.withValues(alpha: 0.7),
          GameColors.backgroundMedium,
        ],
      )
      ..style = PaintingStyle.fill;
    final annexBorder = Paint()
      ..color = GameColors.dividerColor.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final annexPath = Path()
      ..moveTo(cx - 14, cy - 14)
      ..lineTo(cx - 6, cy - 14)
      ..lineTo(cx - 6, cy + 11)
      ..lineTo(cx - 14, cy + 11)
      ..close();
    canvas.drawPath(annexPath, annexPaint);
    canvas.drawPath(annexPath, annexBorder);

    // 후방 부속 타워 미세 안테나 핀
    canvas.drawLine(
      Offset(cx - 10, cy - 14),
      Offset(cx - 10, cy - 20),
      Paint()
        ..color = GameColors.tacticalWhite
        ..strokeWidth = 1.0,
    );

    // 3. 전방 주 지휘관 본관 건물 (Main Command Center Block)
    final mainBuildingPaint = Paint()
      ..shader = ui.Gradient.linear(Offset(cx, cy - 8), Offset(cx, cy + 11), [
        GameColors.backgroundMedium,
        GameColors.tacticalBlack,
      ])
      ..style = PaintingStyle.fill;

    final mainBuildingBorder = Paint()
      ..color = GameColors.colorAccent.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // 모던한 복합 사다리꼴 형태의 본부 건물 실루엣
    final mainBuildingPath = Path()
      ..moveTo(cx - 10, cy - 8) // 옥상 좌측
      ..lineTo(cx + 14, cy - 8) // 옥상 우측
      ..lineTo(cx + 16, cy + 11) // 하단 우측
      ..lineTo(cx - 12, cy + 11) // 하단 좌측
      ..close();
    canvas.drawPath(mainBuildingPath, mainBuildingPaint);
    canvas.drawPath(mainBuildingPath, mainBuildingBorder);

    // 4. 건물 유리 Facade 관제 격자 창문들 (Luminous Grid Windows)
    final windowPaint = Paint()
      ..color = GameColors.accentNeon.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    const double winW = 3.0;
    const double winH = 2.0;

    // 1층 창문들 (3개 정렬)
    canvas.drawRect(Rect.fromLTWH(cx - 6, cy + 3, winW, winH), windowPaint);
    canvas.drawRect(Rect.fromLTWH(cx, cy + 3, winW, winH), windowPaint);
    canvas.drawRect(Rect.fromLTWH(cx + 6, cy + 3, winW, winH), windowPaint);

    // 2층 창문들 (3개 정렬)
    canvas.drawRect(Rect.fromLTWH(cx - 6, cy - 3, winW, winH), windowPaint);
    canvas.drawRect(Rect.fromLTWH(cx, cy - 3, winW, winH), windowPaint);
    canvas.drawRect(Rect.fromLTWH(cx + 6, cy - 3, winW, winH), windowPaint);

    // 5. 건물 옥상 헬리패드 데크 레이어 (Roof Deck Helipad)
    final helipadPaint = Paint()
      ..color = GameColors.colorAccent.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    final helipadPath = Path()
      ..moveTo(cx - 8, cy - 8)
      ..lineTo(cx + 12, cy - 8)
      ..lineTo(cx + 10, cy - 10)
      ..lineTo(cx - 6, cy - 10)
      ..close();
    canvas.drawPath(helipadPath, helipadPaint);
    canvas.drawPath(
      helipadPath,
      Paint()
        ..color = GameColors.colorAccent.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );

    // 옥상 헬리패드 중앙의 초소형 'H' 식별 데칼 드로잉
    final hPaint = Paint()
      ..color = GameColors.colorAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    final double hx = cx + 2;
    final double hy = cy - 9;
    canvas.drawLine(Offset(hx - 2, hy - 1.5), Offset(hx - 2, hy + 1.5), hPaint);
    canvas.drawLine(Offset(hx + 2, hy - 1.5), Offset(hx + 2, hy + 1.5), hPaint);
    canvas.drawLine(Offset(hx - 2, hy), Offset(hx + 2, hy), hPaint);

    // 6. 건물 1층 대형 보안 게이트 입구 (Fortress Command Gate)
    final gatePaint = Paint()
      ..color = GameColors.tacticalBlack
      ..style = PaintingStyle.fill;
    final gateBorder = Paint()
      ..color = GameColors.colorAccent.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final gatePath = Path()
      ..moveTo(cx - 3, cy + 11)
      ..lineTo(cx - 3, cy + 7)
      ..lineTo(cx + 3, cy + 7)
      ..lineTo(cx + 3, cy + 11)
      ..close();
    canvas.drawPath(gatePath, gatePaint);
    canvas.drawPath(gatePath, gateBorder);
  }
}
