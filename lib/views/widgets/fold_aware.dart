import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

Rect? activeFoldGap(BuildContext context) {
  for (final feature in MediaQuery.displayFeaturesOf(context)) {
    if (feature.type != ui.DisplayFeatureType.fold &&
        feature.type != ui.DisplayFeatureType.hinge) {
      continue;
    }
    final bounds = feature.bounds;
    final isVertical = bounds.height >= bounds.width;
    if (isVertical && bounds.width <= 0) continue;
    if (!isVertical && bounds.height <= 0) continue;
    return bounds;
  }
  return null;
}

Rect largerPaneForGap(Size size, EdgeInsets padding, Rect gap) {
  if (gap.height >= gap.width) {
    final leftWidth = gap.left - padding.left;
    final rightWidth = size.width - padding.right - gap.right;
    if (leftWidth >= rightWidth) {
      return Rect.fromLTRB(padding.left, 0, gap.left, size.height);
    }
    return Rect.fromLTRB(gap.right, 0, size.width - padding.right, size.height);
  }

  final topHeight = gap.top - padding.top;
  final bottomHeight = size.height - padding.bottom - gap.bottom;
  if (bottomHeight >= topHeight) {
    return Rect.fromLTRB(0, gap.bottom, size.width, size.height - padding.bottom);
  }
  return Rect.fromLTRB(0, padding.top, size.width, gap.top);
}


class FoldAwareBody extends StatelessWidget {
  final Widget child;

  const FoldAwareBody({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    final gap = activeFoldGap(context);
    if (gap == null) return child;

    final pane = largerPaneForGap(size, padding, gap);
    final isVertical = gap.height >= gap.width;
    if (isVertical) {
      final isLeft = pane.left <= padding.left + 1;
      return Align(
        alignment: isLeft ? Alignment.centerLeft : Alignment.centerRight,
        child: SizedBox(
          width: pane.width,
          height: double.infinity,
          child: child,
        ),
      );
    }

    final isTop = pane.top <= padding.top + 1;
    return Align(
      alignment: isTop ? Alignment.topCenter : Alignment.bottomCenter,
      child: child,
    );
  }
}
