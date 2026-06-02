import 'dart:ui';
import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:latlong2/latlong.dart' hide Path;
import '../../core/constants/colors.dart';
import '../../core/constants/game_config.dart';
import '../conquest_game.dart';

/// 지도 상에서 특정 헥사곤 거점의 영역과 외각선을 그리고, 현재 점령 중일 때 게이지 진행 상황 및 펄스 이펙트 애니메이션을 렌더링하는 Flame 컴포넌트
/// 중심점(0, 0) 기준 로컬 좌표계 및 줌 레벨별 Bezier 그리기 패스 캐싱을 활용하여 극대화된 렌더링 속도를 보장합니다.
class HexTileComponent extends PositionComponent
    with HasGameReference<ConquestGame> {
  /// 헥사곤 좌표축 파라미터
  final int q;
  final int r;

  /// 타일의 지리적 고정 중심 좌표
  final LatLng centerLatLng;

  /// 타일의 지리적 고정 6개 꼭짓점 좌표 목록
  final List<LatLng> cornerLatLngs;

  /// 이 헥사곤이 현재 렌더링되고 있는 줌 레벨 스케일의 LOD 픽셀 크기
  final double hexSize;

  /// 타일이 점령되었을 때 칠해질 요원의 진영 색상 (Hex)
  String? colorHex;

  /// 현재 이 타일이 요원(물리/위성)에 의해 점령 시도 중인지 여부
  bool isCapturing;

  /// 점령 시도의 진행 진척도 (0.0 ~ 1.0)
  double progress;

  /// 현재 이 타일을 점령 시도 중인 요원의 진영 색상 (Hex)
  String? capturingColorHex;

  /// 로컬 꼭짓점 6개의 픽셀 상대 좌표 리스트 (중심 (0, 0) 기준)
  List<Offset> localCorners = [];

  /// 마지막으로 꼭짓점 및 패스를 연산 완료한 시점의 카메라 줌 레벨 캐시
  double lastCalculatedZoom = -1.0;

  /// 마지막으로 꼭짓점 및 패스를 연산 완료한 시점의 카메라 회전 각도(라디안) 캐시
  double lastCalculatedRotation = -999.0;

  /// 타일 내부 영역을 채울 때 사용하는 Paint 객체
  late Paint _fillPaint;

  /// 점령 진행 중일 때 외곽선 애니메이션을 드로잉하는 Paint 객체
  late Paint _capturePaint;

  /// 매 프레임 그리기 성능 향상을 위해 꼭짓점 좌표를 기반으로 빌드해 보관하는 그리기 패스 객체
  Path? _cachedPath;

  /// 점령 외곽선 펄스 애니메이션 속도를 계산하기 위한 타임 누적 값
  double _timer = 0;

  /// 헥사곤의 평균 반지름 (그라데이션 및 프러스텀 컬링 연산용)
  double _tileRadius = 0;

  /// HexTileComponent 생성자로 필요한 헥사곤 좌표 정보와 상태를 설정받습니다.
  HexTileComponent({
    required this.q,
    required this.r,
    required this.centerLatLng,
    required this.cornerLatLngs,
    required this.colorHex,
    required this.hexSize,
    this.isCapturing = false,
    this.progress = 0.0,
    this.capturingColorHex,
  });

  /// 점령 요원의 식별 색상, 점령 진행도 상태가 갱신되었을 때 해당 상태를 반영하고 화면 갱신을 준비합니다.
  void updateData({
    String? colorHex,
    bool? isCapturing,
    double? progress,
    String? capturingColorHex,
  }) {
    if (colorHex != null && this.colorHex != colorHex) {
      this.colorHex = colorHex;
      if (isMounted) _updateStyles();
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
    // 0. 수명 주기 가드: 제거 중이거나 마운트가 덜 된 컴포넌트는 드로잉 즉시 강제 중지하여 잔상 차단
    if (isRemoving || !isMounted) return;

    // 1. 초고속 프러스텀 컬링 (중심점 위치와 픽셀 반지름 기준으로 화면 경계 밖 타일 1차 스킵)
    final gameSize = game.size;
    final rVal = _tileRadius > 0 ? _tileRadius + 20.0 : 60.0;
    final isVisible = position.x >= -rVal &&
        position.x <= gameSize.x + rVal &&
        position.y >= -rVal &&
        position.y <= gameSize.y + rVal;
    if (!isVisible) return;

    // 2. 줌 레벨 및 카메라 회전각 변동 여부 감지하여 로컬 꼭짓점 좌표계 및 Bezier 그리기 패스 캐싱 처리
    final double currentZoom = game.mapController?.camera.zoom ?? 1.0;
    final double currentRotation = game.mapController?.camera.rotation ?? 0.0;

    // 컴포넌트 자체의 회전각(라디안)을 카메라 회전각과 100% 실시간으로 일치시킴
    angle = currentRotation * (math.pi / 180.0);

    // 지도가 회전해도 헥사곤의 고유 형태는 변하지 않으므로, 패스 캐싱 조건에서 회전값 비교를 배제하여 CPU 연산 낭비를 완벽 차단합니다.
    if (_cachedPath == null || (currentZoom - lastCalculatedZoom).abs() > 0.001) {
      if (game.mapController == null) return;

      final centerOffset = game.mapController!.camera.latLngToScreenOffset(centerLatLng);

      // 카메라 회전각(라디안)에 따른 역회전 삼각비 산출
      final double rotationRad = currentRotation * (math.pi / 180.0);
      final double cosTheta = math.cos(-rotationRad);
      final double sinTheta = math.sin(-rotationRad);

      // 로컬 중심점 (0, 0)을 기준으로 한 상대적 픽셀 꼭짓점 좌표 산출 (역회전 행렬을 적용하여 '회전 0' 정방향 상태로 정규화)
      localCorners = cornerLatLngs.map((latlng) {
        final offset = game.mapController!.camera.latLngToScreenOffset(latlng);
        final rx = offset.dx - centerOffset.dx;
        final ry = offset.dy - centerOffset.dy;

        // 역회전 변환 수행
        final nx = rx * cosTheta - ry * sinTheta;
        final ny = rx * sinTheta + ry * cosTheta;
        return Offset(nx, ny);
      }).toList();

      // 로컬 꼭짓점들로부터 평균 반지름 계산
      double radSum = 0;
      for (final c in localCorners) {
        radSum += math.sqrt(c.dx * c.dx + c.dy * c.dy);
      }
      _tileRadius = localCorners.isNotEmpty ? radSum / localCorners.length : 0.0;

      // 둥근 모서리 벌집 타일(Rounded Hexagon Path) 로컬 좌표계 그리기 패스 생성
      final double cornerRadius = math.min(8.0, _tileRadius * 0.26);
      const double padding = 2.2; // 타일 간 보드게임형 갭

      // 1) 패딩이 수축 적용된 로컬 꼭짓점 계산
      final List<Offset> insetCorners = [];
      for (int i = 0; i < localCorners.length; i++) {
        final c = localCorners[i];
        // 로컬 중심 (0, 0) 기준이므로 꼭짓점에서 중심 방향 벡터는 (-c.dx, -c.dy)
        final dx = -c.dx;
        final dy = -c.dy;
        final dist = math.sqrt(dx * dx + dy * dy);

        final double insetX = dist > padding
            ? c.dx + (dx / dist) * padding
            : c.dx;
        final double insetY = dist > padding
            ? c.dy + (dy / dist) * padding
            : c.dy;
        insetCorners.add(Offset(insetX, insetY));
      }

      // 2) 베지에 곡선 기반 둥근 육각형 로컬 그리기 패스 구축
      _cachedPath = Path();
      for (int i = 0; i < insetCorners.length; i++) {
        final current = insetCorners[i];
        final prev = insetCorners[(i - 1 + insetCorners.length) % insetCorners.length];
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

      lastCalculatedZoom = currentZoom;
      lastCalculatedRotation = currentRotation;
    }

    if (localCorners.isEmpty || _cachedPath == null) return;

    // 3. 점령된 타일 채우기 (로컬 중심 (0, 0) 기준 그라데이션 및 드로잉)
    if (colorHex != null) {
      final Color baseColor = _parseColor(colorHex) ?? GameColors.transparent;
      final double gradientRadius = _tileRadius * 1.1;

      // 로컬 중심 (0, 0)을 정밀하게 활용하는 radial gradient 셰이더 바인딩
      _fillPaint.shader = Gradient.radial(
        const Offset(0, 0),
        gradientRadius,
        [
          baseColor.withValues(alpha: GameConfig.tileOpacity * 0.45),
          baseColor.withValues(alpha: GameConfig.tileOpacity * 1.35),
        ],
        const [0.0, 1.0],
      );

      // 1) 젤리 그라데이션 바디 드로잉
      canvas.drawPath(_cachedPath!, _fillPaint);

      // 2) 소프트 테두리 스트로크
      final Paint borderPaint = Paint()
        ..color = baseColor.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawPath(_cachedPath!, borderPaint);
    }

    // 4. 점령 애니메이션 드로잉 (로컬 꼭짓점 기준 좌표 투영 100% 스킵)
    if (isCapturing) {
      final pulse = (0.5 + 0.5 * math.sin(_timer)).clamp(0.0, 1.0);
      final captureColor = _parseColor(capturingColorHex) ?? GameColors.accentNeon;

      // 외곽선 펄스 효과
      _capturePaint.color = captureColor.withValues(
        alpha: (100 + 100 * pulse) / 255,
      );
      _capturePaint.strokeWidth = 1.5 + (2.5 * pulse);
      canvas.drawPath(_cachedPath!, _capturePaint);

      // 내부 채우기 애니메이션 (로컬 경계 Y축 범위 계산)
      canvas.save();
      canvas.clipPath(_cachedPath!);

      double minY = localCorners[0].dy;
      double maxY = localCorners[0].dy;
      for (final c in localCorners) {
        if (c.dy < minY) minY = c.dy;
        if (c.dy > maxY) maxY = c.dy;
      }
      final height = maxY - minY;
      final fillY = maxY - (height * progress);

      final fillRect = Rect.fromLTRB(
        localCorners.map((e) => e.dx).reduce((a, b) => a < b ? a : b),
        fillY,
        localCorners.map((e) => e.dx).reduce((a, b) => a > b ? a : b),
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
