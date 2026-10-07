# Zi Wei Dou Shu Engine v1/v2

## Phạm vi

Service slice này bổ sung engine Tử Vi Đẩu Số native cho iOS. Đây là **feature expansion** so với React Native: baseline `tuViBaziService.ts` chỉ có ba trụ năm/tháng/ngày và Bát Trạch, chưa lập 12 cung hay an chính tinh.

Các file triển khai:

- `Shared/Models/ZiWei.swift`: model strongly typed, input và metadata ruleset.
- `Core/Services/TuViEngine.swift`: pure deterministic engine.
- `Core/Clients/TuViClient.swift`: TCA dependency boundary.
- `numelyra_app_iosTests/TuViEngineTests.swift`: golden, invariant và boundary tests.

## Ruleset đã khóa

`ZiWeiRuleset.vietnameseDefaultV1`:

- ID: `vn-thai-thu-lang-iztro-default`, version `1`.
- Oracle: `SylarLong/iztro 2.6.1`, commit `2c7ef9be669df7b19d1799f4dce335fed3794f78`.
- Tháng nhuận: ngày 1–15 giữ tháng; từ ngày 16 chuyển sang tháng kế tiếp.
- Giờ Tý muộn `23:00–23:59`: tính sang ngày dân dụng kế tiếp.
- Đầu vào v1 là ngày Dương lịch địa phương, giờ/phút, giới tính và UTC offset.
- Đây là ruleset legacy: UTC offset nơi sinh cũng từng được dùng để xác định ngày Sóc. Chỉ giữ lại để tái lập kết quả đã sinh bằng v1.
- Phạm vi năm engine chấp nhận: `1800...2199`; oracle sweep hiện mới bao phủ `1950...2049`, cần mở rộng trước release.
- Không tự suy đoán giới tính hoặc giờ sinh. Caller phải thu thập dữ liệu hợp lệ.

`ZiWeiRuleset.vietnameseDefaultV2` là mặc định mới:

- Giữ chính sách tháng nhuận và giờ Tý muộn của v1.
- Ngày Dương lịch vẫn được hiểu theo ngày dân dụng tại nơi sinh.
- Ngày Sóc và tháng âm luôn dùng múi giờ lịch Việt Nam UTC+7, không thay đổi theo nơi sinh.
- Cô Thần/Quả Tú dùng category `isolation`; v1 vẫn giữ category serialization cũ nhưng compatibility nhận diện theo tên sao.
- iztro 2.6.1 chỉ là oracle cho phép an sao; các ngày lịch Việt khác lịch Trung Quốc phải dùng golden fixture UTC+7 riêng.

Ruleset và revision oracle được lưu trong mỗi `ZiWeiChart`. Engine chỉ chấp nhận toàn bộ cấu hình ruleset chuẩn, không chỉ so ID/version; thay đổi trường phái phải tạo version mới.

## Hệ tọa độ

Domain model dùng thứ tự Địa Chi `Tý = 0 ... Hợi = 11`.

- Cung Mệnh: `Dần + (tháng âm - 1) - giờ chi`.
- Cung Thân: `Dần + (tháng âm - 1) + giờ chi`.
- Thiên Phủ: `(4 - Tử Vi) mod 12` trong hệ `Tý = 0`.
- Khi đối chiếu iztro, index của iztro bắt đầu từ Dần nên phải dịch `+2` về hệ domain.

## Sao được triển khai

### 14 chính tinh

- Chòm Tử Vi: Tử Vi, Thiên Cơ, Thái Dương, Vũ Khúc, Thiên Đồng, Liêm Trinh.
- Chòm Thiên Phủ: Thiên Phủ, Thái Âm, Tham Lang, Cự Môn, Thiên Tướng, Thiên Lương, Thất Sát, Phá Quân.
- Có độ sáng Miếu/Vượng/Đắc/Lợi/Bình/Bất/Hãm theo ruleset v1.

### 14 phụ tinh nền

- Tả Phù, Hữu Bật, Văn Xương, Văn Khúc, Thiên Khôi, Thiên Việt.
- Lộc Tồn, Thiên Mã.
- Địa Không, Địa Kiếp, Hỏa Tinh, Linh Tinh, Kình Dương, Đà La.

### 6 sao tình duyên

- Đào Hoa, Hồng Loan, Thiên Hỷ, Cô Thần, Quả Tú, Thiên Diêu.

### Tứ Hóa

Hóa Lộc, Hóa Quyền, Hóa Khoa và Hóa Kỵ được gắn trực tiếp lên sao đích theo Can năm âm. Tất cả sao có thể nhận Tứ Hóa trong ruleset v1 đều thuộc tập sao đã triển khai.

## Compatibility

`evaluateLoveCompatibility(chartA:chartB:)` là rule engine có thể giải thích:

- Phân tích chính tinh, duyên tinh, sát tinh, độ sáng và Tứ Hóa tại cung Phu Thê.
- Cô Thần và Quả Tú là tín hiệu thử thách; Thiên Diêu được giải thích trung tính, không mặc định cộng điểm.
- Đối chiếu trực tiếp Mệnh A ↔ Mệnh B và Phu Thê A ↔ Phu Thê B.
- Đối chiếu Mệnh A ↔ Phu Thê B và Mệnh B ↔ Phu Thê A bằng Lục Hợp, Tam Hợp và Lục Xung.
- Hai Chi giống nhau được phân loại Đồng Cung trước khi xét Tam Hợp.
- Từ chối so sánh hai chart khác ruleset hoặc có provenance ruleset không nhất quán.
- Trả từng `ZiWeiCompatibilityContribution`, điểm cộng/trừ và disclaimer.
- Điểm số là heuristic truyền thống, không phải xác suất khoa học hay kết luận định mệnh.

Engine Bát Tự hiện tại là domain riêng (`TuViBaziChart`/`TuViBaziSynastry`) và không bị gộp vào `ZiWeiChart`. Tích hợp báo cáo tổng hợp sẽ được thực hiện tại orchestration layer của Chat sau khi Bát Tự đủ bốn trụ và data profile được sửa.

## Kiểm chứng

Golden chính dùng ngày `2023-03-06`, giờ Thìn, nữ, đối chiếu fixture tiếng Việt của iztro:

- Âm lịch: 15/02/2023, Quý Mão.
- Mệnh tại Hợi, Thân tại Mùi, Thủy Nhị Cục.
- Tử Vi và Thiên Phủ đồng cung tại Thân.
- Tứ Hóa Quý: Phá Quân Lộc, Cự Môn Quyền, Thái Âm Khoa, Tham Lang Kỵ.

Invariants:

- 12 cung và 12 địa chi duy nhất.
- 14 chính tinh, mỗi sao đúng một lần.
- 34 sao trong scope v1, mỗi sao đúng một lần.
- Biên Tý muộn, tháng nhuận ngày 15/16, tách múi giờ nơi sinh/lịch Việt, input invalid và tính đối xứng của compatibility.
- Exhaustive contract cho enum Cục/Tứ Hóa; hồi quy Đồng Cung, Cô Thần/Quả Tú, Thiên Diêu và ruleset mismatch.

## Ngoài phạm vi v1

- Đại hạn, tiểu hạn, lưu niên/tháng/ngày/giờ.
- Toàn bộ 38 tạp diệu còn lại và các vòng Tràng Sinh/Bác Sĩ/Thái Tuế.
- Chân thái dương theo kinh độ nơi sinh.
- UI lá số 12 cung, persistence/cache và đồng bộ cloud.
- Suy luận khi không biết giờ sinh.

Các mục này phải được thêm bằng ruleset/slice mới cùng fixture kiểm chứng, không mở rộng âm thầm v1.
