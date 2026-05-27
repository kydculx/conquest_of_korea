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

    // 🚩 이모티콘 렌더링
    _drawHQFlagEmoji(
      canvas,
      _screenCenter!.dx,
      _screenCenter!.dy,
    );
  }

  /// 지정된 화면 중앙(cx, cy) 좌표를 기준으로 친숙하고 직관적인 🚩 깃발 이모지(Emoji)를 텍스트로 정밀 드로잉합니다.
  void _drawHQFlagEmoji(Canvas canvas, double cx, double cy) {
    final textPainter = TextPainter(
      text: const TextSpan(
        text: '🚩',
        style: TextStyle(
          fontSize: 28.0, // 직관적이고 시인성 높은 크기 28.0px
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    // 이모지가 스크린 좌표의 정확한 중심에 고정되도록 오프셋 보정 드로잉
    textPainter.paint(
      canvas,
      Offset(
        cx - textPainter.width / 2,
        cy - textPainter.height / 2,
      ),
    );
  }
}

