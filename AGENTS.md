# Tổng quan dự án

Dự án này xây dựng lại ứng dụng React Native hiện có thành một ứng dụng iOS native bằng Swift.

- `numelyra_app/` chứa mã nguồn React Native gốc và được dùng làm dự án tham chiếu.
- `numelyra_app_ios/` chứa dự án Swift/iOS mới.
- Khi triển khai ứng dụng Swift, hãy tham khảo `numelyra_app/` để đảm bảo giao diện và hành vi tương ứng với ứng dụng React Native.

## Quy trình migration bắt buộc

- Trước khi viết hoặc sửa mã Swift, đọc `migration/README.md` và `migration/STATUS.md`.
- Lần audit đầu tiên phải quét toàn bộ dự án React Native theo `migration/steps/01-full-audit.md`; không chỉ dựa vào `README.md` hoặc một màn hình riêng lẻ.
- Thực hiện tuần tự các step trong `migration/steps/` và cập nhật `migration/STATUS.md` sau mỗi step hoặc feature slice.
- Mặc định chỉ thay đổi `numelyra_app_ios/`. Không sửa `numelyra_app/` nếu người dùng không yêu cầu rõ ràng.

---

# Quy tắc phát triển ứng dụng iOS (`numelyra_app_ios`)

Dự án iOS được xây dựng theo kiến trúc **The Composable Architecture (TCA)** của Point-Free. Khi phát triển các tính năng và màn hình, cần tuân thủ các nguyên tắc sau:

### 1. Cấu trúc Feature chuẩn TCA (`@Reducer`)
Mỗi tính năng/màn hình được tổ chức theo cấu trúc TCA chuẩn:
- **`State`**: Chứa toàn bộ trạng thái dữ liệu cần thiết của màn hình/tính năng.
- **`Action`**: Định nghĩa rõ ràng các hành động của người dùng (UI event) hoặc hệ thống (delegate, internal, response).
- **`Reducer`**: Xử lý logic thay đổi state và các side effects (sử dụng macro `@Reducer`).
- **`View`**: SwiftUI View quan sát và gửi action thông qua `StoreOf<Feature>`.

### 2. Tổ chức thư mục (Project Structure)
Dự án được phân cấp rõ ràng theo các tầng:
- `App/`: Điểm khởi chạy ứng dụng (`AppFeature`, root store, app delegate).
- `Features/`: Chứa các màn hình/tính năng độc lập (mỗi feature nằm trong thư mục riêng gồm `<Feature>Feature.swift` và `<Feature>View.swift`).
- `Core/` / `Clients/`: Quản lý các TCA `@Dependency` (API clients, storage, keychain, analytics, v.v.).
- `Shared/` / `Components/`: Chứa các reusable UI components, models chung, helpers và extensions.

### 3. Quản lý Side Effects & Dependencies
- Tuyệt đối không gọi trực tiếp API hoặc các async side effects từ trong View.
- Toàn bộ side effects phải được định nghĩa thông qua hệ thống **`@Dependency`** của TCA để đảm bảo tính testable và dễ bảo trì.

### 4. Điều hướng (Navigation)
- Quản lý luồng điều hướng bằng State chuẩn của TCA (sử dụng `StackState`, `@Presents`, `Destination`, `sheet(store:)`, `navigationDestination(store:)`).
