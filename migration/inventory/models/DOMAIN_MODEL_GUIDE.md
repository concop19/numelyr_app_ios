# Hướng dẫn cấu trúc domain và cách đọc class diagram

Tài liệu này giải thích cách 10 sơ đồ trong [`CLASS_DIAGRAMS.md`](CLASS_DIAGRAMS.md) được tổ chức và cách các model Swift tương ứng phối hợp trong kiến trúc TCA. Đây là tài liệu định hướng kiến trúc; source React Native tại ref `b89d94fdbee6118edca8c09d9232115da081afb9` vẫn là baseline hành vi.

## 1. Nguyên tắc tổ chức chung

Model được chia theo bốn lớp trách nhiệm. Không dùng một struct duy nhất xuyên qua tất cả các lớp.

| Lớp | Trách nhiệm | Ví dụ |
| --- | --- | --- |
| Domain model | Biểu diễn dữ liệu nghiệp vụ đã hợp lệ, dùng chung giữa reducer và engine | `UserProfile`, `TarotCard`, `AstroFortuneSlip` |
| Boundary DTO | Giữ chính xác schema HTTP, Supabase hoặc notification | `ChatAgentRequest`, `CloudNumerologyProfileDTO`, `CheckoutResponse` |
| Persistence payload | Dữ liệu có version được serialize xuống local storage | `GameHubProgress`, `ArrowEscapeModels.Progress`, `ZipModels.Progress` |
| Feature state | Trạng thái vòng đời UI như loading, selection, presentation và navigation | Nằm trong `Feature.State`, không đưa vào `Shared/Models` nếu không có ý nghĩa nghiệp vụ |

Luồng dữ liệu chuẩn:

```text
HTTP / Supabase / SQLite / UserDefaults
                 ↓ decode
             Boundary DTO
                 ↓ mapper + validation
             Domain model
                 ↓ reducer action
          TCA Feature.State / View
```

Chiều ghi dữ liệu đi ngược lại qua mapper. View không gọi API hoặc storage trực tiếp.

## 2. Cách đọc ký hiệu Mermaid

| Ký hiệu | Ý nghĩa |
| --- | --- |
| `A *-- B` | Composition: `B` thuộc vòng đời của `A` |
| `A o-- B` | Aggregation: `A` có thể chứa hoặc tham chiếu `B`, nhưng `B` có ý nghĩa riêng |
| `A --> B` | Association hoặc mapping trực tiếp |
| `A ..> B` | Dependency: `A` dùng `B` để tính toán, lookup hoặc chuyển đổi |
| `"1"`, `"0..1"`, `"0..*"` | Cardinality đã xác nhận từ source |
| `?` sau kiểu | Giá trị optional/null |
| `<<enumeration>>` | Tập giá trị hữu hạn được biểu diễn bằng Swift `enum` |
| Nhãn `inferred` | Quan hệ suy ra từ luồng sử dụng, không phải foreign key hoặc field trực tiếp |

Mỗi quan hệ `inferred` phải có giải thích và source evidence ngay dưới sơ đồ. Overview chỉ mô tả dependency giữa domain nên không dùng cardinality record.

## 3. Sơ đồ 0 — Tổng quan kiến trúc dữ liệu

Sơ đồ tổng quan đặt chín vùng còn lại vào cùng một hệ thống:

- `ProfileDomain` cung cấp identity và dữ liệu sinh cho Chat, Astrology và Wallpaper.
- `CalendarDomain` cung cấp ngày âm, giờ hoàng đạo và ca dao làm dữ liệu neo cho Astrology.
- `SettingsBillingDomain` quản lý reminder/deep link đi vào Game Hub.
- `GameHubDomain` quản lý discovery, daily challenge và progress chung; luật chơi thuộc `MiniGameDomain`.
- `BoundaryLayer` là cổng duy nhất nối domain với Supabase, REST API và local storage.

Overview không có class implementation tương ứng. Nó là bản đồ dependency để quyết định thứ tự migration:

1. Shared domain model.
2. Boundary DTO và dependency client.
3. Engine/storage mapper.
4. TCA feature.
5. Navigation và UI.

## 4. Sơ đồ 1 — App shell, authentication và profile

### Trách nhiệm

Domain này quản lý danh tính tài khoản, phiên đăng nhập và nhiều hồ sơ thần số học thuộc một tài khoản.

### Nhóm class

- `UserProfile`: domain model dùng trong app. Có `id`, tên, ngày sinh và dữ liệu sinh optional.
- `Gender`: enum nghiệp vụ. `UserProfile.gender` optional vì cloud schema hiện không lưu giới tính.
- `AccountProfileDTO`: row của bảng Supabase `profiles`, đại diện tài khoản auth.
- `CloudNumerologyProfileDTO`: row của `user_numerology_profiles`, không được dùng trực tiếp làm domain state.
- `AuthSession`: snapshot phiên nhạy cảm, chỉ được lưu qua Keychain/Supabase auth storage.

### Luồng chính

```text
Supabase session
    ├── AccountProfileDTO
    └── [CloudNumerologyProfileDTO]
                    ↓ profile mapper
               [UserProfile]
                    ↓ activeProfileId
                 AppFeature
```

Mapper phải ưu tiên ID cloud khi có. Với dữ liệu legacy không có ID cloud, có thể merge theo tên chuẩn hóa + ngày sinh nhưng phải coi đây là heuristic. Không tự gán `.female` khi thiếu giới tính; feature cần yêu cầu người dùng xác nhận trước khi chạy thuật toán phụ thuộc giới tính.

### File Swift

- `Shared/Models/UserProfile.swift`
- `Shared/Models/BoundaryModels.swift`
- Client đích: `Core/Clients/SupabaseClient.swift`

## 5. Sơ đồ 2 — Numerology, Tarot và Chat

### Trách nhiệm

Đây là domain điều phối reading: phân loại câu hỏi, chọn spread Tarot, tính chỉ số thần số học, tạo Bát Tự/Tử Vi và lưu message/card trong lịch sử chat.

### Ba tầng model quan trọng

1. Cấu hình tĩnh:
   - `TarotCard`, `TarotSpread`, `TarotPosition`.
   - `NumerologyCardDefinition`.
2. Kết quả tính toán:
   - `DrawnTarotCard`.
   - `NumerologyIndicator` cho payload chat.
   - `CalculatedNumerologyIndicator` cho UI chi tiết.
   - `TuViBaziSynastry`, `ColorGuidanceContext`.
3. Chat aggregate:
   - `AgentDecision` quyết định intent và spread.
   - `AgentSynthesisPayload` gom các kết quả reading.
   - `ChatCardPayload` là enum typed gắn vào `ChatMessage`.

### Lý do tách model thần số học

React Native có hai schema khác nhau:

- `IndicatorInfo`: `key`, `name`, `value`, `meaning`, dùng trong chat/API.
- `CalculatedIndicator`: metadata thẻ + giá trị tính toán, dùng cho modal/card UI.

Swift giữ riêng `NumerologyIndicator` và `CalculatedNumerologyIndicator`. Việc gộp hai schema sẽ tạo field giả và làm sai API contract.

### Chat-card compatibility

`ChatCardPayload.agentSynthesis` dùng model typed cho payload đã biết. Case `unsupported(JSONValue)` giữ nguyên payload cũ hoặc payload server mới chưa được app hỗ trợ. Không được silently thay payload không decode được bằng object rỗng.

### File Swift

- `Shared/Models/AgentDecision.swift`
- `Shared/Models/ChatMessage.swift`
- `Shared/Models/Numerology.swift`
- `Shared/Models/Tarot.swift`
- `Shared/Models/TuViBazi.swift`
- `Shared/Models/ColorGuidance.swift`

## 6. Sơ đồ 3 — Calendar và dữ liệu văn hóa

### Trách nhiệm

Domain Calendar chứa model thuần cho lịch tuần, ngày âm, giờ hoàng/hắc đạo và record ca dao đọc từ SQLite.

### Cấu trúc

- `CalendarWeekInfo` composition đúng 7 `CalendarDayItem`.
- Mỗi `CalendarDayItem` là input để tính `LunarDate`, 12 `LunarHourInfo` và `DayHoangDaoStatus`.
- `CaDaoRecord` là persistence entity từ bảng SQLite `cadao`; nó không thuộc sở hữu của một ngày.

Quan hệ ngày → ca dao là dependency lookup, không phải composition. Cùng một record có thể xuất hiện lại ở ngày khác.

### Invariant parity quan trọng

Daily ca dao dùng đúng seed:

```text
seed = day * 31 + month * 37 + year * 7
offset = seed % totalCount
query = ORDER BY id LIMIT 1 OFFSET offset
```

Không query `WHERE id = offset`, vì ID trong database không liên tục.

### File Swift

- `Shared/Models/LunarCalendar.swift`
- Client đích: `Core/Clients/CaDaoDatabaseClient.swift`

## 7. Sơ đồ 4 — Astrology

### Trách nhiệm

Astrology chuyển dữ liệu sinh và thời điểm hiện tại thành biểu đồ hành tinh, góc chiếu, vector 32 chiều và lá thăm chiêm tinh.

### Pipeline

```text
UserProfile birth data
        ↓
AstroPlanetaryChart (natal + transit)
        ↓
AstroAspectAnalysis + TemperamentBalance
        ↓
AstroFeatureMetadata
        ├── AstroVectorResult
        └── AstroFortuneRequest → AstroFortuneSlip
```

### Nhóm class

- Astronomy primitives: `AstroPlanetPosition`, `AstroPlanetaryChart`, `ZodiacQuality`.
- Aspect engine: `AstroAspectDefinition`, `DetectedAstroAspect`, `AstroAspectAnalysis`.
- Feature vector: `TemperamentBalance`, `AstroTemperamentMetadata`, `AstroScoreMetadata`, `AstroFeatureMetadata`, `AstroVectorResult`.
- Fortune domain: `AnchorCaDao`, `AstroFortuneSlip`.
- HTTP boundary: `AstroFortuneRequest`, `AstroFortuneResponse`.

### Giải thích enum nền tảng

| Enum | Giá trị | Ý nghĩa |
| --- | --- | --- |
| `AstroElement` | `fire`, `earth`, `air`, `water` | Bốn nguyên tố dùng để phân nhóm 12 cung hoàng đạo |
| `AstroModality` | `cardinal`, `fixed`, `mutable` | Ba tính chất: tiên phong, kiên định và linh hoạt |
| `AstroAspectType` | `conjunction`, `sextile`, `square`, `trine`, `opposition` | Năm góc chiếu chính: 0°, 60°, 90°, 120°, 180° |
| `AstroAspectNature` | `tension`, `harmony`, `neutral` | Nhóm tác động dùng để cộng điểm căng thẳng/hài hòa |
| `AstroDominantSignal` | `tension`, `harmony`, `conjunction`, `balanced` | Kết luận ngắn gọn về tín hiệu chiêm tinh trội trong ngày |

### `ZodiacQuality`

Mỗi cung hoàng đạo được ánh xạ sang một nguyên tố và một tính chất.

| Field | Kiểu | Giải thích |
| --- | --- | --- |
| `element` | `AstroElement` | Nguyên tố của cung: Lửa, Đất, Khí hoặc Nước |
| `modality` | `AstroModality` | Tính chất của cung: tiên phong, kiên định hoặc linh hoạt |

Ví dụ Aries là `fire + cardinal`, Taurus là `earth + fixed`, Gemini là `air + mutable`.

### `AstroPlanetPosition`

Đại diện vị trí của một thiên thể trên hoàng đạo tại một thời điểm.

| Field | Kiểu/range | Giải thích |
| --- | --- | --- |
| `id` | `String` computed | Dùng `name` làm identity ổn định trong SwiftUI/TCA collection |
| `name` | `String` | Tên chuẩn của thiên thể: `Sun`, `Moon`, `Mercury`… `Pluto` |
| `longitude` | `Double`, `[0, 360)` độ | Kinh độ hoàng đạo tuyệt đối |
| `sign` | `String` | Tên cung chứa kinh độ, ví dụ `Aries`, `Scorpio` |
| `signIndex` | `Int`, `0...11` | Chỉ số cung; `0 = Aries`, `11 = Pisces` |
| `degreeInSign` | `Double`, `[0, 30)` độ | Vị trí bên trong cung hiện tại |
| `normalized` | `Double`, `[0, 1)` | `longitude / 360`, dùng để xây vector feature |

Các field dẫn xuất được tính như sau:

```text
signIndex = floor(longitude / 30)
degreeInSign = longitude mod 30
normalized = longitude / 360
```

### `AstroPlanetaryChart`

Snapshot vị trí 10 thiên thể từ Mặt Trời đến Pluto.

| Field | Kiểu | Giải thích |
| --- | --- | --- |
| `targetDate` | `Date` | Thời điểm được dùng để tính chart |
| `isTimeEstimated` | `Bool` | `true` khi natal chart thiếu giờ sinh và phải dùng 12:00 trưa |
| `planets` | `[String: AstroPlanetPosition]` | Dictionary tra cứu nhanh theo tên thiên thể |
| `planetList` | `[AstroPlanetPosition]` | Danh sách có thứ tự dùng cho vòng lặp và vector hóa |

`planets` và `planetList` chứa cùng dữ liệu nhưng phục vụ hai access pattern khác nhau. Mapper phải giữ chúng nhất quán; không thêm hành tinh vào một collection mà bỏ collection còn lại.

### `AstroAspectDefinition`

Configuration mô tả một loại góc chiếu có thể được nhận diện.

| Field | Kiểu | Giải thích |
| --- | --- | --- |
| `type` | `AstroAspectType` | ID máy đọc của góc chiếu |
| `symbol` | `String` | Ký hiệu hiển thị như `☌`, `⚹`, `□`, `△`, `☍` |
| `nameVi` | `String` | Tên tiếng Việt: Trùng tụ, Lục hợp, Vuông góc… |
| `targetAngle` | `Double`, độ | Góc lý tưởng: 0, 60, 90, 120 hoặc 180 |
| `maxOrb` | `Double`, độ | Sai số tối đa vẫn được coi là góc chiếu hợp lệ |
| `nature` | `AstroAspectNature` | Cách góc này đóng góp vào tension/harmony |
| `baseWeight` | `Double` | Trọng số cơ sở trước khi giảm theo orb |

### `DetectedAstroAspect`

Một góc chiếu thực tế được phát hiện giữa hành tinh quá cảnh và hành tinh bản mệnh.

| Field | Kiểu | Giải thích |
| --- | --- | --- |
| `transitPlanet` | `String` | Hành tinh trên bầu trời tại ngày đang xem |
| `natalPlanet` | `String` | Hành tinh trong natal chart của người dùng |
| `type` | `AstroAspectType` | Loại góc gần nhất thỏa `maxOrb` |
| `symbol` | `String` | Ký hiệu UI lấy từ definition |
| `nameVi` | `String` | Tên tiếng Việt lấy từ definition |
| `targetAngle` | `Double` | Góc chuẩn của aspect |
| `actualAngle` | `Double`, `[0, 180]` độ | Khoảng cách góc ngắn nhất giữa hai hành tinh |
| `orb` | `Double`, độ | `abs(actualAngle - targetAngle)`; càng nhỏ càng sát góc chuẩn |
| `weight` | `Double`, `[0, baseWeight]` | Độ mạnh sau khi giảm theo orb |
| `nature` | `AstroAspectNature` | Nhóm tension, harmony hoặc neutral |

Công thức parity cho trọng số:

```text
orbFactor = max(0, 1 - orb / maxOrb)
weight = baseWeight * orbFactor
```

### `AstroAspectAnalysis`

Aggregate kết quả khi so toàn bộ transit chart với natal chart.

| Field | Kiểu/range | Giải thích |
| --- | --- | --- |
| `aspects` | `[DetectedAstroAspect]` | Tất cả góc chiếu đạt điều kiện orb |
| `topAspect` | `DetectedAstroAspect?` | Góc nổi bật nhất; `nil` nếu không phát hiện góc nào |
| `tensionScore` | `Double`, `[0, 1]` | Tỷ lệ hoạt động có nature tension trong tổng tension + harmony |
| `harmonyScore` | `Double`, `[0, 1]` | Tỷ lệ hoạt động harmony trong tổng tension + harmony |
| `conjunctionIntensity` | `Double`, `[0, 1]` | Tỷ trọng năng lượng trùng tụ trên tổng hoạt động |
| `fastPlanetActivity` | `Double`, `[0, 1]` | Tỷ trọng do Sun, Moon, Mercury, Venus và Mars tạo ra |

`tensionScore` và `harmonyScore` thường bù nhau khi có directional aspect. Điểm được chuẩn hóa và làm tròn bốn chữ số thập phân.

### `TemperamentBalance`

Phân bố 10 hành tinh natal theo nguyên tố và tính chất. Mỗi field nằm trong `[0, 1]`.

| Field | Giải thích |
| --- | --- |
| `fire`, `earth`, `air`, `water` | Tỷ lệ hành tinh nằm trong cung thuộc từng nguyên tố; bốn giá trị cộng xấp xỉ 1 |
| `cardinal`, `fixed`, `mutable` | Tỷ lệ hành tinh theo ba modality; ba giá trị cộng xấp xỉ 1 |

### `AstroTemperamentMetadata`

| Field | Kiểu | Giải thích |
| --- | --- | --- |
| `balance` | `TemperamentBalance` | Toàn bộ tỷ lệ định lượng |
| `dominantElement` | `String` | Nhãn Việt của nguyên tố có tỷ lệ cao nhất: Lửa/Đất/Khí/Nước |
| `dominantModality` | `String` | Nhãn Việt của modality cao nhất: Tiên phong/Kiên định/Linh hoạt |

Hai field dominant là dữ liệu dẫn xuất để hiển thị và tạo prompt; `balance` mới là nguồn số liệu gốc.

### `AstroScoreMetadata`

Là phiên bản field-name ngắn của bốn điểm trong `AstroAspectAnalysis`, được nhúng vào feature metadata.

| Field | Nguồn |
| --- | --- |
| `tension` | `AstroAspectAnalysis.tensionScore` |
| `harmony` | `AstroAspectAnalysis.harmonyScore` |
| `conjunction` | `AstroAspectAnalysis.conjunctionIntensity` |
| `fastPlanetActivity` | `AstroAspectAnalysis.fastPlanetActivity` |

### `AstroFeatureMetadata`

Context có thể đọc được bởi người và backend, đi kèm vector 32 chiều.

| Field | Kiểu/range | Giải thích |
| --- | --- | --- |
| `birthDate` | `String` | Ngày sinh nguồn; hiện giữ format tương thích React Native |
| `birthTime` | `String?` | Giờ sinh `HH:mm`; `nil` khi không biết |
| `hasExactTime` | `Bool` | Nghịch đảo logic của natal chart `isTimeEstimated` |
| `confidenceScore` | `Double` | `1.0` nếu có giờ chính xác, `0.7` nếu dùng Noon chart |
| `currentDateIso` | `String` | Thời điểm tạo transit chart theo ISO-8601 |
| `natalSunSign` | `String` | Cung Mặt Trời trong natal chart |
| `natalMoonSign` | `String` | Cung Mặt Trăng trong natal chart |
| `transitMoonSign` | `String` | Cung Mặt Trăng tại thời điểm đang xem |
| `temperament` | `AstroTemperamentMetadata` | Cân bằng nguyên tố/modality của natal chart |
| `topAspect` | `DetectedAstroAspect?` | Góc chiếu nổi bật nhất của ngày |
| `totalAspectsCount` | `Int` | Tổng số aspect được phát hiện |
| `scores` | `AstroScoreMetadata` | Bốn điểm động lực học đã chuẩn hóa |
| `dominantSignal` | `AstroDominantSignal` | Signal trội được suy ra từ ba score chính |
| `vibeSummary` | `String` | Câu mô tả deterministic theo dominant signal, không phải AI output |

Quy tắc chọn `dominantSignal` hiện tại:

- `conjunction` nếu conjunction score ≥ `0.28`.
- `tension` nếu tension cao hơn harmony ít nhất `0.2`.
- `harmony` nếu harmony cao hơn tension ít nhất `0.2`.
- Các trường hợp còn lại là `balanced`.

### `AstroVectorResult`

| Field | Kiểu | Giải thích |
| --- | --- | --- |
| `vector` | `[Double]` | Chính xác 32 phần tử, mỗi phần tử được clamp vào `[0, 1]` |
| `metadata` | `AstroFeatureMetadata` | Context giúp giải thích vector và tạo fortune request |
| `float32Values` | `[Float]` computed | Bản chuyển đổi runtime; không encode và không phải nguồn dữ liệu |

Ý nghĩa từng vùng của vector:

| Index | Nội dung |
| --- | --- |
| `0` | Confidence: `1.0` exact time hoặc `0.7` Noon chart |
| `1...10` | Normalized longitude của 10 hành tinh natal theo thứ tự Sun → Pluto |
| `11...20` | Normalized longitude của 10 hành tinh transit theo thứ tự Sun → Pluto |
| `21...24` | Fire, Earth, Air, Water balance |
| `25...27` | Cardinal, Fixed, Mutable balance |
| `28` | Tension score |
| `29` | Harmony score |
| `30` | Conjunction intensity |
| `31` | Fast-planet activity |

`AstroVectorResult.vector` persist dưới dạng `[Double]`. `[Float]` chỉ là computed runtime representation, tương đương vai trò của `Float32Array` bên React Native.

### `AnchorCaDao` và `AstroFortuneSlip`

| Model/field | Giải thích |
| --- | --- |
| `AnchorCaDao.content` | Câu ca dao dùng làm neo văn hóa/nhịp điệu cho prompt |
| `AnchorCaDao.category` | Nhóm ca dao optional từ SQLite |
| `AstroFortuneSlip.title` | Tiêu đề optional do backend sinh |
| `verse` | Phần thơ/lá thăm chính |
| `mirror` | Diễn giải “gương soi” nội tâm |
| `advice` | Gợi ý hành động |
| `anchorCaDao` | Snapshot ca dao đã dùng; tránh lookup lại làm thay đổi lịch sử |
| `astroMetadata` | Metadata optional để giải thích nguồn kết quả và hỗ trợ cache/debug |

### Field của Astrology API boundary

`AstroFortuneRequest` là DTO gửi server, không phải domain model:

| Field | Giải thích |
| --- | --- |
| `caDaoSample`, `caDaoCategory` | Nội dung và nhóm ca dao làm context |
| `astroSummary` | Bản tóm tắt deterministic từ `vibeSummary` |
| `metadata` | Điểm tension/harmony/conjunction, signal, dominant elements và highlights |
| `recentAdvice` | Tối đa bảy lời khuyên gần nhất để giảm lặp nội dung |
| `userContext` | Context người dùng optional |

`AstroFortuneResponse.success` báo trạng thái nghiệp vụ; `fortune` chỉ có khi thành công; `error` chứa thông báo server nếu thất bại. `AstroFortuneResponsePayload` sau validation được map thành `AstroFortuneSlip` và bổ sung `AnchorCaDao`/`AstroFeatureMetadata` ở client.

Nếu thiếu giờ sinh, `isTimeEstimated = true`, `hasExactTime = false` và confidence mặc định là `0.7`. `birthPlace` chưa đi vào astronomy engine hiện tại.

### File Swift

- `Shared/Models/Astrology.swift`
- DTO: `Shared/Models/BoundaryModels.swift`

## 8. Sơ đồ 5 — Wallpaper Studio

### Trách nhiệm

Domain này xây request cá nhân hóa, nhận URL ảnh từ backend và map thành item hiển thị trong carousel.

### Cấu trúc

- `WallpaperStyleOption` và `WallpaperIntentionOption` là configuration model.
- `LuckyWallpaperRequest` là DTO gửi backend, không phải UI state.
- `LuckyWallpaperResponse` hỗ trợ cả `imageUrls` và legacy `imageUrl`.
- Mỗi URL thành công được map thành một `WallpaperItem` domain.

`WallpaperItem` chỉ chứa URL/metadata nghiệp vụ; trạng thái download, saving, Photos permission và carousel index phải nằm trong `WallpaperFeature.State`.

Persistence history hiện là thay đổi UX đề xuất, chưa phải parity. Nếu được duyệt, persistence client phải lưu metadata và quản lý lifecycle của file ảnh riêng biệt.

### File Swift

- `Shared/Models/Wallpaper.swift`
- DTO: `Shared/Models/BoundaryModels.swift`

## 9. Sơ đồ 6 — Settings, notification và billing

### Trách nhiệm

Domain này quản lý entitlement, checkout bên ngoài và lịch nhắc daily challenge.

### Nhóm class

- `BillingStatus`, `SubscriptionDetail`: response/domain snapshot của subscription.
- `CheckoutRequest`, `CheckoutResponse`: boundary model cho PayOS và PayPal.
- `DailyReminderSettings`: setting local, có invariant giờ `0...23`, phút `0...59`.
- `NotificationPayload`: title/body/deep-link truyền sang UserNotifications.

`BillingStatus.plan` chỉ là dữ liệu hiển thị cho tới khi có quyết định entitlement enforcement. Reducer không được tự khóa feature chỉ dựa trên giả định chưa xác nhận với backend.

`SubscriptionDetail` khai báo CodingKeys rõ cho `current_period_end` và `cancel_at_period_end`.

### File Swift

- `Shared/Models/Billing.swift`
- DTO/event payload: `Shared/Models/BoundaryModels.swift`

## 10. Sơ đồ 7 — Game Hub và progress dùng chung

### Trách nhiệm

Game Hub không chứa luật chơi. Nó quản lý danh sách game, daily rotation, streak và summary chung để hiển thị hub.

### Cấu trúc

- `GameId`: định danh ổn định của 7 game trên storage/deep link.
- `DailyChallenge`: challenge được sinh deterministic từ ngày.
- `GameProgressSummary`: summary tối thiểu cho từng game.
- `GameHubProgress`: aggregate versioned lưu streak và dictionary summary.

Luồng hoàn thành daily:

```text
Mini-game delegate(.dailyCompleted)
               ↓
GameHubFeature.Action
               ↓
GameHubStorageClient.completeDailyChallenge
               ↓
GameHubProgress mới
```

Daily completion cùng ngày là idempotent. Ngày liên tiếp tăng streak; ngày đứt quãng reset về 1.

### File Swift

- `Shared/Models/GameHubModels.swift`
- Client đích: `Core/Clients/GameHubStorageClient.swift`

## 11. Sơ đồ 8 — Model riêng của mini-game

### Lý do namespace

Nhiều game cùng có `Direction`, `Difficulty`, `Board`, `State`, `Puzzle`. Swift namespace chúng theo game để tránh nhập nhằng:

- `ArrowEscapeModels`
- `SpaceGameModels`
- `MindRulesModels`
- `OAnQuanModels`
- `DotBoxModels`
- `SudokuModels`
- `Game2048Models`
- `ZipModels`

Tên Mermaid được làm phẳng như `Zip_Puzzle` vì Mermaid không biểu diễn nested Swift type thuận tiện.

### Ownership theo game

| Namespace | Aggregate chính | Composition | Persistence |
| --- | --- | --- | --- |
| Arrow Escape | `Board`, `Level` | Level → arrows; Board → remaining arrows | `Progress` |
| Space Game | `State`, `MiniBoard` | MiniBoard → mini arrows | In-memory |
| Mind Rules | `Puzzle` | Puzzle → equations | `Progress.activeLevel` |
| Ô Ăn Quan | `State` | 12 cells, 2 scores, optional last move | In-memory |
| DotBox | `State` | Dictionary lines + boxes | In-memory |
| Sudoku | `Board` | 9 × 9 cells | In-memory |
| 2048 | `[Cell]` | Cell coordinates/value | `BestTileProgress` |
| Zip | `Puzzle` | checkpoints, walls, solution path | `Progress` + best result per puzzle |

Chỉ implementation reachable được port. DotBox chuẩn nằm dưới tree `o-an-quan/src/dotbox`; tree `games/dots-boxes` là duplicate dormant.

Board/runtime state vẫn conform `Equatable` và `Sendable` để dùng trong TCA. Chỉ model thực sự đi qua storage/network mới cần phụ thuộc ổn định vào schema `Codable`.

### File Swift

- `Shared/Models/MiniGameModels.swift`

## 12. Sơ đồ 9 — API và storage boundary

### Trách nhiệm

Boundary diagram không mô tả feature. Nó quy định nơi encode/decode, nơi giữ secret và mapper nào phải tồn tại giữa external schema với domain.

### Boundary

| Boundary | Model | Cơ chế đích |
| --- | --- | --- |
| Supabase | Account/profile/knowledge DTO | Supabase Swift/PostgREST |
| REST | Chat, wallpaper, astrology, billing DTO | `APIClient` dependency |
| Auth secret | `AuthSession` | Keychain hoặc storage chuẩn của Supabase SDK |
| Small settings/progress | Versioned Codable payload | UserDefaults dependency |
| Chat history/cache | Versioned JSON | Application Support file store |
| Ca dao | `CaDaoRecord` | SQLite3 hoặc GRDB read-only bundle |

SwiftData không đọc trực tiếp schema của bundled `cadao.db`. Không được thay SQLite boundary bằng SwiftData chỉ vì cả hai có persistence bên dưới.

Boundary DTO không đi thẳng vào View. Client chịu trách nhiệm:

1. Decode schema bên ngoài.
2. Validate field bắt buộc, range và enum.
3. Map sang domain model.
4. Trả lỗi typed cho reducer.
5. Không log token hoặc payload nhạy cảm.

### File Swift

- `Shared/Models/BoundaryModels.swift`
- `Core/Clients/` cho từng dependency implementation.

## 13. Quy tắc thêm model mới

Trước khi thêm class vào diagram hoặc Swift:

1. Xác định model thuộc domain, DTO, persistence hay feature state.
2. Ghi source evidence và optionality thực tế.
3. Dùng enum cho union hữu hạn; dùng `JSONValue` chỉ tại compatibility boundary.
4. Namespace type trùng giữa game/feature.
5. Chỉ conform `Identifiable` khi có identity ổn định, không dùng UUID ngẫu nhiên cho record cần merge.
6. Chỉ conform `Codable` khi type đi qua serialization hoặc là config bundle.
7. Mọi model đưa vào TCA state/action phải `Equatable` và `Sendable`.
8. Relationship inferred phải có nhãn và giải thích dưới Mermaid block.
9. Cập nhật đồng thời `MODEL_CATALOG.md`, `CLASS_DIAGRAMS.md`, `SWIFT_MODEL_MAP.md` và `STATUS.md`.
10. Chạy type-check model và build iOS sau thay đổi.

## 14. Những quyết định vẫn đang mở

- Backend chưa có OpenAPI/versioned fixture để khóa Chat, Wallpaper, Astrology và Billing DTO.
- Cloud profile chưa có `gender`, `birthTime`, `birthPlace`, `isDefault`.
- Chưa chốt lưu wallpaper history lâu dài hay giữ parity memory-only.
- Chưa chốt SQLite3 thuần hay GRDB cho `cadao.db`.
- Cần định nghĩa version/migration policy cho profile, chat history, astrology cache và game progress trước khi release.

Các điểm này phải được giải quyết qua dependency client và migration policy; không nên làm domain model lỏng hơn để che giấu schema chưa rõ.
