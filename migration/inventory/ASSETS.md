# Asset migration manifest

Manifest này là nguồn ánh xạ giữa asset React Native và tên dùng trong Swift. Không tham chiếu trực tiếp đường dẫn cũ từ feature Swift.

## Quy ước

- Asset dùng trong Swift phải có tên `UpperCamelCase` và được truy cập qua `AppAsset`.
- Giữ file React Native làm nguồn đối chiếu; bản sao iOS nằm trong `Assets.xcassets` để Xcode xử lý theo bundle.
- Chỉ nhập asset khi đã xác nhận nằm trong luồng reachable. Asset riêng của feature được nhập cùng vertical slice của feature đó.
- Không phục hồi hoặc sao chép 42 asset đang bị xóa trong working tree React Native nếu chưa có xác nhận.

## Foundation đã chuyển

| Swift asset | Nguồn React Native | Mục đích |
| --- | --- | --- |
| `AuthMascot` | `assets/giao_dien/Whimsical Flame Mascot Reading a Grimoire.png` | Login/onboarding mascot |
| `TabChat` | `assets/icons/tab_chat_flame.jpg` | App shell tab Chat |
| `TabCalendar` | `assets/icons/tab_calendar_flame.jpg` | App shell tab Calendar |
| `TabWallpaper` | `assets/icons/tab_wallpaper_flame.jpg` | App shell tab Wallpaper |
| `TabSettings` | `assets/icons/tab_settings_flame.jpg` | App shell tab Settings |
| `ChatSceneSky` | `assets/giao_dien/giaodien1/chat_screen_asset/backgorund/background_index1.png` | Lớp nền trời Chat |
| `ChatSceneMountains` | `assets/giao_dien/giaodien1/chat_screen_asset/backgorund/background_index2.png` | Lớp núi Chat |
| `ChatSceneForeground` | `assets/giao_dien/giaodien1/chat_screen_asset/backgorund/background_index3.png` | Lớp tiền cảnh Chat |
| `ChatSceneStars` | `assets/giao_dien/giaodien1/chat_screen_asset/items/stars.png` | Trang trí sao Chat |
| `ChatSceneMoon` | `assets/giao_dien/giaodien1/chat_screen_asset/items/moon_top_left.png` | Trang trí trăng Chat |
| `ChatFlameIdleSprite` | `assets/giao_dien/giaodien1/chat_screen_asset/character/fire_char_idle_3x4.png` | Sprite mascot idle |
| `ChatFlameThinkingSprite` | `assets/giao_dien/giaodien1/chat_screen_asset/character/fire_char_thinking_3x4.png` | Sprite mascot thinking |
| `ChatFlameAnswerSprite` | `assets/giao_dien/giaodien1/chat_screen_asset/character/fire_char_answer_3x4.png` | Sprite mascot answer |
| `ChatVIPBadge` | `assets/giao_dien/vip.png` | Trạng thái tài khoản VIP trong Chat |
| `ChatAmbientGlow` | `assets/giao_dien/ambient_glow.png` | Hiệu ứng glow trong Chat |

Đích chung: `numelyra_app_ios/numelyra_app_ios/numelyra_app_ios/Assets.xcassets/Foundation/`.

## Chưa chuyển ở foundation

- 78 lá Tarot và card back: nhập khi triển khai slice Tarot.
- 24 card thần số học: nhập khi triển khai slice Numerology.
- Calendar hero/seasonal art, constellation video, wallpaper presets: nhập theo từng feature và kiểm tra kích thước bundle.
- Game avatar, font, audio và asset nội bộ game: nhập theo từng game; không dùng bản duplicate/legacy.
- App icon/launch assets: source config React Native đang trỏ tới các file bị xóa, nên chưa có baseline đáng tin cậy.
