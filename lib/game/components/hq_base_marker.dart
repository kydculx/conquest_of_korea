import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../conquest_game.dart';
import '../../core/constants/colors.dart';

/// 플레이어의 본부 기지(HQ) 지리적 좌표 상에 홈(Home) 모양 아이콘 마커를 렌더링하여 본부를 시각화하는 Flame 컴포넌트
class HQBaseMarker extends PositionComponent
    with HasGameReference<ConquestGame> {
  /// 본부 기지 타일의 H3 q축 좌표값
  final int q;

  /// 본부 기지 타일의 H3 r축 좌표값
  final int r;

  /// 본부 기지 플레이어의 식별 색상 코드 (Hex)
  String? colorHex;

  /// 깃발 펄럭임 애니메이션을 위한 누적 시간
  double _waveTime = 0.0;

  /// HQBaseMarker 생성자로 H3 좌표 및 진영 색상을 설정받고 렌더링 레이어 우선순위(Priority)를 조율합니다.
  HQBaseMarker({required this.q, required this.r, this.colorHex}) {
    priority = 15; // 플레이어(20)보다는 아래, 일반 타일(0)보다는 위
  }

  /// 본부 기지 플레이어의 테마 식별 색상 정보를 외부에서 갱신합니다.
  void updateColor(String? newColorHex) {
    if (colorHex != newColorHex) {
      colorHex = newColorHex;
    }
  }

  /// 맵 스크롤/카메라 이동 시 ConquestGame에서 직접 스크린 좌표를 position에 주입하여
  /// 게임 루프 update()를 기다리지 않고 즉시 위치를 갱신합니다 (밀림 현상 방지).
  void updateScreenPosition(Offset screenCenter) {
    position = Vector2(screenCenter.dx, screenCenter.dy);
  }

  @override
  void update(double dt) {
    super.update(dt);

    // 펄럭임 애니메이션 시간 누적 (주기성 오버플로우 방지 처리)
    _waveTime += dt * 8.0;
    if (_waveTime > math.pi * 2) {
      _waveTime -= math.pi * 2;
    }
  }

  @override
  void render(Canvas canvas) {
    final gameSize = game.size;
    final isVisible =
        position.x >= -100 &&
        position.x <= gameSize.x + 100 &&
        position.y >= -100 &&
        position.y <= gameSize.y + 100;
    if (!isVisible) return;

    // 🚩 2D 벡터 깃발 정밀 렌더링 (이모지 대비 높은 시인성과 테마 컬러 일치화 확보)
    _drawVectorHQFlag(canvas);
  }

  /// 로컬 좌표 (0,0) 기준으로 펄럭이는 캐주얼 보드게임 스타일의 2D 벡터 깃발(Flag)을 정밀 드로잉합니다.
  void _drawVectorHQFlag(Canvas canvas) {
    // 16진수 진영 색상 파싱 (실패 시 기본 네온 아군 색상)
    final Color flagColor = _parseColor(colorHex) ?? Palette.accentCyan;

    // 1) 깃발 바닥 오프셋 그림자 (Drop Shadow로 공중 입체감 부여)
    final Paint shadowPaint = Paint()
      ..color = Palette.black.withValues(alpha: 0.28)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.8);
    canvas.drawOval(
      const Rect.fromLTRB(-7, 11, 7, 14),
      shadowPaint,
    );

    // 2) 깃대 바닥 꽂임용 원형 링 받침대 (Flag Base)
    final Paint basePaint = Paint()
      ..color = Palette.greyBlueMid
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      const Rect.fromLTRB(-4.5, 11.5, 4.5, 13.8),
      basePaint,
    );

    // 3) 단단한 은색 메탈 재질의 깃대 (Flagpole)
    final Paint flagpolePaint = Paint()
      ..color = Palette.greyBlue
      ..style = PaintingStyle.fill;
    const Rect flagpole = Rect.fromLTRB(-1.2, -16, 1.2, 12);
    canvas.drawRect(flagpole, flagpolePaint);

    // 4) 깃대 끝머리의 아기자기한 황금 장식 구슬 (Top Gold Ornament)
    final Paint goldPaint = Paint()
      ..color = Palette.amberHighlight
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(0, -17.5), 2.8, goldPaint);

    // 5) 바람에 나부끼는 둥근 물결 천 (Waving Flag Banner)
    final Paint flagPaint = Paint()
      ..color = flagColor
      ..style = PaintingStyle.fill;

    // 펄럭임 효과를 위해 삼각함수 위상차(sin, cos) 기반의 미세 Y변형 파동 오프셋 계산 (깃대는 단단히 고정)
    final double waveOffsetMiddle = math.sin(_waveTime) * 1.5;
    final double waveOffsetEnd = math.cos(_waveTime) * 1.8;

    final Path flagPath = Path();
    flagPath.moveTo(1.2, -14.5);
    // 윗변 물결 곡선 연출 (제어점과 끝점 부분에 파동 결합)
    flagPath.quadraticBezierTo(
      8.5,
      -17.8 + waveOffsetMiddle,
      18,
      -13.8 + waveOffsetEnd,
    );
    // 우측 마감선 (끝점 위상 변위 적용)
    flagPath.lineTo(18, -3.8 + waveOffsetEnd);
    // 아랫변 물결 곡선 연출
    flagPath.quadraticBezierTo(
      8.5,
      -6.8 + waveOffsetMiddle,
      1.2,
      -3.5,
    );
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

