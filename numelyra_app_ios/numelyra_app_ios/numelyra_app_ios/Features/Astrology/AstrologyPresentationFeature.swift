import ComposableArchitecture
import Foundation

enum AstrologyPlanetID: String, CaseIterable, Equatable, Hashable, Sendable {
    case sun = "Sun"
    case moon = "Moon"
    case mercury = "Mercury"
    case venus = "Venus"
    case mars = "Mars"
    case jupiter = "Jupiter"
    case saturn = "Saturn"
    case uranus = "Uranus"
    case neptune = "Neptune"
    case pluto = "Pluto"

    var nameVi: String {
        switch self {
        case .sun: "Mặt Trời"
        case .moon: "Mặt Trăng"
        case .mercury: "Sao Thủy"
        case .venus: "Sao Kim"
        case .mars: "Sao Hỏa"
        case .jupiter: "Sao Mộc"
        case .saturn: "Sao Thổ"
        case .uranus: "Thiên Vương"
        case .neptune: "Hải Vương"
        case .pluto: "Diêm Vương"
        }
    }

    var symbol: String {
        switch self {
        case .sun: "☉"
        case .moon: "☽"
        case .mercury: "☿"
        case .venus: "♀"
        case .mars: "♂"
        case .jupiter: "♃"
        case .saturn: "♄"
        case .uranus: "♅"
        case .neptune: "♆"
        case .pluto: "♇"
        }
    }

    var themes: String {
        switch self {
        case .sun: "Bản sắc · Sức sống · Mục tiêu"
        case .moon: "Cảm xúc · Bản năng · An toàn"
        case .mercury: "Tư duy · Ngôn ngữ · Học hỏi"
        case .venus: "Quan hệ · Giá trị · Hấp dẫn"
        case .mars: "Hành động · Ý chí · Can đảm"
        case .jupiter: "Mở rộng · Cơ hội · Niềm tin"
        case .saturn: "Kỷ luật · Trách nhiệm · Trưởng thành"
        case .uranus: "Đổi mới · Tự do · Thức tỉnh"
        case .neptune: "Trực giác · Lý tưởng · Cảm hứng"
        case .pluto: "Chuyển hóa · Tái sinh · Chiều sâu"
        }
    }
}

enum AstrologyZodiacID: String, CaseIterable, Equatable, Hashable, Sendable {
    case aries = "Aries"
    case taurus = "Taurus"
    case gemini = "Gemini"
    case cancer = "Cancer"
    case leo = "Leo"
    case virgo = "Virgo"
    case libra = "Libra"
    case scorpio = "Scorpio"
    case sagittarius = "Sagittarius"
    case capricorn = "Capricorn"
    case aquarius = "Aquarius"
    case pisces = "Pisces"

    var nameVi: String {
        switch self {
        case .aries: "Bạch Dương"
        case .taurus: "Kim Ngưu"
        case .gemini: "Song Tử"
        case .cancer: "Cự Giải"
        case .leo: "Sư Tử"
        case .virgo: "Xử Nữ"
        case .libra: "Thiên Bình"
        case .scorpio: "Bọ Cạp"
        case .sagittarius: "Nhân Mã"
        case .capricorn: "Ma Kết"
        case .aquarius: "Bảo Bình"
        case .pisces: "Song Ngư"
        }
    }

    var symbol: String {
        let symbols = ["♈", "♉", "♊", "♋", "♌", "♍", "♎", "♏", "♐", "♑", "♒", "♓"]
        return symbols[Self.allCases.firstIndex(of: self) ?? 0]
    }
}

enum AstrologyDetailTarget: Equatable, Hashable, Sendable {
    case planet(AstrologyPlanetID)
    case sign(AstrologyZodiacID)
}

enum AstrologyPlanetDetailMode: Equatable, Hashable, Sendable {
    case natal
    case transit
}

extension AppAsset {
    static func astrologyPlanetArtwork(_ planet: AstrologyPlanetID) -> AppAsset {
        switch planet {
        case .sun: .astrologyPlanetSunArtwork
        case .moon: .astrologyPlanetMoonArtwork
        case .mercury: .astrologyPlanetMercuryArtwork
        case .venus: .astrologyPlanetVenusArtwork
        case .mars: .astrologyPlanetMarsArtwork
        case .jupiter: .astrologyPlanetJupiterArtwork
        case .saturn: .astrologyPlanetSaturnArtwork
        case .uranus: .astrologyPlanetUranusArtwork
        case .neptune: .astrologyPlanetNeptuneArtwork
        case .pluto: .astrologyPlanetPlutoArtwork
        }
    }

    static func astrologyPlanetGlyph(_ planet: AstrologyPlanetID) -> AppAsset {
        switch planet {
        case .sun: .astrologyPlanetSunGlyph
        case .moon: .astrologyPlanetMoonGlyph
        case .mercury: .astrologyPlanetMercuryGlyph
        case .venus: .astrologyPlanetVenusGlyph
        case .mars: .astrologyPlanetMarsGlyph
        case .jupiter: .astrologyPlanetJupiterGlyph
        case .saturn: .astrologyPlanetSaturnGlyph
        case .uranus: .astrologyPlanetUranusGlyph
        case .neptune: .astrologyPlanetNeptuneGlyph
        case .pluto: .astrologyPlanetPlutoGlyph
        }
    }

    static func astrologyZodiac(_ sign: AstrologyZodiacID) -> AppAsset {
        switch sign {
        case .aries: .astrologyZodiacAries
        case .taurus: .astrologyZodiacTaurus
        case .gemini: .astrologyZodiacGemini
        case .cancer: .astrologyZodiacCancer
        case .leo: .astrologyZodiacLeo
        case .virgo: .astrologyZodiacVirgo
        case .libra: .astrologyZodiacLibra
        case .scorpio: .astrologyZodiacScorpio
        case .sagittarius: .astrologyZodiacSagittarius
        case .capricorn: .astrologyZodiacCapricorn
        case .aquarius: .astrologyZodiacAquarius
        case .pisces: .astrologyZodiacPisces
        }
    }

    static func astrologyConstellation(_ sign: AstrologyZodiacID) -> AppAsset {
        switch sign {
        case .aries: .astrologyConstellationAries
        case .taurus: .astrologyConstellationTaurus
        case .gemini: .astrologyConstellationGemini
        case .cancer: .astrologyConstellationCancer
        case .leo: .astrologyConstellationLeo
        case .virgo: .astrologyConstellationVirgo
        case .libra: .astrologyConstellationLibra
        case .scorpio: .astrologyConstellationScorpio
        case .sagittarius: .astrologyConstellationSagittarius
        case .capricorn: .astrologyConstellationCapricorn
        case .aquarius: .astrologyConstellationAquarius
        case .pisces: .astrologyConstellationPisces
        }
    }
}

@Reducer
struct AstrologyProfilePickerFeature {
    @ObservableState
    struct State: Equatable {
        var profiles: [UserProfile]
        var selectedID: String?
    }

    enum Action: Equatable {
        case profileTapped(String)
        case closeTapped
        case delegate(Delegate)

        enum Delegate: Equatable {
            case selected(UserProfile)
            case close
        }
    }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .profileTapped(id):
                guard let profile = state.profiles.first(where: { $0.id == id }) else { return .none }
                state.selectedID = id
                return .send(.delegate(.selected(profile)))
            case .closeTapped:
                return .send(.delegate(.close))
            case .delegate:
                return .none
            }
        }
    }
}

@Reducer
struct AstrologyBirthDataFeature {
    @ObservableState
    struct State: Equatable {
        var profile: UserProfile
        var place: String
        var selectedReference: BirthLocationReference?
        var knowsBirthTime: Bool
        var birthTime: String
        var errorMessage: String?
        @Presents var placePicker: BirthPlacePickerFeature.State?

        init(profile: UserProfile) {
            self.profile = profile
            self.place = profile.birthPlace ?? profile.birthLocation?.userLabel ?? ""
            self.selectedReference = profile.birthLocation
            self.knowsBirthTime = profile.effectiveBirthTimeAccuracy == .exact
            self.birthTime = profile.birthTime ?? ""
        }
    }

    enum Action: Equatable {
        case placeChanged(String)
        case knowsBirthTimeChanged(Bool)
        case birthTimeChanged(String)
        case choosePlaceTapped
        case saveTapped
        case closeTapped
        case placePicker(PresentationAction<BirthPlacePickerFeature.Action>)
        case delegate(Delegate)

        enum Delegate: Equatable {
            case saved(UserProfile)
            case close
        }
    }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .placeChanged(value):
                state.place = value
                state.errorMessage = nil
                if value.trimmingCharacters(in: .whitespacesAndNewlines).localizedCaseInsensitiveCompare(
                    state.selectedReference?.userLabel ?? ""
                ) != .orderedSame {
                    state.selectedReference = nil
                }
                return .none

            case let .knowsBirthTimeChanged(value):
                state.knowsBirthTime = value
                state.errorMessage = nil
                return .none

            case let .birthTimeChanged(value):
                state.birthTime = value
                state.errorMessage = nil
                return .none

            case .choosePlaceTapped:
                var picker = BirthPlacePickerFeature.State()
                picker.query = state.place
                state.placePicker = picker
                return .none

            case .saveTapped:
                let place = state.place.trimmingCharacters(in: .whitespacesAndNewlines)
                guard place.count >= 3 else {
                    state.errorMessage = "Vui lòng nhập thành phố hoặc khu vực nơi bạn sinh ra."
                    return .none
                }
                guard let reference = state.selectedReference else {
                    state.errorMessage = "Vui lòng chọn một địa điểm từ danh sách đề xuất."
                    return .none
                }
                let normalizedTime: String?
                if state.knowsBirthTime {
                    guard let value = Self.normalizeBirthTime(state.birthTime) else {
                        state.errorMessage = "Giờ sinh cần đúng định dạng HH:mm, ví dụ 14:30."
                        return .none
                    }
                    normalizedTime = value
                } else {
                    normalizedTime = nil
                }
                var profile = state.profile
                profile.birthPlace = reference.userLabel
                profile.birthLocation = reference
                profile.birthTime = normalizedTime
                profile.birthTimeAccuracy = state.knowsBirthTime ? .exact : .unknown
                state.errorMessage = nil
                return .send(.delegate(.saved(profile)))

            case .closeTapped:
                return .send(.delegate(.close))

            case let .placePicker(.presented(.delegate(.selected(reference, _)))):
                state.place = reference.userLabel
                state.selectedReference = reference
                state.placePicker = nil
                state.errorMessage = nil
                return .none

            case .placePicker(.presented(.delegate(.skipped))):
                state.placePicker = nil
                return .none

            case .placePicker, .delegate:
                return .none
            }
        }
        .ifLet(\.$placePicker, action: \.placePicker) {
            BirthPlacePickerFeature()
        }
    }

    static func normalizeBirthTime(_ value: String) -> String? {
        let parts = value.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: ":")
        guard parts.count == 2,
              let hour = Int(parts[0]),
              let minute = Int(parts[1]),
              (0 ... 23).contains(hour),
              (0 ... 59).contains(minute)
        else { return nil }
        return String(format: "%02d:%02d", hour, minute)
    }
}

@Reducer
struct AstrologyNatalFeature {
    @ObservableState
    struct State: Equatable {}

    enum Action: Equatable {
        case backTapped
        case editBirthDataTapped
        case detailTapped(AstrologyDetailTarget)
    }

    var body: some Reducer<State, Action> { EmptyReducer() }
}

@Reducer
struct AstrologyDetailFeature {
    @ObservableState
    struct State: Equatable {
        var target: AstrologyDetailTarget
        var mode: AstrologyPlanetDetailMode
    }

    enum Action: Equatable {
        case backTapped
        case editBirthDataTapped
        case modeChanged(AstrologyPlanetDetailMode)
    }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .modeChanged(mode):
                state.mode = mode
                return .none
            case .backTapped, .editBirthDataTapped:
                return .none
            }
        }
    }
}
