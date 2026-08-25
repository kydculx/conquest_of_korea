import 'package:flutter/material.dart';

/// 게임 전반에서 사용되는 공용 컬러 클래스 (외부 제어 및 동적 갱신 가능)
class GameColors {
  /// 내 영토(타일)용 화사한 비비드 네온 핑크 마젠타 (시인성과 화사함 대폭 보강)
  static Color myTileColor = const Color(0xFFFF17AB);
  static String get myTileColorHex =>
      '#${myTileColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

  /// 상대 영토(타일)용 화사하고 세련된 파스텔 라벤더 실버 블루 (칙칙한 회색 탈피)
  static Color enemyTileColor = const Color(0xFF9FA8DA);
  static String get enemyTileColorHex =>
      '#${enemyTileColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

  /// 앱 전반의 아기자기한 다크 테마용 배경 그라데이션
  static const Gradient cozyDarkGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF121824), // tacticalBlack
      Color(0xFF1C2434), // 약간 더 깊고 풍부한 다크 딥인디고
    ],
  );

  /// 핵심 솜사탕 블루 액센트 컬러 -> 비비드 솜사탕 네온 시안
  static Color accentNeon = const Color(0xFF00E5FF);

  /// 부가 액센트 컬러 -> 비비드 솜사탕 네온 시안
  static Color colorAccent = const Color(0xFF00E5FF);

  /// 부드러운 스카이 실버 민트 컬러 -> 포근한 다크 차콜 블루그레이
  static Color tacticalGray = const Color(0xFF263238);

  /// 화사한 베이비 스카이 블루 배경 컬러 -> 포근하고 부드러운 미드나잇 블루
  static Color tacticalBlack = const Color(0xFF121824);

  /// 완전 투명 색상
  static Color transparent = const Color(0x00000000);

  /// 공용 화이트 컬러
  static Color tacticalWhite = const Color(0xFFFFFFFF);

  /// 화사하고 부드러운 우유빛 반투명 크림 배경 컬러 -> 92% 불투명 다크 딥 인디고 젤리
  static Color backgroundMedium = const Color(0xF21A2232);

  /// 반투명 우유빛 오버레이 배경 컬러 -> 80% 반투명 다크 딥 인디고 젤리
  static Color backgroundTranslucent = const Color(0xCC1A2232);

  /// 가독성을 대폭 높인 메인 텍스트용 차콜 네이비 컬러 -> 맑고 뽀얀 파스텔 민트 화이트
  static Color textPrimary = const Color(0xFFECEFF1);

  /// 서브 텍스트용 소프트 실버 네이비 컬러 -> 온화한 소프트 실버 그레이
  static Color textSecondary = const Color(0xFFB0BEC5);

  /// 설명용 은은한 파스텔 블루 그레이 컬러 -> 소프트 그레이쉬 블루
  static Color textMuted = const Color(0xFF90A4AE);

  /// 파스텔 톤에 어울리는 연한 차콜 구분선 컬러 -> 화이트 반투명 구분선
  static Color dividerColor = const Color(0x15FFFFFF);

  /// 매우 연한 아기자기 테두리 컬러 -> 미세 화이트 반투명 테두리
  static Color borderLight = const Color(0x0FFFFFFF);

  /// 파스텔 블루 글로우 테두리 컬러 -> 네온 사이버 시안 반투명 테두리
  static Color borderNeon = const Color(0x3300E5FF);

  /// 정밀 미세 격자선 컬러 -> 화이트 초미세 격자선
  static Color techGrid = const Color(0x05FFFFFF);

  /// 상큼하고 부드러운 파스텔 그린 컬러 (성공/안전 상태)
  static Color success = const Color(0xFF81C784);

  /// 달콤한 파스텔 옐로우 오렌지 컬러 (주의/경고 상태)
  static Color warning = const Color(0xFFFFB74D);

  /// 부드러운 파스텔 솜사탕 핑크 레드 컬러 (위험/에러 상태)
  static Color error = const Color(0xFFE57373);

  /// 화사한 파스텔 라이트 블루 컬러 (일반 정보 상태)
  static Color info = const Color(0xFF64B5F6);

  /// 외부(API, DB, 파일 등)에서 넘어온 헥사 코드로 공용 컬러들을 동적 제어하는 메서드
  static void updateCommonColors({
    String? myColor,
    String? enemyColor,
    String? accent,
    String? gray,
    String? black,
    String? txtPrimary,
    String? txtSecondary,
    String? txtMuted,
    String? divColor,
    String? brdLight,
    String? stateSuccess,
    String? stateWarning,
    String? stateError,
    String? stateInfo,
    String? trans,
    String? tacWhite,
    String? bgMedium,
    String? bgTranslucent,
  }) {
    if (myColor != null) {
      final parsed = _parseHexColor(myColor);
      if (parsed != null) {
        myTileColor = parsed;
      }
    }
    if (enemyColor != null) {
      final parsed = _parseHexColor(enemyColor);
      if (parsed != null) {
        enemyTileColor = parsed;
      }
    }
    if (accent != null) {
      final parsed = _parseHexColor(accent);
      if (parsed != null) {
        accentNeon = parsed;
        colorAccent = parsed;
      }
    }
    if (gray != null) {
      final parsed = _parseHexColor(gray);
      if (parsed != null) tacticalGray = parsed;
    }
    if (black != null) {
      final parsed = _parseHexColor(black);
      if (parsed != null) tacticalBlack = parsed;
    }
    if (txtPrimary != null) {
      final parsed = _parseHexColor(txtPrimary);
      if (parsed != null) textPrimary = parsed;
    }
    if (txtSecondary != null) {
      final parsed = _parseHexColor(txtSecondary);
      if (parsed != null) textSecondary = parsed;
    }
    if (txtMuted != null) {
      final parsed = _parseHexColor(txtMuted);
      if (parsed != null) textMuted = parsed;
    }
    if (divColor != null) {
      final parsed = _parseHexColor(divColor);
      if (parsed != null) dividerColor = parsed;
    }
    if (brdLight != null) {
      final parsed = _parseHexColor(brdLight);
      if (parsed != null) borderLight = parsed;
    }
    if (stateSuccess != null) {
      final parsed = _parseHexColor(stateSuccess);
      if (parsed != null) success = parsed;
    }
    if (stateWarning != null) {
      final parsed = _parseHexColor(stateWarning);
      if (parsed != null) warning = parsed;
    }
    if (stateError != null) {
      final parsed = _parseHexColor(stateError);
      if (parsed != null) error = parsed;
    }
    if (stateInfo != null) {
      final parsed = _parseHexColor(stateInfo);
      if (parsed != null) info = parsed;
    }
    if (trans != null) {
      final parsed = _parseHexColor(trans);
      if (parsed != null) transparent = parsed;
    }
    if (tacWhite != null) {
      final parsed = _parseHexColor(tacWhite);
      if (parsed != null) tacticalWhite = parsed;
    }
    if (bgMedium != null) {
      final parsed = _parseHexColor(bgMedium);
      if (parsed != null) backgroundMedium = parsed;
    }
    if (bgTranslucent != null) {
      final parsed = _parseHexColor(bgTranslucent);
      if (parsed != null) backgroundTranslucent = parsed;
    }
  }

  /// 헥사 코드 문자열(#RRGGBB 또는 #AARRGGBB)을 Color 객체로 파싱하는 헬퍼 메서드
  static Color? _parseHexColor(String hex) {
    try {
      final buffer = StringBuffer();
      if (hex.length == 6 || hex.length == 7) buffer.write('ff');
      buffer.write(hex.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (e) {
      return null;
    }
  }
}

/// 게임 UI 전반에서 사용하는 고정 컬러 팔레트 (컴파일 타임 상수).
///
/// 하드코딩된 `Color(0x...)` 리터럴을 대체하기 위한 단일 참조 지점입니다.
/// 서버/외부 설정으로 동적 변경이 필요한 색상은 [GameColors]를 사용하세요.
class Palette {
  Palette._();

  // --- 액센트 ---
  /// 네온 사이버 시안 액센트 (기본 버튼 글로우, 강조 테두리)
  static const Color accentCyan = Color(0xFF00E5FF);

  /// 딥 시안 (액센트 그라데이션 하단)
  static const Color cyanDeep = Color(0xFF00838F);

  /// 발자취 조회 전용 네온 민트
  static const Color footprintMint = Color(0xFF00FFCC);

  /// 브라이트 블루 (패턴/맵 모드 포인트)
  static const Color brightBlue = Color(0xFF0066FF);

  /// 딥 블루 (브라이트 블루 그라데이션 하단)
  static const Color deepBlue = Color(0xFF0033AA);

  /// 스카이 블루 (그라데이션 보조)
  static const Color skyBlue = Color(0xFF00BFFF);

  // --- 상태 · 위험 ---
  /// 위성 점령·경고 강조 레드
  static const Color redAccent = Color(0xFFFF5252);

  /// 소프트 레드 (에러 계열)
  static const Color softRed = Color(0xFFE57373);

  /// 다크 레드 (레드 그라데이션 하단)
  static const Color darkRed = Color(0xFFC62828);

  /// 연한 로즈 (하이라이트 레드)
  static const Color roseLight = Color(0xFFFF8A80);

  /// 성공 상태 그린
  static const Color greenSoft = Color(0xFF81C784);

  /// 확인/완료 그린
  static const Color greenConfirm = Color(0xFF4CAF50);

  /// 네온 그린 (즉시 획득 계열)
  static const Color neonGreen = Color(0xFF00E676);

  /// 안정 청록
  static const Color tealOk = Color(0xFF00AA88);

  /// 경고 오렌지 (소프트)
  static const Color orangeWarning = Color(0xFFFFB74D);

  /// 앰버 하이라이트
  static const Color amberHighlight = Color(0xFFFFD54F);

  /// 정보 블루
  static const Color blueInfo = Color(0xFF64B5F6);

  /// 연한 정보 블루
  static const Color blueSoft = Color(0xFF90CAF9);

  /// 라벤더 (상대 영토 계열 보조)
  static const Color lavender = Color(0xFF9FA8DA);

  // --- 랭킹 메달 ---
  /// 랭킹 골드 (브라이트)
  static const Color gold = Color(0xFFFFD700);

  /// 클래식 골드
  static const Color goldClassic = Color(0xFFD4AF37);

  /// 다크 골드
  static const Color goldDark = Color(0xFFB8860B);

  /// 딥 골드
  static const Color goldDeep = Color(0xFF8B6508);

  /// 실버
  static const Color silver = Color(0xFFC0C0C0);

  /// 브론즈
  static const Color bronze = Color(0xFFCD7F32);

  // --- 오렌지 스케일 (진행도/포인트) ---
  static const Color orangeVivid = Color(0xFFFF9900);
  static const Color orangeSunset = Color(0xFFFF9100);
  static const Color orangeStrong = Color(0xFFFF8800);
  static const Color orangeWarm = Color(0xFFFF7700);
  static const Color orange = Color(0xFFFFA500);
  static const Color orangeCoral = Color(0xFFFF8A65);
  static const Color orangeBurnt = Color(0xFFE65100);
  static const Color orangeRust = Color(0xFFD84315);

  // --- 중립 · 배경 ---
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color transparent = Color(0x00000000);
  static const Color snowWhite = Color(0xFFECEFF1);
  static const Color creamYellow = Color(0xFFFFF7C2);
  static const Color greyLight = Color(0xFFE0E0E0);
  static const Color greyMid = Color(0xFF9E9E9E);
  static const Color greyBlue = Color(0xFFB0BEC5);
  static const Color greyBlueMid = Color(0xFF78909C);
  static const Color greyBlueLight = Color(0xFF90A4AE);
  static const Color slateDark = Color(0xFF263238);
  static const Color slateBlue = Color(0xFF37474F);
  static const Color graphite = Color(0xFF212121);
  static const Color charcoalLight = Color(0xFF1E1E1E);
  static const Color charcoal = Color(0xFF121212);
  static const Color deepNavy = Color(0xFF0F1626);
  static const Color midnightNavy = Color(0xFF121824);
  static const Color indigoNight = Color(0xFF1C2434);
  static const Color brownDark = Color(0xFF5D4037);
  static const Color magentaBrand = Color(0xFFFF17AB);

  // --- 반투명 오버레이 ---
  static const Color navyOverlay92 = Color(0xF21A2232);
  static const Color navyOverlay80 = Color(0xCC1A2232);
  static const Color whiteOpacity20 = Color(0x33FFFFFF);
  static const Color cyanOpacity20 = Color(0x3300E5FF);
  static const Color whiteOpacity8 = Color(0x15FFFFFF);
  static const Color whiteOpacity2 = Color(0x0FFFFFFF);
}
