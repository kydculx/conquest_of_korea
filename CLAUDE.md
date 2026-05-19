# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
flutter pub get          # Install dependencies
flutter run              # Run on connected device/emulator
flutter build apk        # Build Android APK
flutter build ios        # Build iOS
flutter test             # Run all tests
flutter analyze          # Lint / static analysis
```

## Architecture

This is a Flutter location-based territory conquest game ("한국정복") for Korea. Players capture hexagonal tiles on a real map by physically visiting locations.

**Provider dependency chain** (defined in `main.dart`):
```
GeoService → LocationProvider → GameProvider
SupabaseService → GameProvider
ConquestGame (Flame, standalone)
```

**Layer breakdown:**
- `lib/services/` — Pure I/O. `SupabaseService` handles all DB reads/writes and realtime streams. `GeoService` wraps GPS. `HexService` converts lat/lng ↔ hex grid coordinates.
- `lib/providers/` — State. `LocationProvider` holds GPS + compass state. `GameProvider` owns all game state (tiles, score, capture progress, team) and reacts to location changes.
- `lib/controllers/` — Business logic extracted from providers. `CaptureController` owns the capture timer loop and calls back into `GameProvider` via callbacks.
- `lib/game/` — Flame engine layer (`ConquestGame`). Runs independently of the Provider tree; used for game rendering components.
- `lib/views/` — UI only. `GameScreen` is the single screen; `GameMapWidget` renders `flutter_map` with hex overlays; `HudOverlay` shows score/controls.
- `lib/core/` — `GameConstants` (all tunable values), `AppConfig` (env vars from `.env`), `TacticalTheme`.
- `lib/models/` — `HexTile` (tile state + owner), `GameAlert`, `TileOwner` enum.

**Key flows:**
- GPS update → `LocationProvider` notifies → `GameProvider.onLocationUpdated()` → `CaptureController.startCapture()` if auto-capture on
- Capture completes → `SupabaseService.captureTile()` upsert → realtime stream pushes update back to all clients
- Team selection persists via `SharedPreferences`; FCM topic subscriptions are managed in `GameProvider.setSelectedTeam()`

**Environment:** Credentials live in `.env` (loaded via `flutter_dotenv`). `AppConfig` reads them. The `.env` file is listed as a Flutter asset.

**Hex grid:** Axial coordinate system. `HexService.latLngToHex()` maps GPS coords to `(q, r)` hex. Tile IDs are `hex_{q}_{r}`. Tile size is ~400m.
