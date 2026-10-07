# Settings screen — React Native parity specification

## React Native source audited

- `numelyra_app/src/screens/SettingsScreen.tsx`
- `numelyra_app/src/services/billingService.ts`
- `numelyra_app/src/services/dailyNotifications.ts`
- `numelyra_app/src/services/apiConfig.ts`
- `numelyra_app/src/store/authContext.tsx`
- `numelyra_app/App.tsx`
- `numelyra_app/ROADMAP_LOGIN_THEME_PRO.md`

## Reachable behavior

### 1. Visual layout, cosmic sky & palette

- Dark night-sky background `#0E092B` (`preferredColorScheme(.dark)`) with full-screen linear gradient `['#211052', '#11082F', '#0C0625']` (`start: (0.1, 0)`, `end: (0.9, 1)`).
- Decorative non-interactive sky layer (`pointerEvents = "none"`):
  - Crescent moon `☾` (`#FFE7A0`, 86pt, `top = 12`, `trailing = 22`, rotated `-18°`, opacity `0.95`)
  - Star 1 `✦` (`#F8B7FF`, 16pt, `top = 112`, `leading = 26`)
  - Star 2 `✧` (`#FFE29A`, 12pt, `top = 76`, `leading = 164`)
  - Star 3 `✦` (`#FFD779`, 20pt, `top = 188`, `trailing = 52`)
  - Elliptical orbit (`330×250`, `top = -105`, `trailing = -92`, 1pt border `rgba(235, 157, 255, 0.32)`, rotated `25°`)
- Scroll container (`paddingHorizontal = 17`, `paddingTop = 12`, `paddingBottom = 34`, max content width `AppTheme.Size.contentMaxWidth`):
  - Hero header (`paddingHorizontal = 22`, `paddingTop = 9`, `paddingBottom = 26`):
    - Title: `Cài đặt` (`#FCF5FF`, 35pt black, kerning `0.2`, centered)
    - Subtitle: `Tùy chỉnh hành trình NUMELYRA theo cách của bạn` (`#B8A8D8`, 14pt, `marginTop = 5`, centered)
- Reusable `SettingsCard`:
  - Standard gradient `['#321060', '#291051', '#210943']`, border `rgba(153, 95, 210, 0.62)`, shadow `#1A063A`
  - Pro variant gradient `['#421777', '#321060', '#230944']`, border `rgba(184, 111, 226, 0.70)`, shadow `#25074A`
  - Top-to-bottom subtle overlay gradient `['rgba(247, 199, 255, 0.12)', 'rgba(33, 12, 76, 0.04)', 'rgba(8, 4, 34, 0.32)']`
  - Corner radius `24`, padding `17`, bottom spacing `16`.

### 2. Daily reminder card (`NHẮC NHỞ HẰNG NGÀY`)

- Loads persisted `DailyReminderSettings` from key `numelyra:daily-reminder:v1` on screen appearance/focus, defaulting to `{ enabled: false, hour: 20, minute: 0 }` and clamping invalid `hour` (`0...23`) to `20` and `minute` (`0...59`) to `0`.
- Row 1 (`Nhắc chơi mỗi ngày`):
  - Bell icon badge (`45×45`, radius `15`, fill `rgba(127, 75, 168, 0.28)`, border `rgba(255, 209, 109, 0.46)`, icon `#FFD26C`)
  - Dynamic hint:
    - When `canUseNativeNotifications == true`: `Lúc HH:mm theo giờ thiết bị` (2-digit zero-padded hour and minute)
    - When `canUseNativeNotifications == false`: `Khả dụng trên bản phát hành của ứng dụng`
  - Toggle switch (`#F5BA5B` active track) saves updated `DailyReminderSettings`.
- Divider (`1pt rgba(182, 133, 231, 0.23)`, vertical margin `14`).
- Row 2 (`Giờ nhắc` / `Chọn thời điểm phù hợp với bạn`):
  - Clock icon badge (`45×45`, radius `15`, fill `rgba(86, 59, 152, 0.36)`, border `rgba(182, 137, 241, 0.44)`, icon `#C7A4FF`)
  - Preset hour selector row (`[18, 20, 21]` rendered as `18:00`, `20:00`, `21:00`):
    - Selecting an hour saves `{ enabled: dailyReminder.enabled, hour, minute: dailyReminder.minute }`.
- Notification scheduling & permission handling (`dailyNotifications.ts`):
  - Always cancels existing pending notifications before rescheduling.
  - When `enabled == true`, checks/requests notification permission (`UNUserNotificationCenter`).
  - If permission is granted, schedules a repeating daily calendar notification at `hour:minute` with:
    - `title`: `Thử thách hôm nay đã sẵn sàng ✦`
    - `body`: `Giữ chuỗi chơi của bạn cùng NUMELYRA.`
    - `data.url`: `numelyra://games/daily`
  - If the user attempted to enable (`next.enabled == true`) but permission was denied (`saved.enabled == false`), presents an alert:
    - Title: `Chưa bật thông báo`
    - Message: `Bạn có thể bật lại quyền thông báo trong Cài đặt thiết bị bất kỳ lúc nào.`

### 3. Account card (`TÀI KHOẢN`)

- Displays current account status:
  - Icon badge (`45×45`, radius `15`, fill `rgba(139, 58, 157, 0.31)`, border `rgba(237, 160, 255, 0.45)`, icon `#F4B8FF`, `person` when signed in or `person.badge.plus` when guest)
  - Title: `user.email` when signed in, otherwise `Tài khoản khách`
  - Hint:
    - Signed in (`user != nil`): `Hồ sơ trên thiết bị có thể đồng bộ`
    - Guest + Supabase configured (`isConfigured == true`): `Đăng nhập để lưu hành trình trên mọi thiết bị`
    - Guest + unconfigured (`isConfigured == false`): `Dữ liệu hiện được lưu trên thiết bị này`
- Actions below divider:
  - When signed in (`user != nil`):
    1. `Đồng bộ hồ sơ`: sets `busy = true`, runs `syncLocalProfiles()`, triggers success notification haptic (`HapticClient.success`), and shows alert `Đã đồng bộ` (`Hồ sơ trên thiết bị đã được liên kết với tài khoản của bạn.`).
    2. `Đăng xuất` (danger style `#FDA4AF`): triggers light impact haptic (`HapticClient.lightImpact`), sets `busy = true`, runs `signOut()`, clears session & billing state; on error shows alert `Không thể đăng xuất` with error message or fallback `Vui lòng thử lại.`.
  - When guest (`user == nil`):
    - Inline button (`minHeight = 49`, radius `16`, border `rgba(255, 211, 110, 0.52)`, fill `rgba(73, 38, 119, 0.68)`) with label:
      - `isConfigured ? "Đăng nhập hoặc tạo tài khoản" : "Xem hướng dẫn cấu hình"`
      - Trailing chevron `#FFD36E`
      - Tapping emits `.delegate(.didRequestLogin)` (`onRequestLogin`).
- Shows a gold `ActivityIndicator` (`#F5BA5B`, `marginTop = 13`) while `busy == true`.

### 4. Numelyra Pro & billing card (`NUMELYRA PRO`)

- Refreshes billing status (`GET /api/billing/subscription` with `Bearer <accessToken>` and `no-store` cache policy) when:
  - Screen appears / gains focus (if signed in; if guest, resets `billing = nil` and `billingError = ""`)
  - App returns to foreground (`active` scene phase / `UIApplication.willEnterForegroundNotification`)
  - User finishes browser checkout or taps `Cập nhật trạng thái Pro`.
- Header row:
  - Crown badge (`48×48`, circle, border `#C88CF1`, fill `#282057`, symbol `♛` `#FFD36E`)
  - Eyebrow: `GÓI THÀNH VIÊN` (`#FFD16D`, 15pt black, kerning `0.8`)
  - Title: `isPro ? "Bạn đang dùng Pro ✦" : "Mở khóa hành trình đầy đủ"` (`#FCF5FF`, 21pt black)
  - Plan badge: `isPro ? "PRO" : "FREE"` (gold `#F5BA5B` fill with `#110F20` text when Pro; `#27204A` fill with `#C7B9E4` text when Free)
- Body when `isPro == true` (`billing?.plan == .pro`):
  - Summary text: `${provider == .payos ? "Pro qua VietQR / PayOS" : "Pro qua PayPal"}${activeUntil ? " · hiệu lực đến \(activeUntil)" : ""}` where `activeUntil` formats `subscription.current_period_end` in `vi-VN` date format.
- Body when `isPro == false`:
  - Helper text: `Tăng lượt luận giải AI, tạo nhiều hình nền hơn và mở khóa các trải bài chuyên sâu.`
  - Section label: `CHỌN PHƯƠNG THỨC THANH TOÁN`
  - Two radio cards (`paymentMethod`, default `.payos`, selection triggers `HapticClient.selection`):
    1. `VietQR / PayOS` — `79.000đ · 30 ngày`, icon `▣`
    2. `PayPal` — `$3.99 · mỗi tháng`, icon `P`
  - Gold gradient CTA button (`['#FFE8AA', '#F5BD55', '#D98B2E']`, height `56`, radius `20`):
    - Label:
      - Guest (`user == nil`): `ĐĂNG NHẬP ĐỂ NÂNG CẤP`
      - Signed in + `.payos`: `THANH TOÁN VIETQR`
      - Signed in + `.paypal`: `ĐĂNG KÝ QUA PAYPAL`
    - Tapping triggers medium impact haptic (`HapticClient.mediumImpact`):
      - If guest (`user == nil`), emits `.delegate(.didRequestLogin)` immediately.
      - If signed in, sets `busy = true`, clears `billingError`, calls `beginCheckout(paymentMethod)` (`POST /api/billing/payos/checkout` or `POST /api/billing/paypal/checkout` with `{ "locale": "vi" }`), opens checkout URL in browser (`SFSafariViewController`), and refreshes billing status upon return.
      - If checkout throws an error matching `/sign in|đăng nhập|not_authenticated/i`, emits `.delegate(.didRequestLogin)`; otherwise sets `billingError`.
- Footer notices & refresh:
  - When `billing?.checkoutPending == true`: shows warning `Bạn có một yêu cầu PayPal chưa hoàn tất. Hãy xác nhận hoặc quay lại website để hủy yêu cầu đó trước khi thử lại.` (`#FCD34D`)
  - When `billingError` is non-empty: shows alert text (`#FDA4AF`)
  - When signed in (`user != nil`): shows `Cập nhật trạng thái Pro` button with refresh icon (`#C6BDD9`, underlined), triggering `HapticClient.selection` and `refreshBilling()`.

## Native iOS mapping

| Responsibility | Swift target |
| --- | --- |
| Pure formatting, date localization, auth-error matching, reminder normalization | `Shared/Engines/SettingsEngine.swift` |
| Billing & reminder domain models (`BillingStatus`, `BillingProvider`, `DailyReminderSettings`) | `Shared/Models/Billing.swift` |
| Checkout & notification DTOs (`CheckoutRequest`, `CheckoutResponse`, `NotificationPayload`) | `Shared/Models/BoundaryModels.swift` |
| Billing API & `SFSafariViewController` checkout runner | `Core/Clients/BillingClient.swift` |
| `UserDefaults` reminder persistence & `UNUserNotificationCenter` scheduler | `Core/Clients/DailyNotificationClient.swift` |
| TCA State, Action, Reducer, Alert & Delegate contract | `Features/Settings/SettingsFeature.swift` |
| SwiftUI Settings screen | `Features/Settings/SettingsView.swift` |
| Reducer & engine unit tests | `numelyra_app_iosTests/SettingsFeatureTests.swift` |
