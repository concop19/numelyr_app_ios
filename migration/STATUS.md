# Trạng thái migration

File này là nguồn sự thật chung giữa các phiên làm việc. Agent phải cập nhật ngay khi hoàn tất audit, đưa ra quyết định kiến trúc hoặc chuyển xong một feature slice.

## Audit gần nhất

- Trạng thái: Đã hoàn tất audit tĩnh source React Native; chờ runtime validation và target audit
- Thời điểm: 2026-10-06 (Asia/Ho_Chi_Minh)
- Commit/ref React Native: `b89d94fdbee6118edca8c09d9232115da081afb9` + working tree có 42 asset deletion
- Commit/ref Swift: Outer repository chưa có commit `HEAD`
- Người/agent thực hiện: Codex
- Báo cáo: [`inventory/SOURCE_AUDIT.md`](inventory/SOURCE_AUDIT.md), [`inventory/FEATURES.md`](inventory/FEATURES.md), [`inventory/ASSETS.md`](inventory/ASSETS.md), [`inventory/models/README.md`](inventory/models/README.md), [`inventory/models/MODEL_CATALOG.md`](inventory/models/MODEL_CATALOG.md), [`inventory/models/CLASS_DIAGRAMS.md`](inventory/models/CLASS_DIAGRAMS.md), [`inventory/models/DOMAIN_MODEL_GUIDE.md`](inventory/models/DOMAIN_MODEL_GUIDE.md), [`inventory/models/SWIFT_MODEL_MAP.md`](inventory/models/SWIFT_MODEL_MAP.md), [`inventory/models/OPEN_QUESTIONS.md`](inventory/models/OPEN_QUESTIONS.md)

## Tiến độ quy trình

| Step | Trạng thái | Bằng chứng / ghi chú |
| --- | --- | --- |
| 01. Full audit | Đang làm | Đã hoàn tất audit source, asset và 78 model/entity toàn bộ dự án; chưa chạy npm typecheck/test do môi trường |
| 02. Migration map | Đang làm | Đã lập bản đồ model/entity sang Swift (`SWIFT_MODEL_MAP.md`) và class diagram (`CLASS_DIAGRAMS.md`) |
| 03. Swift foundation | Đang làm | Tích hợp TCA 1.26.2, Supabase 2.55.3, AstronomyKit 3.1.0; cấu trúc App/, Features/, Core/, Shared/, test target và build xcodebuild thành công |
| 04. Feature slices | Đang làm | Astrology service slice đã hoàn tất engine/vector/cache/API client và unit test; UI feature chưa triển khai |
| 05. Parity validation | Chưa bắt đầu | Chưa có kết quả đối chiếu |
| 06. Release cutover | Chưa bắt đầu | Chưa sẵn sàng phát hành |

Giá trị trạng thái hợp lệ: `Chưa bắt đầu`, `Đang làm`, `Bị chặn`, `Hoàn tất`.

## Feature inventory

| Feature | Entry point React Native | Phụ thuộc chính | Đích Swift | Trạng thái | Parity / ghi chú |
| --- | --- | --- | --- | --- | --- |
| App shell và navigation | `App.tsx` | Auth, profile, linking, notification | Chưa quyết định | Chưa bắt đầu | 5 tab + Games/Reading Detail; đã audit source |
| Login, guest và profile | `src/screens/LoginScreen.tsx`, `OnboardingScreen.tsx` | Supabase, AsyncStorage | Chưa quyết định | Chưa bắt đầu | Email/Google/guest + multi-profile sync; đã audit source |
| Numerology và Tarot | `src/services/numerologyEngine.ts`, `tarotService.ts` | Knowledge DB, assets, random | Chưa quyết định | Chưa bắt đầu | 24 chỉ số + deck 78 lá; đã audit source |
| Chat | `src/screens/ChatScreen.tsx` | API, history, tarot, TTS/STT, location, Bát Tự | Chưa quyết định | Chưa bắt đầu | Online + local fallback; đã audit source |
| Calendar | `CalendarScreen.tsx` | Lunar, SQLite ca dao, remote/local art | `Core/Services/LunarService.swift`, `Core/Clients/LunarClient.swift`, `Features/Calendar/` | Đang làm | Đã hoàn tất `LunarService` + `LunarClient` + `LunarDaySnapshot`; còn SQLite ca dao, calendar art và UI `CalendarFeature` |
| Astrology | `AstrologyScreen.tsx` | Astronomy engine, API, video, canvas, cache | `Shared/Engines/AstrologyEngine.swift`, `Core/Clients/AstrologyClient.swift` | Đang làm | Đã port engine/vector 32 chiều, cache v3/v2 và daily-fortune API; còn TCA feature, video/canvas, share/haptic và parity UI |
| Wallpaper Studio | `WallpaperStudioScreen.tsx` | API, numerology, assets, Photos | Chưa quyết định | Chưa bắt đầu | 4 ảnh/lần, history memory-only; đã audit source |
| Settings | `SettingsScreen.tsx` | Notification, billing, auth | Chưa quyết định | Chưa bắt đầu | Daily reminder + PayOS/PayPal; đã audit source |
| Game Hub | `GameHubScreen.tsx`, `src/games/gameHub*.ts` | Storage, deep link, notification | Chưa quyết định | Chưa bắt đầu | Daily rotation/streak/chơi tiếp; đã audit source |
| 7 mini-game | `src/games/` | Engine, storage, audio, haptic, orientation, realtime | Chưa quyết định | Chưa bắt đầu | Arrow, Mind Rules, Ô Ăn Quan, DotBox, Sudoku, 2048, Zip; xem inventory |

Thêm hàng khi audit phát hiện feature, route hoặc background flow khác. Không gộp một feature thành “hoàn tất” nếu còn nhánh quan trọng chưa được ánh xạ.

## Quyết định kiến trúc

| Ngày | Quyết định | Lý do | Ảnh hưởng / người duyệt |
| --- | --- | --- | --- |
| 2026-10-06 | Dùng The Composable Architecture (TCA) cho ứng dụng Swift | Quy tắc bắt buộc trong `AGENTS.md` | Mọi feature, navigation, dependency và test Swift |
| 2026-10-06 | Tích hợp TCA 1.26.2 và Supabase 2.55.3; cấu trúc App/, Features/, Core/, Shared/ | Thiết lập nền tảng dự án Swift theo chuẩn Point-Free TCA | Toàn bộ codebase Swift trong `numelyra_app_ios/` |
| 2026-10-06 | Chuyển asset theo manifest và theo vertical slice; foundation chỉ nhập asset app shell/auth/chat đã xác nhận reachable | Tránh copy legacy/duplicate và tránh tăng bundle bởi Tarot, video, wallpaper, game trước khi feature có owner | `Assets.xcassets/Foundation`, `Shared/Assets/AppAsset.swift`, `inventory/ASSETS.md` |
| 2026-10-06 | Theme mặc định dùng palette tím đậm/vàng của app shell React Native và semantic token SwiftUI | Giữ nhận diện hiện tại, loại bỏ màu/spacing hard-code khỏi feature Swift | `Shared/Theme/AppTheme.swift`, `AppThemeComponents.swift` |
| 2026-10-06 | Thiết kế lại model graph thành đúng 10 class diagram và tách rõ domain model, API/Supabase DTO, persistence payload | Loại bỏ schema gộp sai, biểu diễn optionality/inferred relation và giữ contract React Native tại boundary | `inventory/models/CLASS_DIAGRAMS.md`, `Shared/Models/BoundaryModels.swift`, `MiniGameModels.swift` và các model domain |
| 2026-10-06 | Namespace model từng mini-game và dùng enum cho union hữu hạn | Tránh xung đột `Direction`, `Difficulty`, `Board`, `Puzzle`; tăng type safety và `Sendable` cho TCA | `Shared/Models/MiniGameModels.swift`, `AgentDecision.swift`, `Astrology.swift`, `TuViBazi.swift` |
| 2026-10-06 | Dùng AstronomyKit 3.1.0 cho phép tính vị trí thiên thể và đóng gói orchestration trong `AstrologyClient` TCA | AstronomyKit bọc cùng Don Cross Astronomy Engine như baseline React Native; giữ tính toán offline, cache/API testable và không đưa side effect vào View | `Shared/Engines/AstrologyEngine.swift`, `Core/Clients/AstrologyClient.swift`, `Core/Clients/AstrologyFortuneCache.swift` |
| 2026-10-06 | Tách `LunarService` (pure engine) và `LunarClient` (`@DependencyClient`) kèm `LunarDaySnapshot` | Giữ thuật toán Hồ Ngọc Đức/Hoàng lịch thuần túy, deterministic theo `currentHour` và `timeZone = 7.0`, đồng thời dễ mock trong `CalendarFeature` | `Shared/Models/LunarCalendar.swift`, `Core/Services/LunarService.swift`, `Core/Clients/LunarClient.swift` |
| 2026-10-06 | Chuẩn hóa thuật toán Can Chi giờ (Ngũ Thử Độn), Hướng xuất hành (Hỷ/Tài/Hạc Thần), 12 thần Giờ Hoàng Đạo, Lục Diệu Lý Thuần Phong, 12 Trực Kiến Trừ và Ngũ Hành Nạp Âm 60 Hoa Giáp | Thay thế các công thức giả lập `jd % 8` / `jd % 6` ở baseline RN và sửa lỗi thứ tự `startHour = 23` của Giờ Tý trong `getBestDepartureHour` | `Shared/Models/LunarCalendar.swift`, `Core/Services/LunarService.swift`, `numelyra_app_iosTests/LunarServiceTests.swift` |

## Rủi ro và blocker

| Mức độ | Vấn đề | Kế hoạch xử lý | Trạng thái |
| --- | --- | --- | --- |
| Cao | Source RN có 42 asset tracked đang bị xóa, gồm app icon config | Xác nhận đây là thay đổi có chủ đích trước khi lấy asset baseline | Mở |
| Cao | Node/npm không có nên test và typecheck baseline chưa chạy | Chuẩn bị Node phù hợp Expo 57 rồi chạy toàn bộ validation | Mở |
| Cao | Có 71 file test/platform/dormant/duplicate ngoài graph chính | Chỉ port behavior reachable; xác nhận riêng nếu muốn hồi sinh dormant feature | Mở |
| Trung bình | STT native iOS chưa tồn tại; place card và Pro gate chưa nối hoàn chỉnh | Chốt parity mong muốn ở Step 02 thay vì sao chép thiếu sót ngầm | Mở |
| Trung bình | Wallpaper history và một số profile/astrology field chưa persist/nhập từ UI | Chốt data contract và migration policy ở Step 02 | Mở |
| Trung bình | Chat/Wallpaper/Astrology/Billing DTO hiện được suy ra từ mobile client; chưa có OpenAPI/backend schema được version hóa | Đối chiếu backend trước khi khóa API client và thêm contract fixture test | Mở |

## Nhật ký kiểm chứng

| Ngày | Slice/build | Test đã chạy | Kết quả | Khác biệt có chủ đích |
| --- | --- | --- | --- | --- |
| 2026-10-06 | Foundation asset + shared theme | Validate toàn bộ `Contents.json` bằng `jq`; compile catalog bằng `actool`; type-check `AppTheme`, component và `AppAsset` bằng `swiftc`; `xcodebuild` Debug cho generic iOS Simulator | Đạt; exit code 0, `Assets.car` khoảng 12 MB, Debug app khoảng 53 MB | Chỉ chuyển 15 asset app shell/auth/chat; asset Tarot, numerology, calendar, astrology, wallpaper và game sẽ đi cùng feature slice |
| 2026-10-06 | Model foundation + class diagrams | `swiftc -typecheck Shared/Models/*.swift`; đếm 10 Mermaid block và rà mọi nhãn inferred; `xcodebuild` Debug trên iPhone 17 Simulator | Đạt; cả type-check và build exit code 0 | DTO API được mô hình hóa từ client hiện tại; cần fixture/backend schema để khóa contract |
| 2026-10-06 | Astrology service slice | `xcodebuild test` trên iPhone 17 Simulator, chỉ chạy `AstrologyServiceTests` | Đạt; 7/7 test pass, gồm parse giờ sinh/noon UTC, vector, aspect score, dominant signal, cache key UTF-16 và corrupt cache | Giữ cache key/hash tương thích React Native; fallback ca dao vẫn dùng khi feature chưa truyền anchor; JWT chờ auth layer cung cấp |
| 2026-10-06 | LunarService + LunarClient cho Calendar | Biên dịch và chạy golden test `verify_lunar` (biên Tết 1996, Tết 2026, tháng nhuận 2023, Can Chi, 12 giờ Hoàng/Hắc đạo + xung tuổi, Nguyệt Kỵ/Tam Nương, kẹp ngày cuối tháng `moveDate`, tuần ISO, lưới 42 ngày); `xcodebuild` Debug cho generic iOS Simulator | Đạt; toàn bộ golden assertions và `xcodebuild` exit code 0 | `getBestDepartureHour` nhận `currentHour` tường minh qua `LunarClient` để deterministic khi test |
| 2026-10-06 | Chuẩn hóa Can Chi, Hướng & Giờ xuất hành trong `LunarService` | `xcodebuild build-for-testing` và `LunarServiceTests` + `AstrologyServiceTests` | Đạt; `build-for-testing` exit code 0, kiểm chứng Ngũ Thử Độn, Nạp Âm, 12 thần Thanh Long, `getBestDepartureHour`, Hỷ/Tài/Hạc Thần và 12 Trực | Nâng cấp từ `jd % 8` / `jd % 6` sang bảng chuẩn Lịch Vạn Niên theo yêu cầu người dùng; giữ backward-compatible cho `DayDirection`, `LunarHourInfo`, `DayActivities` |
