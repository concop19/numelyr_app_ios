import Foundation

/// 4 nguyên tố chiêm tinh học phương Tây (Classical Astrology Elements).
public nonisolated enum AstroElement: String, Codable, CaseIterable, Equatable, Sendable {
    /// Nguyên tố Lửa (Aries, Leo, Sagittarius) — đại diện cho nhiệt huyết, trực giác, năng lượng hành động và đam mê.
    case fire
    /// Nguyên tố Đất (Taurus, Virgo, Capricorn) — đại diện cho tính thực tế, kiên nhẫn, ổn định, vật chất và kỷ luật.
    case earth
    /// Nguyên tố Khí (Gemini, Libra, Aquarius) — đại diện cho trí tuệ, tư duy trừu tượng, giao tiếp xã hội và kết nối.
    case air
    /// Nguyên tố Nước (Cancer, Scorpio, Pisces) — đại diện cho cảm xúc, trực giác tâm linh, thấu cảm và đời sống nội tâm.
    case water
}

/// 3 tính chất / phương thức biểu đạt hoàng đạo (Astrological Modalities).
public nonisolated enum AstroModality: String, Codable, CaseIterable, Equatable, Sendable {
    /// Tính chất Tiên phong (Aries, Cancer, Libra, Capricorn) — khởi xướng, bắt đầu, dẫn dắt, tạo động lực đột phá.
    case cardinal
    /// Tính chất Kiên định (Taurus, Leo, Scorpio, Aquarius) — duy trì, bảo tồn, kiên định, ổn định và tập trung sâu.
    case fixed
    /// Tính chất Linh hoạt (Gemini, Virgo, Sagittarius, Pisces) — thích nghi, biến chuyển, đa năng, xử lý chuyển tiếp.
    case mutable
}

/// Phẩm chất hoàng đạo kết hợp giữa một Nguyên tố (Element) và một Tính chất (Modality).
public nonisolated struct ZodiacQuality: Codable, Equatable, Sendable {
    /// Nguyên tố hoàng đạo tương ứng (Lửa, Đất, Khí, Nước).
    public var element: AstroElement
    /// Tính chất hoàng đạo tương ứng (Tiên phong, Kiên định, Linh hoạt).
    public var modality: AstroModality

    public init(element: AstroElement, modality: AstroModality) {
        self.element = element
        self.modality = modality
    }
}

/// Tỷ lệ cân bằng 4 nguyên tố và 3 tính chất trong bản mệnh (Natal Temperament Balance).
/// Tất cả các trường là tỷ lệ số thực chuẩn hóa trong khoảng [0.0, 1.0], tính từ 10 hành tinh bản mệnh.
public nonisolated struct TemperamentBalance: Codable, Equatable, Sendable {
    /// Tỷ lệ các hành tinh nằm ở các cung Lửa (Aries, Leo, Sagittarius) [0.0 - 1.0].
    public var fire: Double
    /// Tỷ lệ các hành tinh nằm ở các cung Đất (Taurus, Virgo, Capricorn) [0.0 - 1.0].
    public var earth: Double
    /// Tỷ lệ các hành tinh nằm ở các cung Khí (Gemini, Libra, Aquarius) [0.0 - 1.0].
    public var air: Double
    /// Tỷ lệ các hành tinh nằm ở các cung Nước (Cancer, Scorpio, Pisces) [0.0 - 1.0].
    public var water: Double
    /// Tỷ lệ các hành tinh nằm ở các cung Tiên phong (Cardinal) [0.0 - 1.0].
    public var cardinal: Double
    /// Tỷ lệ các hành tinh nằm ở các cung Kiên định (Fixed) [0.0 - 1.0].
    public var fixed: Double
    /// Tỷ lệ các hành tinh nằm ở các cung Linh hoạt (Mutable) [0.0 - 1.0].
    public var mutable: Double

    public init(
        fire: Double,
        earth: Double,
        air: Double,
        water: Double,
        cardinal: Double,
        fixed: Double,
        mutable: Double
    ) {
        self.fire = fire
        self.earth = earth
        self.air = air
        self.water = water
        self.cardinal = cardinal
        self.fixed = fixed
        self.mutable = mutable
    }
}

/// Tọa độ vị trí hoàng đạo của một thiên thể / hành tinh tại thời điểm khảo sát.
public nonisolated struct AstroPlanetPosition: Identifiable, Codable, Equatable, Sendable {
    /// Định danh duy nhất của hành tinh (dùng tên hành tinh làm ID).
    public var id: String { name }
    /// Tên hành tinh tiếng Anh chuẩn (Sun, Moon, Mercury, Venus, Mars, Jupiter, Saturn, Uranus, Neptune, Pluto).
    public var name: String
    /// Tọa độ kinh độ hoàng đạo tuyệt đối trên vòng tròn thiên cầu, tính theo độ từ 0.0° đến 360.0° (0° = điểm Xuân Phân).
    public var longitude: Double
    /// Tên cung hoàng đạo chứa hành tinh (ví dụ: "Aries", "Taurus", "Gemini", ...).
    public var sign: String
    /// Chỉ số thứ tự cung hoàng đạo (0 = Aries/Bạch Dương, 11 = Pisces/Song Ngư).
    public var signIndex: Int
    /// Độ góc của hành tinh trong phạm vi cung hoàng đạo đó (từ 0.0° đến 30.0°).
    public var degreeInSign: Double
    /// Tọa độ hoàng đạo đã được chuẩn hóa về dải số thực [0.0, 1.0] (tính bằng `longitude / 360.0`).
    public var normalized: Double

    public init(
        name: String,
        longitude: Double,
        sign: String,
        signIndex: Int,
        degreeInSign: Double,
        normalized: Double
    ) {
        self.name = name
        self.longitude = longitude
        self.sign = sign
        self.signIndex = signIndex
        self.degreeInSign = degreeInSign
        self.normalized = normalized
    }
}

/// Biểu đồ tọa độ 10 hành tinh tại một thời điểm xác định (dùng cho Natal Chart hoặc Transit Chart).
public nonisolated struct AstroPlanetaryChart: Codable, Equatable, Sendable {
    /// Thời điểm (ngày giờ UTC) tính toán biểu đồ hành tinh.
    public var targetDate: Date
    /// Đánh dấu giờ sinh có phải là ước lượng hay không (true nếu dùng Noon Chart 12:00:00 UTC do thiếu giờ sinh).
    public var isTimeEstimated: Bool
    /// Bảng từ điển tra cứu nhanh vị trí các hành tinh theo tên (key ví dụ: "Sun", "Moon", ...).
    /// // Tọa độ vị trí hoàng đạo của một thiên thể / hành tinh tại thời điểm khảo sát.
    public var planets: [String: AstroPlanetPosition]
    /// Danh sách tuần tự 10 hành tinh để duyệt lặp và tính toán phân bổ thống kê.
    public var planetList: [AstroPlanetPosition]

    public init(
        targetDate: Date,
        isTimeEstimated: Bool,
        planets: [String: AstroPlanetPosition] = [:],
        planetList: [AstroPlanetPosition] = []
    ) {
        self.targetDate = targetDate
        self.isTimeEstimated = isTimeEstimated
        self.planets = planets
        self.planetList = planetList
    }
}

/// Loại góc chiếu chính (Major Aspects) giữa hai thiên thể trong chiêm tinh học.
public nonisolated enum AstroAspectType: String, Codable, CaseIterable, Equatable, Sendable {
    /// Trùng tụ (0° ± orb) — 2 hành tinh hội tụ tại cùng vị trí, kích hoạt và khuếch đại mạnh mẽ năng lượng của nhau.
    case conjunction
    /// Lục hợp (60° ± orb) — góc hỗ trợ nhẹ nhàng, mang lại cơ hội mở và sự hợp tác thuận lợi.
    case sextile
    /// Vuông góc (90° ± orb) — góc ma sát, thử thách, áp lực nội tâm hoặc ngoại cảnh buộc phải hành động bứt phá.
    case square
    /// Tam hợp (120° ± orb) — góc may mắn, dòng chảy năng lượng hài hòa tự nhiên, tài năng và thuận lợi.
    case trine
    /// Đối đỉnh (180° ± orb) — góc đối kháng trực diện, căng thẳng phân cực hai đầu, đòi hỏi cân bằng và dung hòa.
    case opposition
}

/// Bản chất năng lượng của góc chiếu.
public nonisolated enum AstroAspectNature: String, Codable, CaseIterable, Equatable, Sendable {
    /// Năng lượng căng thẳng, xung đột, thử thách (Vuông góc, Đối đỉnh).
    case tension
    /// Năng lượng hài hòa, thuận lợi, bổ trợ (Tam hợp, Lục hợp).
    case harmony
    /// Năng lượng trung tính / hội tụ đặc biệt (Trùng tụ — phụ thuộc vào tính chất của 2 hành tinh kết hợp).
    case neutral
}

/// Định nghĩa quy chuẩn và thông số kỹ thuật của một loại góc chiếu chiêm tinh.
public nonisolated struct AstroAspectDefinition: Codable, Equatable, Sendable {
    /// Loại góc chiếu (Trùng tụ, Lục hợp, Vuông góc, Tam hợp, Đối đỉnh).
    public var type: AstroAspectType
    /// Ký hiệu thiên văn của góc chiếu (ví dụ: ☌, ⚹, □, △, ☍).
    public var symbol: String
    /// Tên tiếng Việt của góc chiếu ("Trùng tụ", "Lục hợp", "Vuông góc", "Tam hợp", "Đối đỉnh").
    public var nameVi: String
    /// Góc góc chiếu lý tưởng tính theo độ (0°, 60°, 90°, 120°, 180°).
    public var targetAngle: Double
    /// Sai số góc tối đa cho phép (Orb) tính bằng độ (thường từ 5.0° đến 8.0°).
    public var maxOrb: Double
    /// Bản chất năng lượng của góc chiếu (Căng thẳng, Hài hòa, hoặc Trung tính).
    public var nature: AstroAspectNature
    /// Trọng số cơ sở của góc chiếu trong tính toán tổng hợp (ví dụ: 1.0 cho Trùng tụ/Vuông góc, 0.7 cho Lục hợp).
    public var baseWeight: Double
}

/// Một góc chiếu cụ thể được phát hiện giữa hành tinh quá cảnh (Transit) và hành tinh bản mệnh (Natal).
public nonisolated struct DetectedAstroAspect: Codable, Equatable, Sendable {
    /// Tên hành tinh đang quá cảnh trên bầu trời hiện tại (ví dụ: "Moon", "Mars").
    public var transitPlanet: String
    /// Tên hành tinh trên bản đồ sao gốc lúc sinh (ví dụ: "Sun", "Saturn").
    public var natalPlanet: String
    public var type: AstroAspectType
    /// Ký hiệu thiên văn của góc chiếu (☌, ⚹, □, △, ☍).
    public var symbol: String
    /// Tên tiếng Việt của góc chiếu ("Trùng tụ", "Tam hợp", "Vuông góc", ...).
    public var nameVi: String
    /// Góc mục tiêu lý thuyết theo độ (0°, 60°, 90°, 120°, 180°).
    public var targetAngle: Double
    /// Góc thực tế đo được giữa 2 hành tinh trên vòng hoàng đạo (độ).
    public var actualAngle: Double
    /// Độ lệch thực tế so với góc lý thuyết (|actualAngle - targetAngle|), orb càng nhỏ lực tác động càng mạnh.
    public var orb: Double
    /// Trọng số ảnh hưởng sau khi tính đến độ lệch orb và trọng lượng hành tinh (giá trị càng cao tác động càng lớn).
    public var weight: Double
    /// Bản chất năng lượng của góc chiếu (Căng thẳng, Hài hòa, Trung tính).
    public var nature: AstroAspectNature

    public init(
        transitPlanet: String,
        natalPlanet: String,
        type: AstroAspectType,
        symbol: String,
        nameVi: String,
        targetAngle: Double,
        actualAngle: Double,
        orb: Double,
        weight: Double,
        nature: AstroAspectNature
    ) {
        self.transitPlanet = transitPlanet
        self.natalPlanet = natalPlanet
        self.type = type
        self.symbol = symbol
        self.nameVi = nameVi
        self.targetAngle = targetAngle
        self.actualAngle = actualAngle
        self.orb = orb
        self.weight = weight
        self.nature = nature
    }
}

public nonisolated enum AstroHouseSystem: String, Codable, Equatable, Sendable {
    case porphyry
}

public nonisolated enum AstroBirthDataPrecision: String, Codable, Equatable, Sendable {
    case dateOnly
    case timeWithoutLocation
    case complete
}

public nonisolated struct AstroHouseCusp: Codable, Equatable, Sendable {
    public var house: Int
    public var longitude: Double

    public init(house: Int, longitude: Double) {
        self.house = house
        self.longitude = longitude
    }
}

public nonisolated struct AstroAngles: Codable, Equatable, Sendable {
    public var ascendant: Double
    public var descendant: Double
    public var midheaven: Double
    public var imumCoeli: Double

    public init(ascendant: Double, descendant: Double, midheaven: Double, imumCoeli: Double) {
        self.ascendant = ascendant
        self.descendant = descendant
        self.midheaven = midheaven
        self.imumCoeli = imumCoeli
    }
}/*Thuộc tính    Viết tắt    Tên tiếng Việt    Tọa độ thiên văn    Ý nghĩa chiêm tinh
  ascendant    AC / Asc    Điểm Mọc / Cung Mọc    Điểm giao giữa đường hoàng đạo và đường chân trời phía Đông tại thời điểm sinh.    Đỉnh Nhà 1 (Cusp 1): Đại diện cho bản ngã bên ngoài, ngoại hình, phong thái, chiếc "mặt nạ" giao tiếp xã hội và cách một người khởi đầu các trải nghiệm mới.
  descendant    DC / Desc    Điểm Lặn / Cung Lặn    Điểm giao ở chân trời phía Tây, đối đỉnh chính xác 180° với Ascendant ((asc + 180°) % 360°).    Đỉnh Nhà 7 (Cusp 7): Đại diện cho các mối quan hệ đối tác 1-1, hôn nhân, tình cảm cam kết, cách ta tương tác với người khác và những phẩm chất ta tìm kiếm ở bạn đời.
  midheaven    MC (Medium Coeli)    Thiên Đỉnh    Điểm cao nhất của hoàng đạo cắt kinh tuyến trên (Meridian) tại nơi sinh.    Đỉnh Nhà 10 (Cusp 10): Đại diện cho sự nghiệp, danh vọng, địa vị xã hội, mục tiêu cuộc đời, thành tựu lớn nhất và hình ảnh trong mắt công chúng.
  imumCoeli    IC (Imum Coeli)    Thiên Đế / Đáy Trời    Điểm thấp nhất cắt kinh tuyến dưới (Nadir), đối đỉnh chính xác 180° với Midheaven ((mc + 180°) % 360°).    Đỉnh Nhà 4 (Cusp 4): Đại diện cho gốc rễ, gia đình, cội nguồn tổ tiên, tuổi thơ, thế giới nội tâm sâu kín nhất và cảm giác an toàn cơ bản.*/

public nonisolated struct AstroNatalContext: Codable, Equatable, Sendable {
    public var birthUTC: Date
    public var houseSystem: AstroHouseSystem
    public var angles: AstroAngles
    public var houseCusps: [AstroHouseCusp]
    public var planetHouses: [String: Int]
    public var precision: AstroBirthDataPrecision
    public var isLocalTimeAmbiguous: Bool

    public init(
        birthUTC: Date,
        houseSystem: AstroHouseSystem = .porphyry,
        angles: AstroAngles,
        houseCusps: [AstroHouseCusp],
        planetHouses: [String: Int],
        precision: AstroBirthDataPrecision,
        isLocalTimeAmbiguous: Bool = false
    ) {
        self.birthUTC = birthUTC
        self.houseSystem = houseSystem
        self.angles = angles
        self.houseCusps = houseCusps
        self.planetHouses = planetHouses
        self.precision = precision
        self.isLocalTimeAmbiguous = isLocalTimeAmbiguous
    }
}

public nonisolated struct AstroNatalSnapshot: Codable, Equatable, Sendable {
    public var fingerprint: String
    public var engineVersion: String
    public var chart: AstroPlanetaryChart
    public var context: AstroNatalContext?
/*    chart: AstroPlanetaryChart    context: AstroNatalContext?
 Trả lời    "Hành tinh đang ở cung nào?"    "Hành tinh đang ở nhà nào, và hướng bầu trời ra sao?"
 Thông tin    Tọa độ 10 hành tinh trên vòng hoàng đạo    Nhà, ASC, MC, 12 đỉnh nhà
 Cần dữ liệu gì    Chỉ ngày sinh (giờ có thì chính xác hơn)    Phải có giờ sinh + nơi sinh
 Có ? không    Không, luôn có    Có, có thể nil*/
    /*Nhà (house) là cách chiêm tinh chia bầu trời thành 12 phần, mỗi phần đại diện cho một lĩnh vực đời sống. Nó không liên quan đến căn nhà để ở.
     
     So sánh với "cung" để khỏi nhầm
         Cung (sign)    Nhà (house)
     Là gì    12 phần của vòng hoàng đạo, cố định theo vị trí sao    12 phần của bầu trời tại chỗ bạn sinh, đổi theo giờ + nơi sinh
     Trả lời    Hành tinh mang phong cách gì? (Lửa, Đất...)    Phong cách đó biểu hiện ở lĩnh vực nào?
     Ví dụ    Sao Hỏa ở Bạch Dương: hành động nhanh, mạnh    Sao Hỏa ở nhà 10: năng lượng đó dồn vào sự nghiệp

     Một cách nhớ: hành tinh là diễn viên, cung là cách diễn, nhà là sân khấu.

     12 nhà là gì
     Nhà    Lĩnh vực
     1    Bản thân, vẻ ngoài
     2    Tiền bạc, tài sản
     3    Giao tiếp, anh chị em
     4    Gia đình, nhà cửa, gốc rễ
     5    Tình yêu, sáng tạo, vui chơi
     6    Công việc hằng ngày, sức khỏe
     7    Hôn nhân, đối tác
     8    Chia sẻ tài chính, chuyển hóa
     9    Học vấn, du lịch, triết lý
     10    Sự nghiệp, danh tiếng
     11    Bạn bè, cộng đồng, mục tiêu
     12    Nội tâm, điều ẩn giấu

     Đây là các chủ đề thường dùng; chuỗi chủ đề thật (topicVi) nằm trong AstrologyEngine mà mình chưa thấy.*/
    public init(
        fingerprint: String,
        engineVersion: String,
        chart: AstroPlanetaryChart,
        context: AstroNatalContext?
    ) {
        self.fingerprint = fingerprint
        self.engineVersion = engineVersion
        self.chart = chart
        self.context = context
    }
}

public nonisolated struct AstroAngleAspect: Codable, Equatable, Sendable {
    public var transitPlanet: String
    public var angle: String
    public var type: AstroAspectType
    public var nameVi: String
    public var orb: Double
    public var weight: Double
    public var nature: AstroAspectNature

    public init(
        transitPlanet: String,
        angle: String,
        type: AstroAspectType,
        nameVi: String,
        orb: Double,
        weight: Double,
        nature: AstroAspectNature
    ) {
        self.transitPlanet = transitPlanet
        self.angle = angle
        self.type = type
        self.nameVi = nameVi
        self.orb = orb
        self.weight = weight
        self.nature = nature
    }
}

public nonisolated struct ActivatedHouseScore: Identifiable, Codable, Equatable, Sendable {
    public var id: Int { house }
    public var house: Int
    public var score: Double
    public var topicVi: String

    public init(house: Int, score: Double, topicVi: String) {
        self.house = house
        self.score = score
        self.topicVi = topicVi
    }
}

public nonisolated struct AstroDailyContext: Codable, Equatable, Sendable {
    public var transitHouses: [String: Int]
    public var angleAspects: [AstroAngleAspect]
    public var activatedHouses: [ActivatedHouseScore]

    public init(
        transitHouses: [String: Int],
        angleAspects: [AstroAngleAspect],
        activatedHouses: [ActivatedHouseScore]
    ) {
        self.transitHouses = transitHouses
        self.angleAspects = angleAspects
        self.activatedHouses = activatedHouses
    }
}

/// Input sinh cho engine. `resolvedBirthLocation` chỉ sống cục bộ và không được đưa vào API.
public nonisolated struct AstroBirthInput: Codable, Equatable, Sendable {
    public var birthDate: String
    public var birthTime: String?
    public var fullName: String?
    public var birthTimeAccuracy: BirthTimeAccuracy
    // thể hiện giờ sinh này là tự gen hoặc chĩnhs xác
    public var resolvedBirthLocation: ResolvedBirthLocation?
   /// reslvedBirthLocation là việc. ánh xạ dc từ tên nơi ngừoi đó sinh ra thành place id với longtitude và ladtitude
    /// du lieu nay 
    public init(
        birthDate: String,
        birthTime: String? = nil,
        fullName: String? = nil,
        birthTimeAccuracy: BirthTimeAccuracy? = nil,
        resolvedBirthLocation: ResolvedBirthLocation? = nil
    ) {
        self.birthDate = birthDate
        self.birthTime = birthTime
        self.fullName = fullName
        self.birthTimeAccuracy = birthTimeAccuracy
            ?? (birthTime?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ? .exact : .unknown)
        self.resolvedBirthLocation = resolvedBirthLocation
    }
}

/// Input orchestration cho lá thăm hằng ngày. Feature chỉ cần gửi profile và ngày hiện tại;
/// service chịu trách nhiệm vector, cache, lịch sử lời khuyên và HTTP.
public nonisolated struct AstroDailyFortuneQuery: Equatable, Sendable {
    public var date: Date
    public var profile: UserProfile?
    public var anchorCaDao: AnchorCaDao?
    public var userContext: String?

    public init(
        date: Date,
        profile: UserProfile? = nil,
        anchorCaDao: AnchorCaDao? = nil,
        userContext: String? = nil
    ) {
        self.date = date
        self.profile = profile
        self.anchorCaDao = anchorCaDao
        self.userContext = userContext
    }
}

/// Tín hiệu năng lượng tổng quan chiếm ưu thế trong ngày.
public nonisolated enum AstroDominantSignal: String, Codable, CaseIterable, Equatable, Sendable {
    /// Áp lực, căng thẳng chiếm ưu thế (các góc ma sát trội hơn, khuyên nên cẩn trọng, rà soát rủi ro).
    case tension
    /// Hài hòa, thuận lợi chiếm ưu thế (các góc hỗ trợ trội hơn, thuận lợi kết nối và triển khai việc lớn).
    case harmony
    /// Năng lượng hội tụ mạnh mẽ (nhiều góc trùng tụ, phù hợp tập trung dồn sức vào một trọng tâm).
    case conjunction
    /// Trạng thái cân bằng, các dòng tác động đan xen bình ổn, thích hợp duy trì nhịp sống thường nhật.
    case balanced
}

/// Siêu dữ liệu tổng hợp về xu hướng khí chất bản mệnh (Natal Temperament Metadata).
public nonisolated struct AstroTemperamentMetadata: Codable, Equatable, Sendable {
    /// Phân bổ chi tiết tỷ lệ 4 nguyên tố và 3 tính chất trong bản mệnh.
    public var balance: TemperamentBalance
    /// Tên nguyên tố chiếm ưu thế nhất trong bản đồ sinh (ví dụ: "Lửa", "Đất", "Khí", "Nước").
    public var dominantElement: String
    /// Tên tính chất chiếm ưu thế nhất trong bản đồ sinh (ví dụ: "Tiên phong", "Kiên định", "Linh hoạt").
    public var dominantModality: String

    public init(balance: TemperamentBalance, dominantElement: String, dominantModality: String) {
        self.balance = balance
        self.dominantElement = dominantElement
        self.dominantModality = dominantModality
    }
}

/// Bộ điểm số định lượng các động lực chiêm tinh học trong ngày.
/// Tất cả các điểm số được chuẩn hóa trong khoảng [0.0, 1.0].
public nonisolated struct AstroScoreMetadata: Codable, Equatable, Sendable {
    /// Điểm số căng thẳng / thử thách [0.0 - 1.0] (tính từ tỷ trọng các góc Vuông góc và Đối đỉnh).
    public var tension: Double
    /// Điểm số hài hòa / thuận lợi [0.0 - 1.0] (tính từ tỷ trọng các góc Tam hợp và Lục hợp).
    public var harmony: Double
    /// Cường độ hội tụ năng lượng [0.0 - 1.0] (tỷ trọng các góc Trùng tụ trên tổng hoạt động).
    public var conjunction: Double
    /// Mức độ kích hoạt từ các hành tinh di chuyển nhanh (Mặt Trời, Mặt Trăng, Thủy, Kim, Hỏa) [0.0 - 1.0].
    public var fastPlanetActivity: Double

    public init(tension: Double, harmony: Double, conjunction: Double, fastPlanetActivity: Double) {
        self.tension = tension
        self.harmony = harmony
        self.conjunction = conjunction
        self.fastPlanetActivity = fastPlanetActivity
    }
}

/// Kết quả phân tích tổng hợp toàn bộ các góc chiếu giữa Transit Chart và Natal Chart.
public nonisolated struct AstroAspectAnalysis: Codable, Equatable, Sendable {
    /// Danh sách toàn bộ các góc chiếu phát hiện được giữa các hành tinh quá cảnh và bản mệnh.
    public var aspects: [DetectedAstroAspect]
    /// Góc chiếu quan trọng nhất, có trọng số tác động cao nhất trong ngày (nil nếu không phát hiện góc chiếu).
    public var topAspect: DetectedAstroAspect?
    /// Điểm số căng thẳng định lượng [0.0 - 1.0].
    public var tensionScore: Double
    /// Điểm số hài hòa định lượng [0.0 - 1.0].
    public var harmonyScore: Double
    /// Cường độ trùng tụ hội tụ định lượng [0.0 - 1.0].
    public var conjunctionIntensity: Double
    /// Mức độ hoạt động của các hành tinh chu kỳ ngắn [0.0 - 1.0].
    public var fastPlanetActivity: Double

    public init(
        aspects: [DetectedAstroAspect] = [],
        topAspect: DetectedAstroAspect? = nil,
        tensionScore: Double = 0.0,
        harmonyScore: Double = 0.0,
        conjunctionIntensity: Double = 0.0,
        fastPlanetActivity: Double = 0.0
    ) {
        self.aspects = aspects
        self.topAspect = topAspect
        self.tensionScore = tensionScore
        self.harmonyScore = harmonyScore
        self.conjunctionIntensity = conjunctionIntensity
        self.fastPlanetActivity = fastPlanetActivity
    }
}

/// Toàn bộ siêu dữ liệu ngữ nghĩa (Semantic Metadata) của hệ thống chiêm tinh học.
/// Đóng gói trọn vẹn thông tin ngày sinh, khí chất bản mệnh, góc chiếu và bầu không khí ngày.
public nonisolated struct AstroFeatureMetadata: Codable, Equatable, Sendable {
    /// Ngày sinh của người dùng (chuỗi định dạng 'YYYY-MM-DD' hoặc 'DD/MM/YYYY').
    public var birthDate: String
    /// Giờ sinh của người dùng (chuỗi định dạng 'HH:mm', nil nếu không rõ giờ sinh).
    public var birthTime: String?
    /// Đánh dấu người dùng có cung cấp giờ sinh chính xác hay không (true nếu có giờ sinh).
    public var hasExactTime: Bool
    /// Điểm tin cậy của thuật toán tính toán (1.0 nếu có giờ sinh chính xác, 0.7 nếu dùng Noon Chart ước lượng).
    public var confidenceScore: Double
    /// Thời điểm phân tích hiện tại theo chuẩn ISO 8601 string.
    public var currentDateIso: String
    /// Cung Mặt Trời bản mệnh (Sun Sign — định hình bản ngã cốt lõi, lý trí).
    public var natalSunSign: String
    /// Cung Mặt Trăng bản mệnh (Moon Sign — định hình thế giới cảm xúc, tiềm thức).
    public var natalMoonSign: String
    /// Cung Mặt Trăng quá cảnh hiện tại (chi phối tâm trạng ngắn hạn và bầu không khí ngày).
    public var transitMoonSign: String
    /// Dữ liệu khí chất bản mệnh tổng hợp (phân bổ nguyên tố, tính chất và đặc trưng nổi trội).
    public var temperament: AstroTemperamentMetadata
    /// Góc chiếu quan trọng nhất tác động lên bản mệnh trong ngày hôm nay.
    public var topAspect: DetectedAstroAspect?
    /// Tổng số lượng góc chiếu tìm thấy giữa các hành tinh quá cảnh và bản mệnh.
    public var totalAspectsCount: Int
    /// Bộ 4 điểm số động lực học chiêm tinh trong ngày (tension, harmony, conjunction, fastPlanetActivity).
    public var scores: AstroScoreMetadata
    /// Tín hiệu năng lượng chủ đạo trong ngày (tension, harmony, conjunction, balanced).
    public var dominantSignal: AstroDominantSignal
    /// Câu tóm tắt ngữ nghĩa dễ hiểu về xu thế năng lượng và lời khuyên định hướng trong ngày.
    public var vibeSummary: String
    /// V2 fields are optional so v3/v2 cache payloads remain decodable.
    public var birthDataPrecision: AstroBirthDataPrecision?
    public var natalContext: AstroNatalContext?
    public var dailyContext: AstroDailyContext?

    public init(
        birthDate: String,
        birthTime: String? = nil,
        hasExactTime: Bool = false,
        confidenceScore: Double = 0.7,
        currentDateIso: String = "",
        natalSunSign: String = "",
        natalMoonSign: String = "",
        transitMoonSign: String = "",
        temperament: AstroTemperamentMetadata,
        topAspect: DetectedAstroAspect? = nil,
        totalAspectsCount: Int = 0,
        scores: AstroScoreMetadata,
        dominantSignal: AstroDominantSignal = .balanced,
        vibeSummary: String = "",
        birthDataPrecision: AstroBirthDataPrecision? = nil,
        natalContext: AstroNatalContext? = nil,
        dailyContext: AstroDailyContext? = nil
    ) {
        self.birthDate = birthDate
        self.birthTime = birthTime
        self.hasExactTime = hasExactTime
        self.confidenceScore = confidenceScore
        self.currentDateIso = currentDateIso
        self.natalSunSign = natalSunSign
        self.natalMoonSign = natalMoonSign
        self.transitMoonSign = transitMoonSign
        self.temperament = temperament
        self.topAspect = topAspect
        self.totalAspectsCount = totalAspectsCount
        self.scores = scores
        self.dominantSignal = dominantSignal
        self.vibeSummary = vibeSummary
        self.birthDataPrecision = birthDataPrecision
        self.natalContext = natalContext
        self.dailyContext = dailyContext
    }
}

/// Kết quả biểu diễn đặc trưng chiêm tinh học dưới dạng Vector 32 chiều (Pure Astro Feature Vector).
public nonisolated struct AstroVectorResult: Codable, Equatable, Sendable {
    /// Mảng 32 số thực trong đoạn [0.0, 1.0] mã hóa toàn bộ trạng thái thiên văn:
    /// - [0]: Độ tin cậy dữ liệu (1.0 nếu có giờ sinh chính xác, 0.7 nếu dùng Noon Chart).
    /// - [1..10]: Tọa độ hoàng đạo chuẩn hóa của 10 hành tinh bản mệnh (Sun -> Pluto).
    /// - [11..20]: Tọa độ hoàng đạo chuẩn hóa của 10 hành tinh quá cảnh hôm nay.
    /// - [21..24]: Tỷ lệ cân bằng 4 nguyên tố Natal (Fire, Earth, Air, Water).
    /// - [25..27]: Tỷ lệ cân bằng 3 tính chất Natal (Cardinal, Fixed, Mutable).
    /// - [28..31]: 4 điểm số động lực góc chiếu (Tension, Harmony, Conjunction, Fast Planet Activity).
    public var vector: [Double]
    /// Siêu dữ liệu ngữ nghĩa chiêm tinh học đi kèm (phục vụ hiển thị UI và ngữ cảnh cho AI).
    public var metadata: AstroFeatureMetadata

    /// Biểu diễn mảng số thực kiểu Float (tương đương Float32Array ở React Native), tối ưu cho tính toán khoảng cách cosine / tìm kiếm vector.
    public var float32Values: [Float] { vector.map(Float.init) }

    public init(vector: [Double], metadata: AstroFeatureMetadata) {
        self.vector = vector
        self.metadata = metadata
    }
}

/// Dữ liệu câu ca dao dân gian Việt Nam dùng làm chất liệu văn hóa neo (anchor) cho quẻ thăm.
public nonisolated struct AnchorCaDao: Codable, Equatable, Sendable {
    /// Nội dung văn bản câu ca dao hoặc thơ lục bát.
    public var content: String
    /// Thể loại / chủ đề của câu ca dao (ví dụ: "Dân gian", "Tình cảm gia đình", "Lao động", nil nếu không phân loại).
    public var category: String?

    public init(content: String, category: String? = nil) {
        self.content = content
        self.category = category
    }
}

/// Lá Thăm Chiêm Tinh Dân Gian — kết hợp chiêm tinh học phương Tây và văn hóa ca dao Việt Nam.
public nonisolated struct AstroFortuneSlip: Codable, Equatable, Sendable {
    /// Tiêu đề của lá thăm (ví dụ tên quẻ ngày, tùy chọn nil).
    public var title: String?
    /// Bài thơ 4 câu phán đoán vận thế trong ngày phỏng theo thể thức ca dao dân gian.
    public var verse: String
    /// "Gương soi" — phân tích phản chiếu trạng thái tâm lý, nội tâm và cái nhìn thực tại của người bốc thăm.
    public var mirror: String
    /// "Kế sách" — lời khuyên hành động và thái độ ứng xử cụ thể trong ngày.
    public var advice: String
    /// Câu ca dao gốc của Việt Nam làm chất liệu neo văn hóa và nhịp điệu thơ.
    public var anchorCaDao: AnchorCaDao
    /// Siêu dữ liệu chiêm tinh học tương ứng với ngày bốc thăm (tùy chọn).
    public var astroMetadata: AstroFeatureMetadata?

    public init(
        title: String? = nil,
        verse: String,
        mirror: String,
        advice: String,
        anchorCaDao: AnchorCaDao,
        astroMetadata: AstroFeatureMetadata? = nil
    ) {
        self.title = title
        self.verse = verse
        self.mirror = mirror
        self.advice = advice
        self.anchorCaDao = anchorCaDao
        self.astroMetadata = astroMetadata
    }
}
