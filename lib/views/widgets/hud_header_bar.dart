import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';
import '../../providers/game_provider.dart';

/// [상단] '솜사탕 올인원' 정보 캡슐 바 (오직 순수 GP 보유량만 극극 미니멀 노출)
class CozyHeaderBar extends StatelessWidget {
  const CozyHeaderBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<GameProvider, double>(
      selector: (_, provider) => provider.currentGold,
      builder: (context, gold, child) {
        return Container(
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
                color: Color(0xFF00E5FF),
                size: 18.0,
              ),
              const SizedBox(width: 6),
              Text(
                gold.toStringAsFixed(0),
                style: GoogleFonts.fredoka(
                  color: GameColors.textPrimary,
                  fontSize: 12.5,
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
