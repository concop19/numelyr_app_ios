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

## Auth & Onboarding đã chuyển

| Swift asset | Nguồn React Native | Mục đích |
| --- | --- | --- |
| `AuthMascot` | `assets/giao_dien/Whimsical Flame Mascot Reading a Grimoire.png` | Linh thú ngọn lửa đọc sách cổ thần số học (822 KB) |
| `AuthLoginPortal` | `assets/giao_dien/Magical NUMELYRA Login Portal.png` | Minh họa cổng ma thuật NUMELYRA login portal (1.4 MB) |

Đích chung: `numelyra_app_ios/numelyra_app_ios/numelyra_app_ios/Assets.xcassets/Auth/`.

## Chưa chuyển ở foundation

- Wallpaper presets API: nhập theo từng feature và kiểm tra kích thước bundle.
- Game avatar, font, audio và asset nội bộ game: nhập theo từng game; không dùng bản duplicate/legacy.
- App icon/launch assets: source config React Native đang trỏ tới các file bị xóa, nên chưa có baseline đáng tin cậy.

## Calendar đã chuyển

| Swift asset | Nguồn React Native | Mục đích |
| --- | --- | --- |
| `CalendarHero` | `assets/giao_dien/giaodien1/calender_asset/background/ChatGPT Image Sep 25, 2026, 11_00_36 PM (1).png` | Ảnh nền đỉnh tờ lịch Blốc |
| `CalendarTopic` | `assets/giao_dien/giaodien1/calender_asset/background/ChatGPT Image Sep 25, 2026, 11_00_38 PM (3).png` | Khung/ảnh chủ đề ngày tờ lịch Blốc |
| `CalendarHeroAlt` | `assets/giao_dien/giaodien1/calender_asset/background/ChatGPT Image Sep 25, 2026, 11_00_36 PM (2).png` | Biến thể ảnh nền lịch dự phòng |
| `CalendarSpringFallback` | `image/spring/Artisan_blending_tea_with_flame_20260919105940.jpeg` | Tranh Mùa Xuân fallback offline |
| `CalendarSummerFallback` | `image/summer/Artisan_molding_rice_dough_figures_20260919105925.jpeg` | Tranh Mùa Hạ fallback offline |
| `CalendarAutumnFallback` | `image/autom/Artisan_assembling_rotating_shad…_20260919105944.jpeg` | Tranh Mùa Thu fallback offline |
| `CalendarWinterFallback` | `image/winter/Artisan_shaping_clay_vase_20260919110225.jpeg` | Tranh Mùa Đông fallback offline |
| `CalendarMascotIdle` | `assets/giao_dien/giaodien1/calender_asset/mascot/idle_3x4.png` | Mascot ngọn lửa trạng thái nhàn rỗi |
| `CalendarMascot1` | `assets/giao_dien/giaodien1/calender_asset/mascot/ChatGPT Image Sep 25, 2026, 10_55_41 PM.png` | Mascot minh họa chủ đề 1 |
| `CalendarMascot2` | `assets/giao_dien/giaodien1/calender_asset/mascot/ChatGPT Image Sep 25, 2026, 11_00_16 PM.png` | Mascot minh họa chủ đề 2 |
| `cadao.db` (Resource Bundle) | `assets/cadao.db` | CSDL SQLite ca dao/tục ngữ blốc lịch (9.3 MB) |

Đích hình ảnh: `numelyra_app_ios/numelyra_app_ios/numelyra_app_ios/Assets.xcassets/Calendar/`.
Đích database: `numelyra_app_ios/numelyra_app_ios/numelyra_app_ios/Resources/cadao.db`.

## Wallpaper Studio đã chuyển

| Swift asset | Nguồn React Native | Mục đích |
| --- | --- | --- |
| `WallpaperLandscapeBackground` | `assets/giao_dien/giaodien1/wallpaper_asset/background/background.png` | Minh họa phong cảnh nền tím lớn |
| `WallpaperMoon` | `assets/giao_dien/giaodien1/wallpaper_asset/decorate/moon.png` | Trăng khuyết vàng góc trên phải |
| `WallpaperStar` | `assets/giao_dien/giaodien1/wallpaper_asset/decorate/star.png` | Sao lấp lánh trang trí |
| `WallpaperThreeStars` | `assets/giao_dien/giaodien1/wallpaper_asset/decorate/3stars.png` | Cụm 3 ngôi sao trang trí |
| `WallpaperCloudSprite` | `assets/giao_dien/giaodien1/wallpaper_asset/decorate/Dreamy Sunset Cloud Animation Frames.png` | Sprite sheet 6 frame mây trôi hoàng hôn |
| `WallpaperMockCard1` | `assets/giao_dien/giaodien1/wallpaper_asset/mock_wrapper/img1.png` | Thẻ bài mẫu 1 cho loading/preview |
| `WallpaperMockCard2` | `assets/giao_dien/giaodien1/wallpaper_asset/mock_wrapper/img2.png` | Thẻ bài mẫu 2 cho loading/preview |
| `WallpaperMockCard3` | `assets/giao_dien/giaodien1/wallpaper_asset/mock_wrapper/img3.png` | Thẻ bài mẫu 3 cho loading/preview |
| `WallpaperMockCard4` | `assets/giao_dien/giaodien1/wallpaper_asset/mock_wrapper/img4.png` | Thẻ bài mẫu 4 cho loading/preview |

Đích chung: `numelyra_app_ios/numelyra_app_ios/numelyra_app_ios/Assets.xcassets/Wallpaper/`.

## Astrology (Chiêm tinh & Chòm sao) đã chuyển

| Swift asset | Nguồn React Native | Mục đích |
| --- | --- | --- |
| `AstrologyGalaxyBackground` | `assets/giao_dien/giaodien1/constellation/galaxy-background-v2.png` | Ảnh nền dải ngân hà vũ trụ cho Constellation Canvas (2.3 MB) |
| `AstrologyAuroraOverlay` | `assets/giao_dien/giaodien1/constellation/aurora-overlay.png` | Lớp phủ dải ánh sáng cực quang (1.8 MB) |
| `astrology-aurora.mp4` (Resource Bundle) | `assets/giao_dien/giaodien1/constellation/Aurora_flowing_over_calm_lake_20261005153804-clean.mp4` | Video cực quang chuyển động lặp vô tận (14.66 MB) |

Đích hình ảnh: `numelyra_app_ios/numelyra_app_ios/numelyra_app_ios/Assets.xcassets/Astrology/`.
Đích video: `numelyra_app_ios/numelyra_app_ios/numelyra_app_ios/Resources/astrology-aurora.mp4`.

## 24 Thẻ bài Thần số học (Numerology Cards) đã chuyển

| Swift asset | Nguồn React Native | Kích thước | Tên tiếng Việt | Nhóm |
| --- | --- | --- | --- | --- |
| `NumerologyCard01WalksOfLife` | `assets/cards/card_01_walksOfLife.jpg` | 170 KB | Số Đường Đời | Cốt Lõi |
| `NumerologyCard02Mission` | `assets/cards/card_02_mission.jpg` | 216 KB | Số Sứ Mệnh | Cốt Lõi |
| `NumerologyCard03Soul` | `assets/cards/card_03_soul.jpg` | 188 KB | Số Linh Hồn | Cốt Lõi |
| `NumerologyCard04Personality` | `assets/cards/card_04_personality.jpg` | 158 KB | Số Nhân Cách | Cốt Lõi |
| `NumerologyCard05DateOfBirth` | `assets/cards/card_05_dateOfBirth.jpg` | 205 KB | Số Ngày Sinh | Cốt Lõi |
| `NumerologyCard06Mature` | `assets/cards/card_06_mature.jpg` | 240 KB | Số Trưởng Thành | Tiềm Năng |
| `NumerologyCard07Balance` | `assets/cards/card_07_balance.jpg` | 143 KB | Số Cân Bằng | Tiềm Năng |
| `NumerologyCard08RationalThinking` | `assets/cards/card_08_rationalThinking.jpg` | 194 KB | Tư Duy Lý Trí | Tiềm Năng |
| `NumerologyCard09SubconsciousPower` | `assets/cards/card_09_subconsciousPower.jpg` | 157 KB | Sức Mạnh Tiềm Thức | Tiềm Năng |
| `NumerologyCard10Passion` | `assets/cards/card_10_passion.jpg` | 149 KB | Đam Mê Ẩn Giấu | Tiềm Năng |
| `NumerologyCard11Attitude` | `assets/cards/card_11_attitude.jpg` | 162 KB | Thái Độ Tiếp Cận | Tiềm Năng |
| `NumerologyCard12KarmicDebts` | `assets/cards/card_12_karmicDebts.jpg` | 125 KB | Con Số Nợ Nghiệp | Nợ Nghiệp |
| `NumerologyCard13MissingNumbers` | `assets/cards/card_13_missingNumbers.jpg` | 116 KB | Bài Học Số Thiếu | Nợ Nghiệp |
| `NumerologyCard14BridgeLifeMission` | `assets/cards/card_14_bridgeLifeMission.jpg` | 171 KB | Cầu Nối Đ.Đời - Sứ Mệnh | Cầu Nối |
| `NumerologyCard15BridgeSoulPersonality` | `assets/cards/card_15_bridgeSoulPersonality.jpg` | 222 KB | Cầu Nối L.Hồn - N.Cách | Cầu Nối |
| `NumerologyCard16BridgeMaturityPassion` | `assets/cards/card_16_bridgeMaturityPassion.jpg` | 146 KB | Cầu Nối T.Thành - Đ.Mê | Cầu Nối |
| `NumerologyCard17YearIndividual` | `assets/cards/card_17_yearIndividual.jpg` | 216 KB | Năm Cá Nhân | Chu Kỳ |
| `NumerologyCard18MonthIndividual` | `assets/cards/card_18_monthIndividual.jpg` | 146 KB | Tháng Cá Nhân | Chu Kỳ |
| `NumerologyCard19DayIndividual` | `assets/cards/card_19_dayIndividual.jpg` | 133 KB | Ngày Cá Nhân | Chu Kỳ |
| `NumerologyCard20Way` | `assets/cards/card_20_way.jpg` | 155 KB | 4 Đỉnh Cao Cuộc Đời | Chu Kỳ |
| `NumerologyCard21Challenges` | `assets/cards/card_21_challenges.jpg` | 161 KB | 4 Thách Thức Cuộc Đời | Chu Kỳ |
| `NumerologyCard22Arrows` | `assets/cards/card_22_arrows.jpg` | 199 KB | 8 Mũi Tên Cá Tính 3x3 | Biểu Đồ |
| `NumerologyCard23NameChart` | `assets/cards/card_23_nameChart.jpg` | 170 KB | Biểu Đồ Tên & Tần Suất | Biểu Đồ |
| `NumerologyCard24BirthChart` | `assets/cards/card_24_birthChart.jpg` | 219 KB | Biểu Đồ Ngày Sinh 3x3 | Biểu Đồ |

Đích chung: `numelyra_app_ios/numelyra_app_ios/numelyra_app_ios/Assets.xcassets/NumerologyCards/`.

## Bộ bài Tarot (78 Lá Rider-Waite + Lưng bài) đã chuyển

| Swift asset | Nguồn React Native | Mục đích / Tên lá bài |
| --- | --- | --- |
| `TarotCardBack` | `assets/tarot/card-back.png` | Mặt sau thẻ bài Tarot Rider-Waite (2.8 MB) |
| `Tarot00Fool` .. `Tarot21World` (22 lá) | `assets/tarot/cards/00-fool.jpg` .. `21-world.jpg` | Bộ Ẩn Chính (Major Arcana, ~5.6 MB) |
| `TarotWands01` .. `TarotWands14` (14 lá) | `assets/tarot/cards/minor/wands/01.jpg` .. `14.jpg` | Bộ Gậy (Wands Suit, ~3.4 MB) |
| `TarotCups01` .. `TarotCups14` (14 lá) | `assets/tarot/cards/minor/cups/01.jpg` .. `14.jpg` | Bộ Cốc (Cups Suit, ~3.3 MB) |
| `TarotSwords01` .. `TarotSwords14` (14 lá) | `assets/tarot/cards/minor/swords/01.jpg` .. `14.jpg` | Bộ Kiếm (Swords Suit, ~3.2 MB) |
| `TarotPentacles01` .. `TarotPentacles14` (14 lá) | `assets/tarot/cards/minor/pentacles/01.jpg` .. `14.jpg` | Bộ Tiền (Pentacles Suit, ~3.4 MB) |

Đích chung: `numelyra_app_ios/numelyra_app_ios/numelyra_app_ios/Assets.xcassets/Tarot/`.

## Chat Detail / Nghi Thức Rút Bài Tarot (`MysticReadingTraceModal`) đã chuyển

| Swift asset | Nguồn React Native | Mục đích |
| --- | --- | --- |
| `ChatDetailBackground` | `assets/giao_dien/giaodien1/chat_detail/background/background.png` | Ảnh nền phòng cổ điển bàn nghi thức rút bài (`941×1672`, 2.1 MB) |
| `ChatDetailMat` | `assets/giao_dien/giaodien1/chat_detail/item/tham.png` | Thảm trải bài Tarot ở giữa bàn (971 KB) |
| `ChatDetailChest` | `assets/giao_dien/giaodien1/chat_detail/item/hop.png` | Rương gỗ góc trên trái (327 KB) |
| `ChatDetailCandle` | `assets/giao_dien/giaodien1/chat_detail/item/nen.png` | Cây nến góc trên giữa (74 KB) |
| `ChatDetailCandleFlameSprite` | `assets/giao_dien/giaodien1/chat_detail/item/nenchay.png` | Sprite sheet ngọn lửa nến 6 frame ngang (`1448×340`, 496 KB) |
| `ChatDetailBook` | `assets/giao_dien/giaodien1/chat_detail/item/sach.png` | Sách cổ góc dưới trái thảm (178 KB) |
| `ChatDetailPaper` | `assets/giao_dien/giaodien1/chat_detail/item/giay.png` | Cuộn giấy da hiển thị lời luận giải ở đáy màn hình (775 KB) |
| `ChatDetailQuill` | `assets/giao_dien/giaodien1/chat_detail/item/but.png` | Bút lông viết mực phép khi hoàn tất rút bài (73 KB) |
| `ChatDetailTopFlameLeft01` .. `06` (6 ảnh) | `assets/giao_dien/giaodien1/chat_detail/item/lay_left/Sprite-0001.png` .. `Sprite-0006.png` | Chuỗi 6 frame linh vật lửa đứng mép trên bên trái thảm (`FlameCharacterSprite`) |
| `ChatDetailTopFlameRight01` .. `06` (6 ảnh) | `assets/giao_dien/giaodien1/chat_detail/item/lay_right/Sprite-0007.png` .. `Sprite-0012.png` | Chuỗi 6 frame linh vật lửa đứng mép trên bên phải thảm (`FlameCharacterSprite`) |
| `ChatDetailBottomFlameLeft01` .. `06` (6 ảnh) | `assets/giao_dien/giaodien1/chat_detail/item/lac_left/1.png` .. `6.png` | Chuỗi 6 frame linh vật lửa lắc lư mép dưới bên trái thảm (`BottomFlameSprite`) |
| `ChatDetailBottomFlameRight01` .. `06` (6 ảnh) | `assets/giao_dien/giaodien1/chat_detail/item/lac_right/1.png` .. `6.png` | Chuỗi 6 frame linh vật lửa lắc lư mép dưới bên phải thảm (`BottomFlameSprite`) |

Đích chung: `numelyra_app_ios/numelyra_app_ios/numelyra_app_ios/Assets.xcassets/ChatDetail/`.

