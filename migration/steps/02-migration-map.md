# Step 02 — Lập inventory và bản đồ chuyển đổi

## Mục tiêu

Biến kết quả audit thành kế hoạch phụ thuộc rõ ràng, tránh chuyển UI trước khi hiểu logic và dữ liệu.

## Việc bắt buộc

1. Hoàn thiện feature matrix trong `../STATUS.md`: entry point, child view, model, service, storage, asset, permission, test và route liên quan.
2. Vẽ thứ tự phụ thuộc: shared domain/model → storage/network/native adapter → feature UI → app navigation.
3. Ánh xạ mỗi feature sang TCA `State`, `Action`, `Reducer`, dependency client, destination/delegate và `View`; xác định state nào thuộc feature, app root hoặc shared domain.
4. Xác định logic thuần TypeScript có thể port và kiểm thử độc lập, đặc biệt numerology, lunar, tarot, astrology và game engine.
5. Chốt data contract cần giữ tương thích: kiểu ngày/giờ và timezone, enum, JSON field, ID, storage key, API payload/response và quy tắc làm tròn/random seed.
6. Lập asset manifest và quy tắc tên đích trong `Assets.xcassets`; xác định file cần giữ nguyên chất lượng, resize hoặc chuyển định dạng.
7. Với mỗi thư viện React Native/Expo, chọn native equivalent và ghi vào decision log. Các ứng viên cần đánh giá gồm:
   - Navigation → SwiftUI `NavigationStack`, `TabView`.
   - AsyncStorage → `UserDefaults`, file/SwiftData hoặc Keychain theo độ nhạy và cấu trúc dữ liệu.
   - Supabase → Supabase Swift hoặc client API được kiểm soát.
   - Notifications/Location/Photos/Speech → UserNotifications/CoreLocation/Photos/Speech và AVFoundation.
   - Skia/canvas → SwiftUI Canvas, Core Graphics, SpriteKit hoặc Metal theo yêu cầu hiệu năng.
   - SQLite/audio/video/haptic/orientation/linking → native framework tương ứng sau khi xác minh behavior.
8. Xếp hạng feature theo giá trị, rủi ro và dependency; ghi rõ blocker cần giải quyết trước từng slice.

## Điều kiện hoàn tất

- Mọi feature có đường đi từ source tới đích Swift và acceptance criteria.
- Mọi dependency native quan trọng có phương án, lý do và owner.
- Các quyết định có rủi ro cao được ghi rõ; agent không tự âm thầm thay đổi contract hoặc UX.
