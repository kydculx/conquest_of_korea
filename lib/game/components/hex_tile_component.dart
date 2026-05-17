import 'dart:ui';
import 'dart:math' as math;
import 'package:flame/components.dart';
import '../../core/constants.dart';
import '../conquest_game.dart';

/// 헥사곤 점령 타일 렌더링 컴포넌트 (성능 최적화 버전)
class HexTileComponent extends PositionComponent
    with HasGameReference<ConquestGame> {
  String? colorHex;
  List<Offset> corners;
  bool isCapturing;
  double progress;
  String? capturingColorHex;

  late Paint _fillPaint;
  late Paint _capturePaint;
  Path? _cachedPath;
  double _timer = 0;

  HexTileComponent({
    required this.colorHex,
    required this.corners,
    this.isCapturing = false,
    this.progress = 0.0,
    this.capturingColorHex,
  });

  void updateData({
    String? colorHex,
    List<Offset>? corners,
    bool? isCapturing,
    double? progress,
    String? capturingColorHex,
  }) {
    if (colorHex != null && this.colorHex != colorHex) {
      this.colorHex = colorHex;
      if (isMounted) _updateStyles();
    }
    if (corners != null) {
      this.corners = corners;
      _cachedPath = null; // 좌표 변경 시 패시 캐시 무효화
    }
    if (isCapturing != null) this.isCapturing = isCapturing;
    if (progress != null) this.progress = progress;
    if (capturingColorHex != null) this.capturingColorHex = capturingColorHex;
  }

  @override
  void onMount() {
    super.onMount();
    _updateStyles();
  }

  void _updateStyles() {
    final Color baseColor = _parseColor(colorHex) ?? GameColors.transparent;

    _fillPaint = Paint()
      ..color = baseColor.withValues(alpha: GameConstants.tileOpacity)
      ..style = PaintingStyle.fill;

    _capturePaint = Paint()
      ..color = GameColors.accentNeon.withValues(alpha: 150 / 255)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
  }

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

  @override
  void update(double dt) {
    super.update(dt);
    if (isCapturing) _timer += dt * 5;
  }

  @override
  void render(Canvas canvas) {
    if (corners.isEmpty) return;

    // 1. 프러스텀 컬링
    final gameSize = game.size;
    final isVisible = corners.any(
      (c) =>
          c.dx >= -50 &&
          c.dx <= gameSize.x + 50 &&
          c.dy >= -50 &&
          c.dy <= gameSize.y + 50,
    );
    if (!isVisible) return;

    // 2. Path 캐싱 로직
    if (_cachedPath == null) {
      _cachedPath = Path()..moveTo(corners[0].dx, corners[0].dy);
      for (int i = 1; i < corners.length; i++) {
        _cachedPath!.lineTo(corners[i].dx, corners[i].dy);
      }
      _cachedPath!.close();
    }

    // 3. 점령된 타일 채우기
    if (colorHex != null) {
      canvas.drawPath(_cachedPath!, _fillPaint);
    }

    // 4. 점령 애니메이션 최적화
    if (isCapturing) {
      final pulse = (0.5 + 0.5 * math.sin(_timer)).clamp(0.0, 1.0);
      final captureColor =
          _parseColor(capturingColorHex) ?? GameColors.accentNeon;

      // 외곽선 펄스 효과
      _capturePaint.color = captureColor.withValues(alpha: (100 + 100 * pulse) / 255);
      _capturePaint.strokeWidth = 1.5 + (2.5 * pulse);
      canvas.drawPath(_cachedPath!, _capturePaint);

      // 채우기 애니메이션
      canvas.save();
      canvas.clipPath(_cachedPath!);

      double minY = corners[0].dy, maxY = corners[0].dy;
      for (final c in corners) {
        if (c.dy < minY) minY = c.dy;
        if (c.dy > maxY) maxY = c.dy;
      }
      final height = maxY - minY;

      final fillRect = Rect.fromLTRB(
        corners.map((e) => e.dx).reduce((a, b) => a < b ? a : b),
        maxY - (height * progress),
        corners.map((e) => e.dx).reduce((a, b) => a > b ? a : b),
        maxY,
      );

      canvas.drawRect(
        fillRect,
        Paint()
          ..color = captureColor.withValues(alpha: 130 / 255)
          ..style = PaintingStyle.fill,
      );
      canvas.restore();
    }
  }
}
