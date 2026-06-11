import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/strings.dart';

/// 위성 조준 타일 정보 말풍선 본체 위젯 (Cozy 버블 테두리 + BackdropBlur 배경)
class BubbleBody extends StatefulWidget {
  final Color themeColor;
  final bool isError;
  final bool isCooltime;
  final String detailsText;
  final String? distanceStr;
  final String? timeStr;
  final bool showActionButton;
  final String actionButtonText;
  final VoidCallback? onActionPressed;
  final List<Color> buttonGradient;
  final VoidCallback onClosePressed;

  // All-in-One 신규 확장 필드
  final int q;
  final int r;
  final int captureCount;
  final bool isShieldActive;
  final DateTime? shieldExpiration;
  final Future<String>? agentNicknameFuture;
  final bool isRevealed;
  final VoidCallback? onRevealPressed;
  final DateTime? revealExpiration;
  final bool isMine;
  final String myNickname;

  const BubbleBody({super.key,
    required this.themeColor,
    required this.isError,
    required this.isCooltime,
    required this.detailsText,
    this.distanceStr,
    this.timeStr,
    required this.showActionButton,
    required this.actionButtonText,
    this.onActionPressed,
    required this.buttonGradient,
    required this.onClosePressed,
    required this.q,
    required this.r,
    required this.captureCount,
    required this.isShieldActive,
    this.shieldExpiration,
    this.agentNicknameFuture,
    required this.isRevealed,
    this.onRevealPressed,
    this.revealExpiration,
    required this.isMine,
    required this.myNickname,
  });

  @override
  State<BubbleBody> createState() => BubbleBodyState();
}

class BubbleBodyState extends State<BubbleBody> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: ShapeBorderClipper(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: ShapeDecoration(
            color: GameColors.backgroundMedium.withValues(alpha: 0.9),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: widget.themeColor.withValues(alpha: 0.6),
                width: 1.5,
              ),
            ),
          ),
          child: Stack(
            children: [
              // 메인 정보 카드 텍스트 & 버튼들
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 상태 텍스트
                  Row(
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        margin: const EdgeInsets.only(right: 6, top: 1),
                        decoration: BoxDecoration(
                          color: GameColors.textPrimary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Expanded(
                        child: _buildDetailsText(context),
                      ),
                      const SizedBox(width: 20), // 우측 닫기(X) 버튼 영역 겹침 방지 여백 강제 확보
                    ],
                  ),
                  // [신규] All-in-One 타일 상세 정보 그리드 패널 (보안 해제 상태 연동)
                  const SizedBox(height: 8),
                  if (widget.isRevealed) ...[
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        // 📍 좌표 칩
                        _buildMiniBadge(
                          '${GameStrings.hudCoordinateLabel}: ${widget.q}, ${widget.r}',
                          const Color(0xFF00E5FF),
                        ),
                        // 🔥 점령 빈도 칩
                        _buildMiniBadge(
                          GameStrings.satCaptureCount(
                            widget.captureCount.toString(),
                          ),
                          const Color(0xFFFF9900),
                        ),
                        // 🛡️ 쉴드 활성 칩 (활성화 시에만 노출)
                        if (widget.isShieldActive &&
                            widget.shieldExpiration != null) ...[
                          (() {
                            final diff = widget.shieldExpiration!
                                .difference(DateTime.now().toUtc())
                                .inSeconds;
                            if (diff > 0) {
                              final m = diff ~/ 60;
                              final s = diff % 60;
                              final timeStr =
                                  '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
                              return _buildMiniBadge(
                                GameStrings.satShieldWithTime(timeStr),
                                const Color(0xFF4CAF50),
                              );
                            }
                            return const SizedBox.shrink();
                          })(),
                        ],
                        // ⏳ 엿보기 만료 칩 (10분 시간제 해제 타이머 연동)
                        if (widget.revealExpiration != null) ...[
                          (() {
                            final diff = widget.revealExpiration!
                                .difference(DateTime.now().toUtc())
                                .inSeconds;
                            if (diff > 0) {
                              final m = diff ~/ 60;
                              final s = diff % 60;
                              final timeStr =
                                  '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
                              return _buildMiniBadge(
                                GameStrings.satPeekTimeWithTime(timeStr),
                                const Color(0xFFFFD54F),
                              );
                            }
                            return const SizedBox.shrink();
                          })(),
                        ],
                      ],
                    ),
                    // 필요재화 / 소요시간 배지
                    if (widget.distanceStr != null ||
                        widget.timeStr != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.distanceStr != null) ...[
                            _buildBadge(
                              GameStrings.satRequiredGold,
                              widget.distanceStr!,
                              widget.themeColor,
                              isGold: true,
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (widget.timeStr != null)
                            _buildBadge(
                              widget.isCooltime
                                  ? GameStrings.satCooltimeWaitingText
                                  : GameStrings.satRequiredTime,
                              widget.timeStr!,
                              widget.themeColor,
                            ),
                        ],
                      ),
                    ],
                  ] else ...[
                    // 🔒 보안 잠금 칩 -> 귀여운 아기자기한 비밀 은폐로 개조
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _buildMiniBadge(
                          GameStrings.satSecretArea,
                          const Color(0xFFFF5252),
                        ),
                        _buildMiniBadge(
                          GameStrings.satSecretHidden,
                          const Color(0xFFFF5252),
                        ),
                      ],
                    ),
                  ],
                  // 하단 전술 행동 버튼 (All-In-One 통합)
                  if (widget.showActionButton &&
                      widget.onActionPressed != null) ...[
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTapDown: (_) => setState(() => _isPressed = true),
                      onTapUp: (_) {
                        setState(() => _isPressed = false);
                        widget.onActionPressed!();
                      },
                      onTapCancel: () => setState(() => _isPressed = false),
                      child: AnimatedScale(
                        scale: _isPressed ? 0.96 : 1.0,
                        duration: const Duration(milliseconds: 100),
                        child: Container(
                          width: double.infinity,
                          height: 38,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: widget.buttonGradient,
                            ),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25),
                              width: 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: widget.themeColor.withValues(alpha: 0.3),
                                blurRadius: 8.0,
                                spreadRadius: 0.5,
                              ),
                            ],
                          ),
                          child: Center(
                            child: _buildButtonContent(widget.actionButtonText),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),

              // 우상단 정밀 닫기(X) 제스처 버튼 (All-In-One 카드 전용)
              Positioned(
                top: -6,
                right: -6,
                child: GestureDetector(
                  onTap: widget.onClosePressed,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.transparent,
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      color: GameColors.textSecondary.withValues(alpha: 0.7),
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButtonContent(String text) {
    if (text.contains('\$')) {
      final parts = text.split('\$');
      if (parts.length == 2) {
        final prefix = parts[0].trim();
        final suffix = parts[1].replaceAll(')', '').trim();
        return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              prefix,
              style: GoogleFonts.fredoka(
                color: Colors.white,
                fontSize: 12.0,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.monetization_on_rounded,
              color: Color(0xFF00E5FF),
              size: 14.0,
            ),
            const SizedBox(width: 2),
            Text(
              suffix,
              style: GoogleFonts.fredoka(
                color: const Color(0xFF00E5FF),
                fontSize: 12.0,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              ')',
              style: GoogleFonts.fredoka(
                color: Colors.white,
                fontSize: 12.0,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        );
      }
    }

    return Text(
      text,
      style: GoogleFonts.fredoka(
        color: Colors.white,
        fontSize: 12.0,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildMiniBadge(String text, Color color) {
    // ':' 구분자를 기준으로 제목과 값을 파싱하여 제목은 보통체, 값은 굵고 고유 색상으로 분리 렌더링
    final parts = text.split(':');
    final String label;
    final String? value;
    if (parts.length >= 2) {
      label = parts[0].trim();
      value = parts.sublist(1).join(':').trim();
    } else {
      label = text;
      value = null;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            value != null ? '$label: ' : label,
            style: GoogleFonts.quicksand(
              color: GameColors.textSecondary,
              fontSize: 9,
              fontWeight: FontWeight.w500, // 보통 글씨체
            ),
          ),
          if (value != null)
            Text(
              value,
              style: GoogleFonts.quicksand(
                color: color, // 값은 굵고 고유 색상있게
                fontSize: 9.5,
                fontWeight: FontWeight.w900,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBadge(
    String label,
    String value,
    Color color, {
    bool isGold = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.30), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.quicksand(
              color: GameColors.textSecondary,
              fontSize: 9,
              fontWeight: FontWeight.w500, // 제목은 보통 글씨체
            ),
          ),
          // 아이콘은 전부 제거하라는 지시에 의해 Gold 동전 아이콘 렌더링 비활성화
          Text(
            isGold ? value.replaceAll(RegExp(r'[\$\s]'), '') : value,
            style: GoogleFonts.quicksand(
              color: isGold ? const Color(0xFF00E5FF) : color, // 값은 굵고 고유 색상있게
              fontSize: 9.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  /// 닉네임과 테마색/타일색을 연동하여 '누구 님의 구역입니다.' 형태의 미려한 RichText 및 일반 상태 텍스트를 분기 렌더링합니다.
  Widget _buildDetailsText(BuildContext context) {
    final defaultStyle = GoogleFonts.fredoka(
      color: GameColors.textPrimary,
      fontSize: 11.5,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.4,
    );

    // 1. 본인 소유의 타일인 경우 -> 동기적으로 내 닉네임을 내 타일 테마색(GameColors.myTileColor)으로 물들여 표시
    if (widget.isMine) {
      final nameColor = GameColors.myTileColor;
      return RichText(
        text: TextSpan(
          style: defaultStyle,
          children: [
            TextSpan(
              text: widget.myNickname,
              style: TextStyle(color: nameColor),
            ),
            const TextSpan(text: ' 님의 구역입니다.'),
          ],
        ),
      );
    }

    // 2. 다른 플레이어 소유이고 상세 엿보기가 활성화된 경우 -> 비동기적으로 상대 닉네임을 상대 테마색(widget.themeColor)으로 물들여 표시
    if (!widget.isMine && widget.isRevealed && widget.agentNicknameFuture != null) {
      final nameColor = widget.themeColor;
      return FutureBuilder<String>(
        future: widget.agentNicknameFuture,
        builder: (context, snapshot) {
          final nickname = snapshot.data ?? '...';
          return RichText(
            text: TextSpan(
              style: defaultStyle,
              children: [
                TextSpan(
                  text: nickname,
                  style: TextStyle(color: nameColor),
                ),
                const TextSpan(text: ' 님의 구역입니다.'),
              ],
            ),
          );
        },
      );
    }

    // 3. 그 외 일반 정보 상태 (중립지, 정보 가림 상태, 통신 해제 등) -> 기본 detailsText 일반 출력
    return Text(
      widget.detailsText,
      style: defaultStyle,
    );
  }
}
