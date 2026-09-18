import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/strings.dart';
import '../../providers/game_provider.dart';
import '../../services/health_service.dart';

/// [상단] '솜사탕 올인원' 정보 캡슐 바 (오직 순수 GP 보유량만 극극 미니멀 노출)
class CozyHeaderBar extends StatelessWidget {
  const CozyHeaderBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<GameProvider, double>(
      selector: (_, provider) => provider.currentGold,
      builder: (context, gold, child) {
        return GestureDetector(
          onTapUp: (_) => debugPrint('🧪 gold capsule tapped'),
          child: Container(
            height: 38,
          padding: const EdgeInsets.only(
            left: 10,
            right: 16,
            top: 2,
            bottom: 2,
          ),
          decoration: ShapeDecoration(
            color: GameColors.backgroundMedium.withValues(alpha: 0.92),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: const Color(
                  0xFF00E5FF,
                ).withValues(alpha: 0.25), // 시스템 시그니처 시안 보더
                width: 1.2,
              ),
            ),
            shadows: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 3D 보석 느낌의 입체 사이버 시안 코인 엠블럼
              const Icon(
                Icons.monetization_on_rounded,
                color: Palette.accentCyan,
                size: 18.0,
              ),
              const SizedBox(width: 6),
              Text(
                gold.toInt().toString(),
                style: GoogleFonts.fredoka(
                  color: GameColors.textPrimary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.4,
                ),
              ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// [상단] UTC 자정(00시) 리셋까지 남은 시간을 초 단위로 실시간 카운트다운하는 타이머 캡슐 바
class UtcTimerHeaderBar extends StatelessWidget {
  const UtcTimerHeaderBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<GameProvider, String>(
      selector: (_, provider) => provider.utcTimeString,
      builder: (context, utcTimeString, _) {
        return Container(
          height: 38,
          padding: const EdgeInsets.only(
            left: 10,
            right: 14,
            top: 2,
            bottom: 2,
          ),
          decoration: ShapeDecoration(
            color: GameColors.backgroundMedium.withValues(alpha: 0.92),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: Palette.orangeSunset.withValues(alpha: 0.25), // 리셋 마감 임박을 뜻하는 비비드 오렌지/앰버 네온 보더
                width: 1.2,
              ),
            ),
            shadows: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 회수/대기 시간을 연출하는 정밀 시계 토글 아이콘
              const Icon(
                Icons.history_toggle_off_rounded,
                color: Palette.orangeSunset,
                size: 18.0,
              ),
              const SizedBox(width: 6),
              Text(
                utcTimeString,
                style: GoogleFonts.fredoka(
                  color: GameColors.textPrimary,
                  fontSize: 12.0,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

  /// [상단] 오늘의 실시간 걸음수를 표시하는 캡슐 바 (에메랄드 그린 테마)
  /// 미연동 시 버튼 형태로 연동 안내 표시, 탭하면 시스템 설정으로 이동
  /// (복귀 시 거부 확정 해제 + 재확인 자동 수행)
  class StepsHeaderBar extends StatelessWidget {
    const StepsHeaderBar({super.key});

    Widget _capsule(BuildContext context, String text, bool denied) {
      return Container(
        height: 38,
        padding: const EdgeInsets.only(
          left: 10,
          right: 14,
          top: 2,
          bottom: 2,
        ),
        decoration: ShapeDecoration(
          color: GameColors.backgroundMedium.withValues(alpha: 0.92),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: Palette.neonGreen.withValues(alpha: 0.25), // 에메랄드 그린 보더
              width: 1.2,
            ),
          ),
          shadows: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              Icons.directions_run_rounded,
              color: Palette.neonGreen,
              size: 18.0,
            ),
            const SizedBox(width: 6),
            Text(
              text,
              style: GoogleFonts.fredoka(
                color: GameColors.textPrimary,
                fontSize: 12.0,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.4,
              ),
            ),
            if (denied) ...[
              const SizedBox(width: 4),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Palette.neonGreen,
                size: 12.0,
              ),
            ],
          ],
        ),
      );
    }

    Future<void> _onLinkTap(BuildContext context) async {
      try {
        final opened = await HealthService.instance.openHealthSettings();
        if (!context.mounted) return;
        if (!opened) {
          // 설정 화면 열기 실패 시 직접 권한 요청으로 폴백
          await context.read<GameProvider>().retryStepPermissions();
        }
      } catch (e) {
        debugPrint('⚠️ steps link tap error: $e');
        if (context.mounted) {
          await context.read<GameProvider>().retryStepPermissions();
        }
      }
    }

    @override
    Widget build(BuildContext context) {
      return Selector<GameProvider, bool>(
        selector: (_, provider) => provider.isStepDenied,
        builder: (context, denied, _) {
          if (!denied) {
            return Selector<GameProvider, String>(
              selector: (context, provider) {
                // context.locale을 명시적으로 호출하여 언어 변경 시 Selector가 다시 평가되도록 함
                final _ = context.locale;
                return GameStrings.stepsCount(provider.todaySteps);
              },
              builder: (context, text, _) => _capsule(context, text, false),
            );
          }
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _onLinkTap(context),
            child: _capsule(context, GameStrings.linkHealthApp, true),
          );
        },
      );
    }
  }
