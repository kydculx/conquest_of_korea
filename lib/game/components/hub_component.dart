import 'package:conquest_mobile/core/constants.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../models/hub_model.dart';
import '../conquest_game.dart';

class HubComponent extends PositionComponent with HasGameReference<ConquestGame> {
  final String name;
  final HubType type;
  final Offset screenPosition;

  late TextComponent _textLabel;
  bool _shouldRender = true;

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
    
    _textLabel = TextComponent(
      text: name,
      textRenderer: TextPaint(
        style: TextStyle(
          color: Colors.white,
          fontSize: isMajor ? 11 : 9,
          fontWeight: isMajor ? FontWeight.bold : FontWeight.normal,
          shadows: const [
            Shadow(blurRadius: 2, color: Colors.black),
          ],
        ),
      ),
    );
    
    _textLabel.anchor = Anchor.topCenter;
    _textLabel.position = Vector2(size.x / 2, size.y / 2 + hubSize + 2);
    add(_textLabel);
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    if (game.mapController == null) return;
    final zoom = game.mapController!.camera.zoom;
    final isMajor = type == HubType.special || type == HubType.metropolitan || type == HubType.provincial;
    
    // 1. 줌 레벨에 따른 마커 표시 여부 (최적화 핵심)
    if (zoom < 9) {
      _shouldRender = isMajor; // 줌 9 미만: 주요 거점만 표시
    } else if (zoom < 11) {
      _shouldRender = isMajor || type == HubType.city; // 줌 11 미만: 시청까지 표시
    } else {
      _shouldRender = true; // 줌 11 이상: 모두 표시
    }

    // 2. 텍스트 라벨 가시성 (텍스트 렌더링은 무겁기 때문)
    if (_shouldRender) {
      if (zoom < 11) {
        _textLabel.scale = Vector2.all(isMajor ? 1.0 : 0.0);
      } else {
        _textLabel.scale = Vector2.all(1.0);
      }
    }
  }

  @override
  void render(Canvas canvas) {
    if (!_shouldRender) return;

    // 프러스텀 컬링 (화면 밖 렌더링 스킵)
    final gameSize = game.size;
    if (position.x < -50 || position.x > gameSize.x + 50 || 
        position.y < -50 || position.y > gameSize.y + 50) {
      return;
    }

    final isMajor = type == HubType.special || type == HubType.metropolitan || type == HubType.provincial;
    final hubColor = _getHubColor();
    final hubSize = _getHubSize();
    final center = Offset(size.x / 2, size.y / 2);

    final mainPaint = Paint()
      ..color = hubColor
      ..style = PaintingStyle.fill;
    
    if (isMajor) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(0.785398); 
      canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: hubSize * 1.2, height: hubSize * 1.2), mainPaint);
      canvas.restore();
    } else {
      canvas.drawCircle(center, hubSize * 0.8, mainPaint);
    }

    final strokePaint = Paint()
      ..color = Colors.white.withAlpha(200)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    if (isMajor) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(0.785398);
      canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: hubSize * 1.2, height: hubSize * 1.2), strokePaint);
      canvas.restore();
    } else {
      canvas.drawCircle(center, hubSize * 0.8, strokePaint);
    }
  }

  double _getHubSize() {
    switch (type) {
      case HubType.special: return 11;
      case HubType.metropolitan: return 9;
      case HubType.provincial: return 8;
      case HubType.city: return 6;
      case HubType.district:
      case HubType.county: return 4;
    }
  }

  Color _getHubColor() {
    switch (type) {
      case HubType.special: return GameConstants.colorAccent;
      case HubType.metropolitan: return Colors.amber;
      case HubType.provincial: return Colors.orangeAccent;
      case HubType.city: return Colors.lightGreenAccent;
      case HubType.district: return Colors.cyanAccent;
      case HubType.county: return Colors.tealAccent;
    }
  }
}
