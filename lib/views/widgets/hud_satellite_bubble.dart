import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/strings.dart';
import '../../providers/game_provider.dart';
import '../../providers/auth_provider.dart';
import 'satellite_bubble_card.dart';

/// 선택된 위성 조준 타일 위에 실시간으로 위치가 갱신되는 말풍선 위젯.
class SatelliteMapBubble extends StatefulWidget {
  const SatelliteMapBubble({super.key});

  @override
  State<SatelliteMapBubble> createState() => SatelliteMapBubbleState();
}

/// [SatelliteMapBubble]의 주기적 화면 갱신을 담당하는 상태 클래스
class SatelliteMapBubbleState extends State<SatelliteMapBubble> {
  /// 1초 단위로 상태 정보(쿨타임/시간)를 동기화 갱신하기 위한 타이머
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      return const SizedBox.shrink();
    }

    final game = context.read<GameProvider>();
    final tileLatLng = game.selectedScanTileLatLng;
    final selectedId = game.selectedScanTileId;

    if (tileLatLng == null || selectedId == null) {
      return const SizedBox.shrink();
    }
    final bool isCapturing =
        game.isSatelliteCapturing &&
        game.satelliteCapturingTileId == selectedId;

    // --- All-In-One 타일 기본 정보 파싱 ---
    final parts = selectedId.split('_');
    final int q = parts.length == 3 ? (int.tryParse(parts[1]) ?? 0) : 0;
    final int r = parts.length == 3 ? (int.tryParse(parts[2]) ?? 0) : 0;

    final existingTile = game.capturedTiles[selectedId];
    final int captureCount = existingTile?.captureCount ?? 0;
    final bool isShieldActive = existingTile?.isShieldActive ?? false;
    final DateTime? shieldExpiration = existingTile?.shieldExpiration;

    // 내 소유 및 빈 타일 판별
    final myId = auth.user?.id;
    final String myNickname = auth.profile?.nickname ?? '';
    final bool isMine = existingTile != null && existingTile.userId == myId;
    final bool isTileEmpty =
        existingTile == null ||
        existingTile.userId == null ||
        existingTile.userId == 'none';

    // 연결망 판단 (내가 소유한 구역이거나, 본진에서부터 유효한 BFS 연결망이 닿는 경우 true)
    final bool isConnected = isMine || game.checkSatelliteCaptureConnectivity(selectedId);

    // --- 보안 판독(Reveal) 권한 조회 ---
    // 만약 타인 영토인데 연결망마저 끊어졌다면, 무조건 보안 해제 상태를 false로 잠금
    final bool isRevealed = isMine ? true : (isConnected && game.isTileInfoRevealed(selectedId));
    void onRevealPressed() => game.revealTileInfo(selectedId);

    final String? ownerId =
        (existingTile != null && existingTile.userId != 'none' && (isMine || isConnected))
        ? existingTile.userId
        : null;
    final Future<String>? nicknameFuture = ownerId != null
        ? game.getAgentNickname(ownerId)
        : null;

    // --- 상태 계산 ---
    Color themeColor = GameColors.accentNeon;
    bool isError = false;
    bool isCooltime = false;
    String detailsText = GameStrings.satScanActive;
    String? distanceStr;
    String? timeStr;
    bool showActionButton = false;
    String actionButtonText = '';
    VoidCallback? onActionPressed;
    List<Color> buttonGradient = [
      const Color(0xFF00E5FF),
      const Color(0xFF00838F),
    ];

    if (isCapturing) {
      final remainingSec = game.remainingSatelliteCaptureSeconds;
      themeColor = const Color(0xFFFF5252);
      detailsText = GameStrings.satCapturingAttempt;
      timeStr = GameStrings.secondsUnit(remainingSec.toString());
      showActionButton = true;
      actionButtonText = GameStrings.cancel;
      buttonGradient = [const Color(0xFFFF5252), const Color(0xFFC62828)];
      onActionPressed = game.cancelSatelliteCapture;
    } else {
      if (isTileEmpty) {
        final satCooltime = game.remainingSatelliteCaptureCoolSeconds;

        if (satCooltime > 0) {
          final minutes = satCooltime ~/ 60;
          final seconds = satCooltime % 60;
          themeColor = const Color(0xFFFF9900);
          isCooltime = true;
          detailsText = GameStrings.satCooltimeWaitingLabel;
          timeStr =
              '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
        } else if (!isConnected) {
          themeColor = GameColors.error;
          isError = true;
          detailsText = GameStrings.satDisconnectedLabel;
        } else {
          final durationSec = game.getSatelliteCaptureDurationSeconds(
            selectedId,
          );
          detailsText = GameStrings.satLockOnReady;
          final distance = game.getTileDistance(selectedId);
          distanceStr = '\$ $distance';

          // 위성 점령 소모 재화(골드) 부족 여부 검증
          final double currentGold = game.currentGold;
          if (currentGold < distance) {
            themeColor = GameColors.error;
            isError = true;
            detailsText = GameStrings.satGoldShortage;
          } else {
            showActionButton = true;
            actionButtonText = GameStrings.satCaptureAction;
            buttonGradient = [const Color(0xFF00E5FF), const Color(0xFF00838F)];
            onActionPressed = () => game.executeSatelliteCapture(selectedId);
          }
          timeStr = GameStrings.secondsUnit(durationSec.toString());
        }
      } else {
        // 기존 점령지가 존재할 때
        if (isMine) {
          themeColor = GameColors.accentNeon;
          isError = false;
          detailsText = GameStrings.satAlreadyCapturedByMe(myNickname);
          showActionButton = false;
        } else {
          // 상대 타일인 경우
          if (!isConnected) {
            themeColor = GameColors.error;
            isError = true;
            detailsText = GameStrings.satDisconnectedLabel;
            showActionButton = false; // 엿보기 버튼 원천 차단
          } else {
            themeColor = GameColors.error;
            isError = true;
            detailsText = GameStrings.satOtherPlayerTerritory;

            // 상대 타일이고 보안 판독 전인 경우 -> [동네 엿보기] 유료 버튼 바인딩
            if (!isRevealed) {
              themeColor = const Color(0xFFFF7700);
              final dist = game.getTileDistance(selectedId);
              showActionButton = true;
              actionButtonText = GameStrings.satRevealVillageWithGp(
                dist.toString(),
              );
              buttonGradient = [const Color(0xFFFF8800), const Color(0xFFE65100)];
              onActionPressed = onRevealPressed;
            }
          }
        }
      }
    }

    final DateTime? revealExpiration = game.getTileRevealExpiration(selectedId);

    return SizedBox(
      width: 240.0,
      child: BubbleBody(
        themeColor: themeColor,
        isError: isError,
        isCooltime: isCooltime,
        detailsText: detailsText,
        distanceStr: distanceStr,
        timeStr: timeStr,
        showActionButton: showActionButton,
        actionButtonText: actionButtonText,
        onActionPressed: onActionPressed,
        buttonGradient: buttonGradient,
        onClosePressed: () => game.selectScanTile(selectedId), // 닫기 제스처 콜백
        q: q,
        r: r,
        captureCount: captureCount,
        isShieldActive: isShieldActive,
        shieldExpiration: shieldExpiration,
        agentNicknameFuture: nicknameFuture,
        isRevealed: isRevealed,
        onRevealPressed: onRevealPressed,
        revealExpiration: revealExpiration,
        isMine: isMine,
        myNickname: myNickname,
      ),
    );
  }
}


