# Step 06 — Hoàn thiện và cutover

## Checklist

1. Xác nhận bundle ID, URL scheme, signing, entitlement và capability khớp môi trường phát hành.
2. Hoàn thiện privacy usage descriptions cho location, notification, microphone/speech và Photos theo capability thực dùng.
3. Kiểm tra cấu hình production, secret injection, Supabase/OAuth redirect, API endpoint và không để credential trong repository/log.
4. Xác nhận chiến lược tương thích hoặc migration cho profile, chat history, settings và game progress; nếu không thể chuyển dữ liệu từ app cũ, phải ghi rõ quyết định sản phẩm.
5. Kiểm tra icon, launch experience, asset license/size, localization tiếng Việt và accessibility.
6. Chạy release build/archive, test trên thiết bị thật cho capability native và thực hiện regression toàn bộ critical flow.
7. Chỉ đánh dấu hoàn tất khi không còn blocker mức cao, mọi khác biệt đã được duyệt và `STATUS.md` phản ánh đúng trạng thái phát hành.

Sau cutover, giữ inventory và decision log để bảo trì; không xóa baseline React Native cho tới khi người dùng xác nhận.
