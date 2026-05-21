import 'package:easy_localization/easy_localization.dart';

class GameStrings {
  // 앱 정보
  static String get appName => 'appName'.tr();
  static String get tacticalMissionStart => 'tacticalMissionStart'.tr();

  // 공통 버튼 및 라벨
  static String get confirm => 'confirm'.tr();
  static String get cancel => 'cancel'.tr();
  static String get close => 'close'.tr();
  static String get save => 'save'.tr();
  static String get delete => 'delete'.tr();
  static String get edit => 'edit'.tr();
  static String get loading => 'loading'.tr();

  // 인증 관련 (로그인/회원가입)
  static String get login => 'login'.tr();
  static String get logout => 'logout'.tr();
  static String get signup => 'signup'.tr();
  static String get email => 'email'.tr();
  static String get password => 'password'.tr();
  static String get passwordConfirm => 'passwordConfirm'.tr();
  static String get nickname => 'nickname'.tr();
  static String get enterEmail => 'enterEmail'.tr();
  static String get enterPassword => 'enterPassword'.tr();
  static String get enterNickname => 'enterNickname'.tr();
  static String get noAccount => 'noAccount'.tr();
  static String get hasAccount => 'hasAccount'.tr();
  static String get startWithGoogle => 'startWithGoogle'.tr();
  static String get startWithKakao => 'startWithKakao'.tr();
  static String get startWithApple => 'startWithApple'.tr();

  // 프로필 및 설정
  static String get profile => 'profile'.tr();
  static String get myProfile => 'myProfile'.tr();
  static String get profileSettings => 'profileSettings'.tr();
  static String get nicknameSettings => 'nicknameSettings'.tr();
  static String get rank => 'rank'.tr();
  static String get territoryCount => 'territoryCount'.tr();
  static String get totalCaptured => 'totalCaptured'.tr();

  // 게임 관련
  static String get capture => 'capture'.tr();
  static String get capturing => 'capturing'.tr();
  static String get captureComplete => 'captureComplete'.tr();
  static String get myTerritory => 'myTerritory'.tr();
  static String get enemyTerritory => 'enemyTerritory'.tr();
  static String get emptyTerritory => 'emptyTerritory'.tr();
  static String get currentPosition => 'currentPosition'.tr();
  static String get searchingSignal => 'searchingSignal'.tr();

  // 에러 메시지 (ErrorTranslator용)
  static String get errorUnknown => 'errorUnknown'.tr();
  static String get errorDatabase => 'errorDatabase'.tr();
  static String get errorDuplicateInfo => 'errorDuplicateInfo'.tr();
  static String get errorDuplicateEmail => 'errorDuplicateEmail'.tr();
  static String get errorInvalidCredentials => 'errorInvalidCredentials'.tr();
  static String get errorEmailNotConfirmed => 'errorEmailNotConfirmed'.tr();
  static String get errorWeakPassword => 'errorWeakPassword'.tr();
  static String get errorInvalidAuth => 'errorInvalidAuth'.tr();
  static String get errorGoogleConfig => 'errorGoogleConfig'.tr();
  static String get errorNetwork => 'errorNetwork'.tr();
  static String get errorLoginCanceled => 'errorLoginCanceled'.tr();
  static String get errorKakaoConfig => 'errorKakaoConfig'.tr();
  static String get errorNicknameExists => 'errorNicknameExists'.tr();
  static String get errorNicknameCheckRequired => 'errorNicknameCheckRequired'.tr();
  static String get errorEmailCheckRequired => 'errorEmailCheckRequired'.tr();
  static String get signupPending => 'signupPending'.tr();
  static String get signupCompleteMessage => 'signupCompleteMessage'.tr();
  static String get signupTitle => 'signupTitle'.tr();
  static String get checkDuplicate => 'checkDuplicate'.tr();
  static String get nicknameAvailable => 'nicknameAvailable'.tr();
  static String get emailAvailable => 'emailAvailable'.tr();
  static String get emailInvalid => 'emailInvalid'.tr();
  static String get passwordHint => 'passwordHint'.tr();
  static String get selectTacticalColor => 'selectTacticalColor'.tr();
  static String get changeColor => 'changeColor'.tr();
  static String get setupProfile => 'setupProfile'.tr();
  static String get setupProfileSub => 'setupProfileSub'.tr();
  static String get myTacticalColor => 'myTacticalColor'.tr();
  static String get generateNewColor => 'generateNewColor'.tr();
  static String get setupComplete => 'setupComplete'.tr();
  static String get or => 'or'.tr();
  static String get emailAddress => 'emailAddress'.tr();
  static String get createAccount => 'createAccount'.tr();

  // 프로필 추가 UI 텍스트
  static String get loginRequiredPage => 'loginRequiredPage'.tr();
  static String get goBack => 'goBack'.tr();
  static String get agentProfile => 'agentProfile'.tr();
  static String get myTeam => 'myTeam'.tr();
  static String get capturedTiles => 'capturedTiles'.tr();
  static String get operationSettings => 'operationSettings'.tr();
  static String get changeTeamColor => 'changeTeamColor'.tr();
  static String get changeTeamColorSub => 'changeTeamColorSub'.tr();
  static String get pushNotifications => 'pushNotifications'.tr();
  static String get pushNotificationsSub => 'pushNotificationsSub'.tr();
  static String get securityPolicy => 'securityPolicy'.tr();
  static String get securityPolicySub => 'securityPolicySub'.tr();
  static String get accountManagement => 'accountManagement'.tr();
  static String get terminateOperation => 'terminateOperation'.tr();
  static String get logoutConfirmMessage => 'logoutConfirmMessage'.tr();
  static String get customTeamColor => 'customTeamColor'.tr();
  static String get teamColorChanged => 'teamColorChanged'.tr();
  static String get apply => 'apply'.tr();

  // 게임 화면 및 오버레이 UI 텍스트
  static String get tacticalSatelliteSync => 'tacticalSatelliteSync'.tr();
  static String get capturingZone => 'capturingZone'.tr();
  static String get gpsReset => 'gpsReset'.tr();
  static String get auto => 'auto'.tr();
  static String get manual => 'manual'.tr();
  static const String startCaptureModeKo = '점령시작';
  static const String stopCaptureModeKo = '점령정지';
  static String get startCaptureMode => 'startCaptureMode'.tr();
  static String get stopCaptureMode => 'stopCaptureMode'.tr();
  static String get cannotCapture => 'cannotCapture'.tr();
  static String get gpsInaccurateCannotCapture => 'gpsInaccurateCannotCapture'.tr();
  static String get loginRequiredOperation => 'loginRequiredOperation'.tr();
  static String get alreadyCapturedByMe => 'alreadyCapturedByMe'.tr();
  static String get captureAction => 'captureAction'.tr();
  static String get cannotCaptureLabel => 'cannotCaptureLabel'.tr();
  static String get analyzingTacticalData => 'analyzingTacticalData'.tr();

  // 백그라운드 및 외부 시스템 연동 UI
  static String get captureSuccessAlert => 'captureSuccessAlert'.tr();
  static String get captureFailAlert => 'captureFailAlert'.tr();
  static String get captureCanceledOutOfBoundary => 'captureCanceledOutOfBoundary'.tr();
  static String get captureFailedPreempted => 'captureFailedPreempted'.tr();
  static String get countUnit => 'countUnit'.tr();
  static String get gpsServiceNotificationTitle => 'gpsServiceNotificationTitle'.tr();
  static String get gpsServiceNotificationText => 'gpsServiceNotificationText'.tr();
  static String get notificationChannelName => 'notificationChannelName'.tr();
  static String get notificationChannelDescription => 'notificationChannelDescription'.tr();

  // 인증 에러 메시지
  static String get emailAlreadyInUse => 'emailAlreadyInUse'.tr();
  static String get idTokenFetchFailed => 'idTokenFetchFailed'.tr();
  static String get kakaoOidcRequired => 'kakaoOidcRequired'.tr();

  // 로컬 알림 관련 메시지
  static String get notificationCaptureEmptyTitle => 'notificationCaptureEmptyTitle'.tr();
  static String get notificationCaptureEmptyBody => 'notificationCaptureEmptyBody'.tr();
  static String get notificationCaptureEnemyTitle => 'notificationCaptureEnemyTitle'.tr();
  static String get notificationCaptureEnemyBody => 'notificationCaptureEnemyBody'.tr();
  static String get notificationInvasionTitle => 'notificationInvasionTitle'.tr();
  static String get notificationInvasionBody => 'notificationInvasionBody'.tr();

  // HUD 및 전술 상태 라벨
  static String get hudSecScan => 'hudSecScan'.tr();
  static String get hudOffline => 'hudOffline'.tr();
  static String get hudActive => 'hudActive'.tr();
  static String get hudStandby => 'hudStandby'.tr();

  // 맵 스타일 이름 번역
  static String get mapStyleCyber => 'mapStyleCyber'.tr();
  static String get mapStyleDark => 'mapStyleDark'.tr();
  static String get mapStyleSatellite => 'mapStyleSatellite'.tr();
  static String get mapStyleOutline => 'mapStyleOutline'.tr();

  // 메인 기지 및 위성 점령 추가 다국어
  static String get baseSetupCompleteAlert => 'baseSetupCompleteAlert'.tr();
  static String get baseSetupSearchingSignal => 'baseSetupSearchingSignal'.tr();
  static String get baseSetupInstruction => 'baseSetupInstruction'.tr();
  static String get gpsDisabled => 'gpsDisabled'.tr();
  static String get satellitePositionOk => 'satellitePositionOk'.tr();
  static String currentLatitudeLongitude(String lat, String lng) =>
      'currentLatitudeLongitude'.tr(namedArgs: {'lat': lat, 'lng': lng});
  static String get baseSetupTitle => 'baseSetupTitle'.tr();
  static String baseSetupDescription(String tileId) =>
      'baseSetupDescription'.tr(namedArgs: {'tileId': tileId});
  static String get baseSetupConfirmButton => 'baseSetupConfirmButton'.tr();

  static String get profileRebaseTitle => 'profileRebaseTitle'.tr();
  static String get profileRebaseSubtitle => 'profileRebaseSubtitle'.tr();
  static String get gpsSignalError => 'gpsSignalError'.tr();
  static String get rebaseConfirmTitle => 'rebaseConfirmTitle'.tr();
  static String rebaseConfirmContent(String tileId) =>
      'rebaseConfirmContent'.tr(namedArgs: {'tileId': tileId});
  static String get rebaseButton => 'rebaseButton'.tr();
  static String rebaseSuccessAlert(String tileId) =>
      'rebaseSuccessAlert'.tr(namedArgs: {'tileId': tileId});

  static String satelliteCapturingWithTime(String tileId, String seconds) =>
      'satelliteCapturingWithTime'.tr(namedArgs: {'tileId': tileId, 'seconds': seconds});
  static String get satelliteSelectTile => 'satelliteSelectTile'.tr();
  static String get targetLockOn => 'targetLockOn'.tr();
  static String satCooltimeWaiting(String time) =>
      'satCooltimeWaiting'.tr(namedArgs: {'time': time});
  static String get satDisconnected => 'satDisconnected'.tr();
  static String satDurationTime(String seconds) =>
      'satDurationTime'.tr(namedArgs: {'seconds': seconds});
  static String get satAlreadyCaptured => 'satAlreadyCaptured'.tr();
  static String satLockOnTile(String tileId) =>
      'satLockOnTile'.tr(namedArgs: {'tileId': tileId});
  static String get satCaptureTitle => 'satCaptureTitle'.tr();
  static String get captureUpper => 'captureUpper'.tr();
  static String get satelliteLinkActive => 'satelliteLinkActive'.tr();

  static String get hqInvasionNotifTitle => 'hqInvasionNotifTitle'.tr();
  static String get hqInvasionNotifBody => 'hqInvasionNotifBody'.tr();
  static String get hqInvasionAlert => 'hqInvasionAlert'.tr();

  static String get satelliteCooltimeAlert => 'satelliteCooltimeAlert'.tr();
  static String get satelliteAlreadyCapturedAlert => 'satelliteAlreadyCapturedAlert'.tr();
  static String get satelliteDisconnectedAlert => 'satelliteDisconnectedAlert'.tr();
  static String get satelliteNoHQAlert => 'satelliteNoHQAlert'.tr();
  static String get satelliteCoordError => 'satelliteCoordError'.tr();
  static String satelliteCaptureStart(String seconds) =>
      'satelliteCaptureStart'.tr(namedArgs: {'seconds': seconds});
  static String get satelliteUserInvalid => 'satelliteUserInvalid'.tr();
  static String get satelliteCaptureSuccess => 'satelliteCaptureSuccess'.tr();
  static String get satelliteCaptureFail => 'satelliteCaptureFail'.tr();
  static String get satelliteAbortTitle => 'satelliteAbortTitle'.tr();
  static String get satelliteAbortConfirm => 'satelliteAbortConfirm'.tr();
  static String get satelliteKeepOperation => 'satelliteKeepOperation'.tr();
  static String get satelliteCancelOperation => 'satelliteCancelOperation'.tr();
}
