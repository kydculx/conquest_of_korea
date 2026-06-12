import 'package:flutter/material.dart';
import '../../models/alert_model.dart';
import 'alert_widget.dart';

/// 인게임 알림 리스트 위젯
/// 개별 알림들이 유입되고 사라질 때 부드러운 Size, Slide, Fade 애니메이션 효과를 부여합니다.
class TacticalAlertList extends StatefulWidget {
  final List<GameAlert> alerts;

  const TacticalAlertList({super.key, required this.alerts});

  @override
  State<TacticalAlertList> createState() => _TacticalAlertListState();
}

class _TacticalAlertListState extends State<TacticalAlertList> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  final List<GameAlert> _displayedAlerts = [];

  @override
  void initState() {
    super.initState();
    _displayedAlerts.addAll(widget.alerts);
  }

  @override
  void didUpdateWidget(TacticalAlertList oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 1. 삭제된 항목 감지 및 애니메이션과 함께 제거
    final activeIds = widget.alerts.map((e) => e.id).toSet();
    for (int i = _displayedAlerts.length - 1; i >= 0; i--) {
      final alert = _displayedAlerts[i];
      if (!activeIds.contains(alert.id)) {
        _displayedAlerts.removeAt(i);
        _listKey.currentState?.removeItem(
          i,
          (context, animation) => _buildAlertItem(alert, animation),
          duration: const Duration(milliseconds: 250),
        );
      }
    }

    // 2. 추가된 항목 감지 및 애니메이션과 함께 삽입
    final displayedIds = _displayedAlerts.map((e) => e.id).toSet();
    for (int i = widget.alerts.length - 1; i >= 0; i--) {
      final alert = widget.alerts[i];
      if (!displayedIds.contains(alert.id)) {
        // 새로 추가된 알림의 원본 인덱스를 구해서 삽입
        final insertIndex = widget.alerts.indexOf(alert);
        final clampedIndex = insertIndex.clamp(0, _displayedAlerts.length);
        _displayedAlerts.insert(clampedIndex, alert);
        _listKey.currentState?.insertItem(
          clampedIndex,
          duration: const Duration(milliseconds: 300),
        );
      }
    }
  }

  /// 개별 알림 아이템에 Fade, Size, Slide 3중 트랜지션 모션을 주입하여 렌더링합니다.
  Widget _buildAlertItem(GameAlert alert, Animation<double> animation) {
    return FadeTransition(
      opacity: animation,
      child: SizeTransition(
        sizeFactor: CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        ),
        axisAlignment: -1.0, // 위에서부터 아래로 부드럽게 열리며 슬라이딩
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -0.2),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutQuad,
          )),
          child: AlertWidget(alert: alert),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedList(
      key: _listKey,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      initialItemCount: _displayedAlerts.length,
      itemBuilder: (context, index, animation) {
        if (index >= _displayedAlerts.length) return const SizedBox.shrink();
        return _buildAlertItem(_displayedAlerts[index], animation);
      },
    );
  }
}
