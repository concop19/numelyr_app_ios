# Wallpaper Studio — React Native parity spec

## Source đã đọc lại cho slice

- `numelyra_app/src/screens/WallpaperStudioScreen.tsx`
- `numelyra_app/src/components/FloatingWallpaperCloud.tsx`
- `numelyra_app/src/components/ProfilePickerModal.tsx`
- `numelyra_app/src/components/NumerologyCardsModal.tsx`
- `numelyra_app/src/services/wallpaperSaver.native.ts`
- `numelyra_app/src/services/wallpaperSaver.web.ts`
- `numelyra_app/src/services/apiConfig.ts`
- `numelyra_app/src/services/numerology24Service.ts`
- `numelyra_app/src/store/userProfile.ts`
- `numelyra_app/App.tsx`, `app.json`, `package.json`

## Luồng và acceptance criteria

### 1. Input

- Nền tím `#211438`, phong cảnh full-screen, trăng/sao nhấp nháy và sprite mây trôi.
- Prompt mặc định khi để trống là `Falling asleep...`.
- Cho phép mở hồ sơ cá nhân; Wallpaper chỉ dùng một hồ sơ.
- Submit bằng nút mũi tên hoặc phím Go và có medium haptic.

### 2. Generating

- Chọn ngẫu nhiên một trong 6 style và 6 intention.
- Gửi `POST /api/lucky-wallpaper/generate` với JWT nếu có, profile, bốn chỉ số thần số học, `deviceType = mobile`, prompt và `count = 4`.
- Payload thực tế của source dùng key `personalYear` và `personalDay` qua spread `...numbers`. Các inventory cũ ghi `personalYearNumber`/`personalDayNumber` là sai và đã được sửa.
- Màn loading hiển thị tối thiểu 2,5 giây, bốn card nổi và trạng thái “Painting your scene...”.
- Hủy/back phải cancel request đang chạy. Lỗi trở về input, thông báo cụ thể và không âm thầm thay bằng ảnh mock.

### 3. Result

- Nhận cả `imageUrls` và legacy `imageUrl`; URL tương đối được resolve theo API base URL.
- Ảnh mới đứng đầu, giữ tối đa 20 ảnh AI trong memory. Sau lần tạo thành công đầu tiên, preset không còn nằm trong history, đúng source RN.
- Carousel, pagination, bốn thumbnail, fullscreen detail, “Try another” và “Save wallpaper” hoạt động.
- Fullscreen hiển thị affirmation, explanation, style và intention.

### 4. Save/permission

- Xin quyền Photos ở mức add-only và có `NSPhotoLibraryAddUsageDescription`.
- Ảnh remote được tải trước khi tạo `PHAsset`; ảnh preset đọc từ asset catalog.
- Loading chống double-submit; success/failure đều trả state về ổn định và thông báo cho người dùng.
- Permission denied không crash và hiển thị thông báo cấp quyền.

### 5. Navigation phụ

- Menu có lịch sử phiên, tạo mới và 24 lá bài Thần số học.
- Hồ sơ chỉnh trong Wallpaper hiện chỉ sống trong state của app. Persistence/cloud profile vẫn thuộc slice App shell/Auth/Profile và không được giả là đã hoàn tất.
- History vẫn memory-only để giữ parity; chưa tự ý thêm SwiftData.

## Mapping iOS

| Trách nhiệm | Đích Swift |
| --- | --- |
| State machine, request orchestration, presentation | `Features/Wallpaper/WallpaperFeature.swift` |
| SwiftUI input/loading/result/fullscreen/menu/profile/cards | `Features/Wallpaper/WallpaperView.swift` |
| API, random style/intention, download và Photos | `Core/Clients/WallpaperClient.swift` |
| DTO | `Shared/Models/BoundaryModels.swift` |
| Domain | `Shared/Models/Wallpaper.swift` |
| Asset | `Assets.xcassets/Wallpaper/` |
| Reducer/contract tests | `numelyra_app_iosTests/WallpaperFeatureTests.swift` |

## Khác biệt có chủ đích / debt

- SwiftUI dùng native `TabView`, sheet và full-screen cover thay `FlatList`/`Modal` custom, nhưng giữ hierarchy và tương tác chính.
- App shell đầy đủ 5 tab chưa được migrate. Root tạm thời giữ Calendar và Wallpaper trong native `TabView`, mặc định mở Wallpaper để review slice.
- Chưa có runtime screenshot parity vì máy audit chỉ có Command Line Tools, không có iOS Simulator SDK/full Xcode.
- Backend chưa có OpenAPI/versioned fixture; contract hiện khóa theo source mobile và reducer test.
