import 'package:conquest_mobile/core/constants.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../models/hub_model.dart';
import '../conquest_game.dart';

class HubComponent extends PositionComponent
    with HasGameReference<ConquestGame> {
  final String name;
  final HubType type;
  final Offset screenPosition;

  late TextComponent _textLabel;
  bool _shouldRender = true;

  // 특례시 리스트 (수원, 용인, 고양, 창원)
  static const Set<String> _specializedCities = {
    '수원시청',
    '용인시청',
    '고양시청',
    '창원시청',
  };

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
    final tier = _getTier();
    final hubSize = _getHubSize();

    _textLabel = TextComponent(
      text: name,
      textRenderer: TextPaint(
        style: TextStyle(
          color: GameColors.textPrimary,
          fontSize: tier == 1 ? 11 : (tier == 2 ? 10 : 9),
          fontWeight: tier == 1 ? FontWeight.bold : FontWeight.normal,
          shadows: [Shadow(blurRadius: 2, color: GameColors.tacticalBlack)],
        ),
      ),
    );

    _textLabel.anchor = Anchor.topCenter;
    _textLabel.position = Vector2(size.x / 2, size.y / 2 + hubSize + 2);
    add(_textLabel);
  }

  int _getTier() {
    // 1단계: 특별시, 광역시, 도청
    if (type == HubType.special ||
        type == HubType.metropolitan ||
        type == HubType.provincial) {
      return 1;
    }
    // 2단계: 특례시, 일반 시청
    if (_specializedCities.contains(name) || type == HubType.city) {
      return 2;
    }
    // 3단계: 구청, 군청
    return 3;
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (game.mapController == null) return;

    // 줌 레벨을 퍼센트로 환산 (설정된 지도 줌 범위 기준)
    final currentZoom = game.mapController!.camera.zoom;
    final zoomPercent = ((currentZoom - GameConstants.minZoom) /
            (GameConstants.maxZoom - GameConstants.minZoom) *
            100)
        .clamp(0.0, 100.0);

    final tier = _getTier();

    // 사용자 요청 기반 3단계 LOD 로직
    if (zoomPercent < GameConstants.lodThresholdTier1) {
      // 1단계만 표시
      _shouldRender = (tier == 1);
    } else if (zoomPercent < GameConstants.lodThresholdTier2) {
      // 1, 2단계 표시
      _shouldRender = (tier <= 2);
    } else {
      // 모두 표시
      _shouldRender = true;
    }

    // 텍스트 라벨 가시성 (성능을 위해 줌에 따라 제어)
    if (_shouldRender) {
      if (zoomPercent < GameConstants.textThresholdTier1) {
        _textLabel.scale = Vector2.all(tier == 1 ? 1.0 : 0.0);
      } else if (zoomPercent < GameConstants.textThresholdTier2) {
        _textLabel.scale = Vector2.all(tier <= 2 ? 1.0 : 0.0);
      } else {
        _textLabel.scale = Vector2.all(1.0);
      }
    }
  }

  @override
  void render(Canvas canvas) {
    if (!_shouldRender) return;

    final gameSize = game.size;
    if (position.x < -50 ||
        position.x > gameSize.x + 50 ||
        position.y < -50 ||
        position.y > gameSize.y + 50) {
      return;
    }

    final tier = _getTier();
    final hubColor = _getHubColor();
    final hubSize = _getHubSize();
    final center = Offset(size.x / 2, size.y / 2);

    final mainPaint = Paint()
      ..color = hubColor
      ..style = PaintingStyle.fill;

    if (tier == 1) {
      // 1단계는 다이아몬드 형태
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(0.785398);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: hubSize * 1.3,
          height: hubSize * 1.3,
        ),
        mainPaint,
      );
      canvas.restore();
    } else {
      canvas.drawCircle(center, hubSize * 0.9, mainPaint);
    }

    final strokePaint = Paint()
      ..color = GameColors.tacticalWhite.withValues(alpha: 200 / 255)
      ..style = PaintingStyle.stroke
      ..strokeWidth = tier == 1 ? 1.5 : 1.0;

    if (tier == 1) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(0.785398);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: hubSize * 1.3,
          height: hubSize * 1.3,
        ),
        strokePaint,
      );
      canvas.restore();
    } else {
      canvas.drawCircle(center, hubSize * 0.9, strokePaint);
    }
  }

  double _getHubSize() {
    final tier = _getTier();
    if (tier == 1) return 12;
    if (tier == 2) return 8;
    return 5;
  }

  Color _getHubColor() {
    final tier = _getTier();
    if (tier == 1) return GameColors.colorAccent;
    if (tier == 2) return GameColors.warning;
    return GameColors.accentNeon;
  }
}
