import Foundation

public enum WuXingElement: String, Codable, CaseIterable, Equatable, Sendable {
    case metal
    case wood
    case water
    case fire
    case earth
}

public enum CungPhiGroup: String, Codable, CaseIterable, Equatable, Sendable {
    case east = "Đông Tứ Mệnh"
    case west = "Tây Tứ Mệnh"
}

public struct PillarData: Codable, Equatable, Sendable {
    public var gan: String
    public var zhi: String
    public var ganVi: String
    public var zhiVi: String
    public var element: String // Kim, Mộc, Thủy, Hỏa, Thổ
    public var elementEn: WuXingElement

    public init(
        gan: String,
        zhi: String,
        ganVi: String,
        zhiVi: String,
        element: String,
        elementEn: WuXingElement
    ) {
        self.gan = gan
        self.zhi = zhi
        self.ganVi = ganVi
        self.zhiVi = zhiVi
        self.element = element
        self.elementEn = elementEn
    }
}

public struct TuViBaziChart: Codable, Equatable, Sendable {
    public var fullName: String
    public var birthDate: String
    public var gender: Gender
    public var yearPillar: PillarData
    public var monthPillar: PillarData
    public var dayPillar: PillarData
    public var dayMaster: String
    public var dayMasterElement: String
    public var spousalPalace: String
    public var spousalPalaceElement: String
    public var napAmYear: String
    public var napAmElement: String
    public var cungPhi: String
    public var cungPhiElement: String
    public var cungPhiGroup: CungPhiGroup

    public init(
        fullName: String,
        birthDate: String,
        gender: Gender,
        yearPillar: PillarData,
        monthPillar: PillarData,
        dayPillar: PillarData,
        dayMaster: String,
        dayMasterElement: String,
        spousalPalace: String,
        spousalPalaceElement: String,
        napAmYear: String,
        napAmElement: String,
        cungPhi: String,
        cungPhiElement: String,
        cungPhiGroup: CungPhiGroup
    ) {
        self.fullName = fullName
        self.birthDate = birthDate
        self.gender = gender
        self.yearPillar = yearPillar
        self.monthPillar = monthPillar
        self.dayPillar = dayPillar
        self.dayMaster = dayMaster
        self.dayMasterElement = dayMasterElement
        self.spousalPalace = spousalPalace
        self.spousalPalaceElement = spousalPalaceElement
        self.napAmYear = napAmYear
        self.napAmElement = napAmElement
        self.cungPhi = cungPhi
        self.cungPhiElement = cungPhiElement
        self.cungPhiGroup = cungPhiGroup
    }
}

public enum SpousalInteractionType: String, Codable, CaseIterable, Equatable, Sendable {
    case liuHe = "liu_he"
    case sanHe = "san_he"
    case chong
    case hai
    case neutral
}

public struct SpousalInteraction: Codable, Equatable, Sendable {
    public var type: SpousalInteractionType
    public var labelVi: String
    public var description: String

    public init(type: SpousalInteractionType, labelVi: String, description: String) {
        self.type = type
        self.labelVi = labelVi
        self.description = description
    }
}

public enum StemInteractionType: String, Codable, CaseIterable, Equatable, Sendable {
    case he
    case chong
    case neutral
}

public struct StemInteraction: Codable, Equatable, Sendable {
    public var type: StemInteractionType
    public var labelVi: String
    public var description: String

    public init(type: StemInteractionType, labelVi: String, description: String) {
        self.type = type
        self.labelVi = labelVi
        self.description = description
    }
}

public enum HarmonyRelationship: String, Codable, CaseIterable, Equatable, Sendable {
    case sinh
    case khac
    case dongHanh = "dong_hanh"
}

public struct HarmonyRelation: Codable, Equatable, Sendable {
    public var relationship: HarmonyRelationship
    public var labelVi: String?
    public var description: String

    public init(relationship: HarmonyRelationship, labelVi: String? = nil, description: String) {
        self.relationship = relationship
        self.labelVi = labelVi
        self.description = description
    }
}

public enum CungPhiRelationType: String, Codable, CaseIterable, Equatable, Sendable {
    case sinhKhi = "sinh_khi"
    case dienNien = "dien_nien"
    case thienY = "thien_y"
    case phucVi = "phuc_vi"
    case tuyetMenh = "tuyet_menh"
    case hoaHai = "hoa_hai"
    case lucSat = "luc_sat"
    case nguQuy = "ngu_quy"
}

public struct CungPhiBatTrachRelation: Codable, Equatable, Sendable {
    public var type: CungPhiRelationType
    public var isAuspicious: Bool
    public var labelVi: String
    public var description: String

    public init(type: CungPhiRelationType, isAuspicious: Bool, labelVi: String, description: String) {
        self.type = type
        self.isAuspicious = isAuspicious
        self.labelVi = labelVi
        self.description = description
    }
}

public struct SimpleLabelDescription: Codable, Equatable, Sendable {
    public var labelVi: String
    public var description: String

    public init(labelVi: String, description: String) {
        self.labelVi = labelVi
        self.description = description
    }
}

public struct TuViBaziSynastry: Codable, Equatable, Sendable {
    public var personA: TuViBaziChart
    public var personB: TuViBaziChart
    public var compatibilityScore: Int // 0 - 100
    public var spousalInteraction: SpousalInteraction
    public var stemInteraction: StemInteraction
    public var elementHarmony: HarmonyRelation
    public var napAmHarmony: HarmonyRelation
    public var cungPhiBatTrach: CungPhiBatTrachRelation
    public var yearAnimalHarmony: SimpleLabelDescription
    public var summaryVi: String
    public var adviceVi: String

    public init(
        personA: TuViBaziChart,
        personB: TuViBaziChart,
        compatibilityScore: Int,
        spousalInteraction: SpousalInteraction,
        stemInteraction: StemInteraction,
        elementHarmony: HarmonyRelation,
        napAmHarmony: HarmonyRelation,
        cungPhiBatTrach: CungPhiBatTrachRelation,
        yearAnimalHarmony: SimpleLabelDescription,
        summaryVi: String,
        adviceVi: String
    ) {
        self.personA = personA
        self.personB = personB
        self.compatibilityScore = compatibilityScore
        self.spousalInteraction = spousalInteraction
        self.stemInteraction = stemInteraction
        self.elementHarmony = elementHarmony
        self.napAmHarmony = napAmHarmony
        self.cungPhiBatTrach = cungPhiBatTrach
        self.yearAnimalHarmony = yearAnimalHarmony
        self.summaryVi = summaryVi
        self.adviceVi = adviceVi
    }
}
