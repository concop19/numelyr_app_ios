import Foundation

/// Danh mục tĩnh 24 thẻ bài Thần số học Pythagoras, khớp 100% với `NUMEROLOGY_CARDS` trong `src/config/numerologyCards.ts`.
public nonisolated enum NumerologyCardCatalog {
    public static let all: [NumerologyCardDefinition] = [
        NumerologyCardDefinition(
            id: "card_01_walksOfLife",
            number: "01",
            key: NumerologyIndicatorKey.walksOfLife.rawValue,
            nameVi: "Số Đường Đời",
            nameEn: "Life Path",
            category: .core,
            categoryNameVi: "Cốt Lõi",
            assetName: AppAsset.numerologyCard01WalksOfLife.rawValue,
            description: "Chỉ số quan trọng nhất, định hình quỹ đạo cuộc đời, tính cách bẩm sinh và bài học chính bạn cần trải nghiệm."
        ),
        NumerologyCardDefinition(
            id: "card_02_mission",
            number: "02",
            key: NumerologyIndicatorKey.mission.rawValue,
            nameVi: "Số Sứ Mệnh",
            nameEn: "Mission / Destiny",
            category: .core,
            categoryNameVi: "Cốt Lõi",
            assetName: AppAsset.numerologyCard02Mission.rawValue,
            description: "Mục đích tối thượng và dấu ấn di sản mà bạn được sinh ra để cống hiến cho cuộc đời này."
        ),
        NumerologyCardDefinition(
            id: "card_03_soul",
            number: "03",
            key: NumerologyIndicatorKey.soul.rawValue,
            nameVi: "Số Linh Hồn",
            nameEn: "Soul Urge",
            category: .core,
            categoryNameVi: "Cốt Lõi",
            assetName: AppAsset.numerologyCard03Soul.rawValue,
            description: "Khát khao sâu kín nhất trong tâm hồn, động lực nội tại thúc đẩy mọi cảm xúc và lựa chọn cá nhân."
        ),
        NumerologyCardDefinition(
            id: "card_04_personality",
            number: "04",
            key: NumerologyIndicatorKey.personality.rawValue,
            nameVi: "Số Nhân Cách",
            nameEn: "Personality",
            category: .core,
            categoryNameVi: "Cốt Lõi",
            assetName: AppAsset.numerologyCard04Personality.rawValue,
            description: "Chiếc áo phong cách bên ngoài, ấn tượng đầu tiên mà người xung quanh cảm nhận về khí chất của bạn."
        ),
        NumerologyCardDefinition(
            id: "card_05_dateOfBirth",
            number: "05",
            key: NumerologyIndicatorKey.dateOfBirth.rawValue,
            nameVi: "Số Ngày Sinh",
            nameEn: "Birthday Number",
            category: .core,
            categoryNameVi: "Cốt Lõi",
            assetName: AppAsset.numerologyCard05DateOfBirth.rawValue,
            description: "Tài năng thiên bẩm và món quà đặc biệt được vũ trụ ban tặng ngay khi bạn cất tiếng khóc chào đời."
        ),
        NumerologyCardDefinition(
            id: "card_06_mature",
            number: "06",
            key: NumerologyIndicatorKey.mature.rawValue,
            nameVi: "Số Trưởng Thành",
            nameEn: "Maturity Number",
            category: .potential,
            categoryNameVi: "Tiềm Năng",
            assetName: AppAsset.numerologyCard06Mature.rawValue,
            description: "Sức mạnh hợp nhất giữa Đường đời và Sứ mệnh, thăng hoa rực rỡ nhất ở giai đoạn trung niên."
        ),
        NumerologyCardDefinition(
            id: "card_07_balance",
            number: "07",
            key: NumerologyIndicatorKey.balance.rawValue,
            nameVi: "Số Cân Bằng",
            nameEn: "Balance Number",
            category: .potential,
            categoryNameVi: "Tiềm Năng",
            assetName: AppAsset.numerologyCard07Balance.rawValue,
            description: "Điểm tựa tinh thần và phản xạ ứng xử giúp bạn lấy lại bình tĩnh trước những thử thách bất ngờ."
        ),
        NumerologyCardDefinition(
            id: "card_08_rationalThinking",
            number: "08",
            key: NumerologyIndicatorKey.rationalThinking.rawValue,
            nameVi: "Tư Duy Lý Trí",
            nameEn: "Rational Thought",
            category: .potential,
            categoryNameVi: "Tiềm Năng",
            assetName: AppAsset.numerologyCard08RationalThinking.rawValue,
            description: "Phương thức não bộ phân tích thông tin, tư duy logic và đưa ra các quyết định quan trọng."
        ),
        NumerologyCardDefinition(
            id: "card_09_subconsciousPower",
            number: "09",
            key: NumerologyIndicatorKey.subconsciousPower.rawValue,
            nameVi: "Sức Mạnh Tiềm Thức",
            nameEn: "Subconscious Power",
            category: .potential,
            categoryNameVi: "Tiềm Năng",
            assetName: AppAsset.numerologyCard09SubconsciousPower.rawValue,
            description: "Độ nhạy bén trực giác và khả năng bảo vệ bản thân khi đối mặt với khủng hoảng sinh tồn."
        ),
        NumerologyCardDefinition(
            id: "card_10_passion",
            number: "10",
            key: NumerologyIndicatorKey.passion.rawValue,
            nameVi: "Đam Mê Ẩn Giấu",
            nameEn: "Hidden Passion",
            category: .potential,
            categoryNameVi: "Tiềm Năng",
            assetName: AppAsset.numerologyCard10Passion.rawValue,
            description: "Sở thích cháy bỏng và ngọn lửa nội tâm mang lại cho bạn niềm vui thuần khiết không toan tính."
        ),
        NumerologyCardDefinition(
            id: "card_11_attitude",
            number: "11",
            key: NumerologyIndicatorKey.attitude.rawValue,
            nameVi: "Thái Độ Tiếp Cận",
            nameEn: "Attitude / Approach",
            category: .potential,
            categoryNameVi: "Tiềm Năng",
            assetName: AppAsset.numerologyCard11Attitude.rawValue,
            description: "Cách bạn phản ứng tức thời với những trải nghiệm mới mẻ và tình huống hàng ngày."
        ),
        NumerologyCardDefinition(
            id: "card_12_karmicDebts",
            number: "12",
            key: NumerologyIndicatorKey.karmicDebts.rawValue,
            nameVi: "Con Số Nợ Nghiệp",
            nameEn: "Karmic Debts",
            category: .karmic,
            categoryNameVi: "Nghiệp & Cầu Nối",
            assetName: AppAsset.numerologyCard12KarmicDebts.rawValue,
            description: "Những bài học thử thách nghiệp báo (13/4, 14/5, 16/7, 19/1) bạn cần hóa giải để tiến hóa tâm thức."
        ),
        NumerologyCardDefinition(
            id: "card_13_missingNumbers",
            number: "13",
            key: NumerologyIndicatorKey.missingNumbers.rawValue,
            nameVi: "Bài Học Số Thiếu",
            nameEn: "Karmic Lessons",
            category: .karmic,
            categoryNameVi: "Nghiệp & Cầu Nối",
            assetName: AppAsset.numerologyCard13MissingNumbers.rawValue,
            description: "Những phẩm chất năng lượng còn khuyết trong tên họ, là bài tập rèn luyện nâng cấp bản thân."
        ),
        NumerologyCardDefinition(
            id: "card_14_bridgeLifeMission",
            number: "14",
            key: NumerologyIndicatorKey.bridgeLifeMission.rawValue,
            nameVi: "Cầu Nối Đ.Đời - Sứ Mệnh",
            nameEn: "Bridge Life Path - Mission",
            category: .bridge,
            categoryNameVi: "Nghiệp & Cầu Nối",
            assetName: AppAsset.numerologyCard14BridgeLifeMission.rawValue,
            description: "Nhịp cầu hòa giải khoảng cách giữa con người thực tế và lý tưởng cuộc đời của bạn."
        ),
        NumerologyCardDefinition(
            id: "card_15_bridgeSoulPersonality",
            number: "15",
            key: NumerologyIndicatorKey.bridgeSoulPersonality.rawValue,
            nameVi: "Cầu Nối L.Hồn - N.Cách",
            nameEn: "Bridge Soul - Personality",
            category: .bridge,
            categoryNameVi: "Nghiệp & Cầu Nối",
            assetName: AppAsset.numerologyCard15BridgeSoulPersonality.rawValue,
            description: "Sự tương thích giữa nội tâm sâu kín bên trong và diện mạo ứng xử bộc lộ ra ngoài."
        ),
        NumerologyCardDefinition(
            id: "card_16_bridgeMaturityPassion",
            number: "16",
            key: NumerologyIndicatorKey.bridgeMaturityPassion.rawValue,
            nameVi: "Cầu Nối T.Thành - Đ.Mê",
            nameEn: "Bridge Maturity - Passion",
            category: .bridge,
            categoryNameVi: "Nghiệp & Cầu Nối",
            assetName: AppAsset.numerologyCard16BridgeMaturityPassion.rawValue,
            description: "Chìa khóa chuyển hóa sở thích cá nhân thành thành tựu lớn khi bước vào độ chín của đời người."
        ),
        NumerologyCardDefinition(
            id: "card_17_yearIndividual",
            number: "17",
            key: NumerologyIndicatorKey.yearIndividual.rawValue,
            nameVi: "Năm Cá Nhân",
            nameEn: "Personal Year",
            category: .cycle,
            categoryNameVi: "Vận Hạn Chu Kỳ",
            assetName: AppAsset.numerologyCard17YearIndividual.rawValue,
            description: "Dòng chảy năng lượng chủ đạo trong năm hiện tại, báo hiệu cơ hội thuận lợi và điều nên kiêng kỵ."
        ),
        NumerologyCardDefinition(
            id: "card_18_monthIndividual",
            number: "18",
            key: NumerologyIndicatorKey.monthIndividual.rawValue,
            nameVi: "Tháng Cá Nhân",
            nameEn: "Personal Month",
            category: .cycle,
            categoryNameVi: "Vận Hạn Chu Kỳ",
            assetName: AppAsset.numerologyCard18MonthIndividual.rawValue,
            description: "Nhịp điệu biến chuyển năng lượng trong từng tháng giúp bạn lập kế hoạch ngắn hạn chính xác."
        ),
        NumerologyCardDefinition(
            id: "card_19_dayIndividual",
            number: "19",
            key: NumerologyIndicatorKey.dayIndividual.rawValue,
            nameVi: "Ngày Cá Nhân",
            nameEn: "Personal Day",
            category: .cycle,
            categoryNameVi: "Vận Hạn Chu Kỳ",
            assetName: AppAsset.numerologyCard19DayIndividual.rawValue,
            description: "Năng lượng vi mô của ngày hôm nay, chỉ dẫn hành vi và tâm thái thích hợp nhất."
        ),
        NumerologyCardDefinition(
            id: "card_20_way",
            number: "20",
            key: NumerologyIndicatorKey.way.rawValue,
            nameVi: "4 Đỉnh Cao Cuộc Đời",
            nameEn: "4 Pinnacles",
            category: .cycle,
            categoryNameVi: "Vận Hạn Chu Kỳ",
            assetName: AppAsset.numerologyCard20Way.rawValue,
            description: "4 giai đoạn trưởng thành lớn và những đỉnh cao thành tựu tương ứng theo từng chu kỳ 9 năm."
        ),
        NumerologyCardDefinition(
            id: "card_21_challenges",
            number: "21",
            key: NumerologyIndicatorKey.challenges.rawValue,
            nameVi: "4 Thách Thức Cuộc Đời",
            nameEn: "4 Challenges",
            category: .cycle,
            categoryNameVi: "Vận Hạn Chu Kỳ",
            assetName: AppAsset.numerologyCard21Challenges.rawValue,
            description: "4 bài học chướng ngại đi kèm với 4 đỉnh cao, rèn luyện bạn trở thành phiên bản kiên cường."
        ),
        NumerologyCardDefinition(
            id: "card_22_arrows",
            number: "22",
            key: NumerologyIndicatorKey.arrows.rawValue,
            nameVi: "8 Mũi Tên Cá Tính 3x3",
            nameEn: "Arrows of Individuality",
            category: .chart,
            categoryNameVi: "Biểu Đồ Ma Trận",
            assetName: AppAsset.numerologyCard22Arrows.rawValue,
            description: "Các trục sức mạnh hoặc mũi tên trống thể hiện ưu thế và điểm yếu cốt tử trong biểu đồ ngày sinh."
        ),
        NumerologyCardDefinition(
            id: "card_23_nameChart",
            number: "23",
            key: NumerologyIndicatorKey.nameChart.rawValue,
            nameVi: "Biểu Đồ Tên & Tần Suất",
            nameEn: "Name Chart Matrix",
            category: .chart,
            categoryNameVi: "Biểu Đồ Ma Trận",
            assetName: AppAsset.numerologyCard23NameChart.rawValue,
            description: "Ma trận phân bổ chữ cái của tên họ, chỉ ra năng lượng dồi dào hoặc bài học còn thiếu."
        ),
        NumerologyCardDefinition(
            id: "card_24_birthChart",
            number: "24",
            key: NumerologyIndicatorKey.birthChart.rawValue,
            nameVi: "Biểu Đồ Ngày Sinh 3x3",
            nameEn: "Birth Chart Matrix",
            category: .chart,
            categoryNameVi: "Biểu Đồ Ma Trận",
            assetName: AppAsset.numerologyCard24BirthChart.rawValue,
            description: "Bản đồ căn nguyên Pythagoras thể hiện 3 tầng: Thể chất (1-4-7), Cảm xúc (2-5-8), và Trí tuệ (3-6-9)."
        )
    ]

    public static func definition(for key: NumerologyIndicatorKey) -> NumerologyCardDefinition? {
        all.first { $0.key == key.rawValue }
    }

    public static func definition(forKey rawKey: String) -> NumerologyCardDefinition? {
        all.first { $0.key == rawKey }
    }
}
