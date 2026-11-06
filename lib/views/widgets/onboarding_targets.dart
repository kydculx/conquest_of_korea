import 'package:flutter/widgets.dart';

class OnboardingTargets {
  OnboardingTargets._();

  static final GlobalKey goldBar = GlobalKey(debugLabel: 'onboarding_gold_bar');
  static final GlobalKey timerBar = GlobalKey(debugLabel: 'onboarding_timer_bar');
  static final GlobalKey stepsBar = GlobalKey(debugLabel: 'onboarding_steps_bar');
  static final GlobalKey patternBtn =
      GlobalKey(debugLabel: 'onboarding_pattern_btn');
  static final GlobalKey rankingBtn =
      GlobalKey(debugLabel: 'onboarding_ranking_btn');
  static final GlobalKey profileBtn =
      GlobalKey(debugLabel: 'onboarding_profile_btn');
  static final GlobalKey calendarBtn =
      GlobalKey(debugLabel: 'onboarding_calendar_btn');
  static final GlobalKey achievementBtn =
      GlobalKey(debugLabel: 'onboarding_achievement_btn');
  static final GlobalKey photoBtn =
      GlobalKey(debugLabel: 'onboarding_photo_btn');
  static final GlobalKey hqBtn = GlobalKey(debugLabel: 'onboarding_hq_btn');
  static final GlobalKey mapFollowBtn =
      GlobalKey(debugLabel: 'onboarding_map_follow_btn');
  static final GlobalKey mapModeToggleBtn =
      GlobalKey(debugLabel: 'onboarding_map_mode_btn');
  static final GlobalKey mapStyleBtn =
      GlobalKey(debugLabel: 'onboarding_map_style_btn');
}
