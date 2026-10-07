# Auth screen — React Native parity specification

## React Native source audited

- `numelyra_app/src/screens/LoginScreen.tsx`
- `numelyra_app/src/store/authContext.tsx`
- `numelyra_app/src/services/supabaseClient.ts`
- `numelyra_app/src/config/env.ts`
- `numelyra_app/src/store/userProfile.ts`
- `numelyra_app/App.tsx`
- `numelyra_app/src/screens/SettingsScreen.tsx`
- `numelyra_app/ROADMAP_LOGIN_THEME_PRO.md`

## Reachable behavior

### 1. Visual layout & palette (Synchronized with `AppTheme` Mystic Deep Purple & Gold)

- Cosmic dark background (`#0E092B` base + `AppScreenBackground` `#211052 → #11082F → #0C0625` + subtle decorative sky stars `✦`/`✧`, `preferredColorScheme(.dark)`), vertically centered scroll container (`padding = 20`).
- Hero section (`height = 230`, clipped) displaying bundled `AppAsset.authMascot` (`Whimsical Flame Mascot Reading a Grimoire.png`, `245×270`, `marginTop = -26`) over a warm golden radial glow (`AppTheme.Colors.primary.opacity(0.24)`).
- Elevated mystic purple card (`AppTheme.Gradients.cardElevated` `#321060 → #291051 → #210943` + `AppTheme.Gradients.cardOverlay`, `cornerRadius = 26`, `padding = 22`, border `1pt AppTheme.Colors.cardBorder`, shadow `#1A063A` opacity `0.88`, radius `21`, `y = 10`):
  - Eyebrow: `✦ WELCOME TO` (`#FFD16D`, 12pt heavy, kerning `2`)
  - Brand: `NUMELYRA` (`AppTheme.Colors.textPrimary` `#FFF7E8`, 34pt black, kerning `0.4`, golden glow shadow)
  - Tagline: `Unlock your magic ♡` (`AppTheme.Colors.accentPink` `#F2A4CF`, 17pt italic)
  - Dynamic description (`AppTheme.Colors.textSecondary` `#D8C9E8`):
    - Sign-in (`!isSignUp`): `Đăng nhập để lưu và đồng bộ hành trình của bạn.`
    - Sign-up (`isSignUp`): `Tạo tài khoản để đồng bộ hành trình của bạn.`

### 2. Google OAuth sign-in

- Secondary mystic purple button (`AppTheme.Gradients.secondaryAction` `#432078 → #31165E → #211043`, `minHeight = 50`, `cornerRadius = 14`, border `1.5pt #FFD573.opacity(0.55)`) with red circular `G` badge (`24×24`, `#EA4335`) and label `Tiếp tục với Google` (`#FCF5FF`, 14pt bold).
- Tapping fires light impact haptics (`HapticClient.lightImpact`), clears `errorMessage` and `message`, and sets `isGoogleSubmitting = true`.
- Launches OAuth (`provider = google`, `redirect_to = numelyra://auth-callback`, `access_type = offline`, `prompt = consent`) via `ASWebAuthenticationSession`.
- Parses callback URL supporting both PKCE (`?code=...`) and Implicit (`#access_token=...&refresh_token=...`) flows, stores `AuthSession` in iOS Keychain, synchronizes profiles (`profiles` + `user_numerology_profiles`), and emits `.delegate(.didAuthenticate(session))`.
- On failure, displays the error message or fallback `Đăng nhập Google thất bại. Vui lòng thử lại.` and resets `isGoogleSubmitting = false`.

### 3. Email & password sign-in / sign-up

- Divider row `HOẶC VỚI EMAIL` (`#B8A8D8`) between `AppTheme.Colors.divider` (`#B685E7.opacity(0.23)`) rules.
- Inputs (`minHeight = 50`, `AppTheme.Colors.inputBackground` `#2B1947` fill, `1pt AppTheme.Colors.inputBorder` `#8E69C4.opacity(0.52)` border, `cornerRadius = 13`, `AppTheme.Colors.textPrimary` `#FFF7E8` text, `AppTheme.Colors.inputPlaceholder` `#B6A6CE` placeholder, `AppTheme.Colors.primary` `#F5BA5B` cursor tint):
  - `Họ và tên` (shown only when `isSignUp == true`, word capitalization)
  - `Email` (email keyboard, no autocapitalization)
  - `Mật khẩu` with inline `HIỆN` / `ẨN` toggle (`AppTheme.Colors.primaryBright` `#FFD07A`, 11pt heavy) that triggers selection haptics (`HapticClient.selection`).
- Primary submit button (`AppTheme.Gradients.goldAction` `#FFE8AA → #F5BD55 → #D98B2E`, `1pt #FFF1AA.opacity(0.80)` border, `minHeight = 52`, `cornerRadius = 14`, `AppTheme.Colors.textOnPrimary` `#24133F` text & arrow) displays `ĐĂNG NHẬP` or `TẠO TÀI KHOẢN` with a trailing forward arrow.
- Tapping submit always triggers medium impact haptics (`HapticClient.mediumImpact`) and validates in exact React Native order:
  1. Trimmed email matches `/^\S+@\S+\.\S+$/` → otherwise `Hãy nhập một địa chỉ email hợp lệ.`
  2. Password length `>= 6` → otherwise `Mật khẩu cần có ít nhất 6 ký tự.`
  3. When `isSignUp == true`, trimmed full name is non-empty → otherwise `Hãy nhập tên của bạn để tạo tài khoản.`
- When `isSignUp == true` and Supabase returns `needsEmailConfirmation == true` (`user != nil && session == nil`):
  - Sets `message = "Tài khoản đã được tạo. Hãy kiểm tra email để xác nhận, rồi đăng nhập lại."`
  - Switches `isSignUp = false` without emitting `.didAuthenticate`.
- When sign-in or immediate sign-up succeeds, stores `AuthSession` in Keychain, synchronizes local/cloud profiles, and emits `.delegate(.didAuthenticate(session))`.

### 4. Mode switch, unconfigured state & guest mode

- Mode toggle (`Chưa có tài khoản? Tạo tài khoản` / `Đã có tài khoản? Đăng nhập`) triggers selection haptics (`HapticClient.selection`), toggles `isSignUp`, and clears `errorMessage` and `message`.
- When Supabase is not configured (`!isConfigured`), Google and Email submit buttons are disabled (`opacity = 0.55`) and the notice `Chưa có cấu hình Supabase cho mobile app. Bạn vẫn có thể dùng chế độ Khách.` is shown.
- Guest button (`Tiếp tục với tư cách Khách`) is rendered when `allowGuest == true` (default `true`; `false` when opened from Settings login prompt), triggers light impact haptics (`HapticClient.lightImpact`), and emits `.delegate(.didContinueAsGuest)`.

### 5. Cloud & local profile synchronization

- Upserts account metadata into `profiles` (`id`, `email`, `full_name`, `updated_at`).
- Pulls `user_numerology_profiles` ordered by `created_at` descending.
- Pushes local-only profiles matched by normalized key `<fullName.trim().lowercased()>|<birthDate>`.
- Merges remote and local profiles while preserving local `gender`, `isDefault`, `birthTime`, `birthPlace`, `birthLocation`, and `birthTimeAccuracy` (without hardcoding `.female` for cloud-only profiles that lack gender).

## Native iOS mapping

| Responsibility | Swift target |
| --- | --- |
| Pure validation, PKCE, OAuth callback parser, profile merge | `Shared/Engines/AuthEngine.swift` |
| Auth DTOs, `AuthSession`, `AuthSignUpResult`, `AuthError` | `Shared/Models/BoundaryModels.swift` |
| Keychain storage, Supabase Auth/PostgREST, `ASWebAuthenticationSession` | `Core/Clients/SupabaseClient.swift` |
| Runtime environment / Info.plist configuration lookup | `Core/Config/AppConfig.swift` |
| TCA State, Action, Reducer & Delegate contract | `Features/Auth/AuthFeature.swift` |
| SwiftUI Login / Sign-up / Guest screen | `Features/Auth/AuthView.swift` |
| Reducer & engine unit tests | `numelyra_app_iosTests/AuthFeatureTests.swift` |
