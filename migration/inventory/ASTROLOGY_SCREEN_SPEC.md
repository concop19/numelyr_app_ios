# Astrology screen — React Native parity specification

## React Native source audited

- `numelyra_app/src/screens/AstrologyScreen.tsx`
- `numelyra_app/src/features/astrology/AstrologyInsightSheet.tsx`
- `numelyra_app/src/features/astrology/useDailyAstroFortune.ts`
- `numelyra_app/src/features/astrology/dailyAstroFortune.ts`
- `numelyra_app/src/features/constellation/ConstellationCanvas.tsx`
- `numelyra_app/src/features/constellation/constellationPresets.ts`
- `numelyra_app/src/features/constellation/constellationGeometry.ts`
- `numelyra_app/src/features/constellation/constellationSkia.ts`
- `numelyra_app/src/services/astro/astroFortuneService.ts`
- `numelyra_app/src/services/astro/astroVectorEngine.ts`
- `numelyra_app/src/services/astro/astroEngine.ts`
- `numelyra_app/src/services/astro/aspectCalculator.ts`
- `numelyra_app/App.tsx`

## Reachable behavior

### 1. Visual layers, video background & constellation canvas

- Root screen uses dark night background `#02091D` (`preferredColorScheme(.dark)`).
- Background video layer (`astrology-aurora.mp4`):
  - Loops continuously, muted (`isMuted = true`), mixes with external audio (`AVAudioSession.Category.ambient` with `.mixWithOthers`), and does not stay active in the background.
  - Plays only when the screen is visible (`isScreenVisible == true`), app state is active (`isAppActive == true`), Accessibility Reduce Motion is disabled (`reduceMotion == false`), and video playback has not failed (`hasVideoFailed == false`).
  - While the video is preparing its first frame (`!isVideoReady`), when Reduce Motion is enabled, or on playback error, displays the bundled fallback image `AstrologyGalaxyBackground` (`resizeMode="cover"`).
- Night veil overlay: full-screen non-interactive `rgba(0, 13, 50, 0.10)`.
- Constellation canvas (`ConstellationCanvasView`):
  - Renders `105` deterministic ambient stars (`seed = 0x4E554D45`) across the full canvas.
  - Selects the daily constellation symbol deterministically from `(localDate, profileKey)` via `ConstellationEngine.dailySymbol`.
  - Fits the sampled SVG constellation contours into `{ x: 0.16 * width, y: (compact ? 0.23 : 0.24) * height, width: 0.68 * width, height: (compact ? 0.27 : 0.32) * height }` where `compact = height > 0 && height < 720`.
  - Breathing pulse animation oscillates opacity (`0.88...1.0`) and scale (`0.996...1.004`), or stays static at `1.0` when Reduce Motion is enabled.
  - If SVG geometry construction fails, renders a warning banner at `top = safeAreaTop + 150`: `Biểu tượng hôm nay đang tạm ẩn.`.
- Bottom vignette gradient: full-screen non-interactive linear gradient `['rgba(2,8,29,0)', 'rgba(2,8,29,0.08)', 'rgba(2,8,29,0.48)']` at locations `[0, 0.68, 1]`.

### 2. Header & date display

- Centered top brand block (`paddingTop = safeAreaTop + 8`, `paddingHorizontal = 18`):
  - Title `Numelyra` (`#FFFFFF`, 31pt serif, tracking `0.6`, shadow `rgba(65,199,255,0.4)` radius `12`).
  - Divider row (`marginTop = 3`, gap `7`): two `35pt` hairline bars (`#7CEBFF`) flanking a `sparkles` icon (`15pt`, `#7CEBFF`).
  - Date label (`marginTop = 10`): `Hôm nay • DD.MM` (`#F2F8FF`, 15pt, tracking `0.3`, shadow `rgba(0,0,0,0.65)` radius `6`).

### 3. Daily fortune lifecycle, caching & midnight rollover

- Resolves `profile` from parent or `UserProfileClient.activeProfile()`. When `profile` is nil, defaults to `birthDate = "1998-10-20"`, `birthTime = nil`, `fullName = "Đương số"`.
- On initial load or date/profile change (`allowCache = true`):
  - Checks `AstrologyFortuneCache` (`cachedDailyFortune`). If a cached `AstroFortuneSlip` exists, backfills `astroMetadata` when missing, saves back to cache, and renders immediately **without** firing a notification haptic.
  - On cache miss, computes the 32-dimension astro vector & metadata, loads up to 7 prior-day unique advice strings (`recentAdvice`), resolves the daily ca dao from `CaDaoClient.dailyCaDao(date)` (falling back to `AstrologyClient.fallbackAnchor` if empty), calls `POST /api/astro/fortune`, caches the resulting slip, and triggers `HapticClient.success()`.
- Stale in-flight requests are cancelled whenever the date, profile, or retry state changes.
- Schedules a midnight timer for the next local day (`00:00:00.250`) and checks local date key on foreground activation so crossing midnight automatically updates the header date, constellation symbol, and daily fortune.

### 4. Bottom content states & actions

- Always displays eyebrow `BIỂU TƯỢNG HÔM NAY · <SYMBOL TITLE>` (`#6DEBFF`, 11pt heavy, tracking `1.75`, uppercase).
- **Loading state (`isLoading == true`)**:
  - `ProgressView` (`#71E7FF`) + `Đang đọc bầu trời của bạn...` (`#E2F7FF`, 14pt semibold).
- **Error state (`!isLoading && errorMessage != nil`)**:
  - Card (`rgba(3,19,57,0.78)`, border `rgba(124,235,255,0.45)`, radius `18`, padding `14`) showing `errorMessage` (max 2 lines) and capsule button `Thử lại` (`#5BBEFF` border, `rgba(15,96,151,0.35)` fill).
  - Tapping `Thử lại` triggers `HapticClient.mediumImpact()` and fetches a fresh fortune ignoring cache (`.reloadIgnoringCache`).
- **Loaded state (`!isLoading && fortune != nil`)**:
  - Fortune title: `fortune.title || "Quẻ hôm nay"` (`compact ? 17pt : 20pt` heavy, `#FFFFFF`).
  - Fortune verse: `fortune.verse` (`compact ? 17pt : 20pt` serif italic, `#FFFFFF`, max `compact ? 3 : 4` lines, `minimumScaleFactor(0.84)`).
  - Action buttons row (`height = 48`, radius `24`, gap `10`, `marginTop = 15`):
    1. `Chia sẻ quẻ` (`flex = 0.9`, border `rgba(91,190,255,0.85)`, fill `rgba(3,24,70,0.72)`): triggers `HapticClient.lightImpact()` and presents native share sheet with title `fortune.title || "Lá Thăm Chiêm Tinh"` and message:
       `📜 LÁ THĂM CHIÊM TINH HÔM NAY: <title || 'Quẻ Xăm Dân Gian'>\n\n<verse>\n\n🪞 Gương soi: <mirror>\n🎒 Kế sách: <advice>\n\n✨ Bốc quẻ chiêm tinh dân gian trên Numelyra.`
    2. `Xem giải mã` (`flex = 1.1`, border `#5BBEFF`, fill `rgba(3,24,70,0.78)`, shadow `#21BFFF`): triggers `HapticClient.lightImpact()` and opens `AstrologyInsightSheet`.

### 5. Astrology Insight Sheet (`AstrologyInsightSheet`)

- Automatically dismisses if `fortune` becomes `nil`.
- Dark gradient sheet `['#0A1740', '#080D25', '#050716']` (`88%` height detent, top radius `28`, top border `rgba(104, 220, 255, 0.42)`):
  - Header: eyebrow `GIẢI MÃ CHIÊM TINH` (`#71E7FF`, 10pt heavy, tracking `1.8`), title `fortune.title || "Quẻ hôm nay"` (`#FFFFFF`, 21pt serif), close button (`40×40`, accessibility label `Đóng`).
  - Insight cards:
    - `Gương soi tâm trí` (eye icon `#A78BFA`, body `fortune.mirror`)
    - `Kế sách bỏ túi` (flash/bolt icon `#5EEAD4`, body `fortune.advice`)
  - `Lá số bản mệnh` (when `metadata != nil`):
    - Description: `Dựa trên ngày sinh <birthDate><birthTime ? " lúc <birthTime>" : " với giờ sinh ước lượng">.`
    - 2-column grid for `Mặt Trời bản mệnh` & `Mặt Trăng bản mệnh` (localized via `ZODIAC_VI` with zodiac glyphs `♈...♓`) + full-width card `Khí chất nổi trội` (`<dominantElement> · <dominantModality>`).
  - `Bầu trời hôm nay` (when `metadata != nil`):
    - `metadata.vibeSummary`
    - `Mặt Trăng quá cảnh` card (`ZODIAC_VI[transitMoonSign]`)
    - `Góc chiếu nổi bật` card (when `metadata.topAspect != nil`): `<PLANET_VI[transitPlanet]> · <nameVi> · <PLANET_VI[natalPlanet]>` and `Góc <actualAngle.toFixed(0)>° · Sai số <orb.toFixed(1)>°`.
    - `ScoreBar` card with 3 percentage bars (`Math.round(value * 100)%`): `Hài hòa` (`#5EEAD4`), `Thử thách` (`#FB7185`), `Hội tụ` (`#FBBF24`).
  - `Nhịp ca dao neo quẻ` (when `fortune.anchorCaDao.content` is non-empty):
    - Quoted verse `“<content>”` (serif italic) and optional `category` (`#71E7FF`).

## Native iOS mapping

| Responsibility | Swift target |
| --- | --- |
| Astronomical calculations, 32-dim vector, Porphyry houses, aspect analysis | `Shared/Engines/AstrologyEngine.swift` |
| Daily constellation symbol catalog & SVG path sampling/fitting | `Shared/Models/Constellation*.swift`, `Shared/Engines/ConstellationEngine.swift` |
| Daily fortune orchestration, cache v4/v3/v2, `CaDaoClient` daily anchor & API client | `Core/Clients/AstrologyClient.swift`, `Core/Clients/AstrologyFortuneCache.swift` |
| TCA State, Action, Reducer, midnight rollover & share formatting for Astrology screen | `Features/Astrology/AstrologyFeature.swift` |
| TCA State, Action, Reducer & Vietnamese localization helpers for Insight sheet | `Features/Astrology/AstrologyInsightFeature.swift` |
| SwiftUI Astrology screen + `AVQueuePlayer`/`AVPlayerLooper` background video | `Features/Astrology/AstrologyView.swift` |
| SwiftUI Constellation canvas (`Canvas` + `TimelineView`) | `Features/Astrology/ConstellationCanvasView.swift` |
| SwiftUI Astrology Insight sheet | `Features/Astrology/AstrologyInsightSheetView.swift` |
| Reducer & parity unit tests | `numelyra_app_iosTests/AstrologyFeatureTests.swift`, `numelyra_app_iosTests/AstrologyServiceTests.swift` |
