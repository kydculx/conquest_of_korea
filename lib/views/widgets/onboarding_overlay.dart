import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/strings.dart';

/// 최초 로그인 시 사용되는 인게임 HUD UI 안내 온보딩 단계들 (화면 위에서 아래 방향의 논리적 순서)
enum OnboardingStep {
  welcome,
  myLocation,
  goldBar,
  timerBar,
  stepsBar,
  patternBtn,
  achievementBtn,
  rankingBtn,
  profileBtn,
  hqBtn,
  photoBtn, // 📸 타일 사진 촬영 안내 단계
  mapFollowBtn,
  mapModeToggleBtn,
  mapStyleBtn,
  remoteInfo,
  complete
}

/// 최초 로그인 유저에게 HUD UI에 지시선과 하이라이팅 효과를 주어 설명하는 오버레이 가이드 컴포넌트
class OnboardingOverlay extends StatefulWidget {
  final VoidCallback onFinish;

  const OnboardingOverlay({super.key, required this.onFinish});

  @override
  State<OnboardingOverlay> createState() => _OnboardingOverlayState();
}

class _OnboardingOverlayState extends State<OnboardingOverlay> {
  OnboardingStep _currentStep = OnboardingStep.welcome;

  void _nextStep() {
    setState(() {
      final nextIndex = _currentStep.index + 1;
      if (nextIndex < OnboardingStep.values.length) {
        _currentStep = OnboardingStep.values[nextIndex];
      } else {
        widget.onFinish();
      }
    });
  }

  void _prevStep() {
    setState(() {
      final prevIndex = _currentStep.index - 1;
      if (prevIndex >= 0) {
        _currentStep = OnboardingStep.values[prevIndex];
      }
    });
  }

  // 각 단계별 설명 카드에 담길 타이틀과 메시지 정의
  Map<OnboardingStep, _StepContent> _getStepContent() {
    return {
      OnboardingStep.welcome: _StepContent(
        title: GameStrings.onboardingWelcomeTitle,
        description: GameStrings.onboardingWelcomeDesc,
      ),
      OnboardingStep.myLocation: _StepContent(
        title: GameStrings.onboardingMyLocationTitle,
        description: GameStrings.onboardingMyLocationDesc,
      ),
      OnboardingStep.goldBar: _StepContent(
        title: GameStrings.onboardingGoldTitle,
        description: GameStrings.onboardingGoldDesc,
      ),
      OnboardingStep.timerBar: _StepContent(
        title: GameStrings.onboardingTimerTitle,
        description: GameStrings.onboardingTimerDesc,
      ),
      OnboardingStep.stepsBar: _StepContent(
        title: GameStrings.onboardingStepsTitle,
        description: GameStrings.onboardingStepsDesc,
      ),
      OnboardingStep.patternBtn: _StepContent(
        title: GameStrings.onboardingPatternTitle,
        description: GameStrings.onboardingPatternDesc,
      ),
      OnboardingStep.achievementBtn: _StepContent(
        title: GameStrings.onboardingAchievementTitle,
        description: GameStrings.onboardingAchievementDesc,
      ),
      OnboardingStep.rankingBtn: _StepContent(
        title: GameStrings.onboardingRankingTitle,
        description: GameStrings.onboardingRankingDesc,
      ),
      OnboardingStep.profileBtn: _StepContent(
        title: GameStrings.onboardingProfileTitle,
        description: GameStrings.onboardingProfileDesc,
      ),
      OnboardingStep.hqBtn: _StepContent(
        title: GameStrings.onboardingHQTitle,
        description: GameStrings.onboardingHQDesc,
      ),
      OnboardingStep.photoBtn: _StepContent(
        title: GameStrings.onboardingPhotoTitle,
        description: GameStrings.onboardingPhotoDesc,
      ),
      OnboardingStep.mapFollowBtn: _StepContent(
        title: GameStrings.onboardingMapFollowTitle,
        description: GameStrings.onboardingMapFollowDesc,
      ),
      OnboardingStep.mapModeToggleBtn: _StepContent(
        title: GameStrings.onboardingMapModeToggleTitle,
        description: GameStrings.onboardingMapModeToggleDesc,
      ),
      OnboardingStep.mapStyleBtn: _StepContent(
        title: GameStrings.onboardingMapStyleTitle,
        description: GameStrings.onboardingMapStyleDesc,
      ),
      OnboardingStep.remoteInfo: _StepContent(
        title: GameStrings.onboardingRemoteTitle,
        description: GameStrings.onboardingRemoteDesc,
      ),
      OnboardingStep.complete: _StepContent(
        title: GameStrings.onboardingCompleteTitle,
        description: GameStrings.onboardingCompleteDesc,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    final double topOffset = topPadding > 0 ? topPadding + 12.0 : 24.0;
    final double bottomMargin = bottomPadding > 0 ? 16.0 : 32.0;
    final double baseBottomMargin = bottomMargin + bottomPadding;

    // 각 HUD 엘리먼트들의 화면 내 영역 계산 (구멍 뚫기 및 지시선 출발점 확보용)
    Rect targetRect = Rect.zero;
    Offset lineStart = Offset.zero;
    Offset lineEnd = Offset.zero;
    Offset lineControl = Offset.zero;

    // 설명 카드의 Y좌표 및 크기 레이아웃을 단계별 분기하여 겹침 방지 처리
    double cardTop = size.height * 0.35;
    double cardLeft = 24.0;
    double cardWidth = size.width - 48.0;

    // 1. 단계별 targetRect 및 안내 팝업 배치 고정 좌표 연산
    switch (_currentStep) {
      case OnboardingStep.welcome:
      case OnboardingStep.remoteInfo:
      case OnboardingStep.complete:
        // 화면 정중앙에 배치
        cardTop = (size.height - 200) / 2;
        break;

      case OnboardingStep.myLocation:
        // 화면 정중앙의 내 위치 표시 화살표 마커를 하이라이트
        targetRect = Rect.fromCircle(center: Offset(size.width / 2, size.height / 2), radius: 36.0);
        cardTop = size.height - baseBottomMargin - 240.0;

        lineStart = Offset(targetRect.left + targetRect.width / 2, targetRect.bottom + 4.0);
        lineEnd = Offset(lineStart.dx.clamp(40.0, size.width - 40.0), cardTop - 2.0);
        lineControl = Offset(lineStart.dx, lineEnd.dy - 30.0);
        break;

      case OnboardingStep.goldBar:
        targetRect = Rect.fromLTWH(20.0, topOffset + 3.0, 160.0, 38.0);
        cardTop = size.height - baseBottomMargin - 220.0; // 팝업 가림 방지를 위해 하단 배치

        lineStart = Offset(targetRect.left + targetRect.width / 2, targetRect.bottom + 4.0);
        lineEnd = Offset(lineStart.dx.clamp(40.0, size.width - 40.0), cardTop - 2.0);
        lineControl = Offset(lineStart.dx, lineEnd.dy - 30.0);
        break;

      case OnboardingStep.timerBar:
        targetRect = Rect.fromLTWH(20.0, topOffset + 47.0, 130.0, 38.0);
        cardTop = size.height - baseBottomMargin - 220.0;

        lineStart = Offset(targetRect.left + targetRect.width / 2, targetRect.bottom + 4.0);
        lineEnd = Offset(lineStart.dx.clamp(40.0, size.width - 40.0), cardTop - 2.0);
        lineControl = Offset(lineStart.dx, lineEnd.dy - 30.0);
        break;

      case OnboardingStep.stepsBar:
        targetRect = Rect.fromLTWH(20.0, topOffset + 91.0, 120.0, 38.0);
        cardTop = size.height - baseBottomMargin - 220.0;

        lineStart = Offset(targetRect.left + targetRect.width / 2, targetRect.bottom + 4.0);
        lineEnd = Offset(lineStart.dx.clamp(40.0, size.width - 40.0), cardTop - 2.0);
        lineControl = Offset(lineStart.dx, lineEnd.dy - 30.0);
        break;

      case OnboardingStep.patternBtn:
        targetRect = Rect.fromLTWH(size.width - 20.0 - 44.0 * 4 - 10.0 * 3, topOffset, 44.0, 44.0);
        cardTop = size.height - baseBottomMargin - 220.0;

        lineStart = Offset(targetRect.left + targetRect.width / 2, targetRect.bottom + 4.0);
        lineEnd = Offset(lineStart.dx.clamp(40.0, size.width - 40.0), cardTop - 2.0);
        lineControl = Offset(lineStart.dx, lineEnd.dy - 30.0);
        break;

      case OnboardingStep.achievementBtn:
        targetRect = Rect.fromLTWH(size.width - 20.0 - 44.0 * 3 - 10.0 * 2, topOffset, 44.0, 44.0);
        cardTop = size.height - baseBottomMargin - 220.0;

        lineStart = Offset(targetRect.left + targetRect.width / 2, targetRect.bottom + 4.0);
        lineEnd = Offset(lineStart.dx.clamp(40.0, size.width - 40.0), cardTop - 2.0);
        lineControl = Offset(lineStart.dx, lineEnd.dy - 30.0);
        break;

      case OnboardingStep.rankingBtn:
        targetRect = Rect.fromLTWH(size.width - 20.0 - 44.0 * 2 - 10.0, topOffset, 44.0, 44.0);
        cardTop = size.height - baseBottomMargin - 220.0;

        lineStart = Offset(targetRect.left + targetRect.width / 2, targetRect.bottom + 4.0);
        lineEnd = Offset(lineStart.dx.clamp(40.0, size.width - 40.0), cardTop - 2.0);
        lineControl = Offset(lineStart.dx, lineEnd.dy - 30.0);
        break;

      case OnboardingStep.profileBtn:
        targetRect = Rect.fromLTWH(size.width - 20.0 - 44.0, topOffset, 44.0, 44.0);
        cardTop = size.height - baseBottomMargin - 220.0;

        lineStart = Offset(targetRect.left + targetRect.width / 2, targetRect.bottom + 4.0);
        lineEnd = Offset(lineStart.dx.clamp(40.0, size.width - 40.0), cardTop - 2.0);
        lineControl = Offset(lineStart.dx, lineEnd.dy - 30.0);
        break;

      case OnboardingStep.hqBtn:
        targetRect = Rect.fromLTWH(20.0, size.height - baseBottomMargin - 17.0 - 42.0 * 2 - 10.0, 42.0, 42.0);
        cardTop = topOffset + 140.0;

        lineStart = Offset(targetRect.left + targetRect.width / 2, targetRect.top - 4.0);
        lineEnd = Offset(lineStart.dx.clamp(40.0, size.width - 40.0), cardTop + 160.0 + 2.0);
        lineControl = Offset(lineStart.dx, lineEnd.dy + 30.0);
        break;

      case OnboardingStep.photoBtn:
        targetRect = Rect.fromLTWH(20.0, size.height - baseBottomMargin - 17.0 - 42.0 * 3 - 20.0, 42.0, 42.0);
        cardTop = topOffset + 140.0;

        lineStart = Offset(targetRect.left + targetRect.width / 2, targetRect.top - 4.0);
        lineEnd = Offset(lineStart.dx.clamp(40.0, size.width - 40.0), cardTop + 160.0 + 2.0);
        lineControl = Offset(lineStart.dx, lineEnd.dy + 30.0);
        break;

      case OnboardingStep.mapFollowBtn:
        targetRect = Rect.fromLTWH(20.0, size.height - baseBottomMargin - 17.0 - 42.0, 42.0, 42.0);
        cardTop = topOffset + 140.0; // 팝업 가림 방지를 위해 상단 배치

        lineStart = Offset(targetRect.left + targetRect.width / 2, targetRect.top - 4.0);
        lineEnd = Offset(lineStart.dx.clamp(40.0, size.width - 40.0), cardTop + 160.0 + 2.0);
        lineControl = Offset(lineStart.dx, lineEnd.dy + 30.0);
        break;

      case OnboardingStep.mapModeToggleBtn:
        targetRect = Rect.fromLTWH(size.width - 20.0 - 44.0, size.height - baseBottomMargin - 16.0 - 44.0 * 2 - 10.0, 44.0, 44.0);
        cardTop = topOffset + 140.0;

        lineStart = Offset(targetRect.left + targetRect.width / 2, targetRect.top - 4.0);
        lineEnd = Offset(lineStart.dx.clamp(40.0, size.width - 40.0), cardTop + 160.0 + 2.0);
        lineControl = Offset(lineStart.dx, lineEnd.dy + 30.0);
        break;

      case OnboardingStep.mapStyleBtn:
        targetRect = Rect.fromLTWH(size.width - 20.0 - 44.0, size.height - baseBottomMargin - 16.0 - 44.0, 44.0, 44.0);
        cardTop = topOffset + 140.0;

        lineStart = Offset(targetRect.left + targetRect.width / 2, targetRect.top - 4.0);
        lineEnd = Offset(lineStart.dx.clamp(40.0, size.width - 40.0), cardTop + 160.0 + 2.0);
        lineControl = Offset(lineStart.dx, lineEnd.dy + 30.0);
        break;
    }

    final currentContent = _getStepContent()[_currentStep]!;

    return Stack(
      children: [
        // 1. 구멍 뚫린 반투명 백그라운드 페인터 + 지시선 그리기
        Positioned.fill(
          child: CustomPaint(
            painter: OnboardingOverlayPainter(
              targetRect: targetRect,
              step: _currentStep,
              lineStart: lineStart,
              lineEnd: lineEnd,
              lineControl: lineControl,
            ),
          ),
        ),

        // 2. 설명 안내 카드 UI
        Positioned(
          top: cardTop,
          left: cardLeft,
          width: cardWidth,
          child: Container(
            key: ValueKey(_currentStep),
            padding: const EdgeInsets.all(22),
            decoration: ShapeDecoration(
              color: GameColors.backgroundMedium.withValues(alpha: 0.92),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: GameColors.accentNeon.withValues(alpha: 0.4),
                  width: 1.2,
                ),
              ),
              shadows: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: _currentStep == OnboardingStep.welcome ||
                      _currentStep == OnboardingStep.remoteInfo ||
                      _currentStep == OnboardingStep.complete
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              children: [
                // 타이틀
                Text(
                  currentContent.title,
                  style: GoogleFonts.fredoka(
                    color: GameColors.accentNeon,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                  textAlign: _currentStep == OnboardingStep.welcome ||
                          _currentStep == OnboardingStep.remoteInfo ||
                          _currentStep == OnboardingStep.complete
                      ? TextAlign.center
                      : TextAlign.start,
                ),
                const SizedBox(height: 12),
                // 상세 설명
                Text(
                  currentContent.description,
                  style: GoogleFonts.quicksand(
                    color: GameColors.textSecondary,
                    fontSize: 13,
                    height: 1.5,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: _currentStep == OnboardingStep.welcome ||
                          _currentStep == OnboardingStep.remoteInfo ||
                          _currentStep == OnboardingStep.complete
                      ? TextAlign.center
                      : TextAlign.start,
                ),
                const SizedBox(height: 22),
                // 버튼 조작계
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 이전 단계 버튼 (웰컴일 땐 미표시)
                    _currentStep != OnboardingStep.welcome
                        ? OutlinedButton(
                            onPressed: _prevStep,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: GameColors.dividerColor.withValues(alpha: 0.3)),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              GameStrings.onboardingPrev,
                              style: GoogleFonts.fredoka(
                                color: GameColors.textMuted,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),

                    // 다음 / 완료 버튼
                    ElevatedButton(
                      onPressed: _nextStep,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GameColors.accentNeon,
                        foregroundColor: GameColors.tacticalBlack,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _currentStep == OnboardingStep.complete
                            ? GameStrings.onboardingStart
                            : GameStrings.onboardingNext,
                        style: GoogleFonts.fredoka(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// 온보딩 오버레이 백그라운드 구멍(하이라이트) 뚫기 및 지시선(Line) 렌더링용 CustomPainter
class OnboardingOverlayPainter extends CustomPainter {
  final Rect targetRect;
  final OnboardingStep step;
  final Offset lineStart;
  final Offset lineEnd;
  final Offset lineControl;

  OnboardingOverlayPainter({
    required this.targetRect,
    required this.step,
    required this.lineStart,
    required this.lineEnd,
    required this.lineControl,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. 반투명 배경 검은색 마스킹 렌더링
    final backgroundPaint = Paint()..color = Colors.black.withValues(alpha: 0.85);
    final backgroundPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    Path targetPath = Path();
    if (step != OnboardingStep.welcome &&
        step != OnboardingStep.remoteInfo &&
        step != OnboardingStep.complete) {
      if (step == OnboardingStep.myLocation) {
        // 원형 하이라이팅
        targetPath.addOval(targetRect.inflate(6.0));
      } else {
        // 타겟 영역 주위로 약간의 패딩(inflate)을 추가하고 둥근 헥사/박스형 하이라이팅 구멍 생성
        targetPath.addRRect(
          RRect.fromRectAndRadius(targetRect.inflate(6.0), const Radius.circular(14)),
        );
      }
    }

    final finalPath = Path.combine(PathOperation.difference, backgroundPath, targetPath);
    canvas.drawPath(finalPath, backgroundPaint);

    // 2. 가이딩 꺾은선 (지시선) 및 시작점 도트(Dot) 그리기
    if (step != OnboardingStep.welcome &&
        step != OnboardingStep.remoteInfo &&
        step != OnboardingStep.complete) {
      final linePaint = Paint()
        ..color = GameColors.accentNeon // 네온 민트/네온 시안
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8;

      final dotPaint = Paint()
        ..color = GameColors.accentNeon
        ..style = PaintingStyle.fill;

      // 꺾은선 그리기 (Bézier Curve)
      final path = Path()
        ..moveTo(lineStart.dx, lineStart.dy)
        ..quadraticBezierTo(lineControl.dx, lineControl.dy, lineEnd.dx, lineEnd.dy);

      canvas.drawPath(path, linePaint);
      
      // 출발점과 끝점에 하이테크 스타일 도트 원 렌더링
      canvas.drawCircle(lineStart, 4.0, dotPaint);
      canvas.drawCircle(lineEnd, 2.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant OnboardingOverlayPainter oldDelegate) {
    return oldDelegate.targetRect != targetRect ||
        oldDelegate.step != step ||
        oldDelegate.lineStart != lineStart ||
        oldDelegate.lineEnd != lineEnd ||
        oldDelegate.lineControl != lineControl;
  }
}

class _StepContent {
  final String title;
  final String description;

  _StepContent({required this.title, required this.description});
}
