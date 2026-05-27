import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';

/// 하이테크 전술 다크 테마 공통 뒤로가기 버튼
class TacticalBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final double size;

  const TacticalBackButton({super.key, this.onPressed, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        Icons.arrow_back_ios_new_rounded,
        color: GameColors.accentNeon,
        size: size,
      ),
      onPressed: onPressed ?? () => Navigator.of(context).pop(),
    );
  }
}

/// 하이테크 전술 다크 테마 공통 닫기 버튼
class TacticalCloseButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final double size;

  const TacticalCloseButton({super.key, this.onPressed, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.close_rounded, color: GameColors.accentNeon, size: size),
      onPressed: onPressed,
    );
  }
}

/// 하이테크 전술 다크 테마 공통 AppBar 위젯
class TacticalAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? titleText;
  final Widget? title;
  final Widget? leading;
  final List<Widget>? actions;
  final bool centerTitle;
  final bool showBackButton;
  final bool showCloseButton;
  final VoidCallback? leadingOnPressed;
  final Color backgroundColor;
  final double elevation;
  final PreferredSizeWidget? bottom;

  const TacticalAppBar({
    super.key,
    this.titleText,
    this.title,
    this.leading,
    this.actions,
    this.centerTitle = true,
    this.showBackButton = false,
    this.showCloseButton = false,
    this.leadingOnPressed,
    this.backgroundColor = Colors.transparent,
    this.elevation = 0,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    Widget? appBarLeading = leading;
    if (appBarLeading == null) {
      if (showBackButton) {
        appBarLeading = TacticalBackButton(onPressed: leadingOnPressed);
      } else if (showCloseButton) {
        appBarLeading = TacticalCloseButton(onPressed: leadingOnPressed);
      }
    }

    return AppBar(
      title:
          title ??
          (titleText != null
              ? Text(
                  titleText!,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    fontSize: 16,
                  ),
                )
              : null),
      centerTitle: centerTitle,
      backgroundColor: backgroundColor,
      elevation: elevation,
      leading: appBarLeading,
      actions: actions,
      bottom: bottom,
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0.0));
}
