import 'package:flame/components.dart';
import 'package:flutter/material.dart';
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

    // 🚩 전술 2D 벡터 깃발 정밀 렌더링 (이모지 대비 높은 시인성과 전술 컬러 일치화 확보)
    _drawVectorHQFlag(
      canvas,
      _screenCenter!.dx,
      _screenCenter!.dy,
    );
  }

  /// 지정된 화면 중앙(cx, cy) 좌표를 기준으로 펄럭이는 캐주얼 보드게임 스타일의 2D 벡터 깃발(Flag)을 정밀 드로잉합니다.
  void _drawVectorHQFlag(Canvas canvas, double cx, double cy) {
    // 16진수 진영 색상 파싱 (실패 시 기본 네온 아군 색상)
    final Color flagColor = _parseColor(colorHex) ?? const Color(0xFF00E5FF);

    // 1) 깃발 바닥 오프셋 그림자 (Drop Shadow로 공중 입체감 부여)
    final Paint shadowPaint = Paint()
      ..color = const Color(0xFF000000).withValues(alpha: 0.28)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.8);
    canvas.drawOval(
      Rect.fromLTRB(cx - 7, cy + 11, cx + 7, cy + 14),
      shadowPaint,
    );

    // 2) 깃대 바닥 꽂임용 원형 링 받침대 (Flag Base)
    final Paint basePaint = Paint()
      ..color = const Color(0xFF78909C)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromLTRB(cx - 4.5, cy + 11.5, cx + 4.5, cy + 13.8),
      basePaint,
    );

    // 3) 단단한 은색 메탈 재질의 깃대 (Flagpole)
    final Paint flagpolePaint = Paint()
      ..color = const Color(0xFFB0BEC5)
      ..style = PaintingStyle.fill;
    final Rect flagpole = Rect.fromLTRB(cx - 1.2, cy - 16, cx + 1.2, cy + 12);
    canvas.drawRect(flagpole, flagpolePaint);

    // 4) 깃대 끝머리의 아기자기한 황금 장식 구슬 (Top Gold Ornament)
    final Paint goldPaint = Paint()
      ..color = const Color(0xFFFFD54F)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy - 17.5), 2.8, goldPaint);

    // 5) 바람에 나부끼는 둥근 물결 천 (Waving Flag Banner)
    final Paint flagPaint = Paint()
      ..color = flagColor
      ..style = PaintingStyle.fill;

    final Path flagPath = Path();
    flagPath.moveTo(cx + 1.2, cy - 14.5);
    // 윗변 물결 곡선 연출
    flagPath.quadraticBezierTo(cx + 8.5, cy - 17.8, cx + 18, cy - 13.8);
    // 우측 마감선
    flagPath.lineTo(cx + 18, cy - 3.8);
    // 아랫변 물결 곡선 연출
    flagPath.quadraticBezierTo(cx + 8.5, cy - 6.8, cx + 1.2, cy - 3.5);
    flagPath.close();

    canvas.drawPath(flagPath, flagPaint);

    // 6) 깃발 테두리 부드러운 소프트 라인 (Banner Border)
    final Paint flagBorderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawPath(flagPath, flagBorderPaint);
  }

  /// 16진수 색상 디코딩 도우미 유틸리티
  Color? _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    try {
      final buffer = StringBuffer();
      if (hex.length == 6 || hex.length == 7) buffer.write('ff');
      buffer.write(hex.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return null;
    }
  }
}

