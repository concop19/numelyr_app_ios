# Step 05 — Kiểm chứng parity

## Kiểm tra bắt buộc

1. So sánh flow trên cùng persona/profile: lần chạy đầu, guest, đăng nhập, có/không có profile và phiên hết hạn.
2. Dùng cùng fixture để so output engine React Native và Swift; kiểm tra timezone, locale `vi-VN`, Unicode tiếng Việt, leap date và boundary input.
3. So sánh UI bằng screenshot ở thiết bị nhỏ/lớn, light/dark nếu được hỗ trợ, Dynamic Type và Reduce Motion.
4. Kiểm tra lifecycle: cold start, background/foreground, deep link, mở từ notification và khôi phục state.
5. Kiểm tra permission denied/restricted cho location, notification, microphone/speech và Photos; ứng dụng phải có fallback rõ ràng.
6. Kiểm tra offline, timeout, API lỗi, dữ liệu hỏng, storage migration và retry/cancel.
7. Với từng game, kiểm tra luật, scoring, persistence, audio/haptic, orientation, deterministic logic và performance.
8. Chạy toàn bộ test Swift và build sạch; chạy lại test React Native dùng làm baseline nếu source baseline thay đổi.

## Báo cáo

Ghi command/test, simulator/device, kết quả và link/path bằng chứng vào `../STATUS.md`. Mọi khác biệt phải được sửa hoặc đánh dấu là khác biệt có chủ đích đã được chấp nhận.
