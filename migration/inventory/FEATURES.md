# Feature inventory của `numelyra_app`

Audit tĩnh ngày 2026-10-06 trên ref `b89d94fdbee6118edca8c09d9232115da081afb9`, kèm working tree đang thiếu 42 asset đã được Git theo dõi. Mã thực tế được ưu tiên hơn `README.md` và roadmap.

## 1. App shell, lifecycle và navigation

- `App.tsx` bọc ứng dụng trong `SafeAreaProvider` và `AuthProvider`, sau đó chờ auth/profile hydrate.
- Luồng vào app: loading → login hoặc guest → onboarding nếu chưa có profile → main app nếu profile hợp lệ.
- Main app có 5 bottom tab đang hoạt động: Chat, Calendar, Astrology, Wallpaper Studio và Settings. `README.md` vẫn mô tả 4 tab nên đã lỗi thời.
- Root stack có thêm Game Hub và Chat Reading Detail ngoài tab bar.
- URL scheme là `numelyra://`; deep link `games/:entry?` có thể mở Game Hub/Daily Challenge.
- Notification response cũng được chuyển thành deep link. Màn loading có mascot và thông báo trạng thái.

## 2. Auth, guest và hồ sơ người dùng

- Supabase auth hỗ trợ email/password, đăng ký có email confirmation, Google OAuth, sign-out và session auto-refresh.
- Guest mode hoạt động khi người dùng bỏ qua login; nếu Supabase chưa cấu hình thì dữ liệu vẫn dùng local.
- Profile chính gồm họ tên, ngày sinh ISO và giới tính; model còn có `birthTime`/`birthPlace` nhưng UI hiện chưa thu thập hai trường này.
- Hỗ trợ nhiều profile local, chọn active profile, thêm/xóa profile và tự migrate legacy profile.
- Profile Picker có chế độ cá nhân 1 người và ghép đôi đúng 2 người; Wallpaper chỉ cho chọn 1 người.
- Khi đăng nhập, app đồng bộ hai chiều giữa local và Supabase, merge theo `normalized name + birthDate`, dùng bảng `profiles` và `user_numerology_profiles`.
- Gender không được lưu trong schema cloud hiện dùng; profile tải từ cloud mặc định là `female`, sau đó mới có thể được merge từ local.

## 3. Thần số học 24 chỉ số

- Tính toán offline theo Pythagoras từ họ tên và ngày sinh, có xử lý tên tiếng Việt và master number.
- 24 chỉ số được chia thành 6 nhóm:
  - Cốt lõi: Đường Đời, Sứ Mệnh, Linh Hồn, Nhân Cách, Ngày Sinh.
  - Tiềm năng: Trưởng Thành, Cân Bằng, Tư Duy Lý Trí, Sức Mạnh Tiềm Thức, Đam Mê Ẩn Giấu, Thái Độ.
  - Nghiệp/bài học: Nợ Nghiệp, Số Thiếu.
  - Cầu nối: Đường Đời–Sứ Mệnh, Linh Hồn–Nhân Cách, Trưởng Thành–Đam Mê.
  - Chu kỳ: Năm/Tháng/Ngày Cá Nhân, 4 Đỉnh Cao, 4 Thách Thức.
  - Biểu đồ: 8 Mũi Tên, Biểu Đồ Tên và Biểu Đồ Ngày Sinh.
- `NumerologyCardsModal` hiển thị lưới 24 card, lọc theo nhóm và mở modal luận giải chi tiết.
- Luận giải ưu tiên bảng Supabase `numerology_knowledge`; nếu offline, dùng archetype local và dữ liệu năm cá nhân.
- Tính con giáp, thiên can và ngũ hành năm sinh được dùng trong profile/calendar.

## 4. Chat và “Tiểu Linh Miêu”

- Chat yêu cầu ít nhất một profile, lưu lịch sử riêng cho user ID hoặc `guest`, giới hạn 100 message và khôi phục trạng thái bài Tarot đã lật.
- Backend `/api/chat/classify` phân loại intent; khi lỗi mạng, `agentDecisionEngine` phân loại local.
- Các intent tồn tại: câu rác, ghép đôi tình duyên, màu hợp mệnh, hai lựa chọn, tìm địa điểm, tính cách/bản mệnh, vận trình thời gian, lời khuyên hằng ngày và general.
- Backend `/api/chat/agent` nhận câu hỏi, timezone, profile, chỉ số, Tarot, Bát Tự, màu và location context. Nếu lỗi, app tự tổng hợp câu trả lời local.
- Ghép đôi 2 profile dùng Tử Vi/Bát Tự thuần, gồm Tứ Trụ, Nhật Chủ, Cung Phu Thê, Thiên Can, Bát Trạch, Nạp Âm và con giáp; luồng này không rút Tarot.
- Tarot có bộ 78 lá Rider–Waite, upright/reversed và 4 spread: 1 lá, 3 lá, 5 lá A/B, 5 lá mối quan hệ. UI có lật 3D, lật tất cả, zoom lá, keyword, reveal gate và reading trace.
- Màu hợp mệnh kết hợp năm âm với nguyên tố của một lá Tarot để chọn 2 màu trong palette 5 màu.
- Tìm địa điểm hỏi khoảng cách, ngân sách, người đi cùng và trạng thái mở cửa; chỉ xin vị trí foreground một lần rồi gửi tọa độ lên backend.
- `PlaceSuggestionsCard` đã có UI mở Google Maps nhưng hiện chỉ được import, chưa được render; kết quả địa điểm có thể chỉ xuất hiện dưới dạng text backend.
- Chat có TTS tiếng Việt qua `expo-speech`, dừng khi rời tab. STT hiện chỉ dựa vào Web Speech API nên không hoạt động native iOS.
- UI có animated flame mascot, category color, typewriter preview, màn chi tiết câu trả lời, nút mở Game Hub và shortcut mở 24 card.
- Billing status được tải khi focus Chat nhưng `isPro`/VIP asset chưa được render hoặc dùng để khóa tính năng trong client.

## 5. Calendar và văn hóa dân gian

- Chọn ngày bằng previous/next/today hoặc month picker 42 ô; hiển thị tuần hiện tại.
- Thuật toán âm lịch offline chuyển dương–âm, can chi ngày/tháng/năm, tiết khí, ngày hoàng/hắc đạo, nguyệt kỵ/tam nương và cảnh báo ngày.
- Tính 12 giờ hoàng/hắc đạo, giờ kỵ con giáp, giờ xuất hành tốt nhất, hướng tốt, việc nên làm và kiêng cữ.
- Dữ liệu ca dao/tục ngữ lấy từ SQLite bundle `cadao.db`, chọn ổn định theo ngày và có fallback local.
- Calendar art đổi theo mùa/ngày, ưu tiên URL `assets.numelyra.online` hoặc biến môi trường và có ảnh local fallback.
- Bottom sheet chi tiết đang được nối cho Hoàng lịch và Điển tích/Ca dao. Nhánh `lunar_destiny` đã có UI nhưng chưa có entry point từ Calendar.
- Hai nút header Menu/Lịch sử hiện là control trang trí, chưa gắn hành động.

## 6. Astrology hằng ngày

- Tính Natal/Transit chart offline bằng `astronomy-engine`; khi thiếu giờ sinh dùng Noon chart với confidence thấp hơn.
- Tính vị trí hành tinh, cung hoàng đạo, cân bằng nguyên tố/tính chất và các aspect lớn: conjunction, sextile, square, trine, opposition.
- Sinh vector chiêm tinh 32 chiều, score tension/harmony/conjunction/fast-planet và dominant signal.
- Chọn biểu tượng chòm sao ổn định theo local date + profile; parse SVG có giới hạn an toàn, sample path, fit geometry và sinh ambient stars deterministic.
- Màn hình dùng video aurora 15 MB, tự pause theo focus/AppState và fallback về ảnh khi Reduce Motion bật hoặc video lỗi.
- `/api/astro/fortune` tạo “lá thăm” gồm thơ, gương soi và kế sách, neo theo ca dao local và metadata chiêm tinh.
- Cache theo profile + ngày bằng key v3, tham chiếu tối đa 7 lời khuyên ngày trước để giảm lặp; tự đổi ngày lúc nửa đêm.
- Có retry, share sheet và insight sheet giải thích score, hành tinh/aspect và ca dao nguồn.

## 7. Wallpaper Studio

- Luồng 3 trạng thái: nhập mong muốn → animation generating tối thiểu 2,5 giây → carousel kết quả.
- Cá nhân hóa bằng profile và các số Đường Đời, Sứ Mệnh, Năm Cá Nhân, Ngày Cá Nhân.
- Random một trong 6 style và 6 intention rồi gọi `/api/lucky-wallpaper/generate` để xin 4 ảnh.
- Response chứa image URL, affirmation, explanation, lucky colors, style và intention; app giữ tối đa 20 ảnh AI trong state hiện tại.
- Có 5 preset ban đầu, variation thumbnails, full-screen preview, menu mở 24 card/chọn profile/tạo mới và lưu ảnh vào Photos.
- Lịch sử wallpaper không persist qua lần khởi động lại app; sau khi tạo thành công chỉ ảnh AI được giữ trong history mới.
- Khi backend lỗi, app quay về input và báo lỗi, không giả vờ dùng ảnh mock làm kết quả AI.

## 8. Settings, notification và Pro billing

- Daily reminder cho Game Hub dùng local notification và deep link `numelyra://games/daily`; lựa chọn giờ hiện có 18:00, 20:00, 21:00.
- Account card hiển thị guest/user, cho login, sync profile và sign-out.
- Pro card tải subscription, trạng thái pending và thời hạn; checkout qua PayOS/VietQR hoặc PayPal bằng browser ngoài.
- Khi quay lại foreground, app refresh entitlement.
- UI mô tả Pro mở khóa quota/trải bài, nhưng source client chưa có logic quota hoặc feature gate tương ứng; enforcement có thể nằm ở backend.

## 9. Game Hub và daily challenge

- Hub có danh sách game, “chơi tiếp” theo `playedAt`, số lần hoàn thành, daily challenge và streak.
- Daily xoay ổn định theo ngày qua 5 game: Zip, Mind Rules, Sudoku, 2048 và Arrow Escape. Ô Ăn Quan/DotBox không nằm trong vòng daily.
- Progress Hub lưu local bằng `numelyra:game-hub:v1`; notification mở thẳng daily challenge.

### 9.1 Arrow Escape

- 40 level từ Easy đến Expert, 3 mạng, tap mũi tên khi đường thoát không bị chặn, hint tự loại một mũi tên, undo/retry và level select có unlock persistence.
- Có tutorial, victory/fail, coin copy và âm thanh/haptic/settings.
- Multiplayer realtime cho create/join room, ready/countdown, cùng level, progress đối thủ, kết quả/rematch/forfeit; dùng backend tùy chỉnh và Pusher.
- Có mode phụ “Bắn Gà Nạp Đạn” landscape: space shooter theo wave/boss, health/shield/ammo/power-up và puzzle Arrow Escape dùng để nạp đạn.

### 9.2 Mind Rules

- Entry thực tế trong Game Hub là wrapper đơn giản `MindRulesGame.tsx`: 48 puzzle tìm quy luật số, nhập đáp án, hint/explanation, đếm lần sai, nhớ level hiện tại và daily deterministic.
- Một ứng dụng Expo Router/Jotai đầy đủ hơn (level select, star rating, theme/settings/result) vẫn nằm trong source nhưng không reachable từ `App.tsx`.

### 9.3 Ô Ăn Quan

- Bàn 10 ô dân + 2 ô quan, rải quân theo hai chiều, ăn chuỗi, tự gieo lại khi hết dân, sweep cuối ván và tính quan = 10 điểm.
- Đấu với AI easy/medium/hard bằng greedy/minimax, có animation trace, âm thanh, undo, luật chơi, chọn độ khó và modal kết quả.
- Mặc định yêu cầu landscape và có prompt xoay màn hình; Game Hub mở cùng component với tab Ô Ăn Quan.

### 9.4 DotBox / Nối Ô

- Nối cạnh để chiếm hộp, chiếm hộp được thêm lượt; có PvE hoặc pass-and-play PvP.
- AI easy/medium/hard, board 3×3 đến 6×6, undo, luật, âm thanh, điểm và modal kết quả.
- Game Hub mở tab DotBox trong component Ô Ăn Quan. Một copy `src/games/dots-boxes/` riêng tồn tại nhưng không được dùng.

### 9.5 Sudoku

- Generator bảo đảm unique solution, 4 độ khó easy/medium/hard/expert và daily board seeded theo ngày.
- Có chọn ô/số, pencil notes, conflict/error count, tự xóa note liên quan, undo/history, erase, pause/timer, new game và light/dark theme.
- Hoàn thành board sẽ hoàn tất daily challenge.

### 9.6 2048

- Board 4×4, swipe gesture và keyboard trên web, merge tile, game-over/restart, custom font và sound theo hướng/maximum tile.
- Lưu best tile bằng `game-2048:best-tile:v1`; Daily hoàn thành khi đạt tile 128.
- Engine dùng board module-scoped và reset khi vào screen để ván practice cũ không tự hoàn tất Daily.

### 9.7 Zip

- 24 puzzle seeded cố định và một daily puzzle seeded theo ngày, filter easy/medium/hard.
- Mục tiêu là vẽ một path liên tục đi qua mọi ô, checkpoint theo đúng thứ tự và không xuyên wall.
- Hỗ trợ drag/tap, backtrack, undo, reset, hint, timer/move/backtrack stats, tutorial, confetti/win modal.
- Lưu best time/moves/backtracks, completed puzzle, tutorial state và daily streak bằng `zip:progress:v1`.

## 10. Capability và dữ liệu cần giữ khi chuyển sang Swift

- Native capability: OAuth/browser callback, notifications, deep link, location, Photos, TTS/STT, share sheet, haptic, audio/video, SQLite, screen orientation và canvas/Skia-class rendering.
- Backend endpoints: chat agent/classify, astrology fortune, lucky wallpaper, billing subscription/PayOS/PayPal. `BAZI_LOVE` được khai báo nhưng flow chat hiện tự tính local và không gọi endpoint này.
- Supabase tables: `profiles`, `user_numerology_profiles`, `numerology_knowledge`.
- Storage contract chính: legacy profile, profile list/active ID, chat history theo owner, daily reminder, astro cache v3, Game Hub, từng game và Supabase auth session.

## 11. Code hiện không phải feature active

- `AnswerFlamePopup`, `ReadingTraceModal` và `readingTraceLayout` không reachable; app dùng `MysticReadingTraceModal` và màn detail mới.
- Full Mind Rules router app, standalone DotBox tree, một OAnQuan tree cũ và Zip router-source không được nối vào entry hiện tại.
- Các file `.web.tsx` là variant web, không phải implementation cần port sang iOS.
- Roadmap Theme System mô tả ý định nhưng chưa có theme engine chung trong app đang chạy.
