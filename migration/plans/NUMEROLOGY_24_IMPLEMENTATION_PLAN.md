# Kế hoạch migration 24 chỉ số Thần số học sang iOS

Ngày lập: 2026-10-07  
Phạm vi: chỉ lập kế hoạch cho `numelyra_app_ios/`; không thay đổi baseline React Native.

> Phạm vi triển khai được chốt ngày 2026-10-07: chỉ thực hiện model, pure engine và test logic. Knowledge client, TCA Feature, navigation và giao diện trong các slice N3–N6 được hoãn cho đến khi có yêu cầu riêng.

## 1. Kết luận audit

Feature đang chạy trong React Native gồm ba phần khác nhau:

1. `src/services/numerologyEngine.ts` tính đủ 24 giá trị để hiển thị trong `NumerologyCardsModal`.
2. `src/services/numerology24Service.ts` là calculator rút gọn cho Chat và Wallpaper; nó chỉ hỗ trợ 9 key.
3. `src/services/numerologyKnowledge.ts` tải luận giải từ bảng Supabase `numerology_knowledge`, sau đó fallback sang nội dung archetype local.

UI active là `NumerologyCardsModal.tsx` và `IndicatorDetailModal.tsx`. `MysticIndicatorDetailModal.tsx` và `ReadingTraceModal.tsx` không phải entry active của luồng 24 card hiện tại.

Điểm vào đang hoạt động:

- Chat mở modal 24 card cho profile đang chọn.
- Wallpaper mở cùng modal và dùng riêng Đường Đời, Sứ Mệnh, Năm Cá Nhân, Ngày Cá Nhân để cá nhân hóa request.
- Chat agent yêu cầu một tập con chỉ số qua `targetIndicators` rồi đưa kết quả vào payload và local fallback synthesis.

Phần iOS đã có sẵn:

- Model scaffold: `Shared/Models/Numerology.swift`.
- `UserProfile`: `Shared/Models/UserProfile.swift`.
- 24 ảnh card và lookup helper trong `Assets.xcassets/NumerologyCards/` và `Shared/Assets/AppAsset.swift`.
- TCA, Supabase Swift và test target đã được thiết lập.

Phần iOS còn thiếu hoàn toàn: engine, dependency client, knowledge repository, reducer/view, navigation integration và test của numerology.

## 2. Contract hành vi cần giữ

### 2.1 Danh mục 24 card

| # | Key | Nhóm | Giá trị hiện tại |
| ---: | --- | --- | --- |
| 1 | `walksOfLife` | Cốt lõi | Số Đường Đời |
| 2 | `mission` | Cốt lõi | Số Sứ Mệnh |
| 3 | `soul` | Cốt lõi | Số Linh Hồn |
| 4 | `personality` | Cốt lõi | Số Nhân Cách |
| 5 | `dateOfBirth` | Cốt lõi | Số Ngày Sinh |
| 6 | `mature` | Tiềm năng | Số Trưởng Thành |
| 7 | `balance` | Tiềm năng | Số Cân Bằng |
| 8 | `rationalThinking` | Tiềm năng | Tư Duy Lý Trí |
| 9 | `subconsciousPower` | Tiềm năng | Sức Mạnh Tiềm Thức |
| 10 | `passion` | Tiềm năng | Một hoặc nhiều số Đam Mê Ẩn Giấu |
| 11 | `attitude` | Tiềm năng | Thái Độ Tiếp Cận |
| 12 | `karmicDebts` | Nghiệp | Danh sách 13/4, 14/5, 16/7, 19/1 hoặc không có |
| 13 | `missingNumbers` | Nghiệp | Danh sách số thiếu 1...9 hoặc không thiếu |
| 14 | `bridgeLifeMission` | Cầu nối | Chênh lệch Đường Đời–Sứ Mệnh |
| 15 | `bridgeSoulPersonality` | Cầu nối | Chênh lệch Linh Hồn–Nhân Cách |
| 16 | `bridgeMaturityPassion` | Cầu nối | Chênh lệch Trưởng Thành–Đam Mê |
| 17 | `yearIndividual` | Chu kỳ | Năm Cá Nhân tại ngày tham chiếu |
| 18 | `monthIndividual` | Chu kỳ | Tháng Cá Nhân tại ngày tham chiếu |
| 19 | `dayIndividual` | Chu kỳ | Ngày Cá Nhân tại ngày tham chiếu |
| 20 | `way` | Chu kỳ | Bốn Đỉnh Cao |
| 21 | `challenges` | Chu kỳ | Bốn Thách Thức |
| 22 | `arrows` | Biểu đồ | Các mũi tên mạnh/trống trong ma trận 3×3 |
| 23 | `nameChart` | Biểu đồ | Thống kê tần suất tên |
| 24 | `birthChart` | Biểu đồ | Thống kê chữ số ngày sinh |

### 2.2 Hành vi UI

- Màn hình phủ toàn màn hình, nền tối, header có tên profile và ngày sinh.
- Bộ lọc gồm Tất Cả và 6 nhóm; mặc định Tất Cả.
- Grid hai cột; card có ảnh, số thứ tự, nhãn nhóm, giá trị, tên Việt/Anh.
- Chạm card có haptic nhẹ và mở detail sheet.
- Detail hiển thị metadata ngay lập tức, tải luận giải bất đồng bộ, có loading, nội dung, fallback offline và phần toàn văn có thể mở rộng.
- Đóng detail có success haptic; đóng màn hình quay lại parent mà không thay profile.
- Nếu profile đổi hoặc ngày hệ thống bước sang ngày mới, ba chỉ số chu kỳ phải được tính lại.

### 2.3 Contract knowledge

- Query Supabase theo đúng cặp `indicator_key` + `number_value` và lấy `title`, `content`.
- Parse markdown thành `overview`, tối đa 3 strengths, tối đa 2 challenges, advice và giữ `fullContent`.
- Lỗi mạng, Supabase chưa cấu hình hoặc không có row đều phải trả fallback local; không để detail thành màn lỗi rỗng.
- Fallback Năm Cá Nhân 1...9 giữ nội dung riêng; các số 1...9, 11, 22, 33 dùng archetype chung.

## 3. Sai khác và lỗi legacy phải khóa trước khi port

Không được tự chọn một công thức rồi gọi đó là parity. Hai calculator cũ đang khác nhau:

1. Đường Đời của modal cộng toàn bộ chữ số ngày sinh; calculator Chat rút gọn ngày/tháng/năm trước rồi mới cộng.
2. Modal có nhánh giữ số `10`, `11`, `22` cho Đường Đời nhưng không giữ `33`; calculator Chat giữ `11`, `22`, `33`.
3. `bridgeMaturityPassion` trong modal luôn coi Đam Mê là `0` vì `passion` thực tế luôn là chuỗi.
4. Ngày sinh sai định dạng bị thay âm thầm bằng hôm nay ở một nhánh và `2000-01-01` ở nhánh khác.
5. `new Date()` và timezone thiết bị được gọi trực tiếp nên fixture chu kỳ không deterministic.
6. Fallback knowledge dùng `parseInt` cho giá trị tổng hợp. Ví dụ danh sách số hoặc chuỗi không phải số có thể bị gán nhầm archetype số đầu tiên hoặc số 1.
7. Card Biểu Đồ Tên/Ngày Sinh hiện chỉ trả câu tổng số phần tử, chưa trả ma trận/tần suất để UI trực quan hóa.

Quyết định đề xuất cho bản migration đầu tiên:

- Version hóa ruleset thay vì trộn hành vi:
  - `reactNativeCardsV1`: tái lập kết quả của `numerologyEngine.ts` cho màn 24 card.
  - `reactNativeAgentV1`: tái lập tập con của `numerology24Service.ts` cho Chat/Wallpaper.
- Dùng chung primitives chuẩn hóa tên, chữ Y, bảng Pythagoras, rút gọn số và parse ngày; chỉ khác ở formula policy đã được test.
- Không âm thầm sửa kết quả người dùng cũ trong slice parity. Các sửa lỗi rõ ràng được đưa vào `unifiedV2` sau khi có golden fixtures và quyết định sản phẩm.
- Với input không hợp lệ trên iOS, trả lỗi validation có kiểu rõ ràng. Chỉ adapter legacy mới được phép áp fallback tương thích.
- Gắn `rulesetVersion` vào snapshot/cache/payload để kết quả có thể tái lập.

## 4. Kiến trúc iOS đích

```text
UserProfile + reference Date/Calendar/TimeZone
                    |
                    v
          NumerologyEngine (pure)
                    |
      +-------------+----------------+
      |                              |
24-card snapshot              requested indicators
      |                              |
NumerologyFeature             Chat / Wallpaper adapters
      |
selected indicator
      v
NumerologyKnowledgeClient -> Supabase row -> markdown parser
                            \-> bundled offline fallback
```

### 4.1 Shared/Models

Mở rộng `Shared/Models/Numerology.swift`:

- `NumerologyIndicatorKey: String, CaseIterable` chứa đúng 24 key.
- `NumerologyRulesetVersion`.
- `NumerologyInput` gồm tên, ngày sinh đã parse, ngày tham chiếu và timezone.
- `NumerologySnapshot` gồm profile identity, ruleset, reference date và 24 kết quả.
- Các model có cấu trúc cho `Arrow`, `NameChart`, `BirthChart`, pinnacle/challenge; adapter mới chuyển chúng thành `NumerologyValue`/`displayValue` tại boundary.
- `NumerologyKnowledgeDTO` giữ schema Supabase tách khỏi `KnowledgeReading` domain.

Giữ riêng `NumerologyIndicator` compact cho Chat và `CalculatedNumerologyIndicator` cho UI như model map hiện tại; không gộp hai contract.

### 4.2 Shared/Engines

Tạo `Shared/Engines/NumerologyEngine.swift` là pure, `Sendable`, không biết Supabase/SwiftUI/TCA:

- Chuẩn hóa Unicode tiếng Việt bằng decomposition + folding, xử lý riêng `đ/Đ`.
- Parse chặt `yyyy-MM-dd`; adapter parity có thể hỗ trợ `dd/MM/yyyy` như modal cũ.
- Inject `referenceDate`, `Calendar` và `TimeZone` để Năm/Tháng/Ngày Cá Nhân deterministic.
- Một lần tính tạo đủ intermediate values và snapshot; không gọi đệ quy tính lại nhiều chỉ số.
- Cho phép lấy subset theo key từ cùng snapshot.
- Tách formatter giá trị khỏi công thức để localization không làm đổi logic.

### 4.3 Core/Clients

Tạo `Core/Clients/NumerologyClient.swift` bằng `@DependencyClient`:

- `calculateSnapshot(profile, referenceDate, ruleset)`.
- `requestedIndicators(profile, keys, referenceDate, ruleset)`.
- `loadKnowledge(key, value, title)` async.

Tạo `Core/Clients/NumerologyKnowledgeClient.swift` hoặc repository nội bộ:

- Live implementation query Supabase qua dependency hiện có, không khởi tạo SDK/singleton trong View.
- Test/preview implementation trả fixture tức thì.
- Parser markdown là hàm pure và có unit test.
- Offline catalog nằm trong Swift/resource bundle, không phụ thuộc mạng.
- Request detail phải có cancellation ID để response của card cũ không ghi đè card mới.

### 4.4 Features/Numerology (TCA)

Tạo:

- `Features/Numerology/NumerologyFeature.swift`
- `Features/Numerology/NumerologyView.swift`
- `Features/Numerology/NumerologyDetailFeature.swift`
- `Features/Numerology/NumerologyDetailView.swift`
- Các subview thuần trình bày như `NumerologyCardView`, `NumerologyCategoryPicker`, `NumerologyChartView`.

State chính:

- `profile`, `selectedCategory`, `snapshot`, `isLoading`, validation/error state.
- `@Presents var detail: NumerologyDetailFeature.State?`.
- `referenceDate`/ruleset chỉ lưu khi cần hiển thị và test; lấy thời gian từ TCA dependency.

Action chính:

- `onAppear`, `profileChanged`, `categorySelected`, `cardTapped`, `dayBoundaryReached`.
- `snapshotResponse`, `detail(PresentationAction)`, `closeTapped`, delegate dismiss.

Reducer:

- Tính snapshot qua dependency, không gọi side effect trong View.
- Mở detail bằng navigation state TCA.
- Theo dõi đổi ngày khi app active để refresh ba chỉ số chu kỳ.
- Giữ category khi đóng detail; reset lựa chọn khi đóng toàn màn hình theo behavior parent.

View:

- `LazyVGrid` adaptive/tối thiểu 2 cột ở iPhone, không lấy width global tại thời điểm module load.
- Dùng 24 `AppAsset` hiện có, semantic theme token, Dynamic Type, VoiceOver label kết hợp tên + giá trị + nhóm.
- Detail dùng `.sheet(store:)` hoặc presentation state tương đương; có loading skeleton/progress, retry chỉ khi online query cần retry, và luôn có offline content.
- Haptic qua dependency client hoặc action-driven effect, không gọi trực tiếp trong View.

### 4.5 Tích hợp parent

- Chat: parent giữ `@Presents var numerology`, truyền active profile, map `targetIndicators` bằng `requestedIndicators` và giữ nguyên thứ tự key từ classifier.
- Wallpaper: dùng adapter agent ruleset cho Đường Đời/Sứ Mệnh/Năm/Ngày Cá Nhân; cùng snapshot/reference date trong một request generation.
- App shell hiện vẫn là foundation screen, vì vậy Numerology có thể được preview/test độc lập trước; chỉ nối route production khi Chat/Profile/Wallpaper TCA có owner rõ ràng.

## 5. Thứ tự triển khai

### Slice N1 — Khóa contract và golden fixtures

- Tạo fixture tối thiểu 12 hồ sơ từ engine React Native với clock/timezone cố định.
- Bao phủ tên có dấu/`Đ`, tên chứa `Y`, nhiều khoảng trắng/ký tự lạ, ngày 11/22, master 11/22/33, ngày nhuận, nhiều Đam Mê đồng hạng và đủ mũi tên mạnh/trống.
- Xuất kết quả của cả hai calculator để chứng minh nơi giống/khác.
- Ghi quyết định parity/correction và ruleset version vào `migration/STATUS.md`.

Điều kiện qua: fixture review xong; không còn công thức “ngầm chọn”.

### Slice N2 — Pure engine và model

- Thêm enum key, ruleset, snapshot và structured chart models.
- Port primitives và 24 phép tính.
- Tạo adapters card/agent; unknown requested key bị bỏ qua đúng như RN.
- Unit test toàn bộ fixture, input invalid và timezone/day boundary.

Điều kiện qua: 24/24 key có kết quả, deterministic, thread-safe, không import TCA/SwiftUI/Supabase.

### Slice N3 — Knowledge client và offline

- Thêm DTO/query Supabase, parser markdown, archetype/personal-year fallback.
- Sửa fallback cho composite values bằng nội dung theo loại chỉ số thay vì `parseInt` mơ hồ; nếu cần parity tuyệt đối, giữ hành vi này trong legacy adapter và đánh dấu debt.
- Test success/no-row/network-error/malformed-content/cancellation.

Điều kiện qua: mọi card luôn có nội dung detail hữu ích khi offline.

### Slice N4 — TCA feature và SwiftUI

- Implement reducer, view grid, filter, detail presentation, haptic/accessibility.
- Dùng asset card đã port; không thêm/copy lại ảnh.
- Thêm reducer test và snapshot/manual parity checklist cho iPhone nhỏ/lớn, portrait, Dynamic Type và Reduce Motion.

Điều kiện qua: mở → lọc → chọn card → đọc detail → đóng hoạt động ổn định, kể cả đổi card nhanh và mất mạng.

### Slice N5 — Tích hợp Chat và Wallpaper

- Nối presentation state vào parent khi hai parent feature được migration.
- Nối subset indicators vào chat request/local synthesis.
- Nối 4 giá trị personalization vào wallpaper request.
- Contract test JSON bảo đảm key và `number|string` tương thích backend.

Điều kiện qua: cùng profile/clock/ruleset cho cùng kết quả ở grid, Chat và Wallpaper theo policy đã chọn.

### Slice N6 — Parity và cutover feature

- Chạy Swift tests/build.
- So sánh screenshot và hành vi với RN trên cùng profile.
- Kiểm tra online/offline, Supabase configured/unconfigured, đổi ngày, đổi timezone và app foreground.
- Ghi mọi intentional difference vào `migration/STATUS.md`.

Điều kiện qua: không còn mismatch chưa giải thích; feature row có thể chuyển sang Hoàn tất.

## 6. Ma trận test bắt buộc

### Engine

- Chuẩn hóa tiếng Việt và `đ/Đ`; quy tắc Y theo từng từ.
- Master number ở từng chỉ số cho phép giữ master.
- Hai ruleset legacy trên cùng fixture.
- Danh sách missing/passion đồng hạng; karmic debt không trùng.
- Ba cầu nối; bốn pinnacle; bốn challenge.
- Tám đường mũi tên mạnh/trống và ma trận có số 0.
- Clock cố định quanh 23:59/00:00 ở `Asia/Ho_Chi_Minh` và timezone khác.
- Input trống/sai/ngày không tồn tại/năm nhuận.

### Knowledge

- Query đúng key/value.
- Parser heading viết hoa/thường, bullet `-`, `*`, `•`, thiếu section.
- Fallback 1...9/11/22/33, Năm Cá Nhân và composite value.
- Network timeout, no row, Supabase off, request bị cancel.

### Reducer/UI

- Default 24 card; số lượng nhóm lần lượt 5/6/2/3/5/3.
- Filter, selection, close, reopen, profile change, day change.
- Response detail đến sai thứ tự không ghi đè state mới.
- VoiceOver, Dynamic Type, contrast, tap target, landscape/iPad adaptive grid.

### Integration

- Thứ tự `targetIndicators` được giữ.
- Unknown key không được thay bằng chỉ số khác.
- Chat và Wallpaper serialize đúng schema backend.
- Profile active đổi thì không tái sử dụng snapshot/knowledge sai profile.

## 7. Definition of Done

- Có một engine pure dùng chung, với ruleset version rõ ràng và clock/timezone injected.
- 24 card, 6 nhóm, detail knowledge và offline fallback hoạt động.
- Chat/Wallpaper dùng adapter có contract được test; không còn logic numerology rải trong View.
- 24 asset hiện có được dùng đúng key; không tăng bundle bằng bản sao.
- Unit/reducer/contract tests pass và `xcodebuild` thành công.
- Parity UI/behavior được ghi bằng fixture + screenshot checklist.
- `migration/STATUS.md` ghi bằng chứng, intentional differences và debt còn lại.

## 8. Ngoài phạm vi slice đầu

- Thay đổi nội dung 212 bài trên Supabase.
- Sửa backend/classifier hoặc mở rộng feature gate Pro.
- Thiết kế lại toàn bộ Chat/Wallpaper/App shell.
- Khẳng định một trường phái thần số học là “chuẩn” khi chưa có product decision.
- Xóa ruleset legacy trước khi dữ liệu/behavior cũ được đối chiếu và chấp thuận.
