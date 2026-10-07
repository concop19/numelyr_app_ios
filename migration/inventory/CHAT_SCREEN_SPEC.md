# Chat Screen — Native iOS/TCA specification

## Phạm vi nguồn React Native

- Entry point: `numelyra_app/src/screens/ChatScreen.tsx`.
- Thành phần reachable: profile picker, classify/agent API, history, Tarot ritual (`MysticReadingTraceModal`), TTS, location preferences và reading detail.
- Không port các nhánh dormant/unwired: `AnswerFlamePopup`, `ReadingTraceModal`, `renderCardWidget`, xóa từng message và xóa toàn bộ history.
- React Native là baseline giao diện/luồng. Riêng phép tính compatibility cũ trong `tuViBaziService.ts` không còn là nguồn đúng theo xác nhận sản phẩm ngày 2026-10-07.

## Kiến trúc iOS

`Features/Chat/` là vertical slice TCA gồm:

- `ChatFeature`: owner, hydrate, history, composer, classify/agent fallback, Tarot, STT/TTS và destinations.
- `ChatProfilePickerFeature`: chọn cá nhân/ghép đôi, thêm/xóa profile, active profile.
- `ChatPlacePickerFeature`: 2/5/10 km, ngân sách, người đi cùng, đang mở và yêu cầu vị trí theo thao tác.
- `ChatReadingRitualFeature`: lật bài tuần tự, haptic, đồng bộ hai điều kiện “đã lật đủ” và “đã có response”.
- `ChatReadingDetailFeature`: câu hỏi, bài xuôi/ngược, lời giải, compatibility và structured place cards.

Side effects được đặt trong dependency:

- `ChatClient`: `/api/chat/classify`, `/api/chat/agent`, Bearer JWT, HTTP error và flexible payload.
- `ChatHistoryClient`: JSON envelope v1 theo owner trong Application Support, actor serialize write, giới hạn 100 message.
- `SpeechClient`: `AVSpeechSynthesizer` giọng `vi-VN`, loại Markdown/URL và chia đoạn dài.
- `SpeechRecognitionClient`: Speech framework + `AVAudioEngine`, locale `vi-VN`, partial/final/cancel.
- `PlaceLocationClient`: foreground permission, dùng cache ≤5 phút và accuracy ≤1 km trước khi request một lần.
- `ExternalURLClient`: mở Maps/source URL từ reducer.
- `UserProfileClient`: validate/thêm/xóa/chọn active profile; View không đọc `UserDefaults` trực tiếp.

## Contract Chat

- `ChatCardPayload` nhận `agent_synthesis`, structured place suggestions, legacy `tarot`, legacy `lunar_guidance`; payload chưa biết được giữ lossless bằng `unsupported(JSONValue)`.
- Tarot do máy rút là nguồn sự thật cho animation và history. Response agent không được thay bộ bài local.
- Structured place payload được gộp vào `AgentSynthesisPayload`; khi offline không tạo địa điểm giả.
- History guest và user tách theo owner; assistant restore luôn ở trạng thái typewriter hoàn tất.
- Compatibility Chat dùng `TuViEngine` ruleset `vietnameseDefaultV2` và `evaluateLoveCompatibility`, không dùng lại công thức RN `tuViBaziService.ts`. Payload mới là `ChatZiWeiCompatibilityPayload` gồm hai chart và analysis có contribution/disclaimer. Luồng mới yêu cầu giới tính + giờ sinh chính xác của cả hai hồ sơ và không fallback sang nữ/12:00. `TuViBaziSynastry` chỉ còn để decode dữ liệu/backend legacy.

## Luồng gửi

1. Chỉ gửi sau hydrate, draft có nội dung và không có request đang chạy. Thiếu profile mở picker trước khi append.
2. Append user message, persist, gọi server classify; lỗi dùng `ChatDecisionEngine` local.
3. Trash trả lời ngay, không tính chỉ số/rút bài/gọi agent.
4. `where_to_go` mở preference sheet rồi xin vị trí. Cancel/denied không gọi agent.
5. Tính đúng subset Numerology, lập compatibility v2 khi có hai profile, rút Tarot local và tạo color context khi cần.
6. Có Tarot thì mở full-screen ritual ngay trong lúc agent request chạy. Lời giải chỉ xuất hiện sau khi cả response và lượt lật cuối hoàn tất.
7. Agent lỗi dùng `ChatSynthesisEngine`; location offline trả thông báo, không giả lập place.
8. Persist sau các thay đổi quan trọng; request, recognition và TTS dừng khi đổi owner/rời màn.

## UI và accessibility

- Chat là tab đầu/mặc định; app shell hiển thị đúng Chat, Calendar, Astrology, Wallpaper, Settings. Auth được trình bày nội bộ từ Settings.
- Nền ba lớp, sao nhấp nháy, mascot idle/thinking/answer, header Numelyra, composer profile/mic/send.
- Mặc định chỉ hiển thị lượt gần nhất; history toggle hiển thị tối đa 100 message.
- Bubble assistant typewriter, tối đa ba dòng; chỉ mở detail khi chạy xong.
- Ritual dùng asset `ChatDetail`, card front/back, reversed rotation, haptic và TTS đúng một lần.
- Tôn trọng Dynamic Type, VoiceOver và Reduce Motion; ritual không thể dismiss khi còn chờ.
- Moon/Game Hub hiển thị disabled cho tới khi App có destination Game Hub.
- Usage descriptions: location when-in-use, microphone và speech recognition. Không bật background location/audio.

## Khác biệt có chủ đích

- Color question với hai profile bị chặn trước khi append và yêu cầu chuyển về một profile.
- iOS có STT thật và structured place card; RN hiện chưa nối hai UI này đầy đủ.
- Profile mới dùng native controls cho ngày sinh, giờ sinh và giới tính.
- Compatibility dùng engine Tử Vi v2 mới và thang điểm 0–100; không giữ phép tính Bát Tự RN cũ 60–98 vì đã được xác nhận là sai.
- Không migrate AsyncStorage history cũ; native bắt đầu store v1 riêng.

## Validation hiện tại

- `swiftc -parse` toàn bộ app/test và `swiftc -typecheck` pure Chat model/engine subset: đạt ngày 2026-10-07.
- XCTest sources: có coverage cho intent, spread count, unknown payload round-trip, nested place payload, compatibility v2 offline synthesis, thiếu profile và color/two-profile guard.
- `xcodebuild`, chạy XCTest, Simulator screenshot và RN comparison: bị chặn trên máy hiện tại vì `xcode-select` trỏ tới `/Library/Developer/CommandLineTools` và không có full Xcode/iOS Simulator SDK.
