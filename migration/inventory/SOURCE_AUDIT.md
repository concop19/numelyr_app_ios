# Báo cáo audit source React Native

## Phạm vi và phương pháp

- Ref: `b89d94fdbee6118edca8c09d9232115da081afb9`.
- Quét toàn bộ tree trừ `.git`, dependency và build cache; không đọc giá trị secret trong `.env`.
- Lập inventory file, line count, import reachability từ `App.tsx`/`index.ts`, route, storage, API, Supabase, native capability, static asset reference và test case.
- Deep-read entry, toàn bộ 9 screen, store/service/config/feature, Game Hub và entry/engine của từng game.

## Độ phủ source

| Khu vực | File TS/TSX | Dòng | Nội dung đã kiểm kê | Trạng thái |
| --- | ---: | ---: | --- | --- |
| `src/screens` | 9 | 7.622 | Tất cả screen, state, handler, navigation và API call | Đã audit |
| `src/components` | 20 | 5.403 | Modal, mascot, chat UI, card, sprite và calendar detail | Đã audit |
| `src/config` | 4 | 806 | Env schema, calendar art/images, 24 numerology cards | Đã audit |
| `src/db` | 1 | 168 | SQLite ca dao import/query/fallback | Đã audit |
| `src/features` | 10 | 1.576 | Astrology daily/cache và constellation pipeline | Đã audit |
| `src/games` | 142 | 24.032 | Hub, 7 game, engine, persistence, duplicate/dormant tree | Đã audit |
| `src/services` | 29 | 5.811 | API, billing, chat, lunar, numerology, tarot, astro, native adapter | Đã audit |
| `src/store` | 2 | 519 | Auth/session/profile sync và local state | Đã audit |
| **Tổng `src`** | **217** | **45.937** | | **Đã quét tĩnh** |

Ngoài `src`, đã audit `App.tsx`, `index.ts`, `package.json`, `app.json`, `eas.json`, TypeScript/Metro config, README và roadmap.

## Reachability

- 146/217 file source được import trực tiếp hoặc gián tiếp từ entry iOS theo static graph.
- 71 file không reachable gồm 16 test, declaration, web variant và các implementation dormant/duplicate.
- Nhóm dormant đáng chú ý: full Mind Rules Expo Router app, standalone DotBox tree, OAnQuan legacy tree, Zip router-source, chat popup/trace cũ và mini puzzle generator chưa dùng.
- Reachability là static approximation; React Native platform resolver chọn `.native.ts(x)` cho iOS dù import không có suffix.

## Asset audit

- `assets/` có khoảng 212 file: 78 ảnh Tarot, 24 numerology card, 77 asset giao diện, game audio/avatar, mascot, font, video và `cadao.db`.
- Asset lớn cần chú ý khi port: aurora video khoảng 15 MB, SQLite khoảng 9,3 MB, nhiều PNG 1–3 MB.
- Có hai bộ avatar game giống nhau trong `image/game_avt` và `assets/image/game_avt`; app đang dùng bộ dưới `assets/`.
- Hai static require bị thiếu nằm trong OAnQuan tree legacy không reachable.
- Working tree nguồn hiện có 42 asset tracked bị xóa. Trong đó `app.json` đang trỏ tới 5 file không còn trên disk: icon, favicon và ba Android adaptive icon.
- Không phục hồi hoặc sửa bất kỳ asset nào trong lần audit này.

## Test audit

- Có 16 file test, tập trung vào astrology/cache/constellation, chat history, color guidance, Game Hub, Arrow Escape, Ô Ăn Quan/DotBox, Sudoku và Zip.
- Logic lớn chưa thấy unit test trực tiếp: 24 numerology indicators, lunar calendar, Tử Vi/Bát Tự, Tarot draw, auth/profile sync, billing, notification và wallpaper generation.
- Không chạy được `npm test`/`npm run typecheck` vì host hiện không có `node` hoặc `npm` trong PATH. Đây là giới hạn môi trường, không phải kết quả pass/fail.

## Rủi ro được phát hiện

1. Source đang dirty với 42 asset deletion; ref Git không mô tả chính xác working tree đang audit.
2. STT native iOS chưa có implementation; service hiện là Web Speech API.
3. Place result UI đã viết nhưng chưa render; flow `where_to_go` chỉ chắc chắn gửi context và nhận text/card payload.
4. Client tải Pro entitlement nhưng chưa thực thi quota/feature gate và chưa dùng VIP visual.
5. `birthTime`/`birthPlace` tồn tại trong model nhưng không có UI input; astrology thường dùng Noon chart fallback.
6. Wallpaper history chỉ nằm trong memory; không persist sau restart.
7. Có nhiều code duplicate/dormant; port toàn bộ theo folder sẽ mang theo tính năng không chạy và tăng chi phí.
8. Calendar có control/header và nhánh modal chưa nối hành động.
9. Một số engine active dùng `@ts-nocheck`; cần lấy test/golden behavior làm contract thay vì dựa vào type safety hiện tại.
10. README/roadmap lệch mã thực tế, đặc biệt số tab và Theme System.

## Kết luận audit

Danh mục feature đầy đủ nằm tại [FEATURES.md](FEATURES.md). Audit tĩnh source React Native đã hoàn tất; runtime test, quan sát UI trên thiết bị và target Swift audit vẫn phải thực hiện trước khi xem Step 01 hoàn tất tuyệt đối.
