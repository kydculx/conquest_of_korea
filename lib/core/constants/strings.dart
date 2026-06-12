import 'package:easy_localization/easy_localization.dart';

/// 게임 내 다국어 번역 문자열 리소스를 제공하는 클래스
class GameStrings {
  // --- 앱 정보 ---
  /// 앱 이름 번역 문자열
  static String get appName => 'appName'.tr();

  /// 미션 개시 번역 문자열
  static String get tacticalMissionStart => 'tacticalMissionStart'.tr();

  // --- 공통 버튼 및 라벨 ---
  /// 확인 버튼 라벨
  static String get confirm => 'confirm'.tr();

  /// 취소 버튼 라벨
  static String get cancel => 'cancel'.tr();

  /// 닫기 버튼 라벨
  static String get close => 'close'.tr();

  /// 저장 버튼 라벨
  static String get save => 'save'.tr();

  /// 삭제 버튼 라벨
  static String get delete => 'delete'.tr();

  /// 수정 버튼 라벨
  static String get edit => 'edit'.tr();

  /// 로딩 중 표시 라벨
  static String get loading => 'loading'.tr();

  // --- 인증 관련 (로그인/회원가입) ---
  /// 로그인 버튼 라벨
  static String get login => 'login'.tr();

  /// 로그아웃 버튼 라벨
  static String get logout => 'logout'.tr();

  /// 회원가입 버튼 라벨
  static String get signup => 'signup'.tr();

  /// 이메일 입력 필드 라벨
  static String get email => 'email'.tr();

  /// 비밀번호 입력 필드 라벨
  static String get password => 'password'.tr();

  /// 비밀번호 확인 입력 필드 라벨
  static String get passwordConfirm => 'passwordConfirm'.tr();

  /// 닉네임 입력 필드 라벨
  static String get nickname => 'nickname'.tr();

  /// 이메일 입력 힌트
  static String get enterEmail => 'enterEmail'.tr();

  /// 비밀번호 입력 힌트
  static String get enterPassword => 'enterPassword'.tr();

  /// 닉네임 입력 힌트
  static String get enterNickname => 'enterNickname'.tr();

  /// 계정이 없는 경우 안내 문구
  static String get noAccount => 'noAccount'.tr();

  /// 이미 계정이 있는 경우 안내 문구
  static String get hasAccount => 'hasAccount'.tr();

  /// 구글 로그인 시작 버튼 라벨
  static String get startWithGoogle => 'startWithGoogle'.tr();

  /// 애플 로그인 시작 버튼 라벨
  static String get startWithApple => 'startWithApple'.tr();

  // --- 프로필 및 설정 ---
  /// 프로필 메뉴 타이틀
  static String get profile => 'profile'.tr();

  /// 내 프로필 메뉴 타이틀
  static String get myProfile => 'myProfile'.tr();

  /// 프로필 설정 메뉴 타이틀
  static String get profileSettings => 'profileSettings'.tr();

  /// 닉네임 설정 메뉴 타이틀
  static String get nicknameSettings => 'nicknameSettings'.tr();

  /// 랭킹 라벨
  static String get rank => 'rank'.tr();

  /// 영토(타일) 소유 개수 라벨
  static String get territoryCount => 'territoryCount'.tr();

  /// 누적 점령 횟수 라벨
  static String get totalCaptured => 'totalCaptured'.tr();

  // --- 게임 관련 ---
  /// 점령하기 버튼 라벨
  static String get capture => 'capture'.tr();

  /// 점령 진행 중 상태 라벨
  static String get capturing => 'capturing'.tr();

  /// 점령 완료 상태 라벨
  static String get captureComplete => 'captureComplete'.tr();

  /// 아군 영토 표시 라벨
  static String get myTerritory => 'myTerritory'.tr();

  /// 적군 영토 표시 라벨
  static String get enemyTerritory => 'enemyTerritory'.tr();

  /// 중립(빈) 영토 표시 라벨
  static String get emptyTerritory => 'emptyTerritory'.tr();

  /// 현재 위치 표시 라벨
  static String get currentPosition => 'currentPosition'.tr();

  /// GPS 신호 탐색 상태 라벨
  static String get searchingSignal => 'searchingSignal'.tr();

  // --- 에러 메시지 (ErrorTranslator용) ---
  /// 알 수 없는 오류 메시지
  static String get errorUnknown => 'errorUnknown'.tr();

  /// 데이터베이스 연동 오류 메시지
  static String get errorDatabase => 'errorDatabase'.tr();

  /// 중복 정보 존재 오류 메시지
  static String get errorDuplicateInfo => 'errorDuplicateInfo'.tr();

  /// 중복 이메일 오류 메시지
  static String get errorDuplicateEmail => 'errorDuplicateEmail'.tr();

  /// 잘못된 인증 정보 오류 메시지
  static String get errorInvalidCredentials => 'errorInvalidCredentials'.tr();

  /// 이메일 미인증 오류 메시지
  static String get errorEmailNotConfirmed => 'errorEmailNotConfirmed'.tr();

  /// 취약한 비밀번호 오류 메시지
  static String get errorWeakPassword => 'errorWeakPassword'.tr();

  /// 세션 만료 등 유효하지 않은 인증 오류 메시지
  static String get errorInvalidAuth => 'errorInvalidAuth'.tr();

  /// 구글 설정 오류 메시지
  static String get errorGoogleConfig => 'errorGoogleConfig'.tr();

  /// 네트워크 상태 불안정 오류 메시지
  static String get errorNetwork => 'errorNetwork'.tr();

  /// 로그인 취소 안내 메시지
  static String get errorLoginCanceled => 'errorLoginCanceled'.tr();

  /// 닉네임 중복 오류 메시지
  static String get errorNicknameExists => 'errorNicknameExists'.tr();

  /// 닉네임 중복 체크 필수 안내 메시지
  static String get errorNicknameCheckRequired =>
      'errorNicknameCheckRequired'.tr();

  /// 이메일 중복 체크 필수 안내 메시지
  static String get errorEmailCheckRequired => 'errorEmailCheckRequired'.tr();

  /// 가입 승인 대기 안내 메시지
  static String get signupPending => 'signupPending'.tr();

  /// 가입 완료 안내 메시지
  static String get signupCompleteMessage => 'signupCompleteMessage'.tr();

  /// 회원가입 화면 타이틀
  static String get signupTitle => 'signupTitle'.tr();

  /// 중복 확인 버튼 라벨
  static String get checkDuplicate => 'checkDuplicate'.tr();

  /// 사용 가능한 닉네임 안내 메시지
  static String get nicknameAvailable => 'nicknameAvailable'.tr();

  /// 사용 가능한 이메일 안내 메시지
  static String get emailAvailable => 'emailAvailable'.tr();

  /// 유효하지 않은 이메일 형식 오류 메시지
  static String get emailInvalid => 'emailInvalid'.tr();

  /// 비밀번호 설정 조건 힌트 메시지
  static String get passwordHint => 'passwordHint'.tr();

  /// 테마 컬러 선택 타이틀
  static String get selectTacticalColor => 'selectTacticalColor'.tr();

  /// 컬러 변경 버튼 라벨
  static String get changeColor => 'changeColor'.tr();

  /// 프로필 설정 화면 타이틀
  static String get setupProfile => 'setupProfile'.tr();

  /// 프로필 설정 부가 안내 메시지
  static String get setupProfileSub => 'setupProfileSub'.tr();

  /// 내 테마 컬러 명칭 라벨
  static String get myTacticalColor => 'myTacticalColor'.tr();

  /// 새로운 컬러 무작위 생성 버튼 라벨
  static String get generateNewColor => 'generateNewColor'.tr();

  /// 프로필 설정 완료 안내 문구
  static String get setupComplete => 'setupComplete'.tr();

  /// "또는" 연결어
  static String get or => 'or'.tr();

  /// 이메일 주소 텍스트 필드 라벨
  static String get emailAddress => 'emailAddress'.tr();

  /// 계정 생성 버튼 라벨
  static String get createAccount => 'createAccount'.tr();

  // --- 프로필 추가 UI 텍스트 ---
  /// 로그인 필요 안내 페이지 문구
  static String get loginRequiredPage => 'loginRequiredPage'.tr();

  /// 이전 화면으로 이동 버튼 라벨
  static String get goBack => 'goBack'.tr();

  /// 플레이어 프로필 타이틀
  static String get agentProfile => 'agentProfile'.tr();

  /// 소속 팀 명칭 라벨
  static String get myTeam => 'myTeam'.tr();

  /// 점령한 타일 개수 표시 라벨
  static String get capturedTiles => 'capturedTiles'.tr();

  /// 작전 설정 메뉴 타이틀
  static String get operationSettings => 'operationSettings'.tr();

  /// 테마 컬러 변경 버튼 라벨
  static String get changeTacticalColor => 'changeTacticalColor'.tr();

  /// 테마 컬러 변경 안내 문구
  static String get changeTacticalColorSub => 'changeTacticalColorSub'.tr();

  /// 푸시 알림 수신 설정 버튼 라벨
  static String get pushNotifications => 'pushNotifications'.tr();

  /// 푸시 알림 수신 설정 안내 문구
  static String get pushNotificationsSub => 'pushNotificationsSub'.tr();

  /// 보안 정책 문서 확인 버튼 라벨
  static String get securityPolicy => 'securityPolicy'.tr();

  /// 보안 정책 문서 확인 안내 문구
  static String get securityPolicySub => 'securityPolicySub'.tr();

  /// 서비스 이용약관 버튼 라벨
  static String get termsOfService => 'termsOfService'.tr();

  /// 서비스 이용약관 안내 문구
  static String get termsOfServiceSub => 'termsOfServiceSub'.tr();

  /// 개인정보 처리방침 버튼 라벨
  static String get privacyPolicy => 'privacyPolicy'.tr();

  /// 개인정보 처리방침 안내 문구
  static String get privacyPolicySub => 'privacyPolicySub'.tr();

  /// 계정 관리 메뉴 타이틀
  static String get accountManagement => 'accountManagement'.tr();

  /// 계정 탈퇴 버튼 라벨
  static String get terminateOperation => 'terminateOperation'.tr();

  /// 로그아웃 확인 팝업 안내 메시지
  static String get logoutConfirmMessage => 'logoutConfirmMessage'.tr();

  /// 커스텀 테마 컬러 라벨
  static String get customTacticalColor => 'customTacticalColor'.tr();

  /// 테마 컬러 변경 완료 안내 메시지
  static String get tacticalColorChanged => 'tacticalColorChanged'.tr();

  /// 로그아웃 확인 팝업 타이틀
  static String get logoutConfirmTitle => 'logoutConfirmTitle'.tr();

  /// 테마 색상 설정 팝업 타이틀
  static String get tacticalColorSetupTitle => 'tacticalColorSetupTitle'.tr();

  /// 신호 스펙트럼 믹서 부제
  static String get signalSpectrumMixer => 'signalSpectrumMixer'.tr();

  /// 영토 변경 알림 타이틀
  static String get notifTerritoryAttackTitle =>
      'notifTerritoryAttackTitle'.tr();

  /// 영토 변경 알림 부제
  static String get notifTerritoryAttackSub => 'notifTerritoryAttackSub'.tr();

  /// 원격 모드 완료 알림 타이틀
  static String get notifSatelliteCompleteTitle =>
      'notifSatelliteCompleteTitle'.tr();

  /// 원격 모드 완료 알림 부제
  static String get notifSatelliteCompleteSub =>
      'notifSatelliteCompleteSub'.tr();

  /// 시스템 긴급 공지 타이틀
  static String get notifSystemNoticeTitle => 'notifSystemNoticeTitle'.tr();

  /// 시스템 긴급 공지 부제
  static String get notifSystemNoticeSub => 'notifSystemNoticeSub'.tr();

  /// 적용하기 버튼 라벨
  static String get apply => 'apply'.tr();

  /// 랭킹판 타이틀
  static String get tacticalRankingBoard => 'tacticalRankingBoard'.tr();

  /// 랭킹 헤더 순위 라벨
  static String get rankingHeaderRank => 'rankingHeaderRank'.tr();

  /// 랭킹 헤더 구역수 라벨
  static String get rankingHeaderCapturedTiles =>
      'rankingHeaderCapturedTiles'.tr();

  /// 랭킹 헤더 일일 이동 라벨
  static String get rankingHeaderDailyMovedTiles =>
      'rankingHeaderDailyMovedTiles'.tr();

  /// 랭킹 헤더 누적 이동 라벨
  static String get rankingHeaderTotalMovedTiles =>
      'rankingHeaderTotalMovedTiles'.tr();

  /// 점령 영토 탭 레이블
  static String get capturedTerritory => 'capturedTerritory'.tr();

  /// 랭킹별 설명 글 게터
  static String get rankingDescCapturedTiles => 'rankingDescCapturedTiles'.tr();
  static String get rankingDescDailyMovedTiles => 'rankingDescDailyMovedTiles'.tr();
  static String get rankingDescTotalMovedTiles => 'rankingDescTotalMovedTiles'.tr();

  /// 타일 단위 매핑 함수
  static String tileUnit(int count) =>
      'tileUnit'.tr(namedArgs: {'count': count.toString()});

  /// 랭킹 데이터 부재 안내 문구
  static String get noRankingData => 'noRankingData'.tr();

  /// 플레이어(나) 표시
  static String get agentMe => 'agentMe'.tr();

  /// 닉네임과 (나) 매핑 함수
  static String nicknameWithMe(String nickname) =>
      'nicknameWithMe'.tr(namedArgs: {'nickname': nickname});

  /// 구역 개수 단위 매핑 함수
  static String territoryUnit(int count) =>
      'territoryUnit'.tr(namedArgs: {'count': count.toString()});

  /// 순위 단위 매핑 함수
  static String rankUnit(int rank) =>
      'rankUnit'.tr(namedArgs: {'rank': rank.toString()});

  /// 순위 미정 상태 라벨
  static String get rankUnranked => 'rankUnranked'.tr();

  /// 상위 100위 통계 정보
  static String get top100Stats => 'top100Stats'.tr();

  // --- 게임 화면 및 오버레이 UI 텍스트 ---
  /// 원격 모드 신호 연결 진행 상태 문구
  static String get tacticalSatelliteSync => 'tacticalSatelliteSync'.tr();

  /// 영토 점령 시도 안내 문구
  static String get capturingZone => 'capturingZone'.tr();

  /// GPS 좌표 오차 보정 버튼 라벨
  static String get gpsReset => 'gpsReset'.tr();

  /// 자동 모드 상태 라벨
  static String get auto => 'auto'.tr();

  /// 수동 모드 상태 라벨
  static String get manual => 'manual'.tr();

  /// 점령 모드 개시 버튼 라벨
  static String get startCaptureMode => 'startCaptureMode'.tr();

  /// 점령 모드 중단 버튼 라벨
  static String get stopCaptureMode => 'stopCaptureMode'.tr();

  /// 점령 불가 안내 메시지
  static String get cannotCapture => 'cannotCapture'.tr();

  /// GPS 정확도 저하로 인한 점령 불능 안내 메시지
  static String get gpsInaccurateCannotCapture =>
      'gpsInaccurateCannotCapture'.tr();

  /// 플레이를 위한 로그인 필요 메시지
  static String get loginRequiredOperation => 'loginRequiredOperation'.tr();

  /// 이미 본인이 점령한 구역 안내 메시지
  static String get alreadyCapturedByMe => 'alreadyCapturedByMe'.tr();

  /// 점령 액션 실행 라벨
  static String get captureAction => 'captureAction'.tr();

  /// 점령 불가 상태 라벨
  static String get cannotCaptureLabel => 'cannotCaptureLabel'.tr();

  /// 게임 데이터 분석 진행 중 안내 메시지
  static String get analyzingTacticalData => 'analyzingTacticalData'.tr();

  // --- 백그라운드 및 외부 시스템 연동 UI ---
  /// 점령 성공 로컬 알림 타이틀
  static String get captureSuccessAlert => 'captureSuccessAlert'.tr();

  /// 점령 실패 로컬 알림 타이틀
  static String get captureFailAlert => 'captureFailAlert'.tr();

  /// 경계선 이탈로 인한 점령 취소 안내 메시지
  static String get captureCanceledOutOfBoundary =>
      'captureCanceledOutOfBoundary'.tr();

  /// 타 플레이어의 선점령으로 인한 실패 안내 메시지
  static String get captureFailedPreempted => 'captureFailedPreempted'.tr();

  /// 개수/개소 수량 단위 문자열 ("개")
  static String get countUnit => 'countUnit'.tr();

  /// GPS 백그라운드 서비스 알림 타이틀
  static String get gpsServiceNotificationTitle =>
      'gpsServiceNotificationTitle'.tr();

  /// GPS 백그라운드 서비스 알림 내용
  static String get gpsServiceNotificationText =>
      'gpsServiceNotificationText'.tr();

  /// 푸시 알림 채널 명칭
  static String get notificationChannelName => 'notificationChannelName'.tr();

  /// 푸시 알림 채널 상세 설명
  static String get notificationChannelDescription =>
      'notificationChannelDescription'.tr();

  // --- 인증 에러 메시지 ---
  /// 이미 사용 중인 이메일 주소 오류 메시지
  static String get emailAlreadyInUse => 'emailAlreadyInUse'.tr();

  /// 인증 ID 토큰 획득 실패 오류 메시지
  static String get idTokenFetchFailed => 'idTokenFetchFailed'.tr();

  // --- 로컬 알림 관련 메시지 ---
  /// 중립 영토 점령 시도 알림 타이틀
  static String get notificationCaptureEmptyTitle =>
      'notificationCaptureEmptyTitle'.tr();

  /// 중립 영토 점령 시도 알림 상세 본문
  static String get notificationCaptureEmptyBody =>
      'notificationCaptureEmptyBody'.tr();

  /// 타 영토 확보 시도 알림 타이틀
  static String get notificationCaptureEnemyTitle =>
      'notificationCaptureEnemyTitle'.tr();

  /// 타 영토 확보 시도 알림 상세 본문
  static String get notificationCaptureEnemyBody =>
      'notificationCaptureEnemyBody'.tr();

  /// 영토 변경 경고 알림 타이틀
  static String get notificationInvasionTitle =>
      'notificationInvasionTitle'.tr();

  /// 영토 변경 경고 알림 상세 본문
  static String get notificationInvasionBody => 'notificationInvasionBody'.tr();

  // --- HUD 및 점령 상태 라벨 ---
  /// 초 단위 스캔 주기 라벨
  static String get hudSecScan => 'hudSecScan'.tr();

  /// HUD 오프라인 상태 표시 라벨
  static String get hudOffline => 'hudOffline'.tr();

  /// HUD 활성화 상태 표시 라벨
  static String get hudActive => 'hudActive'.tr();

  /// HUD 대기 상태 표시 라벨
  static String get hudStandby => 'hudStandby'.tr();

  // --- 맵 스타일 이름 번역 ---
  /// 사이버 펑크 맵 스타일 명칭
  static String get mapStyleCyber => 'mapStyleCyber'.tr();

  /// 다크 테마 맵 스타일 명칭
  static String get mapStyleDark => 'mapStyleDark'.tr();

  /// 위성 사진 맵 스타일 명칭
  static String get mapStyleSatellite => 'mapStyleSatellite'.tr();

  // --- 본진 및 원격 모드 점령 추가 다국어 ---
  /// 본진 설정 완료 안내 팝업 문구
  static String get baseSetupCompleteAlert => 'baseSetupCompleteAlert'.tr();

  /// 본진 위치 신호 탐색 상태 라벨
  static String get baseSetupSearchingSignal => 'baseSetupSearchingSignal'.tr();

  /// 본진 설정 안내 문구
  static String get baseSetupInstruction => 'baseSetupInstruction'.tr();

  /// GPS 기능 비활성화 경고 문구
  static String get gpsDisabled => 'gpsDisabled'.tr();

  /// 원격 모드 신호 연결 확인 완료 라벨
  static String get satellitePositionOk => 'satellitePositionOk'.tr();

  /// 현재 위도 및 경도 수치 포맷팅 함수
  static String currentLatitudeLongitude(String lat, String lng) =>
      'currentLatitudeLongitude'.tr(namedArgs: {'lat': lat, 'lng': lng});

  /// 본진 설정 화면 타이틀
  static String get baseSetupTitle => 'baseSetupTitle'.tr();

  /// 지정한 본진 타일 정보 안내 포맷팅 함수
  static String baseSetupDescription(String tileId) =>
      'baseSetupDescription'.tr(namedArgs: {'tileId': tileId});

  /// 본진 설정 최종 확인 버튼 라벨
  static String get baseSetupConfirmButton => 'baseSetupConfirmButton'.tr();

  /// 프로필 본진 이전(Rebase) 타이틀
  static String get profileRebaseTitle => 'profileRebaseTitle'.tr();

  /// 프로필 본진 이전 상세 부제
  static String get profileRebaseSubtitle => 'profileRebaseSubtitle'.tr();

  /// GPS 신호 오차 경고 메시지
  static String get gpsSignalError => 'gpsSignalError'.tr();

  /// 기지 이전 최종 확인 타이틀
  static String get rebaseConfirmTitle => 'rebaseConfirmTitle'.tr();

  /// 이전 대상 기지 타일 상세 안내 포맷팅 함수
  static String rebaseConfirmContent({
    required String tileId,
    required String cost,
    required String currentGold,
  }) => 'rebaseConfirmContent'.tr(
    namedArgs: {'tileId': tileId, 'cost': cost, 'currentGold': currentGold},
  );

  /// 본진 이전 재화 부족 경고 메시지 포맷팅 함수
  static String rebaseGoldShortageMessage(String cost, String currentGold) =>
      'rebaseGoldShortageMessage'.tr(
        namedArgs: {'cost': cost, 'currentGold': currentGold},
      );

  /// 본진 이전 동일 위치 오류 메시지
  static String get rebaseSameLocationMessage =>
      'rebaseSameLocationMessage'.tr();

  /// 기지 이전 버튼 라벨
  static String get rebaseButton => 'rebaseButton'.tr();

  /// 기지 이전 완료 안내 문구 포맷팅 함수
  static String rebaseSuccessAlert(String tileId) =>
      'rebaseSuccessAlert'.tr(namedArgs: {'tileId': tileId});

  /// 원격 모드 점령 시 잔여 시간 표시 포맷팅 함수
  static String satelliteCapturingWithTime(String tileId, String seconds) =>
      'satelliteCapturingWithTime'.tr(
        namedArgs: {'tileId': tileId, 'seconds': seconds},
      );

  /// 원격 모드 타겟 타일 선택 대기 안내 문구
  static String get satelliteSelectTile => 'satelliteSelectTile'.tr();

  /// 원격 모드 타겟 고정(조준) 상태 라벨
  static String get targetLockOn => 'targetLockOn'.tr();

  /// 원격 모드 대기 안내 문구 포맷팅 함수
  static String satCooltimeWaiting(String time) =>
      'satCooltimeWaiting'.tr(namedArgs: {'time': time});

  /// 원격 모드 연결 유실 상태 라벨
  static String get satDisconnected => 'satDisconnected'.tr();

  /// 원격 모드 점령 소요 시간 포맷팅 함수
  static String satDurationTime(String seconds) =>
      'satDurationTime'.tr(namedArgs: {'seconds': seconds});

  /// 이미 아군이 원격으로 점령한 타일 안내 문구
  static String get satAlreadyCaptured => 'satAlreadyCaptured'.tr();

  /// 원격 모드 지정 타일 조준 포맷팅 함수
  static String satLockOnTile(String tileId) =>
      'satLockOnTile'.tr(namedArgs: {'tileId': tileId});

  /// 원격 모드 점령 타이틀
  static String get satCaptureTitle => 'satCaptureTitle'.tr();

  /// 대문자 형태 점령 지시어
  static String get captureUpper => 'captureUpper'.tr();

  /// 원격 모드 통신 활성화 상태 라벨
  static String get satelliteLinkActive => 'satelliteLinkActive'.tr();

  /// 본진 변경 위험 알림 타이틀
  static String get hqInvasionNotifTitle => 'hqInvasionNotifTitle'.tr();

  /// 본진 변경 위험 알림 상세 본문
  static String get hqInvasionNotifBody => 'hqInvasionNotifBody'.tr();

  /// 본진 변경 실시간 인게임 알림 문구
  static String get hqInvasionAlert => 'hqInvasionAlert'.tr();

  /// 원격 모드 대기 미경과 경고 문구
  static String get satelliteCooltimeAlert => 'satelliteCooltimeAlert'.tr();

  /// 이미 아군이 점령한 영토 원격 점령 불가 경고 문구
  static String get satelliteAlreadyCapturedAlert =>
      'satelliteAlreadyCapturedAlert'.tr();

  /// 원격 모드 통신 연결 유실 경고 문구
  static String get satelliteDisconnectedAlert =>
      'satelliteDisconnectedAlert'.tr();

  /// 본진 미설정으로 인한 원격 점령 불가 경고 문구
  static String get satelliteNoHQAlert => 'satelliteNoHQAlert'.tr();

  /// 원격 모드 타겟 좌표 확인 오류 경고 문구
  static String get satelliteCoordError => 'satelliteCoordError'.tr();

  /// 원격 모드 점령 개시 포맷팅 함수
  static String satelliteCaptureStart(String seconds) =>
      'satelliteCaptureStart'.tr(namedArgs: {'seconds': seconds});

  /// 유효하지 않은 플레이어 정보 경고 문구
  static String get satelliteUserInvalid => 'satelliteUserInvalid'.tr();

  /// 원격 모드 점령 성공 완료 안내 문구
  static String get satelliteCaptureSuccess => 'satelliteCaptureSuccess'.tr();

  /// 원격 모드 점령 실패 경고 문구
  static String get satelliteCaptureFail => 'satelliteCaptureFail'.tr();

  /// 원격 모드 점령 강제 중단 타이틀
  static String get satelliteAbortTitle => 'satelliteAbortTitle'.tr();

  /// 원격 모드 점령 취소 확인 질문 문구
  static String get satelliteAbortConfirm => 'satelliteAbortConfirm'.tr();

  /// 점령 계속 수행 버튼 라벨
  static String get satelliteKeepOperation => 'satelliteKeepOperation'.tr();

  /// 점령 중단 철회 버튼 라벨
  static String get satelliteCancelOperation => 'satelliteCancelOperation'.tr();

  /// HUD 골드 수치 표시 라벨
  static String get hudGold => 'hudGold'.tr();

  /// 원격 모드 정밀 조준 활성화 상태 라벨
  static String get satScanActive => 'satScanActive'.tr();

  /// 원격 모드 조준점 점령 시도 상태 라벨
  static String get satCapturingAttempt => 'satCapturingAttempt'.tr();

  /// 원격 모드 대기 작동 중 라벨
  static String get satCooltimeWaitingLabel => 'satCooltimeWaitingLabel'.tr();

  /// 원격 모드 통신 차단 라벨
  static String get satDisconnectedLabel => 'satDisconnectedLabel'.tr();

  /// 원격 모드 조준 준비 완료 라벨
  static String get satLockOnReady => 'satLockOnReady'.tr();

  /// 이미 아군 점령 구역 라벨
  static String get satAlreadyCapturedLabel => 'satAlreadyCapturedLabel'.tr();

  /// 점령 즉시 실행 버튼 라벨
  static String get captureExecute => 'captureExecute'.tr();

  /// 원격 모드 점령 시 필요 소모 GP 재화 명칭
  static String get satRequiredGold => 'satRequiredGold'.tr();

  /// 원격 모드 점령 시 소요시간 명칭
  static String get satRequiredTime => 'satRequiredTime'.tr();

  /// 원격 모드 점령 대기 단축 라벨
  static String get satCooltimeWaitingText => 'satCooltimeWaitingText'.tr();

  /// 원격 모드 점령 시 보유 재화 부족 상태 메시지
  static String get satGoldShortage => 'satGoldShortage'.tr();

  // --- 정책 동의 관련 ---
  /// 이용 정책 동의 화면 타이틀
  static String get termsAgreement => 'termsAgreement'.tr();

  /// 필수 및 선택 약관 전체 동의 버튼 라벨
  static String get agreeAll => 'agreeAll'.tr();

  /// 만 14세 이상 이용 동의 라벨
  static String get agreeAge => 'agreeAge'.tr();

  /// 서비스 이용약관 동의 라벨
  static String get agreeTerms => 'agreeTerms'.tr();

  /// 개인정보 수집 및 이용 동의 라벨
  static String get agreePrivacy => 'agreePrivacy'.tr();

  /// 위치기반 서비스 이용동의 약관 라벨
  static String get agreeLocation => 'agreeLocation'.tr();

  /// 마케팅 알림 수신 동의 라벨
  static String get agreeMarketing => 'agreeMarketing'.tr();

  /// 약관 상세 내용 보기 버튼 라벨
  static String get viewDetail => 'viewDetail'.tr();

  /// 동의하고 계속 진행하기 버튼 라벨
  static String get agreeAndContinue => 'agreeAndContinue'.tr();

  /// 서비스 이용약관 상세 바텀시트 타이틀
  static String get agreeTermsBottomSheetTitle =>
      'agreeTermsBottomSheetTitle'.tr();

  /// 개인정보 처리방침 상세 바텀시트 타이틀
  static String get agreePrivacyBottomSheetTitle =>
      'agreePrivacyBottomSheetTitle'.tr();

  /// 위치 정보 서비스 약관 상세 바텀시트 타이틀
  static String get agreeLocationBottomSheetTitle =>
      'agreeLocationBottomSheetTitle'.tr();

  /// 마케팅 수신동의 상세 바텀시트 타이틀
  static String get agreeMarketingBottomSheetTitle =>
      'agreeMarketingBottomSheetTitle'.tr();

  /// 서비스 이용약관 상세 본문 문구
  static String get agreeTermsDetail => 'agreeTermsDetail'.tr();

  /// 개인정보 처리방침 상세 본문 문구
  static String get agreePrivacyDetail => 'agreePrivacyDetail'.tr();

  /// 위치 정보 서비스 약관 상세 본문 문구
  static String get agreeLocationDetail => 'agreeLocationDetail'.tr();

  /// 마케팅 정보 수신동의 상세 본문 문구
  static String get agreeMarketingDetail => 'agreeMarketingDetail'.tr();

  /// 백그라운드 위치 권한 설정 팝업 타이틀
  static String get bgLocationSetupTitle => 'bgLocationSetupTitle'.tr();

  /// 백그라운드 위치 권한 설정 팝업 메시지
  static String get bgLocationSetupMessage => 'bgLocationSetupMessage'.tr();

  /// 나중에 버튼 라벨
  static String get later => 'later'.tr();

  /// 설정하기 버튼 라벨
  static String get setupNow => 'setupNow'.tr();

  /// 백그라운드 통신 보장 설정 팝업 타이틀
  static String get bgNetworkSetupTitle => 'bgNetworkSetupTitle'.tr();

  /// 백그라운드 통신 보장 설정 팝업 메시지
  static String get bgNetworkSetupMessage => 'bgNetworkSetupMessage'.tr();

  /// 계정 삭제 버튼 라벨
  static String get deleteAccount => 'deleteAccount'.tr();

  /// 계정 삭제 경고 타이틀
  static String get deleteAccountConfirmTitle =>
      'deleteAccountConfirmTitle'.tr();

  /// 계정 삭제 안내 상세 경고 문구
  static String get deleteAccountConfirmMessage =>
      'deleteAccountConfirmMessage'.tr();

  /// 계정 삭제 동의 체크박스 라벨
  static String get deleteAccountCheckboxLabel =>
      'deleteAccountCheckboxLabel'.tr();

  /// 계정 삭제 완료 알림 문구
  static String get deleteAccountSuccess => 'deleteAccountSuccess'.tr();

  /// 점령 모드 변경 팝업 타이틀
  static String get modeChangeDialogTitle => 'modeChangeDialogTitle'.tr();

  /// 이동 모드 설명 타이틀
  static String get modeMoveTitle => 'modeMoveTitle'.tr();

  /// 이동 모드 상세 설명 본문
  static String get modeMoveDesc => 'modeMoveDesc'.tr();

  /// 원격 모드 설명 타이틀
  static String get modeRemoteTitle => 'modeRemoteTitle'.tr();

  /// 원격 모드 상세 설명 본문
  static String get modeRemoteDesc => 'modeRemoteDesc'.tr();

  /// 모드 기동 확인 버튼 라벨
  static String get modeConfirm => 'modeConfirm'.tr();

  /// 알림 성공 타이틀
  static String get alertSuccess => 'alertSuccess'.tr();

  /// 알림 경고 타이틀
  static String get alertWarn => 'alertWarn'.tr();

  /// 알림 오류 타이틀
  static String get alertError => 'alertError'.tr();

  /// 알림 안내 타이틀
  static String get alertInfo => 'alertInfo'.tr();

  // --- 위성/All-in-One 정보 팝업 관련 추가 번역 ---
  /// 이미 내 영토가 된 구역 안내 (동적 닉네임 전달)
  static String satAlreadyCapturedByMe(String nickname) =>
      'satAlreadyCapturedByMe'.tr(namedArgs: {'nickname': nickname});

  /// 다른 유저의 동네 안내
  static String get satOtherPlayerTerritory => 'satOtherPlayerTerritory'.tr();

  /// 재화 소모 정보 보기 라벨 (동적 거리 전달)
  static String satRevealVillageWithGp(String distance) =>
      'satRevealVillageWithGp'.tr(namedArgs: {'distance': distance});

  /// 원격점령하기 액션 라벨
  static String get satCaptureAction => 'satCaptureAction'.tr();

  /// 비밀 구역 안내 라벨
  static String get satSecretArea => 'satSecretArea'.tr();

  /// 비밀 은폐 안내 라벨
  static String get satSecretHidden => 'satSecretHidden'.tr();

  /// 땅주인 라벨
  static String get satVillageOwner => 'satVillageOwner'.tr();

  /// 땅주인 비밀 안내 라벨
  static String get satItsSecret => 'satItsSecret'.tr();

  /// 보호막 만료 시간 표시 (동적 시간 전달)
  static String satShieldWithTime(String time) =>
      'satShieldWithTime'.tr(namedArgs: {'time': time});

  /// 정보시간 표시 (동적 시간 전달)
  static String satPeekTimeWithTime(String time) =>
      'satPeekTimeWithTime'.tr(namedArgs: {'time': time});

  /// 점령 빈도 횟수 표시 (동적 횟수 전달)
  static String satCaptureCount(String count) =>
      'satCaptureCount'.tr(namedArgs: {'count': count});

  /// 언어 설정 타이틀
  static String get languageSettings => 'languageSettings'.tr();

  /// 언어 설정 상세 설명
  static String get languageSettingsSub => 'languageSettingsSub'.tr();

  /// 표시 언어 선택 타이틀
  static String get selectLanguage => 'selectLanguage'.tr();

  /// 한국어
  static String get languageKorean => 'languageKorean'.tr();

  /// 영어
  static String get languageEnglish => 'languageEnglish'.tr();

  /// 언어 변경 완료 알림
  static String get languageChanged => 'languageChanged'.tr();

  /// 한국어로 언어 변경 완료 알림
  static String get languageChangedToKorean => 'languageChangedToKorean'.tr();

  /// 영어로 언어 변경 완료 알림
  static String get languageChangedToEnglish => 'languageChangedToEnglish'.tr();

  /// 보안 해제 실패 알림
  static String get satSecurityDecryptFailed => 'satSecurityDecryptFailed'.tr();

  /// 보안 해제 성공 알림
  static String get satSecurityDecryptSuccess =>
      'satSecurityDecryptSuccess'.tr();

  /// 위성 점령 골드 부족 상세 정보 (required, current 인자)
  static String satGoldShortageDetail(String required, String current) =>
      'satGoldShortageDetail'.tr(
        namedArgs: {'required': required, 'current': current},
      );

  /// 약관 기록 없음 알림
  static String get termsAgreementRecordNotFound =>
      'termsAgreementRecordNotFound'.tr();

  /// 필수 동의 누락 알림
  static String get requiredPolicyAgreementMissing =>
      'requiredPolicyAgreementMissing'.tr();

  /// '필수' 라벨
  static String get requiredLabel => 'requiredLabel'.tr();

  /// '초' 단위 매핑
  static String secondsUnit(String seconds) =>
      'secondsUnit'.tr(namedArgs: {'seconds': seconds});

  /// 언어 시스템 설명 라벨
  static String get appO10NSystem => 'appO10NSystem'.tr();

  /// 나의 순위 라벨
  static String get rankingMyLabel => 'rankingMyLabel'.tr();

  /// 월드 연결 로딩 메시지
  static String get loadingBaseConnection => 'loadingBaseConnection'.tr();

  /// 스플래시 화면 서브타이틀 번역 문자열
  static String get splashSubtitle => 'splashSubtitle'.tr();

  // --- 게임 설명서 (Game Guide) ---
  /// 게임 설명서 타이틀
  static String get gameGuide => 'gameGuide'.tr();

  /// 게임 설명서 서브타이틀
  static String get gameGuideSub => 'gameGuideSub'.tr();

  /// 게임 개요 타이틀
  static String get guideOverviewTitle => 'guideOverviewTitle'.tr();

  /// 게임 개요 내용
  static String get guideOverviewContent => 'guideOverviewContent'.tr();

  /// 이동 모드 설명 타이틀
  static String get guideMoveModeTitle => 'guideMoveModeTitle'.tr();

  /// 이동 모드 설명 내용
  static String get guideMoveModeContent => 'guideMoveModeContent'.tr();

  /// 원격 모드 설명 타이틀
  static String get guideRemoteModeTitle => 'guideRemoteModeTitle'.tr();

  /// 원격 모드 설명 내용
  static String get guideRemoteModeContent => 'guideRemoteModeContent'.tr();

  /// 본진 기지 설명 타이틀
  static String get guideHqTitle => 'guideHqTitle'.tr();

  /// 본진 기지 설명 내용
  static String get guideHqContent => 'guideHqContent'.tr();

  /// 구역 설명 타이틀
  static String get guideAreaTitle => 'guideAreaTitle'.tr();

  /// 구역 설명 내용
  static String get guideAreaContent => 'guideAreaContent'.tr();

  /// 점령 설명 타이틀
  static String get guideCaptureTitle => 'guideCaptureTitle'.tr();

  /// 점령 설명 내용
  static String get guideCaptureContent => 'guideCaptureContent'.tr();

  /// 영토 보호막 설명 타이틀
  static String get guideShieldTitle => 'guideShieldTitle'.tr();

  /// 영토 보호막 설명 내용
  static String get guideShieldContent => 'guideShieldContent'.tr();

  /// 보안 정보 조회 설명 타이틀
  static String get guideRevealTitle => 'guideRevealTitle'.tr();

  /// 보안 정보 조회 설명 내용
  static String get guideRevealContent => 'guideRevealContent'.tr();

  /// 실시간 경보 설명 타이틀
  static String get guideAlertTitle => 'guideAlertTitle'.tr();

  /// 실시간 경보 설명 내용
  static String get guideAlertContent => 'guideAlertContent'.tr();

  // --- HUD 정보창 다국어 라벨 ---
  /// 좌표 라벨
  static String get hudCoordinateLabel => 'hudCoordinateLabel'.tr();

  /// 점령횟수 라벨
  static String get hudCaptureCountLabel => 'hudCaptureCountLabel'.tr();

  /// 필요재화 라벨
  static String get hudRequiredGoldLabel => 'hudRequiredGoldLabel'.tr();

  /// 소요시간 라벨
  static String get hudRequiredTimeLabel => 'hudRequiredTimeLabel'.tr();

  /// 보안 구역 라벨
  static String get hudSecretAreaLabel => 'hudSecretAreaLabel'.tr();

  /// 정보 은폐됨 라벨
  static String get hudSecretHiddenLabel => 'hudSecretHiddenLabel'.tr();

  /// 중복 로그인 다이얼로그 타이틀
  static String get duplicateLoginTitle => 'duplicateLoginTitle'.tr();

  /// 중복 로그인 다이얼로그 본문
  static String get duplicateLoginMessage => 'duplicateLoginMessage'.tr();

  // --- 업적 관련 (Achievements) ---
  static String get achievementBoardTitle => 'achievementBoardTitle'.tr();
  static String get achievements => 'achievements'.tr();
  static String get achievementUnlockedAlert => 'achievementUnlockedAlert'.tr();
  static String get unlocked => 'unlocked'.tr();
  static String get locked => 'locked'.tr();

  // 1. 누적 점령 타일
  static String get achCapT1Title => 'achCapT1Title'.tr();
  static String get achCapT1Desc => 'achCapT1Desc'.tr();
  static String get achCapT2Title => 'achCapT2Title'.tr();
  static String get achCapT2Desc => 'achCapT2Desc'.tr();
  static String get achCapT3Title => 'achCapT3Title'.tr();
  static String get achCapT3Desc => 'achCapT3Desc'.tr();
  static String get achCapT4Title => 'achCapT4Title'.tr();
  static String get achCapT4Desc => 'achCapT4Desc'.tr();

  // 2. 적 진영 점령 타일
  static String get achInvT1Title => 'achInvT1Title'.tr();
  static String get achInvT1Desc => 'achInvT1Desc'.tr();
  static String get achInvT2Title => 'achInvT2Title'.tr();
  static String get achInvT2Desc => 'achInvT2Desc'.tr();
  static String get achInvT3Title => 'achInvT3Title'.tr();
  static String get achInvT3Desc => 'achInvT3Desc'.tr();
  static String get achInvT4Title => 'achInvT4Title'.tr();
  static String get achInvT4Desc => 'achInvT4Desc'.tr();

  // 3. 누적 이동 타일 수
  static String get achMovT1Title => 'achMovT1Title'.tr();
  static String get achMovT1Desc => 'achMovT1Desc'.tr();
  static String get achMovT2Title => 'achMovT2Title'.tr();
  static String get achMovT2Desc => 'achMovT2Desc'.tr();
  static String get achMovT3Title => 'achMovT3Title'.tr();
  static String get achMovT3Desc => 'achMovT3Desc'.tr();
  static String get achMovT4Title => 'achMovT4Title'.tr();
  static String get achMovT4Desc => 'achMovT4Desc'.tr();

  // 4. 일일 최고 이동 타일 수
  static String get achDmovT1Title => 'achDmovT1Title'.tr();
  static String get achDmovT1Desc => 'achDmovT1Desc'.tr();
  static String get achDmovT2Title => 'achDmovT2Title'.tr();
  static String get achDmovT2Desc => 'achDmovT2Desc'.tr();
  static String get achDmovT3Title => 'achDmovT3Title'.tr();
  static String get achDmovT3Desc => 'achDmovT3Desc'.tr();
  static String get achDmovT4Title => 'achDmovT4Title'.tr();
  static String get achDmovT4Desc => 'achDmovT4Desc'.tr();

  // 5. 위성 스캔 점령
  static String get achSatCapT1Title => 'achSatCapT1Title'.tr();
  static String get achSatCapT1Desc => 'achSatCapT1Desc'.tr();
  static String get achSatCapT2Title => 'achSatCapT2Title'.tr();
  static String get achSatCapT2Desc => 'achSatCapT2Desc'.tr();
  static String get achSatCapT3Title => 'achSatCapT3Title'.tr();
  static String get achSatCapT3Desc => 'achSatCapT3Desc'.tr();
  static String get achSatCapT4Title => 'achSatCapT4Title'.tr();
  static String get achSatCapT4Desc => 'achSatCapT4Desc'.tr();

  // 6. 위성 스캔 정보 조회
  static String get achSatInfT1Title => 'achSatInfT1Title'.tr();
  static String get achSatInfT1Desc => 'achSatInfT1Desc'.tr();
  static String get achSatInfT2Title => 'achSatInfT2Title'.tr();
  static String get achSatInfT2Desc => 'achSatInfT2Desc'.tr();
  static String get achSatInfT3Title => 'achSatInfT3Title'.tr();
  static String get achSatInfT3Desc => 'achSatInfT3Desc'.tr();
  static String get achSatInfT4Title => 'achSatInfT4Title'.tr();
  static String get achSatInfT4Desc => 'achSatInfT4Desc'.tr();

  // 7. 본부 기지(HQ) 중심 요새화
  static String get achHqFortT1Title => 'achHqFortT1Title'.tr();
  static String get achHqFortT1Desc => 'achHqFortT1Desc'.tr();
  static String get achHqFortT2Title => 'achHqFortT2Title'.tr();
  static String get achHqFortT2Desc => 'achHqFortT2Desc'.tr();
  static String get achHqFortT3Title => 'achHqFortT3Title'.tr();
  static String get achHqFortT3Desc => 'achHqFortT3Desc'.tr();
  static String get achHqFortT4Title => 'achHqFortT4Title'.tr();
  static String get achHqFortT4Desc => 'achHqFortT4Desc'.tr();

  // 8. 보유 골드 재화량
  static String get achGoldT1Title => 'achGoldT1Title'.tr();
  static String get achGoldT1Desc => 'achGoldT1Desc'.tr();
  static String get achGoldT2Title => 'achGoldT2Title'.tr();
  static String get achGoldT2Desc => 'achGoldT2Desc'.tr();
  static String get achGoldT3Title => 'achGoldT3Title'.tr();
  static String get achGoldT3Desc => 'achGoldT3Desc'.tr();
  static String get achGoldT4Title => 'achGoldT4Title'.tr();
  static String get achGoldT4Desc => 'achGoldT4Desc'.tr();
}

class GameUrls {
  static const String termsOfService = 'https://jjim.vercel.app/terms';
  static const String privacyPolicy = 'https://jjim.vercel.app/privacy';
}
