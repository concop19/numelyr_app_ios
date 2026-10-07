import SwiftUI

enum AppAsset: String, CaseIterable, Sendable {
    // MARK: - Auth
    case authMascot = "AuthMascot"
    case authLoginPortal = "AuthLoginPortal"

    // MARK: - Tab Shell
    case tabChat = "TabChat"
    case tabCalendar = "TabCalendar"
    case tabWallpaper = "TabWallpaper"
    case tabSettings = "TabSettings"

    case chatSceneSky = "ChatSceneSky"
    case chatSceneMountains = "ChatSceneMountains"
    case chatSceneForeground = "ChatSceneForeground"
    case chatSceneStars = "ChatSceneStars"
    case chatSceneMoon = "ChatSceneMoon"

    case chatFlameIdleSprite = "ChatFlameIdleSprite"
    case chatFlameThinkingSprite = "ChatFlameThinkingSprite"
    case chatFlameAnswerSprite = "ChatFlameAnswerSprite"
    case chatVIPBadge = "ChatVIPBadge"
    case chatAmbientGlow = "ChatAmbientGlow"

    // MARK: - Chat Detail (Mystic Reading Trace Ritual)
    case chatDetailBackground = "ChatDetailBackground"
    case chatDetailMat = "ChatDetailMat"
    case chatDetailChest = "ChatDetailChest"
    case chatDetailCandle = "ChatDetailCandle"
    case chatDetailCandleFlameSprite = "ChatDetailCandleFlameSprite"
    case chatDetailBook = "ChatDetailBook"
    case chatDetailPaper = "ChatDetailPaper"
    case chatDetailQuill = "ChatDetailQuill"

    case chatDetailTopFlameLeft01 = "ChatDetailTopFlameLeft01"
    case chatDetailTopFlameLeft02 = "ChatDetailTopFlameLeft02"
    case chatDetailTopFlameLeft03 = "ChatDetailTopFlameLeft03"
    case chatDetailTopFlameLeft04 = "ChatDetailTopFlameLeft04"
    case chatDetailTopFlameLeft05 = "ChatDetailTopFlameLeft05"
    case chatDetailTopFlameLeft06 = "ChatDetailTopFlameLeft06"

    case chatDetailTopFlameRight01 = "ChatDetailTopFlameRight01"
    case chatDetailTopFlameRight02 = "ChatDetailTopFlameRight02"
    case chatDetailTopFlameRight03 = "ChatDetailTopFlameRight03"
    case chatDetailTopFlameRight04 = "ChatDetailTopFlameRight04"
    case chatDetailTopFlameRight05 = "ChatDetailTopFlameRight05"
    case chatDetailTopFlameRight06 = "ChatDetailTopFlameRight06"

    case chatDetailBottomFlameLeft01 = "ChatDetailBottomFlameLeft01"
    case chatDetailBottomFlameLeft02 = "ChatDetailBottomFlameLeft02"
    case chatDetailBottomFlameLeft03 = "ChatDetailBottomFlameLeft03"
    case chatDetailBottomFlameLeft04 = "ChatDetailBottomFlameLeft04"
    case chatDetailBottomFlameLeft05 = "ChatDetailBottomFlameLeft05"
    case chatDetailBottomFlameLeft06 = "ChatDetailBottomFlameLeft06"

    case chatDetailBottomFlameRight01 = "ChatDetailBottomFlameRight01"
    case chatDetailBottomFlameRight02 = "ChatDetailBottomFlameRight02"
    case chatDetailBottomFlameRight03 = "ChatDetailBottomFlameRight03"
    case chatDetailBottomFlameRight04 = "ChatDetailBottomFlameRight04"
    case chatDetailBottomFlameRight05 = "ChatDetailBottomFlameRight05"
    case chatDetailBottomFlameRight06 = "ChatDetailBottomFlameRight06"

    // MARK: - Calendar
    case calendarHero = "CalendarHero"
    case calendarTopic = "CalendarTopic"
    case calendarHeroAlt = "CalendarHeroAlt"
    case calendarSpringFallback = "CalendarSpringFallback"
    case calendarSummerFallback = "CalendarSummerFallback"
    case calendarAutumnFallback = "CalendarAutumnFallback"
    case calendarWinterFallback = "CalendarWinterFallback"
    case calendarMascotIdle = "CalendarMascotIdle"
    case calendarMascot1 = "CalendarMascot1"
    case calendarMascot2 = "CalendarMascot2"

    // MARK: - Wallpaper
    case wallpaperLandscapeBackground = "WallpaperLandscapeBackground"
    case wallpaperMoon = "WallpaperMoon"
    case wallpaperStar = "WallpaperStar"
    case wallpaperThreeStars = "WallpaperThreeStars"
    case wallpaperCloudSprite = "WallpaperCloudSprite"
    case wallpaperMockCard1 = "WallpaperMockCard1"
    case wallpaperMockCard2 = "WallpaperMockCard2"
    case wallpaperMockCard3 = "WallpaperMockCard3"
    case wallpaperMockCard4 = "WallpaperMockCard4"

    // MARK: - Astrology
    case astrologyGalaxyBackground = "AstrologyGalaxyBackground"
    case astrologyAuroraOverlay = "AstrologyAuroraOverlay"

    /// URL to the bundled looping Aurora video for Astrology screen background.
    static var astrologyAuroraVideoURL: URL? {
        Bundle.main.url(forResource: "astrology-aurora", withExtension: "mp4")
    }

    // MARK: - Numerology Cards
    case numerologyCard01WalksOfLife = "NumerologyCard01WalksOfLife"
    case numerologyCard02Mission = "NumerologyCard02Mission"
    case numerologyCard03Soul = "NumerologyCard03Soul"
    case numerologyCard04Personality = "NumerologyCard04Personality"
    case numerologyCard05DateOfBirth = "NumerologyCard05DateOfBirth"
    case numerologyCard06Mature = "NumerologyCard06Mature"
    case numerologyCard07Balance = "NumerologyCard07Balance"
    case numerologyCard08RationalThinking = "NumerologyCard08RationalThinking"
    case numerologyCard09SubconsciousPower = "NumerologyCard09SubconsciousPower"
    case numerologyCard10Passion = "NumerologyCard10Passion"
    case numerologyCard11Attitude = "NumerologyCard11Attitude"
    case numerologyCard12KarmicDebts = "NumerologyCard12KarmicDebts"
    case numerologyCard13MissingNumbers = "NumerologyCard13MissingNumbers"
    case numerologyCard14BridgeLifeMission = "NumerologyCard14BridgeLifeMission"
    case numerologyCard15BridgeSoulPersonality = "NumerologyCard15BridgeSoulPersonality"
    case numerologyCard16BridgeMaturityPassion = "NumerologyCard16BridgeMaturityPassion"
    case numerologyCard17YearIndividual = "NumerologyCard17YearIndividual"
    case numerologyCard18MonthIndividual = "NumerologyCard18MonthIndividual"
    case numerologyCard19DayIndividual = "NumerologyCard19DayIndividual"
    case numerologyCard20Way = "NumerologyCard20Way"
    case numerologyCard21Challenges = "NumerologyCard21Challenges"
    case numerologyCard22Arrows = "NumerologyCard22Arrows"
    case numerologyCard23NameChart = "NumerologyCard23NameChart"
    case numerologyCard24BirthChart = "NumerologyCard24BirthChart"

    /// Helper to find numerology card asset by indicator index (1...24)
    static func numerologyCard(index: Int) -> AppAsset? {
        switch index {
        case 1: return .numerologyCard01WalksOfLife
        case 2: return .numerologyCard02Mission
        case 3: return .numerologyCard03Soul
        case 4: return .numerologyCard04Personality
        case 5: return .numerologyCard05DateOfBirth
        case 6: return .numerologyCard06Mature
        case 7: return .numerologyCard07Balance
        case 8: return .numerologyCard08RationalThinking
        case 9: return .numerologyCard09SubconsciousPower
        case 10: return .numerologyCard10Passion
        case 11: return .numerologyCard11Attitude
        case 12: return .numerologyCard12KarmicDebts
        case 13: return .numerologyCard13MissingNumbers
        case 14: return .numerologyCard14BridgeLifeMission
        case 15: return .numerologyCard15BridgeSoulPersonality
        case 16: return .numerologyCard16BridgeMaturityPassion
        case 17: return .numerologyCard17YearIndividual
        case 18: return .numerologyCard18MonthIndividual
        case 19: return .numerologyCard19DayIndividual
        case 20: return .numerologyCard20Way
        case 21: return .numerologyCard21Challenges
        case 22: return .numerologyCard22Arrows
        case 23: return .numerologyCard23NameChart
        case 24: return .numerologyCard24BirthChart
        default: return nil
        }
    }

    /// Helper to find numerology card asset by card id or key
    static func numerologyCard(idOrKey: String) -> AppAsset? {
        let normalized = idOrKey.replacingOccurrences(of: "card_", with: "").lowercased()
        switch normalized {
        case _ where normalized.contains("walksoflife"): return .numerologyCard01WalksOfLife
        case _ where normalized.contains("mission"): return .numerologyCard02Mission
        case _ where normalized.contains("soul"): return .numerologyCard03Soul
        case _ where normalized.contains("personality"): return .numerologyCard04Personality
        case _ where normalized.contains("dateofbirth") || normalized.contains("birthday"): return .numerologyCard05DateOfBirth
        case _ where normalized.contains("mature") || normalized.contains("maturity"): return .numerologyCard06Mature
        case _ where normalized.contains("balance"): return .numerologyCard07Balance
        case _ where normalized.contains("rational"): return .numerologyCard08RationalThinking
        case _ where normalized.contains("subconscious"): return .numerologyCard09SubconsciousPower
        case _ where normalized.contains("passion"): return .numerologyCard10Passion
        case _ where normalized.contains("attitude"): return .numerologyCard11Attitude
        case _ where normalized.contains("karmicdebt"): return .numerologyCard12KarmicDebts
        case _ where normalized.contains("missing"): return .numerologyCard13MissingNumbers
        case _ where normalized.contains("bridgelifemission"): return .numerologyCard14BridgeLifeMission
        case _ where normalized.contains("bridgesoulpersonality"): return .numerologyCard15BridgeSoulPersonality
        case _ where normalized.contains("bridgematuritypassion"): return .numerologyCard16BridgeMaturityPassion
        case _ where normalized.contains("yearindividual") || normalized.contains("personalyear"): return .numerologyCard17YearIndividual
        case _ where normalized.contains("monthindividual") || normalized.contains("personalmonth"): return .numerologyCard18MonthIndividual
        case _ where normalized.contains("dayindividual") || normalized.contains("personalday"): return .numerologyCard19DayIndividual
        case _ where normalized.contains("way") || normalized.contains("pinnacle"): return .numerologyCard20Way
        case _ where normalized.contains("challenge"): return .numerologyCard21Challenges
        case _ where normalized.contains("arrow"): return .numerologyCard22Arrows
        case _ where normalized.contains("namechart"): return .numerologyCard23NameChart
        case _ where normalized.contains("birthchart"): return .numerologyCard24BirthChart
        default: return nil
        }
    }

    // MARK: - Tarot (78 Cards + Card Back)
    case tarotCardBack = "TarotCardBack"

    // Major Arcana
    case tarot00Fool = "Tarot00Fool"
    case tarot01Magician = "Tarot01Magician"
    case tarot02HighPriestess = "Tarot02HighPriestess"
    case tarot03Empress = "Tarot03Empress"
    case tarot04Emperor = "Tarot04Emperor"
    case tarot05Hierophant = "Tarot05Hierophant"
    case tarot06Lovers = "Tarot06Lovers"
    case tarot07Chariot = "Tarot07Chariot"
    case tarot08Strength = "Tarot08Strength"
    case tarot09Hermit = "Tarot09Hermit"
    case tarot10WheelOfFortune = "Tarot10WheelOfFortune"
    case tarot11Justice = "Tarot11Justice"
    case tarot12HangedMan = "Tarot12HangedMan"
    case tarot13Death = "Tarot13Death"
    case tarot14Temperance = "Tarot14Temperance"
    case tarot15Devil = "Tarot15Devil"
    case tarot16Tower = "Tarot16Tower"
    case tarot17Star = "Tarot17Star"
    case tarot18Moon = "Tarot18Moon"
    case tarot19Sun = "Tarot19Sun"
    case tarot20Judgement = "Tarot20Judgement"
    case tarot21World = "Tarot21World"

    // Minor Arcana - Wands
    case tarotWands01 = "TarotWands01"
    case tarotWands02 = "TarotWands02"
    case tarotWands03 = "TarotWands03"
    case tarotWands04 = "TarotWands04"
    case tarotWands05 = "TarotWands05"
    case tarotWands06 = "TarotWands06"
    case tarotWands07 = "TarotWands07"
    case tarotWands08 = "TarotWands08"
    case tarotWands09 = "TarotWands09"
    case tarotWands10 = "TarotWands10"
    case tarotWands11 = "TarotWands11"
    case tarotWands12 = "TarotWands12"
    case tarotWands13 = "TarotWands13"
    case tarotWands14 = "TarotWands14"

    // Minor Arcana - Cups
    case tarotCups01 = "TarotCups01"
    case tarotCups02 = "TarotCups02"
    case tarotCups03 = "TarotCups03"
    case tarotCups04 = "TarotCups04"
    case tarotCups05 = "TarotCups05"
    case tarotCups06 = "TarotCups06"
    case tarotCups07 = "TarotCups07"
    case tarotCups08 = "TarotCups08"
    case tarotCups09 = "TarotCups09"
    case tarotCups10 = "TarotCups10"
    case tarotCups11 = "TarotCups11"
    case tarotCups12 = "TarotCups12"
    case tarotCups13 = "TarotCups13"
    case tarotCups14 = "TarotCups14"

    // Minor Arcana - Swords
    case tarotSwords01 = "TarotSwords01"
    case tarotSwords02 = "TarotSwords02"
    case tarotSwords03 = "TarotSwords03"
    case tarotSwords04 = "TarotSwords04"
    case tarotSwords05 = "TarotSwords05"
    case tarotSwords06 = "TarotSwords06"
    case tarotSwords07 = "TarotSwords07"
    case tarotSwords08 = "TarotSwords08"
    case tarotSwords09 = "TarotSwords09"
    case tarotSwords10 = "TarotSwords10"
    case tarotSwords11 = "TarotSwords11"
    case tarotSwords12 = "TarotSwords12"
    case tarotSwords13 = "TarotSwords13"
    case tarotSwords14 = "TarotSwords14"

    // Minor Arcana - Pentacles
    case tarotPentacles01 = "TarotPentacles01"
    case tarotPentacles02 = "TarotPentacles02"
    case tarotPentacles03 = "TarotPentacles03"
    case tarotPentacles04 = "TarotPentacles04"
    case tarotPentacles05 = "TarotPentacles05"
    case tarotPentacles06 = "TarotPentacles06"
    case tarotPentacles07 = "TarotPentacles07"
    case tarotPentacles08 = "TarotPentacles08"
    case tarotPentacles09 = "TarotPentacles09"
    case tarotPentacles10 = "TarotPentacles10"
    case tarotPentacles11 = "TarotPentacles11"
    case tarotPentacles12 = "TarotPentacles12"
    case tarotPentacles13 = "TarotPentacles13"
    case tarotPentacles14 = "TarotPentacles14"

    /// Tra cứu lá bài Tarot theo ID (ví dụ: "0-fool", "wands-01", "cups-10").
    /// Tự động fallback về mặt sau thẻ bài (.tarotCardBack) nếu không tìm thấy.
    static func tarotCard(id: String) -> AppAsset {
        let key = id.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        switch key {
        case "0-fool", "00-fool": return .tarot00Fool
        case "1-magician", "01-magician": return .tarot01Magician
        case "2-high-priestess", "02-high-priestess": return .tarot02HighPriestess
        case "3-empress", "03-empress": return .tarot03Empress
        case "4-emperor", "04-emperor": return .tarot04Emperor
        case "5-hierophant", "05-hierophant": return .tarot05Hierophant
        case "6-lovers", "06-lovers": return .tarot06Lovers
        case "7-chariot", "07-chariot": return .tarot07Chariot
        case "8-strength", "08-strength": return .tarot08Strength
        case "9-hermit", "09-hermit": return .tarot09Hermit
        case "10-wheel-of-fortune": return .tarot10WheelOfFortune
        case "11-justice": return .tarot11Justice
        case "12-hanged-man": return .tarot12HangedMan
        case "13-death": return .tarot13Death
        case "14-temperance": return .tarot14Temperance
        case "15-devil": return .tarot15Devil
        case "16-tower": return .tarot16Tower
        case "17-star": return .tarot17Star
        case "18-moon": return .tarot18Moon
        case "19-sun": return .tarot19Sun
        case "20-judgement": return .tarot20Judgement
        case "21-world": return .tarot21World

        case "wands-01", "wands-1": return .tarotWands01
        case "wands-02", "wands-2": return .tarotWands02
        case "wands-03", "wands-3": return .tarotWands03
        case "wands-04", "wands-4": return .tarotWands04
        case "wands-05", "wands-5": return .tarotWands05
        case "wands-06", "wands-6": return .tarotWands06
        case "wands-07", "wands-7": return .tarotWands07
        case "wands-08", "wands-8": return .tarotWands08
        case "wands-09", "wands-9": return .tarotWands09
        case "wands-10": return .tarotWands10
        case "wands-11": return .tarotWands11
        case "wands-12": return .tarotWands12
        case "wands-13": return .tarotWands13
        case "wands-14": return .tarotWands14

        case "cups-01", "cups-1": return .tarotCups01
        case "cups-02", "cups-2": return .tarotCups02
        case "cups-03", "cups-3": return .tarotCups03
        case "cups-04", "cups-4": return .tarotCups04
        case "cups-05", "cups-5": return .tarotCups05
        case "cups-06", "cups-6": return .tarotCups06
        case "cups-07", "cups-7": return .tarotCups07
        case "cups-08", "cups-8": return .tarotCups08
        case "cups-09", "cups-9": return .tarotCups09
        case "cups-10": return .tarotCups10
        case "cups-11": return .tarotCups11
        case "cups-12": return .tarotCups12
        case "cups-13": return .tarotCups13
        case "cups-14": return .tarotCups14

        case "swords-01", "swords-1": return .tarotSwords01
        case "swords-02", "swords-2": return .tarotSwords02
        case "swords-03", "swords-3": return .tarotSwords03
        case "swords-04", "swords-4": return .tarotSwords04
        case "swords-05", "swords-5": return .tarotSwords05
        case "swords-06", "swords-6": return .tarotSwords06
        case "swords-07", "swords-7": return .tarotSwords07
        case "swords-08", "swords-8": return .tarotSwords08
        case "swords-09", "swords-9": return .tarotSwords09
        case "swords-10": return .tarotSwords10
        case "swords-11": return .tarotSwords11
        case "swords-12": return .tarotSwords12
        case "swords-13": return .tarotSwords13
        case "swords-14": return .tarotSwords14

        case "pentacles-01", "pentacles-1": return .tarotPentacles01
        case "pentacles-02", "pentacles-2": return .tarotPentacles02
        case "pentacles-03", "pentacles-3": return .tarotPentacles03
        case "pentacles-04", "pentacles-4": return .tarotPentacles04
        case "pentacles-05", "pentacles-5": return .tarotPentacles05
        case "pentacles-06", "pentacles-6": return .tarotPentacles06
        case "pentacles-07", "pentacles-7": return .tarotPentacles07
        case "pentacles-08", "pentacles-8": return .tarotPentacles08
        case "pentacles-09", "pentacles-9": return .tarotPentacles09
        case "pentacles-10": return .tarotPentacles10
        case "pentacles-11": return .tarotPentacles11
        case "pentacles-12": return .tarotPentacles12
        case "pentacles-13": return .tarotPentacles13
        case "pentacles-14": return .tarotPentacles14

        default: return .tarotCardBack
        }
    }

    // MARK: - Chat Detail Flame Sprite Helpers

    enum ChatDetailFlameSide: String, Sendable, Equatable {
        case left
        case right
    }

    struct ChatDetailFlameFrame: Sendable, Equatable {
        let asset: AppAsset
        let width: CGFloat
        let height: CGFloat
    }

    /// 6-frame top mat flame characters (`lay_left` / `lay_right`) with intrinsic bounds from `FlameCharacterSprite.tsx`.
    static func chatDetailTopFlameFrames(side: ChatDetailFlameSide) -> [ChatDetailFlameFrame] {
        switch side {
        case .left:
            return [
                ChatDetailFlameFrame(asset: .chatDetailTopFlameLeft01, width: 163, height: 184),
                ChatDetailFlameFrame(asset: .chatDetailTopFlameLeft02, width: 159, height: 180),
                ChatDetailFlameFrame(asset: .chatDetailTopFlameLeft03, width: 151, height: 185),
                ChatDetailFlameFrame(asset: .chatDetailTopFlameLeft04, width: 163, height: 150),
                ChatDetailFlameFrame(asset: .chatDetailTopFlameLeft05, width: 167, height: 169),
                ChatDetailFlameFrame(asset: .chatDetailTopFlameLeft06, width: 153, height: 180),
            ]
        case .right:
            return [
                ChatDetailFlameFrame(asset: .chatDetailTopFlameRight01, width: 176, height: 190),
                ChatDetailFlameFrame(asset: .chatDetailTopFlameRight02, width: 179, height: 193),
                ChatDetailFlameFrame(asset: .chatDetailTopFlameRight03, width: 167, height: 189),
                ChatDetailFlameFrame(asset: .chatDetailTopFlameRight04, width: 181, height: 143),
                ChatDetailFlameFrame(asset: .chatDetailTopFlameRight05, width: 168, height: 170),
                ChatDetailFlameFrame(asset: .chatDetailTopFlameRight06, width: 171, height: 176),
            ]
        }
    }

    /// 6-frame bottom mat flame characters (`lac_left` / `lac_right`) with intrinsic bounds from `BottomFlameSprite.tsx`.
    static func chatDetailBottomFlameFrames(side: ChatDetailFlameSide) -> [ChatDetailFlameFrame] {
        switch side {
        case .left:
            return [
                ChatDetailFlameFrame(asset: .chatDetailBottomFlameLeft01, width: 472, height: 493),
                ChatDetailFlameFrame(asset: .chatDetailBottomFlameLeft02, width: 478, height: 496),
                ChatDetailFlameFrame(asset: .chatDetailBottomFlameLeft03, width: 427, height: 502),
                ChatDetailFlameFrame(asset: .chatDetailBottomFlameLeft04, width: 472, height: 469),
                ChatDetailFlameFrame(asset: .chatDetailBottomFlameLeft05, width: 460, height: 466),
                ChatDetailFlameFrame(asset: .chatDetailBottomFlameLeft06, width: 394, height: 469),
            ]
        case .right:
            return [
                ChatDetailFlameFrame(asset: .chatDetailBottomFlameRight01, width: 421, height: 487),
                ChatDetailFlameFrame(asset: .chatDetailBottomFlameRight02, width: 412, height: 457),
                ChatDetailFlameFrame(asset: .chatDetailBottomFlameRight03, width: 418, height: 448),
                ChatDetailFlameFrame(asset: .chatDetailBottomFlameRight04, width: 400, height: 430),
                ChatDetailFlameFrame(asset: .chatDetailBottomFlameRight05, width: 409, height: 433),
                ChatDetailFlameFrame(asset: .chatDetailBottomFlameRight06, width: 421, height: 460),
            ]
        }
    }

    var image: Image {
        Image(rawValue)
    }
}

extension Image {
    init(appAsset: AppAsset) {
        self.init(appAsset.rawValue)
    }
}
