import 'package:conquest_mobile/core/constants.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../models/hub_model.dart';
import '../conquest_game.dart';

class HubComponent extends PositionComponent with HasGameReference<ConquestGame> {
  final String name;
  final HubType type;
  final Offset screenPosition;

  HubComponent({
    required this.name,
    required this.type,
    required this.screenPosition,
  }) {
    final s = _getHubSize() * 2;
    size = Vector2(s, s);
    position = Vector2(screenPosition.dx, screenPosition.dy);
    anchor = Anchor.center;
  }

  @override
  Future<void> onLoad() async {
    final isMajor = type == HubType.special || type == HubType.metropolitan || type == HubType.provincial;
    final hubSize = _getHubSize();
    
    // 텍스트 컴포넌트 추가
    final textComponent = TextComponent(
      text: name,
      textRenderer: TextPaint(
        style: TextStyle(
          color: Colors.white,
          fontSize: isMajor ? 11 : 9,
          fontWeight: isMajor ? FontWeight.bold : FontWeight.normal,
          shadows: const [
            Shadow(blurRadius: 2, color: Colors.black),
            Shadow(blurRadius: 2, color: Colors.black),
          ],
        ),
      ),
    );
    
    // 위치를 하단으로 잡음
    textComponent.anchor = Anchor.topCenter;
    textComponent.position = Vector2(size.x / 2, size.y / 2 + hubSize + 4);
    
    add(textComponent);
  }

  @override
  void render(Canvas canvas) {
    // 0. 프러스텀 컬링: 화면 밖의 거점은 렌더링 생략 (여유 마진 50px)
    final gameSize = game.size;
    if (position.x < -50 || position.x > gameSize.x + 50 || 
        position.y < -50 || position.y > gameSize.y + 50) {
      return;
    }

    final isMajor = type == HubType.special || type == HubType.metropolitan || type == HubType.provincial;
    final hubColor = _getHubColor();
    final hubSize = _getHubSize();
    final center = Offset.zero;

    // 1. 네온 글로우 효과
    final glowPaint = Paint()
      ..color = hubColor.withAlpha(isMajor ? 180 : 120)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(center, hubSize * 1.5, glowPaint);

    // 2. 중심 마커
    final mainPaint = Paint()
      ..color = hubColor
      ..style = PaintingStyle.fill;
    
    if (isMajor) {
      // 주요 거점은 사각형(다이아몬드) 형태
      canvas.save();
      canvas.rotate(0.785398); // 45도 회전
      canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: hubSize * 1.2, height: hubSize * 1.2), mainPaint);
      canvas.restore();
    } else {
      canvas.drawCircle(center, hubSize * 0.8, mainPaint);
    }

    // 3. 테두리
    final strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    if (isMajor) {
      canvas.save();
      canvas.rotate(0.785398);
      canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: hubSize * 1.2, height: hubSize * 1.2), strokePaint);
      canvas.restore();
    } else {
      canvas.drawCircle(center, hubSize * 0.8, strokePaint);
    }

    // 4. 이름 라벨 배경 (TextComponent 아래에 배경 그려주기)
    // 약간의 꼼수로 TextComponent의 너비를 알기 위해선 텍스트 길이에 비례한 고정값 사용 (또는 렌더에서 배경 생략)
    // 렌더 성능을 위해 배경은 여기서 간단히 그림
    final textWidth = name.length * (isMajor ? 10.0 : 8.0); 
    final textHeight = isMajor ? 14.0 : 12.0;

    final bgPaint = Paint()..color = Colors.black.withAlpha(160);
    final bgRect = Rect.fromLTWH(
      -textWidth / 2 - 4,
      hubSize + 4,
      textWidth + 8,
      textHeight + 2,
    );
    canvas.drawRRect(RRect.fromRectAndRadius(bgRect, const Radius.circular(4)), bgPaint);
  }

  double _getHubSize() {
    switch (type) {
      case HubType.special:
        return 12;
      case HubType.metropolitan:
        return 10;
      case HubType.provincial:
        return 8;
      default:
        return 6;
    }
  }

  Color _getHubColor() {
    switch (type) {
      case HubType.special:
        return GameConstants.colorAccent;
      case HubType.metropolitan:
        return Colors.amber;
      case HubType.provincial:
        return Colors.orange;
      default:
        return Colors.white.withAlpha(200);
    }
  }
}
