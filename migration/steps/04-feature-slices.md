# Step 04 — Chuyển đổi theo vertical slice

## Thứ tự mặc định

Thứ tự chỉ được đổi khi dependency map chứng minh hợp lý hơn; mọi thay đổi phải ghi vào `STATUS.md`.

1. App shell, auth/guest, profile và onboarding.
2. Shared domain engines: numerology, lunar, tarot, astrology và các formatter liên quan.
3. Chat end-to-end: history, API, reading, TTS/STT, location và các modal liên quan.
4. Calendar và Astrology, gồm canvas/video/fallback.
5. Wallpaper Studio và quyền lưu Photos.
6. Settings, notification, billing và account/profile management.
7. Game Hub, sau đó từng game như một slice độc lập: 2048, Sudoku, Dots & Boxes, Ô Ăn Quan, Arrow Escape, Mind Rules và ZIP.

## Chu trình cho từng slice

1. Đọc lại toàn bộ file React Native thuộc slice và dependency trực tiếp; cập nhật inventory nếu source thay đổi.
2. Viết acceptance criteria từ behavior thực tế, gồm success/loading/empty/error/offline/permission states.
3. Port logic/model trước, sau đó TCA dependency client, `State`/`Action`/`Reducer`, SwiftUI View và navigation state.
4. Chuyển đúng asset, animation, audio, haptic và accessibility có ý nghĩa cho trải nghiệm.
5. Viết reducer/dependency test bằng `TestStore`, test logic thuần và đối chiếu với baseline trước khi chuyển slice tiếp theo.
6. Cập nhật trạng thái, bằng chứng test, khác biệt có chủ đích và debt còn lại trong `STATUS.md`.

Không chia sẻ singleton hoặc state ngầm chỉ để mô phỏng React hook/context. Ưu tiên contract rõ ràng và lifecycle phù hợp với SwiftUI.
