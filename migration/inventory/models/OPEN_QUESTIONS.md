# Các Vấn đề Kỹ thuật & Câu hỏi Mở (Open Questions)

Tài liệu này tổng hợp các điểm chênh lệch schema (schema drift), trường dữ liệu chưa dùng, rủi ro đồng bộ và các quyết định kiến trúc cần thống nhất trước khi triển khai chi tiết mã nguồn Swift.

---

## 1. Schema Drift & Rủi ro Đồng bộ

### 1.1 Thiếu trường `gender` trên bảng Supabase `user_numerology_profiles`
- **Hiện trạng trong React Native**: Bảng cloud `user_numerology_profiles` chỉ có các cột `(id, user_id, name, birth_date, created_at)` (`userProfile.ts:95-103`). Khi người dùng đăng nhập trên thiết bị mới và kéo hồ sơ từ cloud về, client bắt buộc phải hardcode `gender = 'female'` (`authContext.tsx:66`). Sau đó, nếu máy cục bộ có dữ liệu cũ thì mới merge lại (`authContext.tsx:111`).
- **Dẫn chứng**: `src/store/userProfile.ts:95-103`, `src/store/authContext.tsx:66, 111`.
- **Ảnh hưởng nếu chọn sai**:
  - Nếu giữ nguyên: Người dùng nam đăng nhập lại trên iOS sẽ bị gán nhầm giới tính nữ, dẫn đến tính toán quẻ Bát Tự / Tử Vi / Cung Phi Bát Trạch bị sai lệch (vì Cung Phi và phối hôn phụ thuộc trực tiếp vào giới tính nam/nữ).
  - Nếu sửa schema: Cần bổ sung cột `gender text` trên bảng Supabase `user_numerology_profiles` và cập nhật backend SQL migration.

---

### 1.2 Trường `birthTime` và `birthPlace` tồn tại trong Model nhưng thiếu UI thu thập
- **Hiện trạng trong React Native**: `UserProfile` có cả `birthTime?` và `birthPlace?` (`userProfile.ts:13-14`), còn `UserBirthInput`/`PureAstroFeatureMetadata` chỉ truyền `birthTime` (`astroVectorEngine.ts:20-32`). `OnboardingScreen.tsx` và `SettingsScreen.tsx` không có trường nhập hai giá trị này, nên profile tạo qua UI hiện tại thường kích hoạt **Noon chart** (12:00) với confidence giảm từ `1.0` xuống `0.7`. Không được khẳng định “luôn luôn” vì dữ liệu legacy/import vẫn có thể chứa giờ sinh.
- **Dẫn chứng**: `src/store/userProfile.ts:13-14`, `src/services/astro/astroEngine.ts:20`, `src/features/astrology/dailyAstroFortune.ts:3-6`.
- **Ảnh hưởng nếu chọn sai**:
  - Nếu không hỗ trợ giờ sinh trên iOS: Độ chính xác của cung Mọc (Ascendant) và vị trí Mặt Trăng quá cảnh (Transit Moon) sẽ bị giảm sút.
  - Đề xuất: Thêm mục chỉnh sửa giờ sinh và nơi sinh trong `ProfileEditorView` trên iOS để tăng độ tin cậy của thuật toán chiêm tinh.

---

### 1.3 Lịch sử tạo hình nền (Wallpaper History) không được lưu trữ bền vững
- **Hiện trạng trong React Native**: Khi người dùng tạo 4 hình nền may mắn qua AI (`/api/lucky-wallpaper/generate`), kết quả chỉ được thêm vào state React cục bộ `setHistory` (`WallpaperStudioScreen.tsx:499-502`). Toàn bộ lịch sử này **bị mất hoàn toàn khi tắt app hoặc thoát màn hình**.
- **Dẫn chứng**: `src/screens/WallpaperStudioScreen.tsx:499-502`, `FEATURES.md:81`.
- **Ảnh hưởng nếu chọn sai**:
  - Người dùng sau khi trả tiền hoặc dùng quota tạo ảnh đẹp nếu vô tình đóng app sẽ không thể tìm lại các ảnh vừa tạo.
  - Đề xuất Swift: Lưu danh sách `WallpaperItem` vào SwiftData hoặc thư mục Documents cục bộ để người dùng có thể xem lại bộ sưu tập bất kỳ lúc nào.

---

## 2. Ranh giới Kiểu dữ liệu & Type Safety

### 2.1 Trường `card?: any` trong Tin nhắn Chat
- **Hiện trạng trong React Native**: `MessageItem.card` và `StoredChatMessage.card` đều có kiểu `any` hoặc `unknown`. Khi render, hàm `renderCardWidget` (`ChatScreen.tsx:1238`) tự kiểm tra cấu trúc động để hiển thị widget tương ứng (`agent_synthesis`, `two_choices`, `color_guidance`, `tuViBazi`, v.v.).
- **Dẫn chứng**: `src/screens/ChatScreen.tsx:59, 840, 1238`, `src/services/chatHistoryStorage.ts:10`.
- **Ảnh hưởng nếu chọn sai**:
  - Nếu trong Swift dùng `[String: Any]` hoặc `JSONValue`: Sẽ mất hoàn toàn lợi thế an toàn của hệ thống type Swift, dễ gây crash runtime khi giải mã tin nhắn cũ.
  - Đề xuất Swift: Định nghĩa enum strongly-typed `ChatCardPayload` với các cases:
    ```swift
    enum ChatCardPayload: Codable, Equatable, Sendable {
        case agentSynthesis(AgentSynthesisPayload)
        case loveCompatibility(TuViBaziSynastry)
        case colorGuidance(ColorGuidanceContext)
        case twoOptions(TwoOptionsPayload)
        case timingTrajectory(TrajectoryPayload)
        case singleMessage(SingleMessagePayload)
    }
    ```

---

### 2.2 Thuật toán Lấy Ca Dao theo ngày từ SQLite
- **Hiện trạng trong React Native**: Bảng SQLite `cadao` có ID không liên tục. Hàm `getDailyCaDao(date)` (`cadaoService.ts:94`) dùng `seed = day * 31 + month * 37 + year * 7`, sau đó lấy `OFFSET seed % totalCount` trên kết quả `ORDER BY id`.
- **Dẫn chứng**: `src/db/cadaoService.ts:94-115`.
- **Ảnh hưởng nếu chọn sai**:
  - Nếu Swift dùng thuật toán băm (hash) khác hoặc query trực tiếp theo `WHERE id = ...`, câu ca dao hàng ngày và thơ trong Lá Thăm Chiêm Tinh trên iOS sẽ bị lệch so với bản React Native trên cùng một ngày.

---

## 3. Quota & Gói Pro Billing

### 3.1 Gói Pro chưa có cơ chế khóa tính năng ở Client
- **Hiện trạng trong React Native**: Client có gọi API `/api/billing/subscription` để lấy `plan: 'pro' | 'free'`, tuy nhiên trong mã nguồn hiện tại **không có bất kỳ đoạn code nào kiểm tra `plan === 'pro'` để khóa tính năng hay giới hạn lượt chat**.
- **Dẫn chứng**: `src/services/billingService.ts:7-29`, `src/screens/ChatScreen.tsx:40, 51`, `FEATURES.md:51, 90`.
- **Ảnh hưởng nếu chọn sai**:
  - Không rõ việc kiểm soát lượt chat/tạo ảnh được backend chặn qua HTTP 403/429 hay client phải tự quản lý quota.
  - Cần xác nhận với đội ngũ backend về cơ chế thực thi Pro entitlement.

---

## 4. Code Dormant & Duplicate trong Game Hub

### 4.1 Hai cây thư mục riêng biệt cho Mind Rules và DotBox
- **Hiện trạng trong React Native**:
  - Mini-game Mind Rules có 1 file wrapper hoạt động thực tế `MindRulesGame.tsx` (chứa 48 puzzles) và 1 ứng dụng Expo Router đầy đủ chưa được gắn vào app (`src/games/mind-rules/src/`).
  - Mini-game DotBox reachable nằm trong `src/games/o-an-quan/src/dotbox/`; một cây duplicate riêng tồn tại tại `src/games/dots-boxes/`.
- **Dẫn chứng**: `src/games/mind-rules/MindRulesGame.tsx`, `src/games/dots-boxes/dotbox/`, `SOURCE_AUDIT.md:30`.
- **Ảnh hưởng nếu chọn sai**:
  - Nếu port toàn bộ thư mục `mind-rules/src/` và `dots-boxes/`, chi phí phát triển sẽ tăng gấp 3 lần cho những tính năng mà người dùng hiện tại không thể truy cập từ `App.tsx`.
  - Quyết định: Chỉ port các engine và màn chơi đang thực sự được gắn vào `GameHubScreen.tsx`.
