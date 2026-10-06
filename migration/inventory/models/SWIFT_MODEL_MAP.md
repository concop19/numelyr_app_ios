# Bản đồ Chuyển đổi Model sang Swift (Swift Model Map)

Tài liệu này định nghĩa chi tiết kiến trúc đích cho từng model khi chuyển đổi sang Swift native (`numelyra_app_ios/`), tuân thủ các nguyên tắc thiết kế của **The Composable Architecture (TCA)** và Swift Concurrency (`Sendable`).

---

## 1. Nguyên tắc thiết kế Model trong Swift

1. **Bất biến & Value Semantics**:
   - Tất cả Domain Models và Value Objects phải là `struct` hoặc `enum`.
   - Luôn conform `Equatable` và `Sendable` để hoạt động mượt mà trong State và Action của TCA.
2. **Tuân thủ Protocol tiêu chuẩn**:
   - Các model có định danh duy nhất (Profile, Message, Card, Level, Puzzle) conform `Identifiable` với `id: String` hoặc `id: Int`.
   - Các DTO truyền nhận qua mạng hoặc lưu trữ key-value conform `Codable`.
3. **Chiến lược Coding Keys**:
   - Supabase và Backend API sử dụng định dạng `snake_case` (ví dụ: `birth_date`, `life_path_number`, `user_id`).
   - Swift Client sử dụng `camelCase` chuẩn kết hợp `CodingKeys` hoặc cấu hình `JSONDecoder().keyDecodingStrategy = .convertFromSnakeCase`.
4. **Phân tách Ranh giới Lưu trữ**:
   - Sensitive tokens (Supabase JWT/refresh token) → Lưu trong **iOS Keychain** (`@Dependency(\.keychain)`).
   - User settings, flags, active profile ID, tiến độ game nhỏ → Lưu trong **UserDefaults / AppStorage** (`@Dependency(\.defaultStorage)`).
   - Danh sách profile và các setting/progress nhỏ → JSON versioned trong **UserDefaults**; giữ legacy key trong migration adapter.
   - Chat history và cache chiêm tinh → JSON file versioned trong **Application Support**, không ghi payload lớn vào UserDefaults.
   - Wallpaper history → chỉ là candidate cho file store/SwiftData; chưa thay đổi parity cho đến khi quyết định sản phẩm được duyệt.
   - Ca dao tục ngữ → đọc file bundle SQLite `cadao.db` qua SQLite3 C-API hoặc GRDB (`@Dependency(\.caDaoDatabase)`). SwiftData không phải reader cho schema SQLite hiện hữu.

---

## 2. Bảng quy đổi Model chi tiết

### 2.1 Domain 1: App Shell, Authentication & Profiles

| Model React Native | Model Swift đề xuất | Kiểu Swift | Module / Feature đích | Protocols bắt buộc | Cơ chế Lưu trữ | Ghi chú chuyển đổi |
| :--- | :--- | :---: | :--- | :--- | :--- | :--- |
| `UserProfile` (legacy) | `UserProfile` | `struct` | `Features/Auth`, `Shared/Models` | `Identifiable, Codable, Equatable, Sendable` | UserDefaults JSON v2 | Hợp nhất với `ProfileItem`; migration dùng id ổn định `default-profile`. |
| `ProfileItem` | `UserProfile` | `struct` | `Features/Auth`, `Shared/Models` | `Identifiable, Codable, Equatable, Sendable` | UserDefaults JSON v2 | `gender` là optional; không hardcode `.female` khi cloud thiếu dữ liệu. |
| `SupabaseProfileRow` | `AccountProfileDTO` | `struct` | `Core/Clients/SupabaseClient` | `Codable, Identifiable, Equatable, Sendable` | Supabase Table `profiles` | Ánh xạ trường `full_name` → `fullName`. |
| `SupabaseUserNumerologyProfileRow`| `CloudProfileDTO` | `struct` | `Core/Clients/SupabaseClient` | `Codable, Identifiable, Equatable, Sendable` | Supabase `user_numerology_profiles` | Cần bổ sung cột `gender` trong schema cloud nếu muốn đồng bộ hoàn toàn. |
| `AuthSession` | `AuthSession` | `struct` | `Core/Clients/SupabaseClient` | `Codable, Equatable, Sendable` | Keychain (`@Dependency(\.keychain)`) | Tuyệt đối không lưu token dạng plain-text trong UserDefaults. |
| `RootStackParamList` | `AppFeature.Path` | `enum` | `App/AppFeature.swift` | `Equatable, Sendable` | In-memory (TCA `StackState`) | Sử dụng `StackState<AppFeature.Path.State>` để điều hướng. |

---

### 2.2 Domain 2: Numerology, Tarot & Chat Agent

| Model React Native | Model Swift đề xuất | Kiểu Swift | Module / Feature đích | Protocols bắt buộc | Cơ chế Lưu trữ | Ghi chú chuyển đổi |
| :--- | :--- | :---: | :--- | :--- | :--- | :--- |
| `MessageItem` / `StoredChatMessage` | `ChatMessage` | `struct` | `Features/Chat`, `Shared/Models` | `Identifiable, Codable, Equatable, Sendable` | JSON file / SwiftData | Thay thế `card: any` bằng enum strongly-typed `ChatCardPayload`. |
| `AgentDecision` | `AgentDecision` | `struct` | `Features/Chat`, `Core/Clients` | `Codable, Equatable, Sendable` | In-memory / HTTP DTO | `intent`, `mode`, `spreadId` dùng enum typed. |
| `TarotCardData` | `TarotCard` | `struct` | `Features/Chat`, `Shared/Models` | `Identifiable, Codable, Equatable, Sendable` | Static bundled JSON | Đọc từ 78 file asset hoặc 1 file JSON nhúng sẵn trong bundle. |
| `DrawnCardResult` | `DrawnTarotCard` | `struct` | `Features/Chat`, `Shared/Models` | `Codable, Equatable, Sendable` | In-memory / Chat State | Chứa `TarotCard`, `isReversed`, `position`. |
| `TarotSpreadConfig` | `TarotSpread` | `struct` | `Features/Chat`, `Shared/Models` | `Identifiable, Equatable, Sendable` | Static in-code / Config | 4 kiểu trải bài chuẩn. |
| `ColorGuidanceContext`| `ColorGuidanceContext`| `struct` | `Features/Chat`, `Shared/Models` | `Codable, Equatable, Sendable` | In-memory / Message payload | Palette 5 màu phong thủy + 2 màu được chọn. |
| `NumerologyCardMeta` | `NumerologyCardDefinition` | `struct` | `Features/Chat`, `Shared/Models` | `Identifiable, Codable, Equatable, Sendable` | Static bundled config | Metadata/asset của 24 thẻ, không trộn với kết quả tính. |
| `IndicatorInfo` | `NumerologyIndicator` | `struct` | `Features/Chat`, `Shared/Models` | `Identifiable, Codable, Equatable, Sendable` | In-memory / HTTP DTO | Compact chat value: `key`, `name`, `value`, `meaning`. |
| `CalculatedIndicator` | `CalculatedNumerologyIndicator` | `struct` | `Features/Chat`, `Shared/Models` | `Identifiable, Codable, Equatable, Sendable` | In-memory | Composition của definition và kết quả tính; không gộp schema với `IndicatorInfo`. |
| `KnowledgeReadingResult` | `KnowledgeReading` | `struct` | `Features/Chat`, `Core/Clients` | `Codable, Equatable, Sendable` | HTTP / Cache Supabase | Luận giải chi tiết 24 chỉ số. |
| `PersonTuViBaziChart`| `TuViBaziChart` | `struct` | `Features/Chat`, `Shared/Models` | `Codable, Equatable, Sendable` | In-memory | Tứ Trụ, Nhật Chủ, Cung Phu Thê. |
| `TuViBaziSynastryResult`| `TuViBaziSynastry`| `struct` | `Features/Chat`, `Shared/Models` | `Codable, Equatable, Sendable` | In-memory | Điểm tương hợp duyên nợ 2 hồ sơ. |
| `PlaceSearchContext` | `PlaceSearchContext` | `struct` | `Features/Chat`, `Core/Clients` | `Codable, Equatable, Sendable` | CoreLocation / HTTP DTO | Tọa độ GPS + ngân sách + người đi cùng. |

---

### 2.3 Domain 3: Calendar & Văn hóa Dân gian

| Model React Native | Model Swift đề xuất | Kiểu Swift | Module / Feature đích | Protocols bắt buộc | Cơ chế Lưu trữ | Ghi chú chuyển đổi |
| :--- | :--- | :---: | :--- | :--- | :--- | :--- |
| `LunarDate` | `LunarDate` | `struct` | `Features/Calendar`, `Shared/Models`| `Codable, Equatable, Hashable, Sendable`| Pure computation | Thuật toán Hồ Ngọc Đức viết thuần bằng Swift. |
| `HourInfo` | `LunarHourInfo` | `struct` | `Features/Calendar`, `Shared/Models`| `Identifiable, Codable, Equatable, Sendable`| In-memory | 12 giờ hoàng đạo / hắc đạo. |
| `CaDaoItem` | `CaDaoRecord` | `struct` | `Core/Clients/DatabaseClient` | `Identifiable, Codable, Equatable, Sendable`| SQLite (`cadao.db`) | Đọc qua SQLite C-API nhúng trong bundle. |
| `WeekInfo` | `CalendarWeekInfo` | `struct` | `Features/Calendar` | `Equatable, Sendable` | In-memory UI State | Danh sách 7 ngày trong tuần hiện tại. |

---

### 2.4 Domain 4: Astrology

| Model React Native | Model Swift đề xuất | Kiểu Swift | Module / Feature đích | Protocols bắt buộc | Cơ chế Lưu trữ | Ghi chú chuyển đổi |
| :--- | :--- | :---: | :--- | :--- | :--- | :--- |
| `PlanetPosition` | `AstroPlanetPosition` | `struct` | `Features/Astrology`, `Shared/Models`| `Codable, Equatable, Sendable` | Pure computation | Tính bằng thư viện Swift tương đương `astronomy-engine` hoặc C port. |
| `PlanetaryChart` | `AstroPlanetaryChart` | `struct` | `Features/Astrology`, `Shared/Models`| `Codable, Equatable, Sendable` | In-memory | Natal Chart & Transit Chart. |
| `DetectedAspect` | `DetectedAstroAspect` | `struct` | `Features/Astrology`, `Shared/Models`| `Codable, Equatable, Sendable` | In-memory | Góc chiếu: Trùng tụ, Lục hợp, Vuông góc, Tam hợp, Đối đỉnh. |
| `PureAstroFeatureMetadata`| `AstroFeatureMetadata`| `struct` | `Features/Astrology`, `Shared/Models`| `Codable, Equatable, Sendable` | In-memory | Giữ đủ temperament, top aspect, 4 scores, confidence và dominant signal. |
| `PureAstroVectorResult`| `AstroVectorResult` | `struct` | `Features/Astrology`, `Shared/Models`| `Codable, Equatable, Sendable` | In-memory | Persist `[Double]`; `[Float]` là computed runtime representation. |
| `AstroFortuneSlip` | `AstroFortuneSlip` | `struct` | `Features/Astrology`, `Core/Clients` | `Codable, Equatable, Sendable` | AsyncStorage/UserDefaults | Thơ 4 câu + Gương soi + Kế sách. |
| `ConstellationGeometry`| `ConstellationGeometry`| `struct`| `Features/Astrology` | `Equatable, Sendable` | SVG / SwiftUI Path | Dùng SwiftUI `Path` và `Canvas` render biểu tượng chòm sao. |

---

### 2.5 Domain 5: Wallpaper Studio

| Model React Native | Model Swift đề xuất | Kiểu Swift | Module / Feature đích | Protocols bắt buộc | Cơ chế Lưu trữ | Ghi chú chuyển đổi |
| :--- | :--- | :---: | :--- | :--- | :--- | :--- |
| `WallpaperItem` | `WallpaperItem` | `struct` | `Features/Wallpaper`, `Shared/Models`| `Identifiable, Codable, Equatable, Sendable`| In-memory / SwiftData | Đề xuất bổ sung lưu trữ bền vững (Persistence) qua SwiftData thay vì chỉ lưu memory. |
| `LuckyWallpaperRequestBody`| `LuckyWallpaperRequest`| `struct` | `Features/Wallpaper`, `Core/Clients` | `Codable, Sendable` | HTTP POST Body | Chuyển đổi snake_case sang camelCase. |
| `LuckyWallpaperResponseBody`| `LuckyWallpaperResponse`| `struct` | `Features/Wallpaper`, `Core/Clients` | `Codable, Sendable` | HTTP Response Body | Nhận 4 URLs ảnh từ AI server. |

---

### 2.6 Domain 6: Settings, Notification & Billing

| Model React Native | Model Swift đề xuất | Kiểu Swift | Module / Feature đích | Protocols bắt buộc | Cơ chế Lưu trữ | Ghi chú chuyển đổi |
| :--- | :--- | :---: | :--- | :--- | :--- | :--- |
| `BillingStatus` | `BillingStatus` | `struct` | `Features/Settings`, `Core/Clients` | `Codable, Equatable, Sendable` | HTTP GET Response | Gói Free/Pro và trạng thái subscription. |
| `DailyReminderSettings`| `DailyReminderSettings`| `struct`| `Features/Settings`, `Core/Clients` | `Codable, Equatable, Sendable` | UserDefaults | Quản lý thông báo qua `UserNotifications` framework. |

---

### 2.7 Domain 7: Game Hub & Shared Progress

| Model React Native | Model Swift đề xuất | Kiểu Swift | Module / Feature đích | Protocols bắt buộc | Cơ chế Lưu trữ | Ghi chú chuyển đổi |
| :--- | :--- | :---: | :--- | :--- | :--- | :--- |
| `GameId` | `GameId` | `enum` | `Features/GameHub`, `Shared/Models` | `String, Codable, CaseIterable, Equatable, Sendable` | Storage identifier | `'arrow-escape'`, `'mind-rules'`, `'sudoku'`, `'game-2048'`, `'zip'`, v.v. |
| `DailyChallenge` | `DailyChallenge` | `struct` | `Features/GameHub`, `Shared/Models` | `Identifiable, Codable, Equatable, Sendable` | Pure computation | Thử thách hàng ngày xoay vòng theo ngày. |
| `GameHubProgress` | `GameHubProgress` | `struct` | `Features/GameHub`, `Shared/Models` | `Codable, Equatable, Sendable` | UserDefaults (`"numelyra.game_hub.progress"`) | Lưu chuỗi streak và lịch sử hoàn thành. |

---

### 2.8 Domain 8: Mini-games

| Model React Native | Model Swift đề xuất | Kiểu Swift | Module / Feature đích | Protocols bắt buộc | Cơ chế Lưu trữ | Ghi chú chuyển đổi |
| :--- | :--- | :---: | :--- | :--- | :--- | :--- |
| `ArrowNode` (Arrow Escape)| `ArrowEscapeModels.Arrow` | `struct` | `Features/GameHub/Games/ArrowEscape` | `Identifiable, Codable, Equatable, Sendable` | In-memory | Tọa độ mũi tên và đường thoát. |
| `LevelDefinition` (Arrow)| `ArrowEscapeModels.Level` | `struct` | `Features/GameHub/Games/ArrowEscape` | `Identifiable, Codable, Equatable, Sendable` | Static bundled config | 40 màn chơi từ Easy đến Expert. |
| `SpaceGameState` | `SpaceGameModels.State` | `struct` | `Features/GameHub/Games/SpaceGame` | `Codable, Equatable, Sendable` | In-memory | Score, wave, ammo, health. |
| `Puzzle` (Mind Rules) | `MindRulesModels.Puzzle` | `struct` | `Features/GameHub/Games/MindRules` | `Identifiable, Codable, Equatable, Sendable` | Static bundled config | Puzzle tìm quy luật số. |
| `OAnQuanState` | `OAnQuanModels.State` | `struct` | `Features/GameHub/Games/OAnQuan` | `Codable, Equatable, Sendable` | In-memory | Trạng thái bàn cờ 10 ô dân + 2 ô quan. |
| `DotBoxGameState` | `DotBoxModels.State` | `struct` | `Features/GameHub/Games/DotBox` | `Codable, Equatable, Sendable` | In-memory | Ma trận đường kẻ và các hộp đã chiếm. |
| `CellState` (Sudoku) | `SudokuModels.Cell` | `struct` | `Features/GameHub/Games/Sudoku` | `Codable, Equatable, Sendable` | In-memory | Ô cờ, số đã điền, bút chì notes. |
| `BoardCell` (2048) | `Game2048Models.Cell` | `struct` | `Features/GameHub/Games/2048` | `Identifiable, Codable, Equatable, Sendable` | In-memory | Vị trí x, y và giá trị lũy thừa của 2. |
| `ZipPuzzle` | `ZipModels.Puzzle` | `struct` | `Features/GameHub/Games/Zip` | `Identifiable, Codable, Equatable, Sendable` | Static bundled config | Puzzle + daily puzzle. |
| `ZipProgress` | `ZipModels.Progress` | `struct` | `Features/GameHub/Games/Zip` | `Codable, Equatable, Sendable` | UserDefaults JSON | Lưu best time/move/backtrack theo puzzle. |

---

### 2.9 API, Supabase và payload boundary

Các type dưới đây đã được hiện thực trong `Shared/Models/BoundaryModels.swift`. Chúng không được dùng trực tiếp làm TCA feature state; client dependency phải map DTO sang domain model.

| Boundary React Native | Swift model | Serialize boundary | Ghi chú |
| :--- | :--- | :--- | :--- |
| Supabase `profiles` row | `AccountProfileDTO` | Supabase/PostgREST | CodingKeys cho `full_name`, `updated_at`. |
| Supabase `user_numerology_profiles` row | `CloudNumerologyProfileDTO` | Supabase/PostgREST | Không có `gender`; mapper không được tự gán giới tính. |
| Supabase `numerology_knowledge` row | `NumerologyKnowledgeDTO` | Supabase/PostgREST | Giữ `indicator_key`, `number_value`. |
| `/api/chat/classify` request/response | `ChatClassifyRequest`, `ChatClassifyResponse` | JSON HTTP | Response chứa `AgentDecision?`. |
| `/api/chat/agent` request/response | `ChatAgentRequest`, `ChatAgentResponse` | JSON HTTP | Payload card chưa nhận diện được giữ bằng `JSONValue`. |
| `/api/lucky-wallpaper/generate` | `LuckyWallpaperRequest`, `LuckyWallpaperResponse` | JSON HTTP | Hỗ trợ cả `imageUrls` và legacy `imageUrl`. |
| `/api/astro/fortune` | `AstroFortuneRequest`, `AstroFortuneResponse` | JSON HTTP | Tách response DTO khỏi `AstroFortuneSlip` domain. |
| Billing checkout | `CheckoutRequest`, `CheckoutResponse` | JSON HTTP | Hỗ trợ PayOS `checkoutUrl` và PayPal `approvalUrl`. |
| Daily notification data | `NotificationPayload` | UserNotifications | `url` chứa deep link `numelyra://games/daily`. |

### 2.10 Namespace mini-game

Các model trùng tên được namespace trong `Shared/Models/MiniGameModels.swift`: `ArrowEscapeModels`, `SpaceGameModels`, `MindRulesModels`, `OAnQuanModels`, `DotBoxModels`, `SudokuModels`, `Game2048Models`, `ZipModels`. Các payload progress conform `Codable`; board/runtime state conform `Equatable` và `Sendable` để dùng trong TCA state/action.
