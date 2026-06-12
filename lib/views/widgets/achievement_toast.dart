import 'dart:async';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../models/achievement_model.dart';

/// 업적 해금 시 화면 상단에 표시되는 3D 네온 플로팅 토스트 연출 위젯
class AchievementToast extends StatefulWidget {
  final Achievement achievement;
  final VoidCallback onDismiss;

  /// AchievementToast 생성자
  const AchievementToast({
    super.key,
    required this.achievement,
    required this.onDismiss,
  });

  @override
  State<AchievementToast> createState() => _AchievementToastState();

  /// 오버레이 상에 토스트를 직접 바인딩하여 띄워주는 정적 헬퍼 메소드
  static void show(BuildContext context, Achievement achievement) {
    final overlayState = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 16,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: AchievementToast(
            achievement: achievement,
            onDismiss: () {
              overlayEntry.remove();
            },
          ),
        ),
      ),
    );

    overlayState.insert(overlayEntry);
  }
}

class _AchievementToastState extends State<AchievementToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _yTranslationAnimation;
  late final Animation<double> _opacityAnimation;
  late final Animation<double> _scaleAnimation;

  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _yTranslationAnimation = Tween<double>(begin: -80, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const ElasticOutCurve(0.8),
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const ElasticOutCurve(0.8),
      ),
    );

    _controller.forward();

    // 3.5초 뒤에 사라짐
    _dismissTimer = Timer(const Duration(milliseconds: 3500), () {
      if (mounted) {
        _controller.reverse().then((_) {
          widget.onDismiss();
        });
      }
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tierColor = _getTierColor(widget.achievement.tier);
    final icon = _getCategoryIcon(widget.achievement.category);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _yTranslationAnimation.value),
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: child,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          // 어두운 보드 패널과 반투명 아크릴 느낌
          color: const Color(0xFF0F1626).withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: tierColor,
            width: 2.0,
          ),
          boxShadow: [
            // 3D 네온 글로우 효과
            BoxShadow(
              color: tierColor.withValues(alpha: 0.35),
              blurRadius: 15,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
            // 내부 입체감 쉐도우
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 10,
              spreadRadius: -2,
            )
          ],
        ),
        child: Row(
          children: [
            // 글로우 베이스의 뱃지 구역
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: tierColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(color: tierColor.withValues(alpha: 0.5), width: 1.5),
              ),
              child: Center(
                child: Icon(
                  icon,
                  color: tierColor,
                  size: 26,
                ),
              ),
            ),
            const SizedBox(width: 14),
            // 명칭 및 설명 텍스트
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '🏆 업적 달성',
                    style: TextStyle(
                      color: Color(0xFF00FFCC), // 네온 민트
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      fontFamily: 'Orbit',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tr(widget.achievement.titleKey),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    tr(widget.achievement.descriptionKey),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // 우측의 티어 표기 배지
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: tierColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: tierColor.withValues(alpha: 0.3), width: 1),
              ),
              child: Text(
                'TIER ${widget.achievement.tier}',
                style: TextStyle(
                  color: tierColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Orbit',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getTierColor(int tier) {
    switch (tier) {
      case 1:
        return const Color(0xFFCD7F32); // 브론즈
      case 2:
        return const Color(0xFFC0C0C0); // 실버
      case 3:
        return const Color(0xFFFFD700); // 골드
      case 4:
        return const Color(0xFF00E5FF); // 다이아몬드/플래티넘 네온 민트
      default:
        return Colors.white70;
    }
  }

  IconData _getCategoryIcon(AchievementCategory cat) {
    switch (cat) {
      case AchievementCategory.capturedTiles:
        return Icons.map;
      case AchievementCategory.enemyCapturedTiles:
        return Icons.flash_on;
      case AchievementCategory.totalMovedTiles:
        return Icons.directions_walk;
      case AchievementCategory.dailyMovedTiles:
        return Icons.today;
      case AchievementCategory.satelliteCapture:
        return Icons.satellite_alt;
      case AchievementCategory.satelliteInfo:
        return Icons.radar;
      case AchievementCategory.hqFortification:
        return Icons.security;
      case AchievementCategory.goldAmount:
        return Icons.monetization_on;
      case AchievementCategory.mainBaseMove:
        return Icons.home;
    }
  }
}
