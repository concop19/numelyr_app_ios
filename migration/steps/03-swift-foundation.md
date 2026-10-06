# Step 03 — Thiết lập nền tảng Swift

## Mục tiêu

Tạo nền tảng SwiftUI có thể kiểm thử và mở rộng, chỉ sau khi step 01–02 hoàn tất.

## Việc bắt buộc

1. Xác nhận deployment target, Swift version, bundle ID, URL scheme và capability dựa trên kết quả audit; không bật capability chưa dùng.
2. Thêm và khóa phiên bản TCA tương thích với toolchain sau khi kiểm tra build; tạo root `AppFeature`, root `Store` và navigation state theo quy tắc trong `AGENTS.md`.
3. Tổ chức code theo feature và layer tối thiểu: `App/`, `Features/`, `Core/Clients/`, `Shared/Components/`, domain model/engine và persistence.
4. Port model/data contract và pure engine trước; tạo fixture/golden test dùng cùng input baseline React Native.
5. Định nghĩa side effect qua TCA `@Dependency`; network, storage, time, random, location và notification phải có live/test implementation và không được gọi trực tiếp từ View.
6. Thiết lập quản lý cấu hình không chứa secret trong repository; tách development/production khi baseline yêu cầu.
7. Nhập design token và asset có kiểm soát từ manifest, tránh copy hàng loạt file chưa rõ owner.
8. Tạo app shell tối thiểu có loading/error state và navigation skeleton, nhưng chưa đánh dấu feature parity khi UI/logic chưa đầy đủ.

## Gate trước step tiếp theo

- Xcode build thành công trên simulator phù hợp.
- Unit test nền tảng bằng TCA `TestStore` và golden test đầu tiên chạy được.
- Kiến trúc và dependency mới được ghi trong decision log của `STATUS.md`.
