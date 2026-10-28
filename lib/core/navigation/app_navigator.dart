import 'package:flutter/widgets.dart';

/// 앱 전역에서 라우트 전환을 제어하기 위한 네비게이터 키.
///
/// 알림 탭처럼 UI 컨텍스트 밖에서 발생한 이벤트가
/// 현재 화면을 닫고 게임 화면으로 복귀할 때 사용한다.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
