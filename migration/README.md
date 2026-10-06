# Quy trình chuyển đổi React Native sang Swift

Thư mục này là điểm bắt đầu bắt buộc cho mọi AI agent tham gia chuyển đổi `numelyra_app/` sang `numelyra_app_ios/`.

## Nguyên tắc

1. Đọc `../AGENTS.md`, file này và `STATUS.md` trước khi làm việc.
2. Audit toàn bộ mã nguồn React Native trước khi triển khai. Phải đọc mã thực tế; tài liệu chỉ là nguồn tham khảo.
3. Lập bản đồ màn hình, luồng, model, storage, API, native capability, asset và test trước khi chọn kiến trúc Swift.
4. Không dịch máy móc từng component. Chuyển theo hành vi và vertical slice hoàn chỉnh, dùng API native phù hợp của iOS.
5. Giữ `numelyra_app/` làm baseline chỉ đọc. Mọi thay đổi migration mặc định nằm trong `numelyra_app_ios/` và thư mục `migration/`.
6. Sau mỗi slice, so sánh UI, hành vi, dữ liệu và trạng thái lỗi với ứng dụng React Native rồi cập nhật `STATUS.md`.
7. Không sao chép secret, token, file môi trường hay dữ liệu nhạy cảm vào mã nguồn Swift.

## Trình tự bắt buộc

1. [Audit toàn bộ dự án](steps/01-full-audit.md)
2. [Lập inventory và bản đồ chuyển đổi](steps/02-migration-map.md)
3. [Thiết lập nền tảng Swift](steps/03-swift-foundation.md)
4. [Chuyển đổi theo vertical slice](steps/04-feature-slices.md)
5. [Kiểm chứng parity](steps/05-parity-validation.md)
6. [Hoàn thiện và cutover](steps/06-release-cutover.md)

Không được bỏ qua step 1–2 để đi thẳng vào viết UI. Một step chỉ hoàn tất khi bằng chứng và quyết định liên quan đã được ghi vào `STATUS.md`.

## Prompt audit chuyên biệt

- [Audit model và xây dựng class diagram](prompts/model-class-diagram.md): dùng khi cần quét toàn bộ model React Native, lập catalog, Mermaid class diagram và mapping sang Swift.

## Baseline quan sát ban đầu

- React Native/Expo SDK 57, TypeScript, React Navigation, Supabase, AsyncStorage, Skia và nhiều Expo native module.
- `src/` hiện có khoảng 217 file TypeScript/TSX, 16 test và `assets/` có khoảng 212 file. Agent phải đếm lại khi audit vì baseline có thể thay đổi.
- Các miền lớn đã thấy: auth/profile/onboarding, chat, numerology/tarot, lịch âm, astrology, wallpaper, settings/notification/billing và game hub.
- Dự án Swift hiện là SwiftUI template tối thiểu; chưa có feature migration hoàn chỉnh. Kiến trúc đích bắt buộc là The Composable Architecture (TCA) theo `../AGENTS.md`, nhưng nền tảng TCA chưa được triển khai trong project.

## Definition of Done cho mỗi feature

- Luồng happy path, loading, empty, error, offline và permission-denied đã được xử lý nếu feature có các trạng thái đó.
- Model, format dữ liệu, quy tắc tính toán và storage tương thích với baseline đã thống nhất.
- Asset, accessibility label, animation/haptic quan trọng và navigation/deep link liên quan hoạt động.
- Có unit test cho logic và kiểm tra UI/parity phù hợp; build Swift thành công.
- `STATUS.md` chứa bằng chứng kiểm chứng và các khác biệt có chủ đích.
