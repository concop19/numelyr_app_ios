# Báo cáo tổng hợp: Audit Model & Kiến trúc Dữ liệu React Native sang Swift

## 1. Mục tiêu và phạm vi audit

Tài liệu này tổng kết đợt audit toàn diện về cấu trúc dữ liệu, model nghiệp vụ, DTO, entity lưu trữ và trạng thái ứng dụng trong mã nguồn React Native (`numelyra_app/`) nhằm chuẩn bị nền tảng thiết kế model Swift theo kiến trúc **The Composable Architecture (TCA)** cho `numelyra_app_ios/`.

### Thông tin phiên làm việc
- **Repository nguồn**: `/Users/manhle/numelyra_clone/numelyra_app`
- **Git Commit / Ref**: `b89d94fdbee6118edca8c09d9232115da081afb9`
- **Trạng thái working tree nguồn**: 42 asset tracked bị xóa (chủ yếu là space-arrow sprite và app icons), toàn bộ 217 file mã nguồn TypeScript/TSX và SQLite `cadao.db` nguyên vẹn và sạch (không sửa đổi).
- **Phương pháp audit**: Quét tĩnh toàn bộ codebase, kết hợp deep-read từng module, trace luồng đọc/ghi AsyncStorage, Supabase table, SQLite queries và HTTP payload.

---

## 2. Thống kê file và độ phủ quét

| Khu vực | Số file TS/TSX | Tổng số dòng | Trọng tâm kiểm kê | Trạng thái |
| :--- | :---: | :---: | :--- | :---: |
| `src/store/` | 2 | 519 | AuthContext, UserProfile, multi-profile, Supabase auth | 100% Đã audit |
| `src/services/` | 29 | 5.811 | API config, Chat, Tarot, Numerology, TuVi, Astro, Lunar, Billing | 100% Đã audit |
| `src/db/` | 1 | 169 | SQLite cadao.db, CaDaoItem, queries, fallback | 100% Đã audit |
| `src/config/` | 4 | 806 | NumerologyCards, Env schema, calendar assets | 100% Đã audit |
| `src/features/` | 10 | 1.576 | DailyAstroFortune, Constellation geometry, SVG parser | 100% Đã audit |
| `src/screens/` | 9 | 7.622 | 9 màn hình chính, local synthesis, UI State, chat flow | 100% Đã audit |
| `src/components/` | 20 | 5.403 | Modal, card, place search context, mascot, game board | 100% Đã audit |
| `src/games/` | 142 | 24.032 | GameHub, 7 mini-games, engine, progress storage | 100% Đã audit |
| Root files (`App.tsx`, `index.ts`, `app.json`) | 3 | 426 | Navigation stack, tabs, deep-linking, permissions | 100% Đã audit |
| **Tổng cộng** | **220** | **46.364** | **Toàn bộ source code dự án** | **Hoàn tất** |

---

## 3. Thống kê model theo phân loại

Tổng số model/type được phát hiện và định danh: **78 model**.

| Nhóm phân loại | Số lượng | Mô tả tiêu biểu |
| :--- | :---: | :--- |
| `DomainModel` | 18 | `UserProfile`, `ProfileItem`, `PersonTuViBaziChart`, `CalculatedIndicator`, `AstroFortuneSlip`, `PlanetaryChart`, `LevelDefinition`, `Puzzle`, `DailyChallenge` |
| `ValueObject` | 23 | `HourInfo`, `LunarDate`, `PillarData`, `TuViBaziSynastryResult`, `ColorGuidanceContext`, `PureAstroVectorResult`, `DetectedAspect`, `TemperamentBalance`, `Wall`, `Checkpoint` |
| `APIRequest` | 5 | `ChatAgentRequestBody`, `ChatClassifyRequestBody`, `AstroFortuneRequestBody`, `LuckyWallpaperRequestBody`, `CheckoutRequestBody` |
| `APIResponse` | 7 | `ChatAgentResponseBody`, `ChatClassifyResponseBody`, `AstroFortuneSlip`, `LuckyWallpaperResponseBody`, `BillingStatus`, `PayOSCheckoutResponse`, `PayPalCheckoutResponse` |
| `PersistenceEntity`| 10 | `SupabaseProfileRow`, `SupabaseUserNumerologyProfileRow`, `SupabaseNumerologyKnowledgeRow`, `CaDaoItem` (SQLite), AsyncStorage keys (`@numelyra_chat_history`, `numelyra:game-hub:v1`, v.v.) |
| `Configuration` | 6 | `NumerologyCardMeta`, `TarotCardData`, `TarotSpreadConfig`, `AspectDefinition`, `AstrologySymbolPreset`, `AmmoConfig` |
| `UIState` | 6 | `RootStackParamList`, `LiveTarotReading`, `AmbientMascotState`, `WallpaperItem`, `GameStats`, `DotBoxGameState` |
| `EventPayload` | 2 | `NotificationPayload` (`numelyra://games/daily`), `TapResult` (Arrow Escape) |
| `LegacyOrDormant`| 1 | `BAZI_LOVE` endpoint payload (chỉ khai báo trong `apiConfig.ts:42`, không gọi runtime) |

---

## 4. Bảng ma trận độ phủ (Coverage Matrix) theo Feature

| Feature / Domain | Trạng thái Reachability | Nguồn dữ liệu chính | Lưu trữ / Persistence | Mức độ tin cậy |
| :--- | :--- | :--- | :--- | :---: |
| **1. App Shell & Navigation** | Reachable | `App.tsx` | AsyncStorage (active session) | High |
| **2. Auth & Profiles** | Reachable | `src/store/` | Supabase `profiles`, `user_numerology_profiles`, AsyncStorage | High |
| **3. Numerology (24 Indicators)**| Reachable | `src/services/numerology*` | Offline computed + Supabase `numerology_knowledge` | High |
| **4. Tarot & Chat Agent** | Reachable | `src/services/tarot*`, `ChatScreen.tsx` | REST API (`/api/chat/agent`), AsyncStorage (`@numelyra_chat_history`) | High |
| **5. Calendar & Âm Lịch** | Reachable | `src/services/lunarService.ts`, `src/db/`| Thuật toán Hồ Ngọc Đức + SQLite `cadao.db` | High |
| **6. Astrology & Constellation** | Reachable | `src/services/astro/`, `src/features/` | `astronomy-engine` + REST API + AsyncStorage (`@astro_fortune_v3`) | High |
| **7. Wallpaper Studio** | Reachable | `src/screens/WallpaperStudioScreen.tsx`| REST API (`/api/lucky-wallpaper/generate`), In-memory carousel | High |
| **8. Settings, Notification, Billing**| Reachable | `src/services/billing*`, `dailyNotifications` | REST API + expo-notifications + AsyncStorage (`daily-reminder`) | High |
| **9. Game Hub** | Reachable | `src/games/gameHub*` | AsyncStorage (`numelyra:game-hub:v1`) | High |
| **10. Mini-game: Arrow Escape** | Reachable | `src/games/arrow-escape/` | Zustand persist (`arrow-escape-progress`) | High |
| **11. Mini-game: Space Game** | Reachable (sub-mode)| `src/games/arrow-escape/src/space_game`| In-memory game loop | High |
| **12. Mini-game: Mind Rules** | Reachable | `src/games/mind-rules/` | AsyncStorage (`mind-rules:active-progress:v1`) | High |
| **13. Mini-game: Ô Ăn Quan** | Reachable | `src/games/o-an-quan/` | In-memory board state | High |
| **14. Mini-game: DotBox** | Reachable | `src/games/dots-boxes/` | In-memory board state | High |
| **15. Mini-game: Sudoku** | Reachable | `src/games/sudoku/` | In-memory seeded board | High |
| **16. Mini-game: 2048** | Reachable | `src/games/game-2048/` | AsyncStorage (`game-2048:best-tile:v1`) | High |
| **17. Mini-game: Zip** | Reachable | `src/games/zip/` | AsyncStorage (`zip:progress:v1`) | High |

---

## 5. Danh sách tài liệu chi tiết

1. [`MODEL_CATALOG.md`](MODEL_CATALOG.md): Danh mục tra cứu chi tiết toàn bộ 78 model kèm định nghĩa trường, kiểu dữ liệu, ràng buộc và dẫn chứng mã nguồn.
2. [`CLASS_DIAGRAMS.md`](CLASS_DIAGRAMS.md): Toàn bộ 10 Mermaid Class Diagram (1 Overview + 9 Domain Diagrams) trực quan hóa quan hệ cấu trúc dữ liệu.
3. [`SWIFT_MODEL_MAP.md`](SWIFT_MODEL_MAP.md): Bảng quy đổi từng model sang Swift struct/enum, protocol (`Codable`, `Sendable`, `Identifiable`), module đích và cơ chế lưu trữ.
4. [`OPEN_QUESTIONS.md`](OPEN_QUESTIONS.md): Tổng hợp các điểm chênh lệch schema, trường dữ liệu chưa dùng, rủi ro đồng bộ và câu hỏi cần xác nhận.
5. [`DOMAIN_MODEL_GUIDE.md`](DOMAIN_MODEL_GUIDE.md): Giải thích cách 10 class diagram được tổ chức, trách nhiệm từng domain, luồng dữ liệu, file Swift sở hữu và quy tắc mở rộng model.
