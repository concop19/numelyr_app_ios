# Lá Thăm Chiêm Tinh: luồng dữ liệu kèm từng struct

**Cách đọc:** đi từ trên xuống. Mỗi bước có 3 phần: **NHẬN** (struct vào), **LÀM** (logic), **RA** (struct ra, và là input của bước sau). Struct nào xuất hiện lần đầu thì được giải thích đầy đủ ngay tại đó; lần sau chỉ nhắc tên.

Ký hiệu: `?` = có thể rỗng (nil). `[X]` = danh sách X.

```
AstroDailyFortuneQuery
   │ ① ─► ResolvedBirthLocation?
   │ ② ─► AstroBirthInput
   │ ③ ─► (cache) AstroFortuneSlip?  ── có thì dừng
   │ ④ ─► AstroNatalSnapshot
   │ ⑤ ─► AstroFeatureMetadata (+ AstroVectorResult)
   │ ⑥ ─► [String] lời khuyên cũ
   │ ⑦ ─► AstroFortuneRequest
   │ ⑧ ─► AstroFortuneResponse
   └ ⑨⑩ ─► AstroFortuneSlip (hoàn chỉnh, lưu cache)
```

---

## ⓪ INPUT của tính năng

### `AstroDailyFortuneQuery`: "đơn yêu cầu" của người dùng

| Trường | Kiểu | Là gì |
| --- | --- | --- |
| `date` | Date | Ngày bốc thăm |
| `profile` | UserProfile? | Hồ sơ người dùng. Nil thì coi như khách |
| `anchorCaDao` | AnchorCaDao? | Ca dao làm nền cho thơ. Nil thì dùng mặc định |
| `userContext` | String? | Ghi chú người dùng gõ thêm, gửi nguyên cho AI |

### `AnchorCaDao`: câu ca dao neo

| Trường | Là gì |
| --- | --- |
| `content` | Nội dung bài ca dao/lục bát |
| `category` | Thể loại ("Dân gian"...). Nil thì coi là "Dân gian" |

### `UserProfile` (định nghĩa ở file khác, đây là phần code này dùng)

| Trường | Là gì |
| --- | --- |
| `id` | Mã người dùng, nằm trong fingerprint |
| `fullName` | Tên |
| `birthDate` | Ngày sinh dạng chuỗi |
| `birthTime` | Giờ sinh, có thể nil |
| `birthLocation.placeID` | Mã địa điểm nơi sinh, có thể nil |
| `effectiveBirthTimeAccuracy` | Độ chắc chắn của giờ sinh |

### `AstroFortuneCachePolicy` (enum): bấm bốc thăm theo kiểu nào

| Case | Nghĩa |
| --- | --- |
| `useCache` | Có lá thăm đã lưu cho hôm nay thì dùng luôn |
| `reloadIgnoringCache` | Bỏ qua bản lưu, làm lại từ đầu (gọi lại server) |

---

## ① Tìm nơi sinh

**NHẬN:** `profile.birthLocation.placeID` **LÀM:** chỉ khi giờ sinh là `exact` **và** có `placeID` thì hỏi `birthLocationClient` để lấy tọa độ + múi giờ. Lỗi thì bỏ qua (không dừng cả tính năng). **RA:** `ResolvedBirthLocation?` (định nghĩa ở file khác; chứa tọa độ và múi giờ nơi sinh). Nil nghĩa là không có nhà/ASC ở các bước sau.

Liên quan: `BirthTimeAccuracy` (enum ở file khác) có ít nhất `.exact` (biết giờ chính xác) và `.unknown` (không biết giờ).

---

## ② Gói dữ liệu sinh

**NHẬN:** `profile` + `ResolvedBirthLocation?` **LÀM:** gộp thành một gói chuẩn để engine tính. Thiếu thì điền mặc định: ngày sinh `1998-10-20`, tên "Đương số", độ chính xác `.unknown`. **RA:**

### `AstroBirthInput`

| Trường | Là gì |
| --- | --- |
| `birthDate` | Ngày sinh (chuỗi) |
| `birthTime` | Giờ sinh hoặc nil |
| `fullName` | Tên (không ảnh hưởng tính toán sao) |
| `birthTimeAccuracy` | Độ chính xác giờ. Nếu không truyền: có giờ thì `.exact`, không thì `.unknown` |
| `resolvedBirthLocation` | Nơi sinh đã giải mã. **Chỉ ở máy, không bao giờ gửi server** |

---

## ③ Kiểm cache

**NHẬN:** `date` + `profile` + `AstroFortuneCachePolicy` **LÀM:** tạo khóa `@astro_fortune_v4_{ngày}_{fingerprint}` rồi tra `UserDefaults`. Nếu có và policy là `useCache` thì trả luôn. Nếu bản lưu thiếu `astroMetadata` (đời cũ) thì tính bổ sung rồi ghi đè. **RA:** `AstroFortuneSlip?` (xem ⑨). Có thì kết thúc, không thì sang ④.

Phần tạo khóa nằm ở `AstrologyCacheKey`: `localDateKey` (ngày dạng `2026-10-07`), `profileFingerprint` (mã băm hồ sơ), `current/version3/version2` (khóa theo đời), `natal` (khóa bản đồ gốc). Bản cũ v2/v3 chỉ được đọc để lấy lịch sử lời khuyên.

---

## ④ Bản đồ sao lúc sinh

**NHẬN:** `AstroBirthInput` + fingerprint **LÀM:** dùng bản lưu nếu `fingerprint` và `engineVersion` khớp; không thì tính mới (vị trí 10 hành tinh lúc sinh, và nếu đủ giờ + nơi sinh thì thêm ASC/MC, 12 nhà). Chỉ lưu khi chưa có `birthLocation` hoặc đã giải mã được nơi sinh. **RA:**

### `AstroNatalSnapshot`: "bản đồ sao gốc" đã đóng gói

| Trường | Là gì |
| --- | --- |
| `fingerprint` | Mã băm hồ sơ lúc tính. Khác mã hiện tại = cache cũ |
| `engineVersion` | Phiên bản thuật toán lúc tính |
| `chart` | Vị trí 10 hành tinh lúc sinh (`AstroPlanetaryChart`) |
| `context` | Nhà, ASC, MC (`AstroNatalContext?`), nil nếu thiếu giờ/nơi sinh |

### `AstroPlanetaryChart`: bảng 10 hành tinh tại một thời điểm (dùng cho cả lúc sinh lẫn hôm nay)

| Trường | Là gì |
| --- | --- |
| `targetDate` | Thời điểm UTC của bảng |
| `isTimeEstimated` | `true` nếu không có giờ sinh nên dùng "Noon Chart" (12:00 UTC) |
| `planets` | Tra nhanh theo tên: `planets["Moon"]` |
| `planetList` | 10 hành tinh theo thứ tự, để lặp và tính thống kê |

### `AstroPlanetPosition`: một hành tinh

| Trường | Là gì |
| --- | --- |
| `name` | Sun, Moon, Mercury, Venus, Mars, Jupiter, Saturn, Uranus, Neptune, Pluto (cũng là `id`) |
| `longitude` | Vị trí trên vòng hoàng đạo, 0–360° |
| `sign` | Tên cung chứa nó ("Libra"...) |
| `signIndex` | Số thứ tự cung, 0 = Bạch Dương … 11 = Song Ngư |
| `degreeInSign` | Độ trong cung, 0–30° |
| `normalized` | `longitude/360`, để đưa vào vector |

### `AstroNatalContext`: nhà và góc của bản đồ gốc (chỉ khi đủ dữ liệu)

| Trường | Là gì |
| --- | --- |
| `birthUTC` | Giờ sinh đổi sang UTC |
| `houseSystem` | Cách chia nhà (`AstroHouseSystem`, hiện chỉ `.porphyry`) |
| `angles` | 4 góc bản đồ (`AstroAngles`) |
| `houseCusps` | 12 đỉnh nhà (\[`AstroHouseCusp`\]) |
| `planetHouses` | Hành tinh nào ở nhà mấy, ví dụ `["Sun": 10]` |
| `precision` | Dữ liệu sinh đầy đủ tới đâu (`AstroBirthDataPrecision`) |
| `isLocalTimeAmbiguous` | `true` nếu giờ địa phương mơ hồ (đổi giờ DST), kết quả có thể lệch 1 giờ |

### `AstroAngles`: 4 góc, đều là kinh độ hoàng đạo

| Trường | Là gì |
| --- | --- |
| `ascendant` | ASC, cung mọc: vẻ ngoài, đầu nhà 1 |
| `descendant` | DSC, đối ASC: các mối quan hệ, đầu nhà 7 |
| `midheaven` | MC, thiên đỉnh: sự nghiệp, đầu nhà 10 |
| `imumCoeli` | IC, đối MC: gốc rễ gia đình, đầu nhà 4 |

### `AstroHouseCusp`: đỉnh một nhà

| Trường | Là gì |
| --- | --- |
| `house` | Số nhà 1–12 |
| `longitude` | Nơi nhà đó bắt đầu trên vòng hoàng đạo |

### Hai enum đi kèm

- **`AstroHouseSystem`:** `.porphyry` (chia 4 phần tư giữa ASC, MC, DSC, IC thành 3 nhà đều nhau). Là enum để sau này thêm hệ khác mà không vỡ cache.
- **`AstroBirthDataPrecision`:** `.dateOnly` (chỉ ngày: Noon Chart, không nhà), `.timeWithoutLocation` (có giờ, thiếu nơi: không nhà), `.complete` (đủ: có ASC/MC/nhà).

---

## ⑤ So sánh hôm nay với bản đồ gốc

**NHẬN:** `AstroBirthInput` + `AstroNatalSnapshot` + ngày hôm nay **LÀM:**

1. Tính `AstroPlanetaryChart` của **hôm nay** (transit).
2. Tìm góc chiếu giữa hành tinh transit và hành tinh natal.
3. Nếu có ASC/MC thì tìm thêm góc chiếu lên các góc.
4. Chấm điểm, tìm nhà bị kích hoạt, tính khí chất bản mệnh.
5. Ghép thành vector 32 số.

**RA:** `AstroVectorResult` → bên trong có `AstroFeatureMetadata` (cái mà bước sau lấy). Các struct tạo nên nó:

### `AstroAspectType` (enum): loại góc chiếu

`conjunction` 0° Trùng tụ · `sextile` 60° Lục hợp · `square` 90° Vuông góc · `trine` 120° Tam hợp · `opposition` 180° Đối đỉnh.

### `AstroAspectNature` (enum): tính chất năng lượng

`tension` (Vuông, Đối: căng thẳng) · `harmony` (Tam hợp, Lục hợp: thuận lợi) · `neutral` (Trùng tụ: khuếch đại, tốt hay xấu tùy hành tinh).

### `AstroAspectDefinition`: "luật" của một loại góc (cấu hình cho engine)

| Trường | Là gì |
| --- | --- |
| `type` | Loại góc |
| `symbol` | Ký hiệu ☌ ⚹ □ △ ☍ |
| `nameVi` | Tên Việt |
| `targetAngle` | Góc lý tưởng (0/60/90/120/180) |
| `maxOrb` | Sai số tối đa vẫn tính là có góc, thường 5–8° |
| `nature` | Bản chất (`AstroAspectNature`) |
| `baseWeight` | Trọng số gốc (Trùng/Vuông 1.0, Lục hợp 0.7) |

### `DetectedAstroAspect`: một góc đã tìm thấy giữa transit và natal

| Trường | Là gì |
| --- | --- |
| `transitPlanet` | Hành tinh hôm nay ("Moon") |
| `natalPlanet` | Hành tinh lúc sinh ("Sun") |
| `type`, `symbol`, `nameVi` | Loại, ký hiệu, tên Việt |
| `targetAngle` | Góc lý thuyết |
| `actualAngle` | Góc thực đo |
| `orb` | Độ lệch \` |
| `weight` | Sức nặng cuối, đã tính orb và độ quan trọng hành tinh |
| `nature` | Căng thẳng/hài hòa/trung tính |

### `AstroAngleAspect`: góc giữa hành tinh transit và **góc bản đồ**

| Trường | Là gì |
| --- | --- |
| `transitPlanet` | Hành tinh hôm nay |
| `angle` | Góc bị chạm ("ASC", "MC"...) |
| `type`, `nameVi`, `orb`, `weight`, `nature` | Như trên |

### `AstroAspectAnalysis`: kết quả tìm góc (bước trung gian)

| Trường | Là gì |
| --- | --- |
| `aspects` | Mọi góc tìm thấy |
| `topAspect` | Góc `weight` lớn nhất, "sự kiện" của ngày |
| `tensionScore` | 0–1, từ Vuông + Đối |
| `harmonyScore` | 0–1, từ Tam hợp + Lục hợp |
| `conjunctionIntensity` | 0–1, từ Trùng tụ |
| `fastPlanetActivity` | 0–1, mức tham gia của Sun, Moon, Mercury, Venus, Mars |

### `ActivatedHouseScore`: một nhà đang bị kích hoạt

| Trường | Là gì |
| --- | --- |
| `house` | Số nhà 1–12 |
| `score` | Điểm kích hoạt |
| `topicVi` | Chủ đề ("Sự nghiệp"...) |

### `AstroDailyContext`: bối cảnh riêng của hôm nay (cần bản đồ gốc có nhà)

| Trường | Là gì |
| --- | --- |
| `transitHouses` | Hôm nay mỗi hành tinh đang đi qua nhà mấy trong bản đồ của bạn |
| `angleAspects` | \[`AstroAngleAspect`\] chạm vào ASC/MC |
| `activatedHouses` | \[`ActivatedHouseScore`\] các nhà nổi bật |

### Khí chất bản mệnh (tính từ 10 hành tinh natal)

- **`AstroElement`** (enum): `fire` Lửa · `earth` Đất · `air` Khí · `water` Nước.
- **`AstroModality`** (enum): `cardinal` Tiên phong · `fixed` Kiên định · `mutable` Linh hoạt. Mỗi cung thuộc đúng 1 nguyên tố và 1 tính chất.
- **`ZodiacQuality`**: ghép một nguyên tố + một tính chất của một cung (`element`, `modality`). Có định nghĩa nhưng code bạn gửi chưa dùng trực tiếp.
- **`TemperamentBalance`**: tỷ lệ 0–1 các hành tinh nằm ở từng nhóm: `fire, earth, air, water` (cộng lại ≈ 1) và `cardinal, fixed, mutable` (cộng lại ≈ 1).
- **`AstroTemperamentMetadata`**: `balance` (cục trên) + `dominantElement` (tên Việt nguyên tố cao nhất, "Lửa") + `dominantModality` ("Kiên định").

### `AstroScoreMetadata`: 4 điểm số 0–1

`tension` (căng thẳng) · `harmony` (hài hòa) · `conjunction` (hội tụ) · `fastPlanetActivity` (hành tinh nhanh).

### `AstroDominantSignal` (enum): nhãn tóm tắt của ngày

`tension` (cẩn trọng) · `harmony` (thuận lợi) · `conjunction` (dồn sức một trọng tâm) · `balanced` (giữ nhịp thường ngày).

### `AstroFeatureMetadata`: **"hồ sơ chiêm tinh hôm nay" (cục chính của bước này)**

| Trường | Là gì |
| --- | --- |
| `birthDate`, `birthTime` | Ngày/giờ sinh gốc |
| `hasExactTime` | Có giờ chính xác không |
| `confidenceScore` | 1.0 (giờ chính xác) hoặc 0.7 (Noon Chart) |
| `currentDateIso` | Thời điểm phân tích |
| `natalSunSign` | Cung Mặt Trời gốc: bản ngã |
| `natalMoonSign` | Cung Mặt Trăng gốc: cảm xúc |
| `transitMoonSign` | Cung Mặt Trăng hôm nay: tâm trạng ngày |
| `temperament` | `AstroTemperamentMetadata` |
| `topAspect` | `DetectedAstroAspect?` nổi bật nhất |
| `totalAspectsCount` | Tổng số góc |
| `scores` | `AstroScoreMetadata` |
| `dominantSignal` | `AstroDominantSignal` |
| `vibeSummary` | Câu tóm tắt do engine viết sẵn |
| `birthDataPrecision?` | `AstroBirthDataPrecision` |
| `natalContext?` | `AstroNatalContext` |
| `dailyContext?` | `AstroDailyContext` |

Ba trường cuối là optional để bản lưu đời cũ vẫn đọc được.

### `AstroVectorResult`: vỏ bọc ngoài

| Trường | Là gì |
| --- | --- |
| `vector` | 32 số 0–1: `[0]` tin cậy · `[1–10]` natal · `[11–20]` transit · `[21–24]` Lửa/Đất/Khí/Nước · `[25–27]` Tiên phong/Kiên định/Linh hoạt · `[28–31]` 4 điểm số |
| `metadata` | `AstroFeatureMetadata` ở trên |
| `float32Values` | `vector` dạng `[Float]` cho tính khoảng cách cosine |

Luồng lá thăm chỉ lấy `.metadata`, không dùng `vector`.

---

## ⑥ Lấy lời khuyên cũ

**NHẬN:** `date` + `profile` **LÀM:** duyệt lùi 1…7 ngày, mỗi ngày thử khóa v4 → v3 → v2, lấy `advice` của lá thăm đầu tiên giải mã được, cắt 500 ký tự, bỏ trùng không phân biệt hoa thường. **RA:** `[String]`, tối đa 7 lời khuyên. Mục đích: gửi cho AI để nó không lặp lại.

---

## ⑦ Đóng gói gửi server

**NHẬN:** `AstroFeatureMetadata` + `AnchorCaDao` + `[String]` lời khuyên cũ + `userContext` **LÀM:** `makeRequest` rút gọn thành câu chữ và điểm số, bỏ mọi dữ liệu cá nhân thô. **RA:**

### `AstroFortuneRequest` (định nghĩa ở file khác; trường suy từ code)

| Trường | Lấy từ đâu |
| --- | --- |
| `caDaoSample` | `anchor.content` |
| `caDaoCategory` | `anchor.category`, mặc định "Dân gian" |
| `astroSummary` | `metadata.vibeSummary` |
| `metadata` | `AstroFortuneRequestMetadata` bên dưới |
| `recentAdvice` | `[String]` bước ⑥ (nil nếu rỗng, tối đa 7) |
| `userContext` | Ghi chú người dùng |

### `AstroFortuneRequestMetadata`

| Trường | Lấy từ đâu |
| --- | --- |
| `tensionScore`, `harmonyScore`, `conjunctionScore` | `scores.*` |
| `dominantSignal` | `metadata.dominantSignal` |
| `dominantElements` | \[nguyên tố trội, tính chất trội\] |
| `highlights` | Câu chữ: góc nổi bật (`"Sun Tam hợp Moon (120°, orb 1.2°)"`), "Mặt Trời gốc X, Mặt Trăng hôm nay Y", "Nhà N – chủ đề đang được kích hoạt" |
| `birthDataPrecision` | Mức dữ liệu sinh |
| `houseSystem` | Hệ nhà |
| `ascendantSign`, `midheavenSign` | Đổi kinh độ ASC/MC thành **tên cung** |
| `planetHouses` | Hành tinh nào ở nhà mấy |
| `activatedHouses` | Các nhà nổi bật |
| `angleHighlights` | 3 góc đầu chạm ASC/MC, dạng câu |

Không có trong gói: tên, ngày giờ sinh, tọa độ.

---

## ⑧ Gọi server AI

**NHẬN:** `AstroFortuneRequest` + token đăng nhập (Supabase, nếu có) **LÀM:** POST JSON tới `AppConfig.astroFortuneURL`, header `Authorization: Bearer <token>`. Mã HTTP không phải 2xx thì ném lỗi. **RA:**

### `AstroFortuneResponse` (định nghĩa ở file khác; trường suy từ code)

| Trường | Là gì |
| --- | --- |
| `success` | Server báo thành công hay không |
| `fortune` | Nội dung: `title`, `verse`, `mirror`, `advice` |
| `error` | Thông báo lỗi nếu có |

### `ClientError` (enum): các lỗi ở bước này

| Case | Khi nào |
| --- | --- |
| `invalidResponse` | Không phải HTTP, hoặc thiếu `success`/`fortune` |
| `server(statusCode, message)` | HTTP lỗi; ưu tiên `message` từ server |

---

## ⑨ Hoàn thiện lá thăm → ⑩ Lưu cache

**NHẬN:** nội dung AI (title, verse, mirror, advice) + `AnchorCaDao` thật + `AstroFeatureMetadata` **LÀM:** gắn thêm ca dao thật và dữ liệu sao (vì `requestFortune` chỉ gán ca dao mặc định), rồi `save` theo khóa ngày + hồ sơ (`try?`, lỗi ghi không chặn). **RA:**

### `AstroFortuneSlip`: **OUTPUT cuối của cả tính năng**

| Trường | Là gì |
| --- | --- |
| `title` | Tên quẻ (nil được) |
| `verse` | Thơ 4 câu phán vận thế |
| `mirror` | "Gương soi": phản chiếu tâm lý |
| `advice` | "Kế sách": hành động cụ thể (cũng là thứ được lấy làm lời khuyên cũ ở bước ⑥ những ngày sau) |
| `anchorCaDao` | Ca dao đã dùng (`AnchorCaDao`) |
| `astroMetadata` | `AstroFeatureMetadata?` của ngày đó |

---

## Phụ lục: các "service" nối các bước

| Service | Struct/enum |
| --- | --- |
| `AstrologyClient` | Struct chứa 3 hàm: `generateVector` (ra `AstroVectorResult`), `natalContext` (ra `AstroNatalContext?`), `dailyFortune` (cả luồng ①→⑩). Có 3 bản: `liveValue` thật, `testValue` rỗng, `previewValue` trả lá thăm mẫu |
| `AstrologyFortuneCache` | Actor lưu `AstroFortuneSlip` và `AstroNatalSnapshot` trong `UserDefaults`, và cung cấp `recentAdvice` |
| `AstrologyCacheKey` | Tạo khóa cache và fingerprint (FNV-1a trên UTF-16 cho khớp bản JavaScript cũ) |
| `AstroBirthInput` → `AstrologyEngine` | Engine ở file khác, nhận dữ liệu sinh và ngày để tính hành tinh, nhà, góc chiếu |