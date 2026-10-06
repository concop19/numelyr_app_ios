# Step 01 — Audit toàn bộ dự án

## Mục tiêu

Hiểu đầy đủ baseline React Native và trạng thái dự án Swift trước khi đưa ra quyết định triển khai.

## Việc bắt buộc

1. Ghi commit/ref hiện tại của cả hai dự án vào `../STATUS.md` nếu chúng là Git repository; nếu không, ghi rõ “không có ref”.
2. Dùng `rg --files` để lập danh sách toàn bộ file trong `numelyra_app/`, loại trừ dependency/build cache như `node_modules`, `Pods`, `.gradle`, `build`, `dist`.
3. Đọc toàn bộ file nguồn và cấu hình dạng text có liên quan: entry point, `package.json`, Expo config, TypeScript config, `src/**/*.ts(x)`, script, test và tài liệu kỹ thuật.
4. Với asset/binary, không cần đọc byte thô. Phải lập catalog gồm path, loại, kích thước/dimension nếu hữu ích, nơi được tham chiếu và feature sở hữu. Kiểm tra cả asset trùng hoặc không còn dùng.
5. Quét import/export và lời gọi để dựng dependency graph cho screens, components, stores, services, engines, database và games.
6. Liệt kê mọi route, tab, modal, deep link, notification action và điều kiện điều hướng từ login/guest/onboarding vào app chính.
7. Liệt kê data model, storage key, bảng/endpoint Supabase, API contract, cache và chiến lược offline/error hiện có. Chỉ ghi tên biến môi trường; không sao chép giá trị secret.
8. Liệt kê capability cần thay thế trên iOS: auth/OAuth, location, notifications, speech, audio/video, media library, SQLite, haptic, orientation, canvas/Skia, linking và background behavior.
9. Đọc toàn bộ test để xác định invariant và golden behavior; chạy typecheck/test React Native nếu môi trường cho phép và ghi kết quả.
10. Audit `numelyra_app_ios/`: target, deployment version, signing/entitlement hiện có, file Swift, asset catalog, dependency và build status.

## Điều kiện hoàn tất

- Mỗi file nguồn/config/test đều đã được đánh dấu `Đã đọc`, `Generated/Vendor` hoặc `Không liên quan` trong inventory do agent thêm vào `STATUS.md` hoặc file inventory được liên kết từ đó.
- Mỗi asset có owner hoặc trạng thái chưa dùng/không rõ.
- Không còn screen, service, storage, API, route hoặc game nào chưa được ghi nhận.
- Các lỗ hổng và mâu thuẫn giữa tài liệu với mã thực tế được ghi ở mục rủi ro.
