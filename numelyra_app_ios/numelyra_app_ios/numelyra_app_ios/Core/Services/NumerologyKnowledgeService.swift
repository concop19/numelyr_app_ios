import Foundation
import SQLite3

/// Dịch vụ tra cứu Luận giải Tri thức 24 Chỉ số Thần số học hoàn toàn Offline từ SQLite (`cadao.db`),
/// kèm bộ từ điển Archetype & Cycle tích hợp sẵn làm tầng dự phòng.
/// Tương ứng với `src/services/numerologyKnowledge.ts` trong dự án React Native.
public nonisolated enum NumerologyKnowledgeService {

    public struct ArchetypeEntry: Equatable, Sendable {
        public let title: String
        public let overview: String
        public let strengths: [String]
        public let challenges: [String]
        public let advice: String
    }

    // MARK: - Từ điển Archetype 1–9, 10, 11, 22, 33 chuẩn trường phái Pythagoras

    public static let archetypeMap: [Int: ArchetypeEntry] = [
        1: ArchetypeEntry(
            title: "Nhà Lãnh Đạo Tiên Phong",
            overview: "Năng lượng khởi nguyên của sự độc lập, quyết đoán, ý chí sắt đá và bản lĩnh tự thân khai mở những con đường mới.",
            strengths: [
                "Độc lập và tự chủ vượt trội",
                "Khả năng khởi xướng và ra quyết định dứt khoát",
                "Tư duy tiên phong, sáng tạo nguyên bản"
            ],
            challenges: [
                "Dễ rơi vào độc đoán hoặc thiếu kiên nhẫn",
                "Khó thỏa hiệp hoặc khó lắng nghe ý kiến người khác",
                "Xu hướng ôm đồm một mình"
            ],
            advice: "Rèn luyện sự khiêm nhường và học cách dẫn dắt bằng cảm hứng thay vì áp đặt quyền uy. Sức mạnh vĩ đại nhất của người lãnh đạo là nâng đỡ người khác."
        ),
        2: ArchetypeEntry(
            title: "Sứ Giả Hòa Bình & Trực Giác",
            overview: "Năng lượng dịu êm của sự thấu cảm, khả năng kết nối, lắng nghe sâu sắc và cân bằng mọi mối quan hệ xung quanh.",
            strengths: [
                "Trực giác nhạy bén, đồng cảm tinh tế",
                "Năng khiếu ngoại giao, hòa giải bất hòa",
                "Khả năng lắng nghe chân thành và xây dựng niềm tin"
            ],
            challenges: [
                "Dễ nhạy cảm thái quá trước lời phán xét",
                "Xu hướng né tránh xung đột dẫn đến kìm nén cảm xúc",
                "Dễ phụ thuộc vào tâm trạng người khác"
            ],
            advice: "Thiết lập ranh giới cảm xúc lành mạnh và tin tưởng vào tiếng nói nội tâm của chính bạn. Hòa hợp không có nghĩa là đánh mất chính mình."
        ),
        3: ArchetypeEntry(
            title: "Nghệ Sĩ Biểu Đạt & Sáng Tạo",
            overview: "Năng lượng rạng rỡ của niềm vui sống, trí tưởng tượng phong phú, tài hoa ngôn từ và khả năng lan tỏa cảm hứng tích cực.",
            strengths: [
                "Lạc quan tự nhiên, thu hút và truyền cảm hứng",
                "Khả năng biểu đạt xuất sắc qua lời nói, câu chữ hoặc nghệ thuật",
                "Tâm hồn phong phú, hòa đồng"
            ],
            challenges: [
                "Dễ phân tán năng lượng vào quá nhiều thứ cùng lúc",
                "Khó kiên trì hoàn thành mục tiêu dài hạn",
                "Đôi khi trốn tránh nỗi buồn bằng sự vui vẻ bề nổi"
            ],
            advice: "Neo giữ những tia sáng sáng tạo vào kỷ luật hành động mỗi ngày. Hãy dám đối diện với chiều sâu nội tâm để tác phẩm và cuộc sống thêm sâu sắc."
        ),
        4: ArchetypeEntry(
            title: "Người Xây Dựng & Kỷ Luật",
            overview: "Năng lượng vững chãi của đất mẹ, sự kiên định, kỷ luật thép, tư duy tổ chức hệ thống và trách nhiệm tuyệt đối.",
            strengths: [
                "Kỷ luật vững vàng, tỉ mỉ, cực kỳ đáng tin cậy",
                "Tư duy logic, quản trị hệ thống và thực thi bài bản",
                "Kiên trì bền bỉ vượt nghịch cảnh"
            ],
            challenges: [
                "Cứng nhắc, khó thích ứng trước thay đổi bất ngờ",
                "Đôi khi quá thận trọng hoặc nghi ngờ cái mới",
                "Dễ làm việc kiệt sức vì trách nhiệm"
            ],
            advice: "Đón nhận sự linh hoạt như một phần tự nhiên của dòng chảy cuộc sống. Hãy cho phép bản thân nghỉ ngơi và tận hưởng thành quả."
        ),
        5: ArchetypeEntry(
            title: "Nhà Thám Hiểm Tự Do",
            overview: "Năng lượng năng động của sự bứt phá, khao khát tự do, thích nghi nhanh nhạy và lòng dũng cảm bước ra khỏi vùng an toàn.",
            strengths: [
                "Thích ứng phi thường trong mọi hoàn cảnh mới",
                "Khát khao phiêu lưu, khám phá thế giới và học hỏi đa chiều",
                "Năng lượng đổi mới, lan tỏa sức sống"
            ],
            challenges: [
                "Dễ bồn chồn, chóng chán khi mọi thứ lặp lại",
                "Sợ sự ràng buộc lâu dài, dễ phân tán cam kết",
                "Thiếu kiên nhẫn khi phải làm việc tiểu tiết"
            ],
            advice: "Tự do đích thực đến từ sự làm chủ bản thân; hãy tìm kiếm tự do trong mục đích thay vì chỉ trốn chạy cam kết."
        ),
        6: ArchetypeEntry(
            title: "Người Nuôi Dưỡng & Tình Yêu Vô Điều Kiện",
            overview: "Năng lượng ấm áp của tình mẫu tử/phụ tử, trách nhiệm gia đình, sự chăm sóc, chữa lành và tạo dựng mái ấm bình an.",
            strengths: [
                "Tình yêu thương sâu sắc, hướng về gia đình và cộng đồng",
                "Trách nhiệm cao, gu thẩm mỹ tinh tế và khả năng bao bọc",
                "Tài năng chữa lành và hòa giải"
            ],
            challenges: [
                "Dễ can thiệp quá sâu hoặc kiểm soát người thân",
                "Hay hy sinh quên mình dẫn đến kiệt sức và oán trách ngầm",
                "Khó buông bỏ lo âu"
            ],
            advice: "Yêu thương bản thân là điều kiện tiên quyết để chăm sóc người khác trọn vẹn. Hãy cho người thân không gian để họ tự trưởng thành."
        ),
        7: ArchetypeEntry(
            title: "Nhà Hiền Triết & Khai Phóng Tri Thức",
            overview: "Năng lượng sâu sắc của tư duy triết học, trực giác tâm linh, hành trình tìm kiếm chân lý tối thượng và sự tĩnh lặng nội tại.",
            strengths: [
                "Tư duy phân tích sắc bén, nhìn thấu bản chất vấn đề",
                "Trực giác tâm linh sâu sắc, độc lập và tinh tế",
                "Khát khao học hỏi và đúc kết tri thức gốc"
            ],
            challenges: [
                "Khép kín, hoài nghi, khó mở lòng chia sẻ cảm xúc",
                "Dễ cảm thấy cô đơn hoặc xa cách với thực tại",
                "Có xu hướng phán xét khi người khác không hiểu mình"
            ],
            advice: "Kết hợp tri thức trí tuệ với sự kết nối con người. Đừng để hành trình tìm kiếm biến thành ốc đảo cô độc; hãy chia sẻ ánh sáng hiểu biết cho đời."
        ),
        8: ArchetypeEntry(
            title: "Nhà Kiến Tạo Thịnh Vượng & Quyền Lực",
            overview: "Năng lượng uy quyền của vật chất, tư duy chiến lược, khả năng điều hành vĩ mô và sự cân bằng nhân quả trong kinh tế.",
            strengths: [
                "Tầm nhìn chiến lược lớn, tài năng kinh doanh và điều hành",
                "Lực hút thịnh vượng và năng lượng dồi dào",
                "Công bằng, kiên cường và khí chất tự tin"
            ],
            challenges: [
                "Dễ bị cuốn vào chủ nghĩa vật chất hoặc áp lực danh tiếng",
                "Khắc nghiệt với bản thân và người dưới quyền",
                "Sợ mất kiểm soát"
            ],
            advice: "Sức mạnh và tài chính là phương tiện phụng sự; khi bạn tạo ra giá trị bền vững cho cộng đồng, sự thịnh vượng tự khắc sẽ theo sau."
        ),
        9: ArchetypeEntry(
            title: "Nhà Nhân Đạo Bác Ái & Trí Huệ",
            overview: "Năng lượng bao dung của lòng vị tha toàn nhân loại, sự giác ngộ, tấm lòng phụng sự vô vị lợi và tinh thần buông bỏ.",
            strengths: [
                "Tấm lòng vị tha, bao dung và trách nhiệm xã hội cao",
                "Tầm nhìn rộng mở, trực giác tâm linh trưởng thành",
                "Khả năng truyền cảm hứng và nâng đỡ"
            ],
            challenges: [
                "Dễ thất vọng trước thực tế trần tục không như lý tưởng",
                "Khó buông bỏ quá khứ hoặc những tổn thương cũ",
                "Đôi khi thiếu thực tế trong tài chính"
            ],
            advice: "Cống hiến với tâm thế an nhiên; chấp nhận sự không hoàn hảo như một phần của hành trình tiến hóa."
        ),
        10: ArchetypeEntry(
            title: "Nhà Lãnh Đạo Đa Tài & Thích Ứng (Số 10)",
            overview: "Sự kết hợp giữa ngọn lửa độc lập (1) và tiềm năng vô hạn (0), sở hữu tính linh hoạt cao, dũng cảm và thu hút.",
            strengths: [
                "Thích ứng phi thường, đa tài và dũng cảm",
                "Dễ thành công trong nhiều lĩnh vực khác nhau",
                "Phong thái tự tin, cuốn hút"
            ],
            challenges: [
                "Dễ tự mãn hoặc dao động khi gặp thất bại nhỏ",
                "Cần tránh phân tán tài năng vào quá nhiều hướng"
            ],
            advice: "Tập trung năng lượng vào lĩnh vực bạn đam mê nhất; sự nhất quán sẽ biến tài năng thành di sản bền vững."
        ),
        11: ArchetypeEntry(
            title: "Bậc Thầy Trực Giác & Soi Sáng (Master 11)",
            overview: "Con số bậc thầy sở hữu tần số trực giác thần bí phi thường, chiếc cầu nối giữa thế giới ý niệm và thực tại trần gian.",
            strengths: [
                "Trực giác thần bí siêu nhạy, khả năng thức tỉnh người khác",
                "Tầm nhìn đi trước thời đại, tâm hồn nhạy cảm tinh khôi",
                "Khả năng thắp sáng hy vọng"
            ],
            challenges: [
                "Năng lượng quá tải dễ gây căng thẳng thần kinh",
                "Dao động giữa nghi ngờ bản thân và gánh nặng sứ mệnh lớn",
                "Cảm giác lạc lõng"
            ],
            advice: "Giữ vững sự cân bằng thân-tâm-trí qua thiền định và lối sống gần gũi thiên nhiên; bạn là sứ giả mang ánh sáng cho những người tìm đường."
        ),
        22: ArchetypeEntry(
            title: "Bậc Thầy Kiến Thiết Thế Giới (Master 22/4)",
            overview: "Con số bậc thầy quyền năng nhất, biến những lý tưởng vĩ đại thành các công trình thực tế phụng sự nhân loại.",
            strengths: [
                "Biến lý tưởng vĩ đại thành hiện thực cụ thể",
                "Tầm nhìn không giới hạn kết hợp kỷ luật phi thường",
                "Khả năng lãnh đạo các dự án mang tính di sản"
            ],
            challenges: [
                "Áp lực khổng lồ từ kỳ vọng bản thân",
                "Sợ thất bại khi gánh vác trách nhiệm lớn",
                "Dễ kiệt sức nếu không phân quyền"
            ],
            advice: "Xây dựng từng viên gạch với sự nhẫn nại; di sản vĩ đại nhất được tạo nên từ sự kiên định mỗi ngày."
        ),
        33: ArchetypeEntry(
            title: "Bậc Thầy Nâng Đỡ & Tình Yêu Phổ Quát (Master 33/6)",
            overview: "Con số bậc thầy của tình thương vị tha cao quý nhất, mang sứ mệnh chữa lành và nâng đỡ tâm hồn con người.",
            strengths: [
                "Tình yêu thương vô điều kiện ở tầng thứ cao nhất",
                "Khả năng chữa lành, dẫn dắt tâm linh và truyền dạy",
                "Hiện thân của lòng tận tụy"
            ],
            challenges: [
                "Gánh nặng cảm xúc của tha nhân đè nặng",
                "Dễ kiệt quệ nếu không biết tự bảo vệ năng lượng cá nhân"
            ],
            advice: "Soi sáng bằng chính sự an lạc nội tại của bạn; hãy là ngọn hải đăng bình yên, đừng gánh thay số phận của người khác."
        )
    ]

    // MARK: - Luận giải cho Năm Cá Nhân (Personal Year 1..9)

    public static let personalYearData: [Int: ArchetypeEntry] = [
        1: ArchetypeEntry(
            title: "Năm Số 1: Khởi Đầu & Tiên Phong",
            overview: "Năm mở đầu cho chu kỳ 9 năm mới. Thời điểm vàng để gieo hạt giống, bắt đầu dự án mới, tự tin bứt phá.",
            strengths: [
                "Ý chí mạnh mẽ, nhiều năng lượng tươi mới",
                "Cơ hội khởi nghiệp, học kỹ năng mới, đổi mới hướng đi"
            ],
            challenges: [
                "Đòi hỏi tự lập, đôi lúc cảm thấy đơn độc"
            ],
            advice: "Dám hành động độc lập, chủ động nắm bắt cơ hội, đừng chần chừ do dự."
        ),
        2: ArchetypeEntry(
            title: "Năm Số 2: Hợp Tác & Kiên Nhẫn",
            overview: "Giai đoạn nuôi dưỡng hạt giống trong tĩnh lặng. Tăng cường hợp tác, chăm sóc các mối quan hệ và lắng nghe trực giác.",
            strengths: [
                "Trực giác nhạy cảm, dễ hòa giải và kết nối đối tác",
                "Bình an nội tâm, cảm xúc sâu lắng"
            ],
            challenges: [
                "Tiến độ công việc có thể chậm lại, cần kiên nhẫn"
            ],
            advice: "Lấy nhu thắng cương, học cách hợp tác chân thành và lắng nghe người đồng hành."
        ),
        3: ArchetypeEntry(
            title: "Năm Số 3: Mở Rộng & Sáng Tạo",
            overview: "Năm nở hoa của trí tưởng tượng và giao tiếp. Thời điểm lý tưởng để kết nối xã hội, học hỏi, lan tỏa hình ảnh cá nhân.",
            strengths: [
                "Năng lượng lạc quan, nhiều ý tưởng đột phá",
                "Giao lưu mở rộng, cơ hội kết nối cộng đồng"
            ],
            challenges: [
                "Dễ tiêu xài phân tán hoặc mất tập trung"
            ],
            advice: "Tận dụng tài năng biểu đạt và sáng tạo, nhưng hãy giữ vững kỷ luật tài chính."
        ),
        4: ArchetypeEntry(
            title: "Năm Số 4: Củng Cố & Kỷ Luật",
            overview: "Năm đặt nền móng vững chắc. Trọng tâm là làm việc chăm chỉ, tổ chức lại công việc, củng cố sức khỏe và tài chính.",
            strengths: [
                "Tư duy thực tế, tính kỷ luật cao",
                "Xây dựng quy trình bài bản, tiết kiệm tích lũy tốt"
            ],
            challenges: [
                "Áp lực công việc nhiều, cảm giác gò bó"
            ],
            advice: "Kiên trì từng bước một, chăm sóc cơ thể vật lý và không nên đầu tư mạo hiểm."
        ),
        5: ArchetypeEntry(
            title: "Năm Số 5: Thay Đổi & Tự Do",
            overview: "Năm giữa chu kỳ mang theo luồng gió mới của sự chuyển dịch, du lịch, bứt phá giới hạn và mở ra cơ hội bất ngờ.",
            strengths: [
                "Thích ứng nhanh, nhiều trải nghiệm phiêu lưu",
                "Cơ hội chuyển mình ngoạn mục"
            ],
            challenges: [
                "Biến động bất ngờ, dễ bồn chồn mất phương hướng"
            ],
            advice: "Linh hoạt đón nhận đổi mới, biến sự thay đổi thành bàn đạp phát triển."
        ),
        6: ArchetypeEntry(
            title: "Năm Số 6: Gia Đình & Phụng Sự",
            overview: "Năm của tình yêu thương, chăm sóc gia đình, tổ ấm, chữa lành các mối quan hệ và phụng sự cộng đồng.",
            strengths: [
                "Tình cảm gia đình gắn kết, tổ ấm an yên",
                "Khả năng chữa lành và nâng đỡ người thân"
            ],
            challenges: [
                "Gánh nặng trách nhiệm gia đình, dễ lo âu thái quá"
            ],
            advice: "Dành thời gian cho những người thân yêu, làm đẹp không gian sống và học cách lắng nghe."
        ),
        7: ArchetypeEntry(
            title: "Năm Số 7: Chiêm Nghiệm & Tri Thức",
            overview: "Năm của nội tâm sâu sắc. Thời điểm tuyệt vời để học tập chuyên sâu, tu dưỡng tinh thần và nhìn lại bản thân.",
            strengths: [
                "Trí tuệ phát triển vượt bậc, thấu hiểu quy luật",
                "Trực giác tâm linh sâu sắc"
            ],
            challenges: [
                "Không thuận lợi cho đầu tư lớn bề ngoài, cần tĩnh lặng"
            ],
            advice: "Đầu tư cho trí tuệ và sự an lạc nội tại; lắng nghe chính mình trước khi quyết định."
        ),
        8: ArchetypeEntry(
            title: "Năm Số 8: Thu Hoạch & Thịnh Vượng",
            overview: "Năm gặt hái thành quả của chu kỳ 9 năm. Cơ hội lớn về tài chính, quyền lực cá nhân, sự nghiệp thăng hoa.",
            strengths: [
                "Khả năng thu hút tài chính và thành tựu lớn",
                "Uy tín và năng lực điều hành vượt trội"
            ],
            challenges: [
                "Cần minh bạch tài chính và thận trọng pháp lý"
            ],
            advice: "Hành động quyết đoán, quản lý dòng tiền bài bản và chia sẻ giá trị cho mọi người."
        ),
        9: ArchetypeEntry(
            title: "Năm Số 9: Hoàn Tất & Tái Sinh",
            overview: "Năm khép lại một chu kỳ 9 năm. Buông bỏ những điều không còn phù hợp, tha thứ, bao dung và chuẩn bị bước sang trang mới.",
            strengths: [
                "Tấm lòng bác ái rộng mở, thanh lọc tâm hồn",
                "Hoàn tất trọn vẹn các mục tiêu lớn"
            ],
            challenges: [
                "Cảm giác chia tay, buông bỏ những điều quen thuộc"
            ],
            advice: "Bao dung tha thứ, dọn dẹp không gian sống và tâm trí để đón nhận chu kỳ rực rỡ tiếp theo."
        )
    ]

    // MARK: - Tra cứu Luận giải

    /// Tra cứu luận giải cho 1 chỉ số từ SQLite `numerology_knowledge` (với fallback sang Archetype).
    public static func getIndicatorReading(
        key: NumerologyIndicatorKey,
        value: NumerologyValue,
        cardNameVi: String,
        customDBPath: String? = nil
    ) -> KnowledgeReading {
        getIndicatorReading(
            indicatorKey: key.rawValue,
            indicatorValue: value.displayValue,
            cardNameVi: cardNameVi,
            customDBPath: customDBPath
        )
    }

    /// Tra cứu luận giải cho 1 chỉ số bằng chuỗi `indicatorKey` và `indicatorValue`.
    public static func getIndicatorReading(
        indicatorKey: String,
        indicatorValue: String,
        cardNameVi: String,
        customDBPath: String? = nil
    ) -> KnowledgeReading {
        let valStr = indicatorValue.trimmingCharacters(in: .whitespacesAndNewlines)

        // 1. Tra cứu trực tiếp từ bảng SQLite `numerology_knowledge` trong `cadao.db`
        if let dbResult = queryDatabase(
            indicatorKey: indicatorKey,
            rawValue: valStr,
            customDBPath: customDBPath
        ) {
            let fallbackTitle = dbResult.title.isEmpty ? "\(cardNameVi) \(valStr)" : dbResult.title
            return parseKnowledgeMarkdown(content: dbResult.content, titleFallback: fallbackTitle)
        }

        // 2. Fallback cho Năm Cá Nhân (`yearIndividual`)
        let parsedInt = extractLeadingInt(from: valStr)
        if indicatorKey == NumerologyIndicatorKey.yearIndividual.rawValue,
           let numVal = parsedInt,
           let yearData = personalYearData[numVal]
        {
            let fullText = """
            \(yearData.overview)

            **Điểm sáng năng lượng:**
            \(yearData.strengths.map { "- \($0)" }.joined(separator: "\n"))

            **Thách thức:**
            \(yearData.challenges.map { "- \($0)" }.joined(separator: "\n"))

            **Lời khuyên:** \(yearData.advice)
            """
            return KnowledgeReading(
                title: "\(cardNameVi): \(yearData.title)",
                source: .offlineArchetype,
                overview: yearData.overview,
                strengths: yearData.strengths,
                challenges: yearData.challenges,
                advice: yearData.advice,
                fullContent: fullText
            )
        }

        // 3. Fallback cho các chỉ số con số (1–9, 10, 11, 22, 33)
        let targetNum = parsedInt ?? 1
        let reducedMod = (targetNum % 9 == 0) ? 9 : (targetNum % 9)
        let arch = archetypeMap[targetNum] ?? archetypeMap[reducedMod] ?? archetypeMap[1]!

        let fullText = """
        \(arch.overview)

        **Điểm mạnh cốt lõi:**
        \(arch.strengths.map { "- \($0)" }.joined(separator: "\n"))

        **Vùng bóng tối cần lưu ý:**
        \(arch.challenges.map { "- \($0)" }.joined(separator: "\n"))

        **Lời khuyên chuyển hóa:** \(arch.advice)
        """

        return KnowledgeReading(
            title: "\(cardNameVi) \(valStr): \(arch.title)",
            source: .offlineArchetype,
            overview: arch.overview,
            strengths: arch.strengths,
            challenges: arch.challenges,
            advice: arch.advice,
            fullContent: fullText
        )
    }

    // MARK: - SQLite Query & Value Normalization

    private static func queryDatabase(
        indicatorKey: String,
        rawValue: String,
        customDBPath: String?
    ) -> (title: String, content: String)? {
        guard let db = CaDaoDatabaseService.openDatabase(customPath: customDBPath) else {
            return nil
        }
        defer { sqlite3_close(db) }

        let candidates = candidateValues(for: indicatorKey, rawValue: rawValue)
        let sql = "SELECT title, content FROM numerology_knowledge WHERE indicator_key = ? AND number_value = ? LIMIT 1;"

        for candidate in candidates {
            var stmt: OpaquePointer?
            guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
                continue
            }
            sqlite3_bind_text(stmt, 1, (indicatorKey as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 2, (candidate as NSString).utf8String, -1, nil)

            if sqlite3_step(stmt) == SQLITE_ROW {
                let title = sqlite3_column_text(stmt, 0).map { String(cString: $0) } ?? ""
                let content = sqlite3_column_text(stmt, 1).map { String(cString: $0) } ?? ""
                sqlite3_finalize(stmt)
                if !content.isEmpty {
                    return (title, content)
                }
            } else {
                sqlite3_finalize(stmt)
            }
        }
        return nil
    }

    /// Sinh danh sách các khóa `number_value` ứng viên để khớp chính xác với dữ liệu 212 bài trong `numerology_knowledge`.
    public static func candidateValues(for indicatorKey: String, rawValue: String) -> [String] {
        var candidates: [String] = []
        if !rawValue.isEmpty {
            candidates.append(rawValue)
        }

        switch indicatorKey {
        case NumerologyIndicatorKey.walksOfLife.rawValue:
            if rawValue == "22" { candidates.append("22/4") }
            if rawValue == "33" { candidates.append("33/6") }

        case NumerologyIndicatorKey.nameChart.rawValue,
             NumerologyIndicatorKey.birthChart.rawValue:
            candidates.append("matrix")

        case NumerologyIndicatorKey.arrows.rawValue:
            let knownArrows = ["1-2-3", "1-4-7", "1-5-9", "2-5-8", "3-5-7", "3-6-9", "4-5-6", "7-8-9"]
            for arrow in knownArrows where rawValue.contains(arrow) {
                candidates.append(arrow)
            }

        case NumerologyIndicatorKey.karmicDebts.rawValue:
            let knownDebts = ["13/4", "14/5", "16/7", "19/1"]
            for debt in knownDebts where rawValue.contains(debt) {
                candidates.append(debt)
            }

        default:
            break
        }

        // Nếu giá trị là danh sách tổng hợp (ví dụ: "3 - 2 - 5 - 10" hoặc "2, 6, 8"), lấy số đầu tiên làm ứng viên
        if let firstInt = extractLeadingInt(from: rawValue) {
            let firstStr = String(firstInt)
            if !candidates.contains(firstStr) {
                candidates.append(firstStr)
            }
        }

        return candidates
    }

    private static func extractLeadingInt(from text: String) -> Int? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        var digits = ""
        for char in trimmed {
            if char.isWholeNumber {
                digits.append(char)
            } else if !digits.isEmpty {
                break
            }
        }
        return Int(digits)
    }

    // MARK: - Markdown Parser

    /// Bóc tách nội dung Markdown thành `KnowledgeReading` có cấu trúc (khớp 100% với `parseKnowledgeMarkdown` trong RN).
    public static func parseKnowledgeMarkdown(content: String, titleFallback: String) -> KnowledgeReading {
        let lines = content.components(separatedBy: .newlines)
        var strengths: [String] = []
        var challenges: [String] = []
        var currentSection = ""
        var overviewText = ""
        var adviceText = ""

        for rawLine in lines {
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            if line.isEmpty { continue }

            if line.hasPrefix("#") || line.contains("BẢN CHẤT") || line.contains("TỔNG QUAN") || line.contains("Ý NGHĨA") {
                currentSection = "overview"
                continue
            } else if line.contains("ĐIỂM MẠNH") || line.contains("ƯU ĐIỂM") || line.contains("NĂNG LỰC") {
                currentSection = "strengths"
                continue
            } else if line.contains("THÁCH THỨC") || line.contains("BÓNG TỐI") || line.contains("CẠM BẪY") || line.contains("ĐIỂM YẾU") {
                currentSection = "challenges"
                continue
            } else if line.contains("LỜI KHUYÊN") || line.contains("HÀNH ĐỘNG") || line.contains("BÀI HỌC") {
                currentSection = "advice"
                continue
            }

            if currentSection == "overview" && overviewText.isEmpty {
                if !line.hasPrefix("#") {
                    overviewText = stripLeadingStars(line)
                }
            } else if currentSection == "strengths" {
                if let bullet = extractBulletItem(line) {
                    strengths.append(bullet)
                }
            } else if currentSection == "challenges" {
                if let bullet = extractBulletItem(line) {
                    challenges.append(bullet)
                }
            } else if currentSection == "advice" && adviceText.isEmpty {
                if !line.hasPrefix("#") {
                    adviceText = stripLeadingStars(line)
                }
            }
        }

        let resolvedOverview: String
        if !overviewText.isEmpty {
            resolvedOverview = overviewText
        } else {
            let prefix = String(content.prefix(260))
            resolvedOverview = prefix + "..."
        }

        let resolvedAdvice = adviceText.isEmpty
            ? "Phát huy điểm mạnh bẩm sinh và giữ vững sự cân bằng nội tại."
            : adviceText

        return KnowledgeReading(
            title: titleFallback,
            source: .supabase,
            overview: resolvedOverview,
            strengths: Array(strengths.prefix(3)),
            challenges: Array(challenges.prefix(2)),
            advice: resolvedAdvice,
            fullContent: content
        )
    }

    private static func stripLeadingStars(_ text: String) -> String {
        var result = text[...]
        while result.first == "*" || result.first == " " {
            result = result.dropFirst()
        }
        return String(result)
    }

    private static func extractBulletItem(_ line: String) -> String? {
        guard line.hasPrefix("-") || line.hasPrefix("*") || line.hasPrefix("•") else {
            return nil
        }
        var dropped = line.dropFirst()
        while dropped.first == "-" || dropped.first == "*" || dropped.first == "•" || dropped.first == " " {
            dropped = dropped.dropFirst()
        }
        let cleaned = String(dropped).trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? nil : cleaned
    }
}
