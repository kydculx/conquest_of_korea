import 'dart:ui';
import 'dart:math' as math;
import 'package:flame/components.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/game_config.dart';
import '../conquest_game.dart';

/// 지도 상에서 특정 헥사곤 거점의 영역과 외각선을 그리고, 현재 점령 중일 때 게이지 진행 상황 및 펄스 이펙트 애니메이션을 렌더링하는 Flame 컴포넌트
class HexTileComponent extends PositionComponent
    with HasGameReference<ConquestGame> {
  /// 타일이 점령되었을 때 칠해질 요원의 진영 색상 (Hex)
  String? colorHex;

  /// 스크린 기준으로 산출된 헥사곤 꼭짓점 6개의 픽셀 좌표 리스트
  List<Offset> corners;

  /// 현재 이 타일이 요원(물리/위성)에 의해 점령 시도 중인지 여부
  bool isCapturing;

  /// 점령 시도의 진행 진척도 (0.0 ~ 1.0)
  double progress;

  /// 현재 이 타일을 점령 시도 중인 요원의 진영 색상 (Hex)
  String? capturingColorHex;

  /// 타일 내부 영역을 채울 때 사용하는 Paint 객체
  late Paint _fillPaint;

  /// 점령 진행 중일 때 외곽선 애니메이션을 드로잉하는 Paint 객체
  late Paint _capturePaint;

  /// 매 프레임 그리기 성능 향상을 위해 꼭짓점 좌표를 기반으로 빌드해 보관하는 그리기 패스 객체
  Path? _cachedPath;

  /// 점령 외곽선 펄스 애니메이션 속도를 계산하기 위한 타임 누적 값
  double _timer = 0;

  /// 꼭짓점 좌표가 변경되어 캐시가 갱신될 때 산출한 타일 중심점 X좌표
  double _centerX = 0;

  /// 꼭짓점 좌표가 변경되어 캐시가 갱신될 때 산출한 타일 중심점 Y좌표
  double _centerY = 0;

  /// 헥사곤의 평균 반지름 (그라데이션 연산용)
  double _tileRadius = 0;

  /// HexTileComponent 생성자로 필요한 헥사곤 좌표 정보와 상태를 설정받습니다.
  HexTileComponent({
    required this.colorHex,
    required this.corners,
    this.isCapturing = false,
    this.progress = 0.0,
    this.capturingColorHex,
  });

  /// 헥사곤 좌표 꼭짓점, 점령 요원의 식별 색상, 점령 진행도 상태가 갱신되었을 때 해당 상태를 반영하고 화면 갱신을 준비합니다.
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

  /// 설정된 점령 진영의 색상을 파싱하여 배경 채우기(Paint) 및 외곽선 스트로크 스타일 브러시를 갱신합니다.
  void _updateStyles() {
    final Color baseColor = _parseColor(colorHex) ?? GameColors.transparent;

    _fillPaint = Paint()
      ..color = baseColor.withValues(alpha: GameConfig.tileOpacity)
      ..style = PaintingStyle.fill;

    _capturePaint = Paint()
      ..color = GameColors.accentNeon.withValues(alpha: 150 / 255)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
  }

  /// 전달된 16진수 문자열 색상 값(예: '#FF12AB')을 분석하여 Flutter Color 객체로 디코딩합니다.
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

    // 1. 프러스텀 컬링 (화면 밖에 있는 타일은 그리지 않고 스킵)
    final gameSize = game.size;
    final isVisible = corners.any(
      (c) =>
          c.dx >= -50 &&
          c.dx <= gameSize.x + 50 &&
          c.dy >= -50 &&
          c.dy <= gameSize.y + 50,
    );
    if (!isVisible) return;

    // 2. 둥근 모서리 벌집 타일(Rounded Hexagon Path) 캐싱 및 중심점/반지름 산출
    if (_cachedPath == null) {
      // 타일의 중심점 계산
      double cx = 0, cy = 0;
      for (final c in corners) {
        cx += c.dx;
        cy += c.dy;
      }
      cx /= corners.length;
      cy /= corners.length;
      _centerX = cx;
      _centerY = cy;

      // 헥사곤 반지름 계산
      double radSum = 0;
      for (final c in corners) {
        final dx = c.dx - cx;
        final dy = c.dy - cy;
        radSum += math.sqrt(dx * dx + dy * dy);
      }
      _tileRadius = radSum / corners.length;

      // 아기자기한 캐주얼 헥사칩 둥글기 수준 (육각형 본래 대칭각과 둥글기의 균형 조율)
      final double cornerRadius = math.min(8.0, _tileRadius * 0.26);
      // 타일 간의 아기자기한 보드게임형 갭(Padding) 생성
      const double padding = 2.2;

      // 1) 패딩이 적용된 수축 꼭짓점 산출
      final List<Offset> insetCorners = [];
      for (int i = 0; i < corners.length; i++) {
        final c = corners[i];
        final dx = cx - c.dx;
        final dy = cy - c.dy;
        final dist = math.sqrt(dx * dx + dy * dy);

        final double insetX = dist > padding
            ? c.dx + (dx / dist) * padding
            : c.dx;
        final double insetY = dist > padding
            ? c.dy + (dy / dist) * padding
            : c.dy;
        insetCorners.add(Offset(insetX, insetY));
      }

      // 2) 베지에 곡선 기반 둥근 육각형 그리기 패스 생성
      _cachedPath = Path();
      for (int i = 0; i < insetCorners.length; i++) {
        final current = insetCorners[i];
        final prev =
            insetCorners[(i - 1 + insetCorners.length) % insetCorners.length];
        final next = insetCorners[(i + 1) % insetCorners.length];

        final vPrevX = prev.dx - current.dx;
        final vPrevY = prev.dy - current.dy;
        final lenPrev = math.sqrt(vPrevX * vPrevX + vPrevY * vPrevY);

        final vNextX = next.dx - current.dx;
        final vNextY = next.dy - current.dy;
        final lenNext = math.sqrt(vNextX * vNextX + vNextY * vNextY);

        final double r = math.min(
          cornerRadius,
          math.min(lenPrev / 2, lenNext / 2),
        );

        final startX = current.dx + (vPrevX / lenPrev) * r;
        final startY = current.dy + (vPrevY / lenPrev) * r;

        final endX = current.dx + (vNextX / lenNext) * r;
        final endY = current.dy + (vNextY / lenNext) * r;

        if (i == 0) {
          _cachedPath!.moveTo(startX, startY);
        } else {
          _cachedPath!.lineTo(startX, startY);
        }
        _cachedPath!.quadraticBezierTo(current.dx, current.dy, endX, endY);
      }
      _cachedPath!.close();
    }

    // 3. 점령된 타일 채우기 (3D 보드게임 칩 & 비대칭 광택 젤리 스펙큘러 입체 스타일)
    if (colorHex != null) {
      final Color baseColor = _parseColor(colorHex) ?? GameColors.transparent;

      // 1) 3D 드롭 섀도우 (바닥 그림자 효과로 공중에 입체적으로 떠 있는 보드게임 칩 느낌 형성)
      canvas.save();
      canvas.translate(0, 3.5); // 아래로 3.5px 오프셋
      final Paint shadowPaint = Paint()
        ..color = const Color(0xFF000000).withValues(alpha: 0.32)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5); // 흐림 효과 가미
      canvas.drawPath(_cachedPath!, shadowPaint);
      canvas.restore();

      // 2) 비대칭 specularity 광원 효과를 가미한 스펙큘러 그라데이션 설계 (빛이 좌측 상단 45도에서 쬐는 볼륨 엠보싱)
      final double gradientRadius = _tileRadius * 1.15;
      _fillPaint.shader = Gradient.radial(
        Offset(_centerX, _centerY),
        gradientRadius,
        [
          const Color(0xFFFFFFFF).withValues(alpha: 0.75), // 좌측 상단 반사Specular 하이라이트
          baseColor.withValues(alpha: GameConfig.tileOpacity * 0.65), // 바디 기본 색상
          baseColor.withValues(alpha: GameConfig.tileOpacity * 1.45), // 하단 음영 섀도우 대비 쫀득한 채색
        ],
        const [0.0, 0.28, 1.0],
        TileMode.clamp,
        null,
        Offset(_centerX - _tileRadius * 0.35, _centerY - _tileRadius * 0.35), // 광원 중심(Focal)을 좌측 상단으로 이동!
        0.0,
      );

      // 3) 3D 입체 젤리 바디 드로잉
      canvas.drawPath(_cachedPath!, _fillPaint);

      // 4) 윗면의 부드러운 하이라이트(림 라이트/베벨 입체감) 테두리 그리기
      final Paint lightBorderPaint = Paint()
        ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.38)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      canvas.drawPath(_cachedPath!, lightBorderPaint);

      // 5) 아래쪽 어두운 입체 음영 테두리 그리기
      final Paint darkBorderPaint = Paint()
        ..color = const Color(0xFF000000).withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8;
      canvas.drawPath(_cachedPath!, darkBorderPaint);
    }

    // 4. 점령 애니메이션 최적화
    if (isCapturing) {
      final pulse = (0.5 + 0.5 * math.sin(_timer)).clamp(0.0, 1.0);
      final captureColor =
          _parseColor(capturingColorHex) ?? GameColors.accentNeon;

      // 외곽선 펄스 효과
      _capturePaint.color = captureColor.withValues(
        alpha: (100 + 100 * pulse) / 255,
      );
      _capturePaint.strokeWidth = 1.5 + (2.5 * pulse);
      canvas.drawPath(_cachedPath!, _capturePaint);

      // 내부 채우기 애니메이션 (아래에서 위로 progress만큼 차오름)
      canvas.save();
      // 둥근 헥사곤 패스로 정밀 클리핑하여 둥근 모서리에 예쁘게 차오르게 제어
      canvas.clipPath(_cachedPath!);

      double minY = corners[0].dy;
      double maxY = corners[0].dy;
      for (final c in corners) {
        if (c.dy < minY) minY = c.dy;
        if (c.dy > maxY) maxY = c.dy;
      }
      final height = maxY - minY;
      final fillY = maxY - (height * progress);

      final fillRect = Rect.fromLTRB(
        corners.map((e) => e.dx).reduce((a, b) => a < b ? a : b),
        fillY,
        corners.map((e) => e.dx).reduce((a, b) => a > b ? a : b),
        maxY,
      );

      final fillPaint = Paint()
        ..color = captureColor.withValues(alpha: 130 / 255)
        ..style = PaintingStyle.fill;

      canvas.drawRect(fillRect, fillPaint);
      canvas.restore();
    }
  }
}
