# Danh mục chi tiết các Model (Model Catalog)

Tài liệu này lưu trữ inventory chi tiết từng model, cấu trúc dữ liệu, DTO và persistence entity được tìm thấy trong mã nguồn React Native `numelyra_app/`. Mọi thông tin đều có dẫn chứng đường dẫn file và số dòng tương ứng trong repository.

---

## 1. Domain 1: App Shell, Authentication, Session & Profile

### 1.1 `UserProfile`
- **Tên Swift đề xuất**: `LegacyUserProfile` (hoặc sáp nhập vào `UserProfile`)
- **Phân loại**: `DomainModel`, `PersistenceEntity`
- **Feature sở hữu**: Auth / Profile (`src/store/userProfile.ts:9-15`)
- **Các trường dữ liệu**:
  - `fullName: string` (bắt buộc)
  - `birthDate: string` (bắt buộc, ISO `YYYY-MM-DD`)
  - `gender: 'male' | 'female'` (bắt buộc)
  - `birthTime?: string` (tùy chọn, vd: `'14:30'`)
  - `birthPlace?: string` (tùy chọn, vd: `'Hà Nội'`)
- **Biên lưu trữ / Serialize**: AsyncStorage (`@tieu_linh_mieu_profile`)
- **Quan hệ**: 1-to-1 với active profile trước khi nâng cấp lên danh sách đa hồ sơ.
- **Nơi tạo / tiêu thụ**: Tạo tại `OnboardingScreen.tsx:55`, lưu qua `saveProfile()`, tiêu thụ tại `App.tsx:92`.
- **Trạng thái**: Reachable (được duy trì song song để tương thích ngược với các component cũ).
- **Đề xuất Swift**: `struct LegacyUserProfile: Codable, Equatable, Sendable`.
- **Mức tin cậy**: High.

### 1.2 `ProfileItem`
- **Tên Swift đề xuất**: `UserProfile`
- **Phân loại**: `DomainModel`, `PersistenceEntity`
- **Feature sở hữu**: Profile Management (`src/store/userProfile.ts:17-25`)
- **Các trường dữ liệu**:
  - `id: string` (bắt buộc, UUID hoặc `prof-<timestamp>-<rand>`)
  - `fullName: string` (bắt buộc)
  - `birthDate: string` (bắt buộc, ISO `YYYY-MM-DD`)
  - `gender?: 'male' | 'female'` (tùy chọn, mặc định `'female'`)
  - `isDefault?: boolean` (tùy chọn)
  - `birthTime?: string` (tùy chọn)
  - `birthPlace?: string` (tùy chọn)
- **Biên lưu trữ / Serialize**: AsyncStorage (`@numelyra_profiles_list`) & Supabase (`user_numerology_profiles`)
- **Quan hệ**: 1-to-N với `UserAccount` (một tài khoản sở hữu nhiều hồ sơ), 1-to-1 với `PersonTuViBaziChart`.
- **Nơi tạo / tiêu thụ**: Tạo trong `userProfile.ts:85` (`addProfile`), đồng bộ tại `authContext.tsx:38`, tiêu thụ trong `ChatScreen.tsx`, `WallpaperStudioScreen.tsx`, `AstrologyScreen.tsx`.
- **Trạng thái**: Reachable.
- **Đề xuất Swift**: `struct UserProfile: Identifiable, Codable, Equatable, Sendable`.
- **Mức tin cậy**: High.

### 1.3 `SupabaseProfileRow`
- **Tên Swift đề xuất**: `AccountProfileRow`
- **Phân loại**: `PersistenceEntity`
- **Feature sở hữu**: Supabase Auth Sync (`src/store/authContext.tsx:46-52`, suy từ query `profiles`)
- **Các trường dữ liệu**:
  - `id: string` (UUID tài khoản auth, primary key)
  - `email: string | null`
  - `full_name: string | null`
  - `updated_at: string` (ISO timestamp)
- **Biên lưu trữ**: Bảng Supabase `public.profiles`.
- **Đề xuất Swift**: `struct AccountProfileRow: Codable, Identifiable, Sendable`.
- **Mức tin cậy**: High.

### 1.4 `SupabaseUserNumerologyProfileRow`
- **Tên Swift đề xuất**: `CloudNumerologyProfileRow`
- **Phân loại**: `PersistenceEntity`
- **Feature sở hữu**: Supabase Sync (`src/store/userProfile.ts:95-103`, `src/store/authContext.tsx:56-60`)
- **Các trường dữ liệu**:
  - `id: string` (UUID profile)
  - `user_id: string` (UUID auth user)
  - `name: string` (ánh xạ từ `fullName`)
  - `birth_date: string` (ánh xạ từ `birthDate`)
  - `created_at?: string`
- **Biên lưu trữ**: Bảng Supabase `public.user_numerology_profiles`.
- **Đặc điểm rủi ro**: Cloud schema hiện tại **không có cột `gender`**, khiến profile tải từ cloud ban đầu mặc định là `'female'` cho đến khi merge local (`authContext.tsx:66, 111`).
- **Đề xuất Swift**: `struct CloudNumerologyProfileRow: Codable, Identifiable, Sendable`.
- **Mức tin cậy**: High.

### 1.5 `RootStackParamList`
- **Tên Swift đề xuất**: `AppDestination` (TCA Navigation Path)
- **Phân loại**: `UIState`
- **Feature sở hữu**: Navigation (`App.tsx:41-45`)
- **Routes**:
  - `Main: undefined` (Bottom Tab Bar 5 tabs)
  - `Games: { entry?: 'daily' } | undefined` (Game Hub)
  - `ChatReadingDetail: ChatReadingDetailParams` (Chi tiết bài đọc)
- **Đề xuất Swift**: `enum AppDestination: Equatable, Sendable` kết hợp trong `AppFeature.Path`.
- **Mức tin cậy**: High.

---

## 2. Domain 2: Numerology, Tarot & Chat Agent

### 2.1 `MessageItem` / `StoredChatMessage`
- **Tên Swift đề xuất**: `ChatMessage`
- **Phân loại**: `DomainModel`, `PersistenceEntity`
- **Feature sở hữu**: Chat (`src/screens/ChatScreen.tsx:59-66`, `src/services/chatHistoryStorage.ts:5-12`)
- **Các trường dữ liệu**:
  - `id: string` (bắt buộc, vd: `mascot-<timestamp>` hoặc `user-<timestamp>`)
  - `sender: 'user' | 'mascot'`
  - `text: string`
  - `time: string` (vd: `'09:30'`)
  - `card?: AgentSynthesisCardPayload | any` (tùy chọn)
  - `isTypingCompleted?: boolean` (quản lý hiệu ứng máy đánh chữ)
- **Biên lưu trữ**: AsyncStorage (`@numelyra_chat_history:v1:<ownerId>`), tối đa 100 tin nhắn.
- **Đề xuất Swift**: `struct ChatMessage: Identifiable, Codable, Equatable, Sendable`.
- **Mức tin cậy**: High.

### 2.2 `AgentDecision`
- **Tên Swift đề xuất**: `AgentDecision`
- **Phân loại**: `DomainModel`, `APIResponse`, `ValueObject`
- **Feature sở hữu**: Decision Engine (`src/services/agentDecisionEngine.ts:11-29`)
- **Các trường dữ liệu**:
  - `mode: 'single' | 'compatibility'`
  - `intent: 'love_match' | 'two_choices' | 'timing_trajectory' | 'daily_guidance' | 'color_guidance' | 'where_to_go' | 'core_personality' | 'trash' | 'general'`
  - `needsTarot: boolean`
  - `spreadId: 'single' | 'three-card' | 'two-options' | 'relationship' | null`
  - `cardCount: number` (0, 1, 3 hoặc 5)
  - `targetIndicators: string[]` (danh sách key chỉ số thần số học cần tính)
  - `thoughtProcess: string` (lập luận suy luận của agent)
  - `replyText?: string` (câu trả lời sớm nếu là câu hỏi rác)
- **Đề xuất Swift**: `struct AgentDecision: Codable, Equatable, Sendable`.
- **Mức tin cậy**: High.

### 2.3 `TarotCardData`
- **Tên Swift đề xuất**: `TarotCard`
- **Phân loại**: `Configuration`, `DomainModel`
- **Feature sở hữu**: Tarot Service (`src/services/tarotService.ts:8-18`, `minorArcana.generated.ts:2-40`)
- **Các trường dữ liệu**:
  - `id: string` (vd: `'0-fool'`, `'wands-01'`)
  - `nameVi: string`, `nameEn: string`
  - `number: number`
  - `emoji: string`
  - `keywordsUpright: string[]`, `keywordsReversed: string[]`
  - `meaningUpright: string`, `meaningReversed: string`
- **Nguồn dữ liệu**: Bộ bài 78 lá chuẩn Rider-Waite (22 Major Arcana + 56 Minor Arcana nhúng tĩnh).
- **Đề xuất Swift**: `struct TarotCard: Identifiable, Codable, Equatable, Sendable`.
- **Mức tin cậy**: High.

### 2.4 `DrawnCardResult`
- **Tên Swift đề xuất**: `DrawnTarotCard`
- **Phân loại**: `ValueObject`, `DomainModel`
- **Feature sở hữu**: Tarot Service (`src/services/tarotService.ts:33-37`)
- **Các trường dữ liệu**:
  - `card: TarotCardData`
  - `isReversed: boolean` (lá bài xuôi hay ngược)
  - `position: TarotPosition` (vị trí trong quẻ trải bài)
- **Đề xuất Swift**: `struct DrawnTarotCard: Codable, Equatable, Sendable`.
- **Mức tin cậy**: High.

### 2.5 `TarotSpreadConfig` & `TarotPosition`
- **Tên Swift đề xuất**: `TarotSpread`, `TarotPosition`
- **Phân loại**: `Configuration`, `ValueObject`
- **Feature sở hữu**: Tarot Service (`src/services/tarotService.ts:20-31`)
- **Spreads hỗ trợ**: `'single'` (1 lá), `'three-card'` (3 lá), `'two-options'` (5 lá A/B), `'relationship'` (5 lá tình cảm).
- **Đề xuất Swift**: `struct TarotSpread: Identifiable, Equatable, Sendable`.
- **Mức tin cậy**: High.

### 2.6 `ColorGuidanceContext`
- **Tên Swift đề xuất**: `ColorGuidanceContext`
- **Phân loại**: `ValueObject`, `DomainModel`
- **Feature sở hữu**: Color Guidance Service (`src/services/colorGuidanceService.ts:20-30`)
- **Các trường dữ liệu**:
  - `ruleVersion: 'v1'`
  - `sourceUrl: string`
  - `lunarYear: number`
  - `element: 'Kim' | 'Thủy' | 'Mộc' | 'Hỏa' | 'Thổ'`
  - `palette: FengShuiColor[]` (bảng 5 màu hợp mệnh)
  - `selectedColorIds: [ColorId, ColorId]` (2 màu được chọn dựa theo lá bài)
  - `tarotElement: 'fire' | 'water' | 'air' | 'earth'`
  - `cardId: string`
  - `isReversed: boolean`
- **Đề xuất Swift**: `struct ColorGuidanceContext: Codable, Equatable, Sendable`.
- **Mức tin cậy**: High.

### 2.7 `IndicatorInfo` & `CalculatedIndicator`
- **Tên Swift đề xuất**: `NumerologyIndicator`
- **Phân loại**: `DomainModel`, `ValueObject`
- **Feature sở hữu**: Numerology (`src/services/numerology24Service.ts:52-57`, `src/services/numerologyEngine.ts:85-89`)
- **Các trường dữ liệu**:
  - `id: string`, `key: string`, `number: string`
  - `nameVi: string`, `nameEn: string`
  - `category: 'core' | 'potential' | 'karmic' | 'bridge' | 'cycle' | 'chart'`
  - `value: number | string`
  - `displayValue: string`
  - `isMaster?: boolean` (11, 22, 33)
  - `description: string`
- **Đề xuất Swift**: `struct NumerologyIndicator: Identifiable, Codable, Equatable, Sendable`.
- **Mức tin cậy**: High.

### 2.8 `KnowledgeReadingResult` & `NumerologyKnowledgeRow`
- **Tên Swift đề xuất**: `NumerologyKnowledgeReading`
- **Phân loại**: `DomainModel`, `PersistenceEntity`
- **Feature sở hữu**: Numerology Knowledge (`src/services/numerologyKnowledge.ts:11-19, 253-257`)
- **Các trường dữ liệu**:
  - `title: string`
  - `source: 'supabase-knowledge' | 'offline-archetype'`
  - `overview: string`
  - `strengths: string[]`
  - `challenges: string[]`
  - `advice: string`
  - `fullContent?: string`
- **Biên lưu trữ**: Bảng Supabase `numerology_knowledge` (`indicator_key`, `number_value`, `content`, `title`).
- **Đề xuất Swift**: `struct NumerologyKnowledgeReading: Codable, Equatable, Sendable`.
- **Mức tin cậy**: High.

### 2.9 `PersonTuViBaziChart` & `TuViBaziSynastryResult`
- **Tên Swift đề xuất**: `TuViBaziChart`, `TuViBaziSynastry`
- **Phân loại**: `DomainModel`, `ValueObject`
- **Feature sở hữu**: Tử Vi & Bát Tự (`src/services/tuViBaziService.ts:22-75`)
- **Các trường dữ liệu chính**:
  - `yearPillar`, `monthPillar`, `dayPillar` (`PillarData`: gan, zhi, element)
  - `dayMaster: string` (Nhật Chủ), `dayMasterElement: string`
  - `spousalPalace: string` (Cung Phu Thê), `cungPhi: string` (Bát Trạch Quái Mệnh)
  - `compatibilityScore: number` (0 - 100%)
  - `spousalInteraction`, `stemInteraction`, `napAmHarmony`, `cungPhiBatTrach`
  - `summaryVi: string`, `adviceVi: string`
- **Đề xuất Swift**: `struct TuViBaziChart: Codable, Equatable, Sendable`, `struct TuViBaziSynastry: Codable, Equatable, Sendable`.
- **Mức tin cậy**: High.

### 2.10 `PlaceSearchContext` & `PlaceSearchPreferences`
- **Tên Swift đề xuất**: `PlaceSearchContext`, `PlaceSearchPreferences`
- **Phân loại**: `ValueObject`, `APIRequest`
- **Feature sở hữu**: Location Service (`src/services/placeLocation.ts:6-16`)
- **Các trường dữ liệu**:
  - `maxDistanceKm: number`
  - `budget: 'low' | 'medium' | 'flexible'`
  - `companion: 'solo' | 'date' | 'friends' | 'family'`
  - `openNow: boolean`
  - `latitude: number`, `longitude: number`
- **Đề xuất Swift**: `struct PlaceSearchContext: Codable, Equatable, Sendable`.
- **Mức tin cậy**: High.

---

## 3. Domain 3: Calendar & Dữ liệu Văn hóa

### 3.1 `LunarDate`
- **Tên Swift đề xuất**: `LunarDate`
- **Phân loại**: `ValueObject`
- **Feature sở hữu**: Lunar Service (`src/services/lunarService.ts:127-132`)
- **Các trường dữ liệu**:
  - `day: number` (1 - 30)
  - `month: number` (1 - 12)
  - `year: number` (năm âm lịch)
  - `leap: boolean` (tháng nhuận)
- **Đề xuất Swift**: `struct LunarDate: Codable, Equatable, Hashable, Sendable`.
- **Mức tin cậy**: High.

### 3.2 `HourInfo`
- **Tên Swift đề xuất**: `LunarHourInfo`
- **Phân loại**: `ValueObject`
- **Feature sở hữu**: Lunar Service (`src/services/lunarService.ts:241-248`)
- **Các trường dữ liệu**:
  - `name: string` (Tý, Sửu...)
  - `range: string` (vd: `'23h-01h'`)
  - `startHour: number` (23, 1, 3...)
  - `isHoangDao: boolean`
  - `isClash: boolean` (kỵ theo tuổi)
  - `label: string` (Thanh Long, Minh Đường...)
- **Đề xuất Swift**: `struct LunarHourInfo: Identifiable, Codable, Equatable, Sendable`.
- **Mức tin cậy**: High.

### 3.3 `CaDaoItem`
- **Tên Swift đề xuất**: `CaDaoRecord`
- **Phân loại**: `DomainModel`, `PersistenceEntity` (SQLite)
- **Feature sở hữu**: Ca Dao Database (`src/db/cadaoService.ts:9-15`)
- **Các trường dữ liệu**:
  - `id: number` (Primary key)
  - `title: string`
  - `content: string` (Nội dung thơ ca dao)
  - `category: string`
  - `url: string`
- **Biên lưu trữ**: SQLite asset `cadao.db`, bảng `cadao`.
- **Đề xuất Swift**: `struct CaDaoRecord: Identifiable, Codable, Equatable, Sendable`.
- **Mức tin cậy**: High.

### 3.4 `WeekInfo` & `WeekDayItem`
- **Tên Swift đề xuất**: `CalendarWeekInfo`, `CalendarDayItem`
- **Phân loại**: `UIState`, `ValueObject`
- **Feature sở hữu**: Calendar (`src/services/lunarService.ts:502-513`)
- **Các trường dữ liệu**:
  - `weekNumber: number`
  - `days: WeekDayItem[]` (date, dayNumber, dayOfWeekVi, isCurrentDay)
- **Đề xuất Swift**: `struct CalendarWeekInfo: Equatable, Sendable`.
- **Mức tin cậy**: High.

---

## 4. Domain 4: Astrology & Chiêm Tinh Học

### 4.1 `PlanetPosition` & `PlanetaryChart`
- **Tên Swift đề xuất**: `AstroPlanetPosition`, `AstroPlanetaryChart`
- **Phân loại**: `DomainModel`, `ValueObject`
- **Feature sở hữu**: Astro Engine (`src/services/astro/astroEngine.ts:8-23`)
- **Các trường dữ liệu**:
  - `name: string`, `body: Body`
  - `longitude: number` (0° đến 360°)
  - `sign: string`, `signIndex: number` (0 = Bạch Dương, 11 = Song Ngư)
  - `degreeInSign: number` (0° đến 30°)
  - `normalized: number` (0.0 đến 1.0)
  - `isTimeEstimated: boolean` (Noon chart fallback khi thiếu giờ sinh)
- **Đề xuất Swift**: `struct AstroPlanetPosition: Codable, Equatable, Sendable`.
- **Mức tin cậy**: High.

### 4.2 `DetectedAspect` & `AspectAnalysisResult`
- **Tên Swift đề xuất**: `DetectedAstroAspect`, `AstroAspectAnalysis`
- **Phân loại**: `DomainModel`, `ValueObject`
- **Feature sở hữu**: Aspect Calculator (`src/services/astro/aspectCalculator.ts:28-48`)
- **Các trường dữ liệu**:
  - `transitPlanet: string`, `natalPlanet: string`
  - `type: 'conjunction' | 'sextile' | 'square' | 'trine' | 'opposition'`
  - `symbol: string`, `actualAngle: number`, `orb: number`, `weight: number`
  - `tensionScore: number`, `harmonyScore: number`, `conjunctionIntensity: number`
- **Đề xuất Swift**: `struct DetectedAstroAspect: Codable, Equatable, Sendable`.
- **Mức tin cậy**: High.

### 4.3 `PureAstroFeatureMetadata` & `PureAstroVectorResult`
- **Tên Swift đề xuất**: `AstroFeatureMetadata`, `AstroVectorResult`
- **Phân loại**: `DomainModel`, `ValueObject`
- **Feature sở hữu**: Astro Vector Engine (`src/services/astro/astroVectorEngine.ts:28-73`)
- **Các trường dữ liệu**:
  - `vector: number[]` (Mảng 32 số thực trong [0.0, 1.0])
  - `confidenceScore: number` (1.0 nếu có giờ sinh, 0.7 nếu dùng Noon chart)
  - `dominantSignal: 'tension' | 'harmony' | 'conjunction' | 'balanced'`
  - `temperament: TemperamentBalance` (fire, earth, air, water, cardinal, fixed, mutable)
- **Đề xuất Swift**: `struct AstroFeatureMetadata: Codable, Equatable, Sendable`.
- **Mức tin cậy**: High.

### 4.4 `AstroFortuneSlip` & `CachedAstroFortune`
- **Tên Swift đề xuất**: `AstroFortuneSlip`, `CachedAstroFortune`
- **Phân loại**: `DomainModel`, `APIResponse`, `PersistenceEntity`
- **Feature sở hữu**: Fortune Service (`src/services/astro/astroFortuneService.ts:9-19`, `dailyAstroFortune.ts:13-16`)
- **Các trường dữ liệu**:
  - `verse: string` (Thơ 4 câu)
  - `mirror: string` (Gương soi nội tâm)
  - `advice: string` (Kế sách hành động)
  - `anchorCaDao: { content: string; category?: string }`
  - `astroMetadata?: PureAstroFeatureMetadata`
- **Biên lưu trữ**: AsyncStorage (`@astro_fortune_v3_<date>_<hashProfile>`).
- **Đề xuất Swift**: `struct AstroFortuneSlip: Codable, Equatable, Sendable`.
- **Mức tin cậy**: High.

### 4.5 `ConstellationGeometry` & `AstrologySymbolPreset`
- **Tên Swift đề xuất**: `ConstellationGeometry`, `ConstellationPreset`
- **Phân loại**: `Configuration`, `ValueObject`
- **Feature sở hữu**: Constellation (`src/features/constellation/types.ts:9-50`)
- **Các trường dữ liệu**:
  - `id: string`, `svgXml: string`, `title: string`
  - `contours: ConstellationContour[]` (`points: ConstellationPoint[]`)
  - `viewBox: SvgViewBox` (minX, minY, width, height)
- **Đề xuất Swift**: `struct ConstellationGeometry: Equatable, Sendable`.
- **Mức tin cậy**: High.

---

## 5. Domain 5: Wallpaper Studio

### 5.1 `WallpaperItem`
- **Tên Swift đề xuất**: `WallpaperItem`
- **Phân loại**: `DomainModel`, `UIState`
- **Feature sở hữu**: Wallpaper Studio (`src/screens/WallpaperStudioScreen.tsx:89-99`)
- **Các trường dữ liệu**:
  - `id: string` (vd: `'ai-<timestamp>-<idx>'`)
  - `source: { uri: string }`
  - `isUri: boolean`
  - `title: string`
  - `affirmation_vi: string`
  - `explanation_vi: string`
  - `luckyColors_vi: string[]`
  - `styleName: string`, `intentionName: string`
- **Đặc điểm rủi ro**: Hiện tại danh sách Wallpaper **chỉ lưu trong memory** (`setHistory`), không persist qua khởi động lại ứng dụng (`FEATURES.md:81`).
- **Đề xuất Swift**: `struct WallpaperItem: Identifiable, Codable, Equatable, Sendable`.
- **Mức tin cậy**: High.

### 5.2 `LuckyWallpaperRequestBody` & `LuckyWallpaperResponseBody`
- **Tên Swift đề xuất**: `LuckyWallpaperRequest`, `LuckyWallpaperResponse`
- **Phân loại**: `APIRequest`, `APIResponse`
- **Feature sở hữu**: Wallpaper Studio (`src/screens/WallpaperStudioScreen.tsx:451-485`)
- **Payload Request**:
  - `fullName: string`, `birthDate: string`
  - `lifePathNumber: number`, `destinyNumber: number`
  - `personalYear: number`, `personalDay: number` (key thực tế từ spread `...numbers` trong source)
  - `intentionId: string`, `styleId: string`, `deviceType: 'mobile'`, `customWish: string`, `count: 4`
- **Payload Response**:
  - `success: boolean`, `imageUrls?: string[]`, `imageUrl?: string`
  - `affirmation_vi?: string`, `explanation_vi?: string`, `luckyColors_vi?: string[]`
  - `style?: { name_vi?: string }`, `intention?: { name_vi?: string }`, `error?: string`
- **Đề xuất Swift**: `struct LuckyWallpaperRequest: Codable, Sendable`, `struct LuckyWallpaperResponse: Codable, Sendable`.
- **Mức tin cậy**: High.

---

## 6. Domain 6: Settings, Notification & Billing

### 6.1 `BillingStatus`
- **Tên Swift đề xuất**: `BillingStatus`
- **Phân loại**: `DomainModel`, `APIResponse`
- **Feature sở hữu**: Billing Service (`src/services/billingService.ts:7-18`)
- **Các trường dữ liệu**:
  - `authenticated: boolean`
  - `plan: 'free' | 'pro'`
  - `canManageBilling?: boolean`
  - `checkoutPending?: boolean`
  - `subscription?: { provider?: 'payos' | 'paypal'; status?: string; current_period_end?: string | null; cancel_at_period_end?: boolean } | null`
- **Đề xuất Swift**: `struct BillingStatus: Codable, Equatable, Sendable`.
- **Mức tin cậy**: High.

### 6.2 `DailyReminderSettings`
- **Tên Swift đề xuất**: `DailyReminderSettings`
- **Phân loại**: `DomainModel`, `PersistenceEntity`
- **Feature sở hữu**: Notification Service (`src/services/dailyNotifications.ts:8`)
- **Các trường dữ liệu**:
  - `enabled: boolean`
  - `hour: number` (0 - 23, mặc định 20)
  - `minute: number` (0 - 59, mặc định 0)
- **Biên lưu trữ**: AsyncStorage (`numelyra:daily-reminder:v1`).
- **Đề xuất Swift**: `struct DailyReminderSettings: Codable, Equatable, Sendable`.
- **Mức tin cậy**: High.

---

## 7. Domain 7: Game Hub & Shared Progress

### 7.1 `DailyChallenge`
- **Tên Swift đề xuất**: `DailyChallenge`
- **Phân loại**: `DomainModel`, `ValueObject`
- **Feature sở hữu**: Game Hub (`src/games/gameHub.ts:20-26`)
- **Các trường dữ liệu**:
  - `id: string` (vd: `'zip:2026-10-06'`)
  - `dateKey: string` (`YYYY-MM-DD`)
  - `gameId: 'arrow-escape' | 'mind-rules' | 'sudoku' | 'game-2048' | 'zip'`
  - `title: string`, `subtitle: string`
- **Đề xuất Swift**: `struct DailyChallenge: Identifiable, Codable, Equatable, Sendable`.
- **Mức tin cậy**: High.

### 7.2 `GameProgressSummary` & `GameHubProgress`
- **Tên Swift đề xuất**: `GameProgressSummary`, `GameHubProgress`
- **Phân loại**: `DomainModel`, `PersistenceEntity`
- **Feature sở hữu**: Game Hub (`src/games/gameHub.ts:13-38`, `gameHubStorage.ts:7-22`)
- **Các trường dữ liệu**:
  - `version: 1`
  - `streak: number`
  - `lastDailyDate: string | null`
  - `games: Partial<Record<GameId, GameProgressSummary>>` (`playedAt: string | null`, `completed: number`, `total: number | null`, `bestScore?: number`)
- **Biên lưu trữ**: AsyncStorage (`numelyra:game-hub:v1`).
- **Đề xuất Swift**: `struct GameHubProgress: Codable, Equatable, Sendable`.
- **Mức tin cậy**: High.

---

## 8. Domain 8: Các Mini-game Riêng Biệt

### 8.1 Mini-game: Arrow Escape & Space Game
- **`ArrowNode`** (`src/games/arrow-escape/src/game/types.ts:10-14`): `id: string`, `path: GridPosition[]`, `fullPath: GridPosition[]`.
- **`LevelDefinition`** (`src/games/arrow-escape/src/game/types.ts:16-22`): `id: number`, `title: string`, `difficulty: Difficulty`, `gridSize: { columns: number; rows: number }`, `arrows: ArrowNode[]`.
- **`BoardState`** (`src/games/arrow-escape/src/game/types.ts:24-29`): `level`, `arrows`, `livesLeft: number`, `removedIds: string[]`.
- **`ArrowEscapePersistedState`** (`src/games/arrow-escape/src/state/gameStore.ts:167-176`): Lưu qua AsyncStorage key `arrow-escape-progress` (`currentLevelId`, `highestUnlockedLevel`, `hasSeenTutorial`, `soundEnabled`, `hapticsEnabled`, `musicEnabled`).
- **`SpaceGameState`** (`src/games/arrow-escape/src/space_game/types.ts:115-126`): `score`, `wave`, `ammo`, `maxAmmo`, `health`, `maxHealth`, `overdriveTimer`, `shieldTimer`, `chickensDefeated`, `status`.

### 8.2 Mini-game: Mind Rules
- **`Equation`** (`src/games/mind-rules/src/data/puzzles.ts:1`): `input: number`, `output: number`.
- **`Puzzle`** (`src/games/mind-rules/src/data/puzzles.ts:3-13`): `id: number`, `title: string`, `equations: Equation[]`, `question: number`, `answer: number`, `hint: string`, `explanation?: string`.
- **`MindRulesProgress`** (`src/games/mind-rules/MindRulesGame.tsx:7`): AsyncStorage `mind-rules:active-progress:v1` (lưu chỉ số level `number`).

### 8.3 Mini-game: Ô Ăn Quan
- **`OAnQuanCell`** (`src/games/o-an-quan/game/gameEngine.ts:32-33`): `type: 'citizen' | 'quan'`, `citizens: number`, `mandarins: number`.
- **`OAnQuanState`** (`src/games/o-an-quan/game/gameEngine.ts:35-60`): `cells: Cell[]`, `currentPlayer: 0 | 1`, `scores: [{ citizens, mandarins }, { citizens, mandarins }]`, `winner`, `log: string[]`.

### 8.4 Mini-game: DotBox (Nối Ô)
- **`Line`** (`src/games/dots-boxes/dotbox/types.ts:8-14`): `id: string`, `d1: Point`, `d2: Point`, `orientation: 'H' | 'V'`, `owner: number | null`.
- **`Box`** (`src/games/dots-boxes/dotbox/types.ts:16-22`): `index: number`, `x: number`, `y: number`, `lineIds: string[]`, `owner: number | null`.
- **`DotBoxGameState`** (`src/games/dots-boxes/dotbox/types.ts:30-43`): `boardSize`, `lines`, `boxes`, `currentPlayer`, `scores`, `isGameOver`, `winner`.

### 8.5 Mini-game: Sudoku
- **`CellState`** (`src/games/sudoku/src/utils/sudokuLogic.ts:3-7`): `value: number`, `isClue: boolean`, `notes: number[]`.
- **`SudokuBoardState`** (`src/games/sudoku/src/utils/sudokuLogic.ts:9`): `CellState[][]` (9x9 grid).

### 8.6 Mini-game: 2048
- **`BoardCell`** (`src/games/game-2048/src/hooks/useGame.tsx:7-12`): `id: string`, `value: number`, `x: number`, `y: number`.
- **`BestTileProgress`** (`src/games/game-2048/Game2048Screen.tsx`): AsyncStorage `game-2048:best-tile:v1` (`number`).

### 8.7 Mini-game: Zip
- **`Checkpoint`** (`src/games/zip/game/types.ts:24-27`): `pos: [row, col]`, `value: number`.
- **`Wall`** (`src/games/zip/game/types.ts:15-18`): `a: [row, col]`, `b: [row, col]`.
- **`ZipPuzzle`** (`src/games/zip/game/types.ts:29-37`): `id: string`, `difficulty`, `size: number`, `checkpoints`, `walls?`, `solution`.
- **`ZipPersistedProgress`** (`src/games/zip/game/types.ts:54-62`): AsyncStorage `zip:progress:v1` (`completed`, `streak`, `lastDailyDate`, `hasSeenTutorial`).

---

## 9. Bảng Duplicate / Overlap & Đề xuất Hợp nhất khi sang Swift

| Type trong React Native | Vị trí trùng lặp | Đề xuất hợp nhất sang Swift |
| :--- | :--- | :--- |
| `UserProfile` vs `ProfileItem` | `src/store/userProfile.ts:9-25` | **Hợp nhất thành `UserProfile` duy nhất** có `id`, `fullName`, `birthDate`, `gender`, `isDefault`, `birthTime`, `birthPlace`. Bỏ hoàn toàn legacy struct sau khi migrate storage key. |
| `MessageItem` vs `StoredChatMessage` | `ChatScreen.tsx:59` vs `chatHistoryStorage.ts:5` | **Hợp nhất thành `ChatMessage` duy nhất**, đưa `card` từ kiểu `any / unknown` thành enum strongly-typed `ChatCardPayload`. |
| `Direction` | `arrow-escape/game/types.ts` vs `game-2048/hooks/useGame.tsx` vs `space_game/types.ts` | **Tách theo namespace từng game**: `ArrowEscape.Direction`, `Game2048.Direction` (do casing khác nhau: `UP` vs `up`). |
| `Difficulty` | `arrow-escape` vs `sudoku` vs `zip` | **Tách enum riêng** do các bậc phân loại khác nhau (`Expert` trong Sudoku/Arrow Escape vs `Easy/Medium/Hard` trong Zip). |
| `DotBox` duplicate tree | `o-an-quan/components/` vs `src/games/dots-boxes/` | **Loại bỏ tree cũ dormant**, chỉ giữ 1 implementation chuẩn khi port sang Swift. |
| `MindRules` duplicate tree | `MindRulesGame.tsx` vs full router app `src/games/mind-rules/src/` | **Chỉ port `MindRulesGame`** (48 puzzles + daily mode) theo đúng hành vi reachable từ Game Hub. |
