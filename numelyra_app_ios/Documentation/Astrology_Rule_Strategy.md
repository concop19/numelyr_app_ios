# Hướng xây bộ rule và nâng cấp Astrology

Tài liệu này chốt hướng làm việc để tiếp tục ở một phiên khác. Mục tiêu là chuyển dữ liệu chiêm tinh đã tính thành nội dung có ích cho người dùng, không biến vector hoặc danh sách vị trí hành tinh thành đầu ra cuối cùng.

## 1. Mục tiêu sản phẩm

Người dùng không cần biết một con số kinh độ là bao nhiêu. Họ cần hiểu:

- Điều gì đang được nhấn mạnh trong bản mệnh hoặc ngày hôm nay?
- Điều đó có thể biểu hiện thành trải nghiệm, phản ứng hay lựa chọn nào?
- Họ có thể thử làm gì cụ thể?

Lá thăm hiện có ba phần nội dung khác nhiệm vụ:

- **Ca dao neo:** chất liệu ngôn ngữ, nhịp/vần và sắc thái dân gian để AI dựa vào khi viết thơ.
- **Gương soi (`mirror`):** phản chiếu một khuynh hướng hoặc trải nghiệm để người dùng tự suy ngẫm.
- **Kế sách (`advice`):** gợi ý hành động cụ thể, nhỏ và làm được trong ngày.

Rule chiêm tinh phải quyết định nội dung luận giải. Ca dao chỉ gợi cách diễn đạt, không quyết định ý nghĩa chiêm tinh.

## 2. Kiến trúc cần hướng tới

Tách hệ thống thành các tầng:

1. **Chart facts:** vị trí, cung, nhà, góc, orb, thời điểm và độ chính xác dữ liệu.
2. **Derived features:** khí chất, góc/nhà được kích hoạt, chỉ báo nổi bật, độ mạnh tương đối/tuyệt đối.
3. **Interpretation rules:** ý nghĩa, biểu hiện thuận lợi/thử thách và khuyến nghị ứng dụng.
4. **Synthesis:** chọn và phối hợp một số rule không trùng nhau thành chủ đề có mạch lạc.
5. **AI rendering:** viết tiếng Việt theo giọng sản phẩm, tạo thơ dựa trên ca dao neo, trả `mirror` và `advice`.

Không yêu cầu AI tự suy luận ý nghĩa từ 32 con số. Rule được truy xuất trước; AI diễn đạt từ các kết luận có căn cứ và dữ kiện liên quan.

## 3. Trạng thái Astrology iOS hiện tại

Nguồn để kiểm tra khi tiếp tục:

- Engine: [`AstrologyEngine.swift`](../numelyra_app_ios/numelyra_app_ios/Shared/Engines/AstrologyEngine.swift)
- Models: [`Astrology.swift`](../numelyra_app_ios/numelyra_app_ios/Shared/Models/Astrology.swift)
- API mapping: [`AstrologyClient.swift`](../numelyra_app_ios/numelyra_app_ios/Core/Clients/AstrologyClient.swift)
- Tài liệu hiện có: [`Astrology.md`](Astrology.md)

### Dữ liệu engine đang tính

- Mười hành tinh Sun–Pluto, có kinh độ, cung, chỉ số cung, độ trong cung và kinh độ chuẩn hóa.
- So sánh transit với natal trên năm góc chính: conjunction, sextile, square, trine, opposition.
- Danh sách aspect nội bộ có cặp hành tinh, loại góc, góc thực tế, orb, trọng số và nature.
- Score tổng hợp: tension, harmony, conjunction, fast-planet activity; có `topAspect` và số lượng góc.
- Khí chất là tỷ lệ nguyên tố/tính chất từ mười hành tinh natal, hiện đếm mỗi hành tinh ngang nhau.
- Khi có giờ sinh chính xác và nơi sinh: tính ASC/DC/MC/IC, 12 cusp Porphyry, nhà của hành tinh natal; tính nhà transit, transit tới ASC/MC và tối đa ba activated houses.
- Vector hiện có 32 chiều: confidence, 20 kinh độ natal/transit chuẩn hóa, 7 tỷ lệ nguyên tố/tính chất, 4 aspect scores.

### Ranh giới API hiện tại

- Vector 32 chiều **không được gửi** tới `POST /api/astro/fortune`.
- Engine có danh sách aspect đầy đủ, nhưng metadata/request chỉ giữ chủ yếu `topAspect`, số lượng, score và một số highlights.
- Request có summary/score, nguyên tố/tính chất trội và một phần context nhà/góc. Cần kiểm tra DTO/API mapping trước khi triển khai rule mới.
- Nếu thiếu dữ liệu sinh đủ chính xác, natal/daily house context có thể `nil`.
- Vì vậy vector không phải đầu ra ngữ nghĩa; metadata hiện tại cũng là bản tóm tắt, chưa phải tập chart facts đầy đủ cho rule engine.

### Dữ liệu engine chưa có hoặc còn thiếu

- Aspect natal–natal.
- Applying/separating và thời điểm aspect chính xác/đang mạnh lên hay yếu đi.
- Vận tốc/nghịch hành trong model chart hiện tại.
- Góc transit tới DC/IC riêng (hiện chỉ ASC/MC).
- Chủ tinh nhà/cung, rulership, dignity/condition.
- Mẫu hình nhiều hành tinh như stellium, grand trine, T-square.
- Chỉ báo hoạt động tuyệt đối trong ngày; các score hiện tại chủ yếu là tỷ lệ đã chuẩn hóa.

Chỉ cần bổ sung các dữ kiện trên khi sản phẩm/rule thực sự dùng đến chúng. Không mở rộng calculator chỉ để tăng số trường.

## 4. Các bộ rule cần nghiên cứu

| Bộ rule | Nội dung cần ánh xạ | Dùng được với engine hiện tại? | Ưu tiên |
|---|---|---:|---:|
| Khí bản mệnh | Tỷ lệ 4 nguyên tố/3 tính chất → cách khởi động, duy trì, xử lý cảm xúc/giao tiếp; điểm mạnh, lệch quá mức, cách cân bằng | Có, nhưng cần đánh giá lại phép đếm ngang nhau và cách chọn tín hiệu trội | 1 |
| Hành tinh trong cung | Chức năng hành tinh biểu hiện theo cung; diễn đạt bằng hành vi/trải nghiệm đời thường | Có placements cung của mười hành tinh trong chart nội bộ; API cần gửi placements cần thiết | 1 |
| Hành tinh trong nhà / cusp | Hành tinh nhấn mạnh lĩnh vực nào; dấu hiệu cusp và phong cách tiếp cận lĩnh vực đó | Có khi đủ birth context; API hiện chỉ nhận một phần | 1 |
| Transit–natal aspects | Chủ đề của từng cặp hành tinh; loại góc làm thay đổi cách tương tác; orb/trọng số ảnh hưởng mức ưu tiên | Có danh sách aspect nội bộ; cần giữ danh sách có cấu trúc qua ranh giới API | 1 |
| Transit qua nhà natal | Hành tinh transit đi qua nhà nào, chủ đề đời sống nào đang được chú ý | Có khi đủ birth context; cần dùng transit planet + natal house, không chỉ top house | 1 |
| Transit tới ASC/MC (và sau này DC/IC) | Hành tinh và góc kích hoạt cách thể hiện bản thân, mục tiêu/công việc, quan hệ, nền tảng riêng tư | Có một phần: ASC/MC, orb tối đa 3° | 2 |
| Aspect natal–natal | Các tương tác ổn định trong bản mệnh để làm “khí bản mệnh” có chiều sâu hơn element/modality | Chưa có; phải bổ sung detector trước khi rule hoạt động | 2 |
| Rule tổng hợp | Xếp hạng, gộp chỉ báo cùng chủ đề, xử lý chỉ báo trái chiều, tránh lặp, chọn mirror/advice | Cần thiết ngay từ đầu | 1 |

Không tạo một đoạn văn riêng cho mọi tổ hợp Cartesian. Dùng rule cơ sở theo hành tinh/cung/nhà/aspect và thêm rule cặp quan trọng; engine chọn, xếp hạng, rồi tổng hợp.

## 5. Cấu trúc rule đề xuất

Rule nên lưu dữ liệu có cấu trúc, có thể truy nguyên và nâng phiên bản. Ví dụ schema khởi đầu:

```json
{
  "ruleId": "transit.mars.square.natal.moon",
  "version": 1,
  "domain": "transit_natal_aspect",
  "conditions": {
    "transitPlanet": "Mars",
    "natalPlanet": "Moon",
    "aspectType": "square",
    "orbMax": 3.0
  },
  "priority": 70,
  "themes": ["emotional_reactivity", "assertion"],
  "experience": "Phản ứng cảm xúc có thể nhanh và mạnh hơn thường ngày.",
  "challenge": "Dễ trả lời ngay khi đang bực hoặc thấy bị thúc ép.",
  "supportiveExpression": "Có thể dùng sự quyết đoán để bảo vệ nhu cầu của mình.",
  "advice": "Tạm dừng trước khi trả lời một tin nhắn khiến mình khó chịu.",
  "source": {
    "title": "Nguồn nghiên cứu",
    "author": "Tác giả",
    "url": "https://...",
    "location": "Chương/trang"
  },
  "tradition": "modern_western",
  "license": "verify_before_reuse"
}
```

Các trường nội dung phải được biên tập theo giọng Numelyra, không sao chép văn bản có bản quyền. Rule cần phân biệt điều kiện, chủ đề, cách biểu hiện, lời khuyên, mức ưu tiên, nguồn và trường phái.

## 6. Thứ tự triển khai đề xuất

### Giai đoạn A — xác định rule và đầu vào có sẵn

- Chốt taxonomy/field names ổn định cho chart facts.
- Ghi rõ source/version: tropical zodiac, house system Porphyry, độ chính xác giờ sinh, engine version.
- Điều chỉnh API mapping để có thể truyền placements và toàn bộ aspect cần thiết ở dạng có nhãn; không dùng vector làm cách duy nhất truyền ngữ cảnh.
- Tính các feature tối thiểu để tách cường độ hoạt động tuyệt đối khỏi tỷ lệ tension/harmony.

### Giai đoạn B — bộ rule v1 dùng được

- Khí bản mệnh.
- Hành tinh trong cung/nhà và cusp/ASC/MC.
- Transit–natal aspect.
- Transit qua nhà natal và transit tới góc.
- Tổng hợp, xếp hạng, gộp ý và chuyển thành `mirror`/`advice`.

### Giai đoạn C — mở rộng sau nghiên cứu

- Natal–natal aspect.
- Applying/separating, retrograde/speed, house rulers/dignities và aspect patterns.
- Thêm rule chỉ khi engine đã xuất dữ kiện tương ứng.

## 7. Yêu cầu cho Gemini Deep Research

Kết quả nghiên cứu cần:

- Đề xuất rule theo từng bộ ở mục 4, không gom mọi thứ thành bài viết chung về astrology.
- Với mỗi bộ, liệt kê dữ kiện cần có, taxonomy, điều kiện/range, cách chấm mức ưu tiên và ví dụ rule.
- Phân biệt trường phái và các chỗ không có đồng thuận; không coi diễn giải chiêm tinh là kết luận khoa học đã được xác nhận.
- Ưu tiên sách/tài liệu gốc hoặc nguồn chuyên môn có thể truy nguyên; ghi tác giả, link, chương/trang và giấy phép nếu có.
- Không chép nguyên văn nguồn có bản quyền; tổng hợp bằng lời mới.
- Đánh dấu mỗi rule là: dùng được với output hiện tại, cần bổ sung chart fact, hoặc cần quyết định sản phẩm.
- Đề xuất rule v1 nhỏ nhưng tạo được lời luận và hành động cụ thể cho người dùng; không chạy theo số lượng rule.

## 8. Prompt sẵn để chuyển sang Gemini Deep Research

> Nghiên cứu sâu các rule diễn giải chiêm tinh phương Tây để xây một database có cấu trúc cho ứng dụng iOS. Mục tiêu sản phẩm là biến chart facts thành trải nghiệm người dùng có ích: “điều gì đang được nhấn mạnh, có thể biểu hiện thế nào, và người dùng có thể thử làm gì”; không chỉ trả về tên hành tinh/góc/số liệu.
>
> Các nhóm cần nghiên cứu: (1) khí bản mệnh từ 4 nguyên tố và 3 tính chất; (2) hành tinh trong cung; (3) hành tinh trong nhà và dấu hiệu trên cusp/ASC/MC; (4) transit–natal aspects theo cặp hành tinh, loại góc và orb; (5) transit qua nhà natal; (6) transit tới ASC/MC; (7) quy tắc tổng hợp nhiều chỉ báo, ưu tiên, mâu thuẫn và tránh lặp. Phân tích riêng natal–natal aspects như phần mở rộng, vì calculator hiện chưa tính chúng.
>
> Output calculator hiện tại: 10 hành tinh natal và transit có longitude/sign/degreeInSign; 5 major aspects transit–natal có pair/type/actualAngle/orb/weight/nature; tỷ lệ nguyên tố/modality đếm ngang 10 hành tinh natal; Porphyry angles/cusps, natal/transit planet houses, activated houses tối đa 3 và transit aspects tới ASC/MC khi birth time/location đủ chính xác. Không có applying/separating, retrograde/speed, natal–natal aspects, rulership/dignity, aspect patterns hay transit-to-DC/IC riêng. Vector 32 chiều không được gửi tới fortune API; client hiện chỉ gửi summary, score và một phần metadata/highlights.
>
> Với mỗi nhóm, hãy cung cấp: schema/điều kiện rule, các chủ đề người dùng cảm nhận được, biểu hiện thuận lợi và thử thách, lời khuyên cụ thể, cách chấm trọng số/độ ưu tiên, ví dụ rule đầy đủ, dữ kiện calculator cần có, khác biệt giữa các trường phái, và nguồn có thể kiểm chứng. Tách rõ đâu là kiến thức phổ biến trong một trường phái, đâu là khác biệt/tranh luận, đâu là suy luận. Dẫn link trực tiếp và tác giả/chương/trang; ghi rõ giấy phép/quyền sử dụng nếu nội dung có thể được tái sử dụng. Không sao chép văn bản có bản quyền. Kết thúc bằng đề xuất rule v1 khả thi theo output calculator hiện có và danh sách calculator/API cần nâng cấp cho các rule còn lại.

## 9. Repo tham khảo về cách tổ chức, không phải nguồn để chép nội dung

- [astrology-skill](https://github.com/wvanderen/astrology-skill): tham khảo module theo placement/aspect và quy trình retrieval → rank → synthesize; không xem là kho bao phủ mọi trường hợp.
- [RoxyAPI natal-chart-api](https://github.com/RoxyAPI/natal-chart-api): tham khảo cấu trúc output có placements, houses, aspects và interpretation summary; API thương mại, không suy diễn rằng content DB công khai.
- [OpAstro](https://github.com/dakidarts/opastro): tham khảo factor provenance/giải thích vì sao một yếu tố được chọn; phần public tự mô tả là bộ nội dung gọn.
- [recursive.eco-schemas](https://github.com/PlayfulProcess/recursive.eco-schemas): tham khảo biểu diễn mục nghĩa cơ sở và mục ghép (`composite_of`).

Các repo này giúp học kiến trúc và format; nội dung chiêm tinh cần nghiên cứu nguồn, ghi xuất xứ và biên tập riêng cho Numelyra.

## 10. Tổng hợp nghiên cứu kiến trúc rule

Tài liệu nghiên cứu bổ sung được lưu trong ngữ cảnh phiên làm việc với tiêu đề “Kiến Trúc Hệ Thống Rule Diễn Giải Chiêm Tinh Phương Tây Cho Ứng Dụng iOS”. Phần này chắt lọc các ý phù hợp với hướng sản phẩm và trạng thái engine hiện tại. Các ngưỡng, công thức trọng số và kỹ thuật thuộc trường phái cần được kiểm chứng theo nguồn gốc trước khi đưa vào rule hoạt động.

### Nguyên tắc diễn giải và provenance

- Phân loại từng rule theo `epistemicTier`: `CONV` (quy ước phổ biến trong một phạm vi xác định), `DOCT` (quan điểm của trường phái/tác giả) hoặc `INFR` (quyết định kỹ thuật của hệ thống). Không trình bày `DOCT` hay `INFR` như sự thật khoa học đã được xác nhận.
- Gắn rule với `schoolProfile`/`tradition`, nguồn có thể truy nguyên (tác giả, tác phẩm, chương/trang hoặc URL), phiên bản và trạng thái quyền sử dụng. Nội dung hiển thị phải được biên tập mới, không sao chép đoạn diễn giải từ nguồn.
- Tách rõ vai trò biểu tượng: hành tinh là chức năng/tác nhân, cung là cách biểu hiện, nhà là lĩnh vực đời sống. Đây là taxonomy diễn giải; lựa chọn hệ nhà và trường phái phải được lưu thành metadata, không được ngầm đổi cách tính chart.
- Dùng ngôn ngữ phi tất định, tránh phán quyết gây lo âu hoặc chẩn đoán. Ưu tiên mô tả khả năng/khuynh hướng, câu hỏi tự soi chiếu và hành động nhỏ người dùng tự chọn.

### Schema rule và chấm điểm

Mở rộng schema khởi đầu ở mục 5 theo hướng có thể truy nguyên và tổng hợp:

```json
{
  "ruleId": "transit.mars.square.natal.moon",
  "version": 1,
  "domain": "transit_natal_aspect",
  "epistemicTier": "DOCT",
  "schoolProfile": "modern_psychological",
  "conditions": {"transitPlanet": "Mars", "natalPlanet": "Moon", "aspectType": "square", "orbMax": 3.0},
  "priority": 70,
  "themes": ["emotional_reactivity", "assertion"],
  "experience": "Phản ứng cảm xúc có thể nhanh và mạnh hơn thường ngày.",
  "challenge": "Có thể muốn trả lời ngay khi đang bực hoặc thấy bị thúc ép.",
  "supportiveExpression": "Sự quyết đoán có thể giúp nhận ra và bảo vệ nhu cầu của mình.",
  "advice": "Tạm dừng một nhịp trước khi trả lời tin nhắn khiến mình khó chịu.",
  "source": {"title": "Nguồn cần xác minh", "author": "", "url": "", "location": ""},
  "licenseStatus": "verify_before_reuse"
}
```

Điểm rule nên tách `priority` biên tập khỏi điểm kích hoạt theo chart. Điểm kích hoạt có thể kết hợp độ khớp điều kiện, orb/độ mạnh do engine cung cấp, độ tin cậy dữ liệu và mức trùng lặp chủ đề. Hệ số theo hành tinh, sect, dignity, nhà góc, applying/separating hoặc dispositor chỉ được dùng khi profile đã yêu cầu và chart facts tương ứng đã được kiểm chứng; không lấy các hệ số ví dụ trong nghiên cứu làm chuẩn mặc định.

### Các quyết định theo từng bộ rule

- **Khí bản mệnh:** nghiên cứu nêu hai hướng khác nhau: cân bằng nguyên tố/tính chất theo chiêm tinh tâm lý hiện đại và temperament cổ điển dựa trên phẩm chất nóng/lạnh/ẩm/khô cùng nhiều đầu vào như ASC, chủ tinh ASC, mùa, pha Mặt Trăng và sect. V1 nên bắt đầu với phương pháp hiện đại trên dữ liệu placements sẵn có, đánh giá lại trọng số hành tinh thay vì đếm ngang nhau. Không kích hoạt mô hình humoral của Lilly khi chưa có đủ chart facts và chưa chốt profile cổ điển.
- **Hành tinh trong cung/nhà:** giữ riêng ý nghĩa cung và nhà. Có thể xếp hạng tín hiệu theo chức năng hành tinh, prominence và độ tin cậy dữ liệu, nhưng dignity, sect, planetary joys, almuten và dispositor chain là phần mở rộng theo trường phái, không phải điều kiện tiên quyết cho rule placement v1.
- **Transit–natal aspects:** giữ danh sách có cấu trúc qua API. Orb và aspect type là đầu vào trực tiếp; applying/separating và các trạng thái truyền thống như reception/bonification/maltreatment chỉ dùng sau khi engine xuất chúng và profile tương ứng được chọn.
- **Natal–natal aspects:** vẫn là mở rộng sau v1 như mục 4, vì engine hiện chưa tính. Nghiên cứu cung cấp các phân loại truyền thống và góc phụ; chỉ thêm góc/điều kiện khi xác định được nguồn, cách tính và nhu cầu sản phẩm.
- **Transit qua nhà và tới góc:** dùng house system và độ tin cậy giờ sinh thực tế do engine báo. Các chính sách Whole Sign/Placidus, cusp crossing, MC “trôi nổi” và ngưỡng giờ sinh/vĩ độ là lựa chọn phương pháp cần quyết định riêng; không tự áp dụng ngưỡng sai số 10 phút hoặc vĩ độ 60° như quy tắc phổ quát.
- **Transit arc:** gom nhiều lần chạm, stations và cửa sổ orb thành `TransitArc` là hướng mở rộng có ích cho trải nghiệm theo tuần/tháng, nhưng cần ephemeris theo thời gian và sản phẩm hỗ trợ nội dung dài hạn. V1 tiếp tục dùng các transit facts hiện có.

### Tổng hợp và xử lý tín hiệu trái chiều

Synthesis nên gom rule theo `themes`, loại các diễn giải trùng lặp, rồi chọn một số chủ đề phù hợp với độ mạnh và độ tin cậy dữ liệu. Tín hiệu trái chiều có thể được diễn đạt như hai nhu cầu cùng tồn tại thay vì loại bỏ một phía. Giới hạn tối đa ba chủ đề là một lựa chọn thiết kế hữu ích để thử nghiệm, không phải định luật diễn giải.

“Rule of Three”, sect light, chart ruler, almuten và dispositor topology có thể làm yếu tố tăng độ ưu tiên trong một profile cụ thể. Không nên yêu cầu một chủ đề phải xuất hiện ở đúng ba chỉ báo mới được nói tới: ngưỡng cứng đó có thể loại bỏ tín hiệu đơn lẻ nhưng mạnh hoặc làm thiên lệch kết quả theo lượng rule đã viết. Trước mắt, dùng số tín hiệu hội tụ như bằng chứng bổ trợ, đồng thời lưu `matchedRuleIds` để giải thích vì sao chủ đề được chọn.

Mỗi chủ đề tổng hợp cần hỗ trợ ba đầu ra có mục đích riêng: phản chiếu trải nghiệm (`mirror`), hành động nhỏ có thể thử (`advice`), và các căn cứ/rule IDs nội bộ để truy nguyên. Ca dao neo chỉ điều khiển cách tạo thơ, không thay thế căn cứ của luận giải.

### Các mục cần nghiên cứu hoặc quyết định trước khi triển khai

- Chọn có cung cấp nhiều `schoolProfile` hay không; nếu có, công khai profile và không trộn âm thầm hệ nhà, orb policy hoặc quy tắc truyền thống.
- Xác minh nguồn sơ cấp, phiên bản, vị trí trích dẫn và quyền sử dụng. Một URL trong tài liệu nghiên cứu chưa tự nó xác nhận độ tin cậy hoặc giấy phép tái sử dụng.
- Chốt taxonomy ổn định cho chart facts, provenance/version của engine, zodiac và house system trước khi mở rộng DTO/API.
- Chỉ bổ sung vận tốc, retrograde, applying/separating, natal–natal aspects, dignity, rulers, aspect patterns hoặc transit arcs khi có bộ rule đã chọn thực sự tiêu thụ các dữ kiện đó.
- Hiệu chỉnh scoring và giới hạn số chủ đề bằng đánh giá sản phẩm trên các chart mẫu; mọi con số khởi đầu là `INFR`, cần được ghi phiên bản và xem lại.

### Trạng thái catalog v1

- Profile đã chọn: `modern_psychological`; giữ tropical zodiac, Porphyry và `astrology-v3-porphyry-1`.
- JSON catalog có 489 rule components: 24 temperament, 120 planet–sign, 120 natal planet–house, 100 directed transit–natal planet pairs, 5 aspect modifiers và 120 transit–house.
- Các component dùng payload template, binding và content fragments tiếng Việt chung để hạn chế lặp; ngưỡng temperament là `INFR`. Nguồn có mapping chapter/page range ở mức mục lục tham khảo; entry riêng cho từng diễn giải chưa được xác minh trong bản sách dùng để biên tập.
- Swift model/validator kiểm tra schema, tương thích, độ phủ, references, provenance cho từng content fragment, ngưỡng temperament, điều kiện khớp ID và rule nhà yêu cầu natal context.
- `AstrologyRuleEvaluator` hiện thực hóa trigger cho temperament, natal sign/house, transit–natal aspect và transit–house; rule nhà chỉ chạy với natal precision `.complete`. Aspect pair được nối với aspect modifier, dùng `DetectedAstroAspect.weight` (đã phản ánh orb theo engine) và render template theo loại góc. Evaluator gộp tín hiệu theo topic ID, kết hợp payload các bằng chứng trong cùng topic, rồi trả tối đa ba topic cùng `matchedRuleIds`.
- Profile temperament là quy ước kỹ thuật `INFR`: `mixed_elements`/`mixed_modalities` dùng độ trải max-min ≤ 0.2; `balanced_profile` yêu cầu cả bảy tỷ lệ nguyên tố/tính chất nằm trong [0.1, 0.4]. Đây là trigger vận hành, không phải kết luận khoa học.
- Engine lưu evaluation vào metadata cục bộ. Sheet Giải mã cung cấp mục **Request data mới · xem trước**, hiển thị JSON envelope gồm payload API hiện tại và `ruleContext` rút gọn (catalog ID/schema, tối đa ba topic, rule IDs). Envelope preview không được đưa vào `AstroFortuneRequest` hiện tại và không gọi network. Mỗi content fragment có `contentProvenance` trỏ về tác phẩm/chủ đề và chapter/page range theo mục lục; trang entry riêng chưa được xác minh. Đây là bản đồ provenance biên tập, không phải xác minh học thuật từng diễn giải.
