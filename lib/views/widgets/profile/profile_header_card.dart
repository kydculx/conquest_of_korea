import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/strings.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/game_provider.dart';
import '../profile_widgets.dart';

/// 프로필 화면 상단 카드: 아이콘, 닉네임(수정 버튼), 이메일, 점령 타일 수를 표시합니다.
class ProfileHeaderCard extends StatelessWidget {
  final AuthProvider auth;
  final GameProvider game;
  final VoidCallback onEditNickname;

  const ProfileHeaderCard({
    required this.auth,
    required this.game,
    required this.onEditNickname,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final profile = auth.profile!;
    final user = auth.user;
    final teamColor = GameColors.myTileColor;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: ShapeDecoration(
        color: GameColors.backgroundMedium.withValues(alpha: 0.85),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: GameColors.accentNeon.withValues(alpha: 0.25),
            width: 1.2,
          ),
        ),
        shadows: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            spreadRadius: 1,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: ShapeDecoration(
              color: teamColor.withValues(alpha: 0.15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: teamColor, width: 2.0),
              ),
            ),
            child: Center(
              child: Icon(Icons.person, size: 40, color: teamColor),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                profile.nickname,
                style: GoogleFonts.fredoka(
                  color: GameColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onEditNickname,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.edit_rounded,
                    size: 16,
                    color: GameColors.accentNeon,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            user?.email ?? '',
            style: GoogleFonts.quicksand(
              color: GameColors.textMuted,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ProfileStatItem(
                label: GameStrings.capturedTiles,
                value: '${game.myCapturedCount}${GameStrings.countUnit}',
                color: GameColors.accentNeon,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
