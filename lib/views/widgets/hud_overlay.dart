import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/game_provider.dart';
import '../../providers/auth_provider.dart';
import 'hud_header_bar.dart';
import 'hud_profile_button.dart';
import 'hud_ranking_button.dart';
import 'hud_achievement_button.dart';
import 'hud_map_cycle_button.dart';
import 'hud_map_follow_button.dart';
import 'hud_satellite_bubble.dart';

/// 인게임 HUD 오버레이 (점수판, 점령 버튼, 유틸리티 버튼, 위성 스캔 연동)
class HudOverlay extends StatelessWidget {
  const HudOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.read<GameProvider>();
    final auth = context.read<AuthProvider>();

    // 기기별 상하단 안전 영역 높이 자동 산출
    final double topPadding = MediaQuery.of(context).padding.top;
    final double bottomPadding = MediaQuery.of(context).padding.bottom;

    // Y축 정밀 오프셋 연산
    final double topOffset = topPadding > 0 ? topPadding + 12.0 : 24.0;

    // 여백 조율을 위한 기본 하단 마진
    final double baseBottomMargin = bottomPadding > 0 ? 16.0 : 32.0;

    return Stack(
      children: [
        const SizedBox.expand(),

        // [상단 좌측] 정밀 대칭 배치된 골드 캡슐 정보 바 (아바타 버튼과 시각적 중심 정렬 보정)
        Positioned(
          top: topOffset + 3.0,
          left: 20.0,
          child: const CozyHeaderBar(),
        ),

        // [상단 우측 - 업적 버튼] 랭킹 버튼 왼쪽에 1:1 대칭 정렬 나란히 배치 (44x44)
        Positioned(
          top: topOffset,
          right: 20.0 + 44.0 + 10.0 + 44.0 + 10.0, // 프로필 44 + 랭킹 44 + 여백 20 오프셋 연산
          child: const AchievementActionButton(size: 44),
        ),

        // [상단 우측 - 랭킹 버튼] 유저 프로필 버튼 바로 왼쪽에 1:1 대칭 정렬 나란히 배치 (44x44)
        Positioned(
          top: topOffset,
          right: 20.0 + 44.0 + 10.0, // 프로필 단추 너비 44 + 여백 10 오프셋 연산
          child: const RankingActionButton(size: 44),
        ),

        // [상단 우측 - 프로필 버튼] 독립 배치된 내 정보 아바타 버튼 (44x44)
        Positioned(
          top: topOffset,
          right: 20.0,
          child: ProfileFloatingButton(auth: auth),
        ),

        // [하단 좌측] 독립 배치된 내 위치 / 맵 회전 토글 버튼 (42x42)
        Positioned(
          bottom: baseBottomMargin + bottomPadding + 17.0,
          left: 20.0,
          child: const MapFollowRotationButton(size: 42, iconSize: 20),
        ),

        // [하단 중앙] 콤팩트해진 점령 조작 버튼 (항상 자동 기동되므로 버튼 미노출)
        const SizedBox.shrink(),

        // [하단 우측 - 테마 순환 버튼] 접이식 메뉴를 걷어내고 기존 메뉴 버튼 자리에 독립형 젤리 단추로 배치 (44x44)
        Positioned(
          bottom: baseBottomMargin + bottomPadding + 16.0,
          right: 20.0, // 기존 기어 트리거 메뉴 버튼 자리에 완벽 대칭 배치
          child: MapStyleCycleButton(game: game, size: 44, iconSize: 22),
        ),

        // [위성 스캔 팝업 레이어] 스캔 모드 여부 변동 시에만 리빌드 격리
        Selector<GameProvider, bool>(
          selector: (_, p) => p.isScanMode,
          builder: (context, isScanMode, child) {
            return Positioned(
              bottom: 90 + baseBottomMargin + bottomPadding,
              left: 0,
              right: 0,
              child: IgnorePointer(
                ignoring: !isScanMode,
                child: Center(
                  child: AnimatedOpacity(
                    opacity: isScanMode ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: isScanMode
                        ? const SatelliteMapBubble()
                        : const SizedBox.shrink(),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
