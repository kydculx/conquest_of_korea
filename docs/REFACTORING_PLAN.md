# 리팩토링 계획서

> **상태**: P1 · P2 실행 완료 (2026-08-25) — P3는 대기 중
> **작성일**: 2026-08-25
> **범위 근거**: `flutter analyze`(프로젝트 코드 클린), 파일 크기 측정, 호출부 그래프 분석

---

## 1. 진단 요약

| # | 항목 | 현황 | 심각도 |
|---|------|------|--------|
| 1 | `lib/providers/game_provider.dart` | **1,528줄** god class. 지도 뷰/알림/스캔/발자국 모드/동전/폴링/UTC 타이머/lifecycle 등 최소 8개 책임. Location·Auth·Achievement 프로바이더 setter 주입으로 강결합 | 높음 |
| 2 | 하드코딩 색상 | `Color(0x...)` 리터럴 **157곳 / 26파일**. `core/constants/colors.dart`가 존재하는데도 산재 (`ranking_screen.dart`에만 25곳) | 중간 |
| 3 | `lib/views/screens/profile_screen.dart` | **1,019줄** 단일 화면 파일 | 중간 |
| 4 | `lib/core/constants/strings.dart` | **1,426줄** 도메인 무관 단일 문자열 덩어리 | 낮음 |
| 5 | CLAUDE.md | 실제 구조와 어긋남 — 문서는 "화면 1개(GameScreen)"로 기술되나 실제로는 스크린 12+, 프로바이더 6, 서비스 10, 컨트롤러 4 | 낮음 |
| 6 | 정적 분석 | 프로젝트 코드 lint 사실상 클린 (654건 중 대부분 `build/` 산출물 노이즈) | — |

**긍정적 기반**: 이미 `CaptureController`, `SatelliteCaptureController`, `NotificationController`, `GoldManager`, `GameTileProvider`로 위임하는 패턴이 수립되어 있고, `PreferencesService`가 SharedPreferences 접근을 성공적으로 중앙화함. → 신규 추출 시 **기존 컨트롤러 패턴을 그대로 따른다.**

---

## 2. P1 — GameProvider 분해 (최우선)

### 2.1 현재 책임 → 이전 대상 매핑

| 책임 그룹 | 관련 상태 (행 번호) | 이전 대상 (신규) |
|-----------|---------------------|------------------|
| UTC 자정 카운트다운 | `_utcTimer`, `_utcTimeString` (L63–69) | `UtcCountdownController` |
| 인게임 알림 배너 | `_alerts`, `addAlert/_addAlertInternal/_removeAlert` (L73, L1028–1066) | `GameAlertManager extends ChangeNotifier` |
| 위성 스캔 선택 | `_isScanMode`, `_selectedScanTileId/LatLng` (L123–125), `toggleScanMode/selectScanTile` (L1067–1096) | `TileSelectionController` |
| 발자국 타일 선택 | `_selectedFootprintTileId/LatLng` (L128–131), `selectFootprintTile/clearSelectedFootprint/toggleFootprintMode` (L980, L1097–1121) | `TileSelectionController` (스캔과 동일 형태이므로 통합) |
| 지도 뷰(카메라/스타일/모드) | `_currentMapStyleIndex`, `_isMapRotationMode`, `_isFollowingUser`, `_mapMode`, `_mapMoveRequestController` (L91–120), `requestMapMove/cycleMapStyle/setFollowingUser/cycleMapMode/_showMapModeAlert` | `MapViewController` |
| 동전 아이템 | `_coins`, `_isRegeneratingCoins` (L138–142) | 기존 `GoldManager`로 흡수 |
| 위치 처리 오케스트레이션 | `onLocationUpdated()` **약 216줄** (L716–932) | GameProvider 잔여본에서 단계별 private 메서드로 분절 후, 점령 판정 부분은 `CaptureController`로 이관 검토 |

### 2.2 분해 후 구조 (목표)

```
GameProvider (파사드 + 오케스트레이터, 목표 ~500줄 이하)
├── GameTileProvider        (기존) 타일 데이터/실시간 동기화
├── CaptureController       (기존) 점령 타이머 루프
├── SatelliteCaptureController (기존) 위성 원격 점령
├── NotificationController  (기존) FCM 구독
├── GoldManager             (기존) ← 코인 상태 흡수
├── MapViewController       (신규) 지도 카메라/스타일/MapMode
├── TileSelectionController (신규) 스캔+발자국 타일 선택 상태
├── GameAlertManager        (신규) 알림 배너 목록
└── UtcCountdownController  (신규) UTC 카운트다운 타이머
```

### 2.3 소비자 영향 범위 (24 호출부 / 15 파일)

`hud_overlay.dart`, `game_map_widget.dart`(4곳), `game_screen.dart`, `splash_screen.dart`(3곳), `profile_screen.dart`(2곳), `achievement_screen.dart`(2곳), `satellite_bubble_card.dart`(2곳), `tile_photo_viewer_dialog.dart`(2곳), 그 외 HUD 위젯 다수.

**호환 전략 (소비자 코드 무변경)**: 1단계에서는 GameProvider의 public getter/method를 **위임 파사드로 유지**하여 소비자 15개 파일을 건드리지 않음. 파사드 제거(소비자가 각 컨트롤러를 직접 watch)는 별도 후속 단계로 선택 사항.

### 2.4 실행 순서 (각 단계 = 독립 커밋 가능한 원자적 변경)

| 단계 | 작업 | 예상 감소량 | 검증 |
|------|------|------------|------|
| S1 | UTC 카운트다운 추출 (가장 단순, 의존성 없음) | −40줄 | analyze + test |
| S2 | 알림 배너 → `GameAlertManager` 추출 | −60줄 | analyze + test |
| S3 | 스캔/발자국 선택 → `TileSelectionController` 추출 | −90줄 | analyze + test |
| S4 | 코인 상태 → `GoldManager` 흡수 | −50줄 | analyze + test |
| S5 | 지도 뷰 상태 → `MapViewController` 추출 | −150줄 | analyze + test |
| S6 | `onLocationUpdated()` 216줄을 단계별 메서드로 분절 | 가독성 | analyze + test |
| S7 | (선택) 파사드 제거 및 소비자 직접 참조 전환 | — | analyze + test + 수동 실행 |

**롤백**: 단계별 커밋으로 각 단계 독립 롤백 가능. S1~S4는 저위험, S5(S6)가 최대 위험(지도 위젯 연동).

---

## 3. P2-a — 하드코딩 색상 통합

- **대상**: `Color(0x...)` 157곳 / 26파일 (상위: `ranking_screen.dart` 25, `satellite_bubble_card.dart` 9, `pattern_guide_screen.dart` 8, `hex_tile_component.dart` 7)
- **방법**:
  1. `core/constants/colors.dart`에 의미 토큰 정의 (예: `rankGold`, `rankSilver`, `alertDanger` 등) — 이미 23개 정의된 토큰 재사용 우선
  2. 파일당 하나의 커밋으로 치환 (시각 회귀 대비 추적 용이)
- **주의**: `game/components/` 내 Flame 색상은 UI 테마와 분리된 게임 렌더링 값일 수 있음 → 동일 값 확인 후에만 치환

## 4. P2-b — profile_screen 분해

- **대상**: `lib/views/screens/profile_screen.dart` (1,019줄)
- **방법**: 섹션별 위젯으로 분리 → `views/widgets/profile/` 하위 배치 (예: 프로필 헤더, 골드/통계 카드, 설정 리스트, 로그아웃 영역). `profile_widgets.dart`(305줄)와의 역할 중복 여부 먼저 확인 후 통합 방향 결정

---

## 5. P3 — 문자열 분할 및 문서 갱신

### 5.1 strings.dart (1,426줄) 도메인별 분할
- `core/constants/strings/` 디렉터리로 분할 (예: `auth_strings.dart`, `game_strings.dart`, `ranking_strings.dart`, `achievement_strings.dart`)
- 기존 import 경로 유지를 위해 `strings.dart`에서 barrel export → 소비자 무변경

### 5.2 CLAUDE.md 갱신
- 실제 구조 반영: 스크린 12+, 프로바이더 6(auth/game_tile/ranking/achievement 추가), 서비스 10(analytics/audio/auth/health/notification/photo/preferences 추가), 컨트롤러 4(gold_manager/notification/satellite_capture 추가)
- Provider 의존 체계 다이어그램 수정

---

## 6. 공통 검증 절차

모든 단계 공통:
```bash
flutter analyze   # 신규 이슈 0 유지 (현재 클린)
flutter test      # 기존 테스트 전부 통과 유지
```
추가로 UI 관련 변경(P2)은 실기기/에뮬레이터 수동 확인 권장.

## 7. 미착용 · 향후 과제 (본 계획서 범위 외)

- `tactical_*.dart` 파일명(`tactical_compass.dart` 등) — 저장소 명명 규칙과 충돌 가능. 사용자 확인 후 rename 별도 진행
- 배경 조사에서 세션 유실로 미완료된 항목: 비동기/스트림 누수 정밀 감사, 데드코드 감사

---

## 8. P1 실행 결과 (2026-08-25)

### 8.1 성과

| 항목 | 이전 | 이후 |
|------|------|------|
| `game_provider.dart` | 1,528줄 | **1,184줄** (−344줄) |
| 추출된 클래스 | — | 신규 5개 (`UtcCountdownController`, `GameAlertManager`, `TileSelectionController`, `CoinManager`, `MapViewController`) |
| 검증 | — | 각 단계 `flutter analyze` 신규 이슈 0 + `flutter test` 기존 상태 동일 (+28 / 기존 실패 3건 변화 없음) |

### 8.2 계획 대비 변경 사항

| 항목 | 계획 | 실제 | 사유 |
|------|------|------|------|
| S4 코인 상태 | `GoldManager` 흡수 | **별도 `CoinManager`** 로 분리 | 골드 잔액 누적과 동전 생성/수집은 책임이 다르고 코드량 ~235줄로, 흡수 시 GoldManager가 430줄+ 혼합 책임 클래스가 됨. 기존 매니저 패턴 준수 |
| `MapMode` enum | (미명시) | `lib/models/map_mode.dart` 로 분리 | `MapViewController`와 소비자 위젯(`hud_map_mode_button`, `hud_overlay`)이 참조. models 배치가 원칙에 부합 |
| `build/` 제외 | 권장 사항 | `analysis_options.yaml` 적용 | analyze 노이즈(654건) 제거로 검증 정확도 확보 |

### 8.3 남은 과제 (목표 "파사드 ~500줄" 도달 위해)

현재 1,184줄. 잔여 비대 영역:
- 생성자 내 컨트롤러 와이어링 (~165줄) — 팩토리/빌더로 분리 검토
- 사진첩 기능 (`loadPhotosForTile`, `uploadPhotoForTile`, `deletePhotoForTile`, `_tilePhotosCache`) — `PhotoManager` 추출 후보 (~120줄)
- 골드 지출 오케스트레이션 (`revealTileInfo`, `rebaseMainBase`) — GoldManager 연계 정리 후보 (~100줄)
- S7(선택): 파사드 getter 제거 및 소비자가 각 컨트롤러를 직접 참조하도록 전환

### 8.4 테스트 관련 확인 사항

- `test/satellite_capture_test.dart` 연결성 1건: HEAD 상태에서도 실패하는 **기존 실패** (stash 검증으로 확인)
- `test/db_footprint_record_test.dart`, `test/db_rpc_verify_test.dart`: 실서버 의존 테스트로 환경/네트워크에 따라 간헐 실패 (HEAD에서도 동일)

---

## 9. P2 실행 결과 (2026-08-25)

### 9.1 P2-a — 하드코딩 색상 통합

| 항목 | 이전 | 이후 |
|------|------|------|
| `Color(0x...)` 리터럴 | 157곳 / 26파일 | **0곳** (`core/constants/colors.dart` 정의부 제외) |
| 신규 토큰 | — | `Palette` 클래스 (static const, ~60개 의미 토큰: 액센트/상태/랭킹 메달/오렌지 스케일/중립/반투명 오버레이) |

**설계 결정**: 기존 `GameColors`(가변 static, 서버 동적 제어 지원) 대신 **불변 `Palette`(static const)** 로 치환.
- 이유: const 컨텍스트(기본 매개변수, const 생성자 인자)에서 가변 토큰 사용 시 컴파일 에러 발생 + 값 불변이므로 시각 변화 0 보장
- 참고: Dart 문법상 `const Palette.gold`는 이름 붙은 생성자 호출로 해석되므로 static const 참조에 `const` 접두사 금지
- 향후 과제: 어떤 색상을 외부 동적 제어(GameColors.updateCommonColors) 대상에 포함할지 제품 결정 후 단계적 전환 필요

### 9.2 P2-b — profile_screen 분해

| 항목 | 이전 | 이후 |
|------|------|------|
| `profile_screen.dart` | 1,019줄 (build() 약 850줄 메가 빌드) | **249줄** 컴포지션 루트 |
| 신규 모듈 | — | `views/widgets/profile/` 7개 파일 (46~280줄) |

분리 목록:
- `profile_header_card.dart` (121) — 상단 카드 위젯
- `notification_sub_settings.dart` (46) — 알림 세부 토글 섹션
- `nickname_change_dialog.dart` (280) — 닉네임 변경 다이얼로그 (검증·골드 비용 포함)
- `gps_accuracy_dialog.dart` (103) — GPS 정확도 선택 다이얼로그
- `account_dialogs.dart` (130) — 로그아웃/회원 탈퇴 확인 다이얼로그
- `rebase_flow.dart` (126) — 본진 이전 플로우 (위치 검증→비용→확인→서버 반영)
- `contact_support.dart` (46) — 문의하기 메일 실행

기존 `profile_widgets.dart`(공용 프리미티브)는 유지. 모든 다이얼로그/플로우는 기존 인스턴스 메서드를 최상위 함수로 그대로 이식(동작 동일).

### 9.3 검증

- `flutter analyze`: lib/ 신규 이슈 0 (4건 = 테스트 파일 기존 이슈)
- `flutter test`: 기존 상태 동일 (+28 / 기존 실패 3건)

### 9.4 관찰된 기존 이슈 (수정하지 않음 — 별도 과제)

- `nickname_change_dialog.dart`: TextEditingController가 dispose되지 않음 (원본 코드부터 존재)
- `tactical_*` 접두어 파일명: §7 명명 규칙 논의와 함께 검토 필요
