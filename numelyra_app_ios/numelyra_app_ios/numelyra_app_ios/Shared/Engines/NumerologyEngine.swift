import Foundation

/// Pure port of the two active React Native numerology calculators.
///
/// `calculate24` mirrors `numerologyEngine.ts`, including its legacy quirks.
/// `requestedIndicators` mirrors the smaller calculator used by Chat/Wallpaper.
/// Time is always injectable so personal cycles remain deterministic in tests.
nonisolated enum NumerologyEngine {
    private static let pythagoreanTable: [Character: Int] = [
        "A": 1, "J": 1, "S": 1,
        "B": 2, "K": 2, "T": 2,
        "C": 3, "L": 3, "U": 3,
        "D": 4, "M": 4, "V": 4,
        "E": 5, "N": 5, "W": 5,
        "F": 6, "O": 6, "X": 6,
        "G": 7, "P": 7, "Y": 7,
        "H": 8, "Q": 8, "Z": 8,
        "I": 9, "R": 9,
    ]

    private static let standardVowels: Set<Character> = ["A", "E", "I", "O", "U"]
    private static let agentSupportedKeys: Set<NumerologyIndicatorKey> = [
        .walksOfLife,
        .mission,
        .soul,
        .personality,
        .dateOfBirth,
        .mature,
        .rationalThinking,
        .yearIndividual,
        .attitude,
    ]

    static func calculate24(
        fullName: String,
        birthDate rawBirthDate: String,
        referenceDate: Date = Date(),
        calendar inputCalendar: Calendar = .current
    ) -> NumerologySnapshot {
        let calendar = inputCalendar
        let current = calendar.dateComponents([.year, .month, .day], from: referenceDate)
        let birthDate = parseCardsBirthDate(
            rawBirthDate,
            referenceDate: referenceDate,
            calendar: calendar
        )

        let normalizedName = normalizeName(fullName.isEmpty ? "NGUOI DUNG" : fullName)
        let words = normalizedName.split(separator: " ").map(String.init)
        let allLetters = words.joined().map { $0 }
        let day = birthDate.day
        let month = birthDate.month
        let year = birthDate.year

        let paddedDate = twoDigits(day) + twoDigits(month) + String(year)
        let lifeDigitSum = paddedDate.compactMap(\.wholeNumberValue).reduce(0, +)
        let walksOfLife = reduceCardsLifePath(lifeDigitSum)

        let missionSum = sumLetters(allLetters)
        let mission = reduceNumber(missionSum, keepMaster: true)

        var soulSum = 0
        var personalitySum = 0
        for word in words {
            for character in word {
                if isVowel(character, in: word) {
                    soulSum += pythagoreanTable[character] ?? 0
                } else {
                    personalitySum += pythagoreanTable[character] ?? 0
                }
            }
        }
        let soul = reduceNumber(soulSum, keepMaster: true)
        let personality = reduceNumber(personalitySum, keepMaster: true)
        let birthday = day == 11 || day == 22 ? day : reduceNumber(day, keepMaster: false)
        let maturity = reduceNumber(walksOfLife + mission, keepMaster: true)

        let balanceSum = words.reduce(0) { result, word in
            result + (word.first.flatMap { pythagoreanTable[$0] } ?? 0)
        }
        let balance = reduceNumber(balanceSum, keepMaster: false)

        let firstName = words.last ?? ""
        let rationalThinking = reduceNumber(
            reduceNumber(sumLetters(Array(firstName)), keepMaster: false)
                + reduceNumber(day, keepMaster: false),
            keepMaster: false
        )

        var nameFrequencies = zeroFrequencies()
        for character in allLetters {
            guard let value = pythagoreanTable[character] else { continue }
            nameFrequencies[value, default: 0] += 1
        }
        let missingNumbers = (1 ... 9).filter { nameFrequencies[$0, default: 0] == 0 }
        let subconsciousPower = 9 - missingNumbers.count
        let maximumFrequency = nameFrequencies.values.max() ?? 0
        let hiddenPassions = maximumFrequency > 0
            ? (1 ... 9).filter { nameFrequencies[$0, default: 0] == maximumFrequency }
            : []

        let passionDisplay = hiddenPassions.isEmpty
            ? "Không xác định"
            : hiddenPassions.map(String.init).joined(separator: ", ")
        let missingDisplay = missingNumbers.isEmpty
            ? "Không thiếu"
            : missingNumbers.map(String.init).joined(separator: ", ")

        let attitude = reduceNumber(
            reduceNumber(day, keepMaster: false) + reduceNumber(month, keepMaster: false),
            keepMaster: false
        )

        var karmicDebts: [String] = []
        appendKarmicDebt(day, to: &karmicDebts)
        let rawLifePath = reduceNumber(day, keepMaster: false)
            + reduceNumber(month, keepMaster: false)
            + reduceNumber(year, keepMaster: false)
        appendKarmicDebt(rawLifePath, to: &karmicDebts)
        appendKarmicDebt(missionSum, to: &karmicDebts)
        let karmicDisplay = karmicDebts.isEmpty
            ? "Không có nợ nghiệp"
            : karmicDebts.joined(separator: ", ")

        let bridgeLifeMission = abs(
            reduceNumber(walksOfLife, keepMaster: false)
                - reduceNumber(mission, keepMaster: false)
        )
        let bridgeSoulPersonality = abs(
            reduceNumber(soul, keepMaster: false)
                - reduceNumber(personality, keepMaster: false)
        )
        // React Native V1 stores hidden passion as a string, so its typeof check
        // always falls back to zero. Preserve that result in the parity ruleset.
        let bridgeMaturityPassion = abs(reduceNumber(maturity, keepMaster: false) - 0)

        let currentYear = current.year ?? 2000
        let currentMonth = current.month ?? 1
        let currentDay = current.day ?? 1
        let personalYear = reduceNumber(
            reduceNumber(currentYear, keepMaster: false)
                + reduceNumber(day, keepMaster: false)
                + reduceNumber(month, keepMaster: false),
            keepMaster: false
        )
        let personalMonth = reduceNumber(
            personalYear + reduceNumber(currentMonth, keepMaster: false),
            keepMaster: false
        )
        let personalDay = reduceNumber(
            personalMonth + reduceNumber(currentDay, keepMaster: false),
            keepMaster: false
        )

        let reducedMonth = reduceNumber(month, keepMaster: false)
        let reducedDay = reduceNumber(day, keepMaster: false)
        let reducedYear = reduceNumber(year, keepMaster: false)
        let pinnacle1 = reducePinnacle(reducedMonth + reducedDay, preservesTenAndEleven: false)
        let pinnacle2 = reducePinnacle(reducedDay + reducedYear, preservesTenAndEleven: false)
        let pinnacle3 = reducePinnacle(pinnacle1 + pinnacle2, preservesTenAndEleven: true)
        let pinnacle4 = reducePinnacle(reducedMonth + reducedYear, preservesTenAndEleven: true)
        let pinnacles = [pinnacle1, pinnacle2, pinnacle3, pinnacle4]

        let challenge1 = abs(reducedMonth - reducedDay)
        let challenge2 = abs(reducedYear - reducedDay)
        let challenge3 = abs(challenge1 - challenge2)
        let challenge4 = abs(reducedMonth - reducedYear)
        let challenges = [challenge1, challenge2, challenge3, challenge4]

        let birthDigitText = String(day) + String(month) + String(year)
        let birthDigits = birthDigitText.compactMap(\.wholeNumberValue)
        var birthFrequencies = zeroFrequencies()
        for digit in birthDigits where (1 ... 9).contains(digit) {
            birthFrequencies[digit, default: 0] += 1
        }
        let arrows = detectedArrows(in: birthFrequencies)
        let arrowsDisplay = arrows.isEmpty
            ? "Cân bằng tự nhiên"
            : arrows.map(\.displayValue).joined(separator: "; ")

        let values: [(NumerologyIndicatorKey, NumerologyValue, Bool)] = [
            (.walksOfLife, .number(walksOfLife), isMaster(walksOfLife)),
            (.mission, .number(mission), isMaster(mission)),
            (.soul, .number(soul), isMaster(soul)),
            (.personality, .number(personality), isMaster(personality)),
            (.dateOfBirth, .number(birthday), birthday == 11 || birthday == 22),
            (.mature, .number(maturity), isMaster(maturity)),
            (.balance, .number(balance), false),
            (.rationalThinking, .number(rationalThinking), false),
            (.subconsciousPower, .number(subconsciousPower), false),
            (.passion, .text(passionDisplay), false),
            (.attitude, .number(attitude), false),
            (.karmicDebts, .text(karmicDisplay), false),
            (.missingNumbers, .text(missingDisplay), false),
            (.bridgeLifeMission, .number(bridgeLifeMission), false),
            (.bridgeSoulPersonality, .number(bridgeSoulPersonality), false),
            (.bridgeMaturityPassion, .number(bridgeMaturityPassion), false),
            (.yearIndividual, .number(personalYear), false),
            (.monthIndividual, .number(personalMonth), false),
            (.dayIndividual, .number(personalDay), false),
            (.way, .text(pinnacles.map(String.init).joined(separator: " - ")), false),
            (.challenges, .text(challenges.map(String.init).joined(separator: " - ")), false),
            (.arrows, .text(arrowsDisplay), false),
            (.nameChart, .text("Tổng \(allLetters.count) chữ cái"), false),
            (.birthChart, .text("Tổng \(birthDigitText.count) chữ số ngày sinh"), false),
        ]

        return NumerologySnapshot(
            rulesetVersion: .reactNativeCardsV1,
            normalizedName: normalizedName,
            birthDate: birthDate,
            referenceDate: referenceDate,
            indicators: values.map {
                NumerologyComputedIndicator(key: $0.0, value: $0.1, isMaster: $0.2)
            },
            nameFrequencies: nameFrequencies,
            birthFrequencies: birthFrequencies,
            missingNumbers: missingNumbers,
            hiddenPassions: hiddenPassions,
            karmicDebts: karmicDebts,
            pinnacles: pinnacles,
            challenges: challenges,
            arrows: arrows
        )
    }

    static func calculate24Cards(
        fullName: String,
        birthDate rawBirthDate: String,
        referenceDate: Date = Date(),
        calendar inputCalendar: Calendar = .current
    ) -> [CalculatedNumerologyIndicator] {
        let snapshot = calculate24(
            fullName: fullName,
            birthDate: rawBirthDate,
            referenceDate: referenceDate,
            calendar: inputCalendar
        )
        let byKey = Dictionary(
            uniqueKeysWithValues: snapshot.indicators.map { ($0.key.rawValue, $0) }
        )
        return NumerologyCardCatalog.all.map { card in
            if let computed = byKey[card.key] {
                return CalculatedNumerologyIndicator(
                    definition: card,
                    value: computed.value,
                    displayValue: computed.value.displayValue,
                    isMaster: computed.isMaster
                )
            }
            return CalculatedNumerologyIndicator(
                definition: card,
                value: .text("—"),
                displayValue: "—",
                isMaster: false
            )
        }
    }

    static func requestedIndicators(
        fullName: String,
        birthDate rawBirthDate: String,
        keys: [String],
        referenceDate: Date = Date(),
        calendar inputCalendar: Calendar = .current
    ) -> [NumerologyIndicator] {
        let birthDate = parseAgentBirthDate(rawBirthDate)
        let normalizedName = normalizeName(fullName)
        let words = normalizedName.split(separator: " ").map(String.init)
        let allLetters = words.joined().map { $0 }
        let day = birthDate.day
        let month = birthDate.month
        let year = birthDate.year

        let reducedDay = reduceNumber(day, keepMaster: false)
        let reducedMonth = reduceNumber(month, keepMaster: false)
        let reducedYear = reduceNumber(year, keepMaster: false)
        let walksOfLife = reduceNumber(reducedDay + reducedMonth + reducedYear, keepMaster: true)
        let mission = reduceNumber(sumLetters(allLetters), keepMaster: true)

        var soulSum = 0
        var personalitySum = 0
        for word in words {
            for character in word {
                if isVowel(character, in: word) {
                    soulSum += pythagoreanTable[character] ?? 0
                } else {
                    personalitySum += pythagoreanTable[character] ?? 0
                }
            }
        }
        let soul = reduceNumber(soulSum, keepMaster: true)
        let personality = reduceNumber(personalitySum, keepMaster: true)
        let birthday = day == 11 || day == 22 ? day : reduceNumber(day, keepMaster: false)
        let maturity = reduceNumber(walksOfLife + mission, keepMaster: true)
        let firstNameSum = sumLetters(Array(words.last ?? ""))
        let rationalThinking = reduceNumber(
            reducedDay + reduceNumber(firstNameSum, keepMaster: false),
            keepMaster: true
        )
        let calendar = inputCalendar
        let targetYear = calendar.component(.year, from: referenceDate)
        let personalYear = reduceNumber(
            reducedDay + reducedMonth + reduceNumber(targetYear, keepMaster: false),
            keepMaster: false
        )
        let attitude = reduceNumber(reducedDay + reducedMonth, keepMaster: false)

        let values: [NumerologyIndicatorKey: Int] = [
            .walksOfLife: walksOfLife,
            .mission: mission,
            .soul: soul,
            .personality: personality,
            .dateOfBirth: birthday,
            .mature: maturity,
            .rationalThinking: rationalThinking,
            .yearIndividual: personalYear,
            .attitude: attitude,
        ]

        return keys.compactMap { rawKey in
            guard let key = NumerologyIndicatorKey(rawValue: rawKey),
                  agentSupportedKeys.contains(key),
                  let value = values[key]
            else { return nil }
            return agentIndicator(key: key, value: value, targetYear: targetYear)
        }
    }

    static func normalizeName(_ rawName: String) -> String {
        guard !rawName.isEmpty else { return "" }
        let replacedD = rawName.replacingOccurrences(of: "đ", with: "d")
            .replacingOccurrences(of: "Đ", with: "D")
        let folded = replacedD.folding(
            options: [.diacriticInsensitive],
            locale: Locale(identifier: "vi_VN")
        ).uppercased()

        var output = ""
        var pendingSpace = false
        for scalar in folded.unicodeScalars {
            if (65 ... 90).contains(Int(scalar.value)) {
                if pendingSpace, !output.isEmpty { output.append(" ") }
                output.unicodeScalars.append(scalar)
                pendingSpace = false
            } else if CharacterSet.whitespacesAndNewlines.contains(scalar) {
                pendingSpace = !output.isEmpty
            } else {
                pendingSpace = !output.isEmpty
            }
        }
        return output
    }

    static func isVowel(_ character: Character, in word: String) -> Bool {
        let upper = Character(String(character).uppercased())
        if standardVowels.contains(upper) { return true }
        guard upper == "Y" else { return false }
        return !word.contains { standardVowels.contains(Character(String($0).uppercased())) }
    }

    static func reduceNumber(_ number: Int, keepMaster: Bool = true) -> Int {
        var current = abs(number)
        while current > 9 {
            if keepMaster, isMaster(current) { break }
            current = String(current).compactMap(\.wholeNumberValue).reduce(0, +)
        }
        return current
    }

    private static func isMaster(_ number: Int) -> Bool {
        number == 11 || number == 22 || number == 33
    }

    private static func reduceCardsLifePath(_ number: Int) -> Int {
        var current = number
        while current >= 10, current != 10, current != 11, current != 22 {
            current = String(current).compactMap(\.wholeNumberValue).reduce(0, +)
        }
        return current
    }

    private static func reducePinnacle(_ number: Int, preservesTenAndEleven: Bool) -> Int {
        var current = number
        while current >= 10 {
            if preservesTenAndEleven, current == 10 || current == 11 { return current }
            current = String(current).compactMap(\.wholeNumberValue).reduce(0, +)
        }
        return current
    }

    private static func sumLetters(_ letters: [Character]) -> Int {
        letters.reduce(0) { $0 + (pythagoreanTable[$1] ?? 0) }
    }

    private static func zeroFrequencies() -> [Int: Int] {
        Dictionary(uniqueKeysWithValues: (1 ... 9).map { ($0, 0) })
    }

    private static func detectedArrows(in frequencies: [Int: Int]) -> [NumerologyArrow] {
        let paths = [
            [1, 4, 7], [2, 5, 8], [3, 6, 9],
            [1, 2, 3], [4, 5, 6], [7, 8, 9],
            [1, 5, 9], [3, 5, 7],
        ]
        return paths.compactMap { path in
            if path.allSatisfy({ frequencies[$0, default: 0] > 0 }) {
                return NumerologyArrow(digits: path, kind: .strong)
            }
            if path.allSatisfy({ frequencies[$0, default: 0] == 0 }) {
                return NumerologyArrow(digits: path, kind: .empty)
            }
            return nil
        }
    }

    private static func appendKarmicDebt(_ rawValue: Int, to debts: inout [String]) {
        let debt: String?
        switch rawValue {
        case 13: debt = "13/4"
        case 14: debt = "14/5"
        case 16: debt = "16/7"
        case 19: debt = "19/1"
        default: debt = nil
        }
        if let debt, !debts.contains(debt) { debts.append(debt) }
    }

    private static func parseCardsBirthDate(
        _ rawValue: String,
        referenceDate: Date,
        calendar: Calendar
    ) -> NumerologyBirthDate {
        if rawValue.isEmpty {
            let components = calendar.dateComponents([.year, .month, .day], from: referenceDate)
            return NumerologyBirthDate(
                day: components.day ?? 1,
                month: components.month ?? 1,
                year: components.year ?? 2000
            )
        }

        if rawValue.contains("-") {
            let datePart = rawValue.split(separator: "T", maxSplits: 1, omittingEmptySubsequences: false).first.map(String.init) ?? rawValue
            let parts = datePart.split(separator: "-", omittingEmptySubsequences: false).map(String.init)
            if parts.count >= 3 {
                return NumerologyBirthDate(
                    day: javascriptIntOrFallback(parts[2], fallback: 1),
                    month: javascriptIntOrFallback(parts[1], fallback: 1),
                    year: javascriptIntOrFallback(parts[0], fallback: 2000)
                )
            }
        } else if rawValue.contains("/") {
            let parts = rawValue.split(separator: "/", omittingEmptySubsequences: false).map(String.init)
            if parts.count >= 3 {
                return NumerologyBirthDate(
                    day: javascriptIntOrFallback(parts[0], fallback: 1),
                    month: javascriptIntOrFallback(parts[1], fallback: 1),
                    year: javascriptIntOrFallback(parts[2], fallback: 2000)
                )
            }
        }
        return NumerologyBirthDate(day: 1, month: 1, year: 2000)
    }

    private static func parseAgentBirthDate(_ rawValue: String) -> NumerologyBirthDate {
        let parts = rawValue.split(separator: "-", omittingEmptySubsequences: false).map(String.init)
        guard parts.count == 3 else {
            return NumerologyBirthDate(day: 1, month: 1, year: 2000)
        }
        return NumerologyBirthDate(
            day: javascriptIntOrFallback(parts[2], fallback: 1),
            month: javascriptIntOrFallback(parts[1], fallback: 1),
            year: javascriptIntOrFallback(parts[0], fallback: 2000)
        )
    }

    private static func javascriptIntOrFallback(_ value: String, fallback: Int) -> Int {
        guard let parsed = javascriptInt(value), parsed != 0 else { return fallback }
        return parsed
    }

    private static func javascriptInt(_ value: String) -> Int? {
        let trimmed = value.drop(while: { $0.isWhitespace })
        var result = ""
        var iterator = trimmed.makeIterator()
        if let first = iterator.next() {
            if first == "+" || first == "-" {
                result.append(first)
            } else if first.isNumber {
                result.append(first)
            } else {
                return nil
            }
        }
        while let character = iterator.next(), character.isNumber {
            result.append(character)
        }
        guard result != "+", result != "-" else { return nil }
        return Int(result)
    }

    private static func twoDigits(_ value: Int) -> String {
        value >= 0 && value < 10 ? "0\(value)" : String(value)
    }

    private static func agentIndicator(
        key: NumerologyIndicatorKey,
        value: Int,
        targetYear: Int
    ) -> NumerologyIndicator {
        let name: String
        let meaning: String
        switch key {
        case .walksOfLife:
            name = "Số Đường Đời (Life Path)"
            meaning = "Chỉ số cốt lõi số \(value), phản ánh bài học và con đường tiến hóa cả đời của bạn."
        case .mission:
            name = "Số Sứ Mệnh (Destiny / Mission)"
            meaning = "Năng lực bẩm sinh và đích đến mà bạn được sinh ra để cống hiến cho cuộc đời (Số \(value))."
        case .soul:
            name = "Số Linh Hồn (Soul Urge)"
            meaning = "Khát vọng sâu kín, điều thực sự nuôi dưỡng cảm xúc và mang lại hạnh phúc cho bạn (Số \(value))."
        case .personality:
            name = "Số Nhân Cách (Personality)"
            meaning = "Ấn tượng và phong thái bên ngoài mà người khác cảm nhận được từ bạn (Số \(value))."
        case .dateOfBirth:
            name = "Số Ngày Sinh (Birthday Number)"
            meaning = "Món quà tài năng đặc biệt và phản xạ tự nhiên trong cuộc sống thường nhật (Số \(value))."
        case .mature:
            name = "Số Trưởng Thành (Maturity)"
            meaning = "Sức mạnh nở rộ sau tuổi 35–40 khi Đường đời và Sứ mệnh hội tụ (Số \(value))."
        case .rationalThinking:
            name = "Số Tư Duy Lý Trí (Rational Thought)"
            meaning = "Cách bạn phân tích dữ kiện và đưa ra quyết định khi đứng trước các ngã rẽ (Số \(value))."
        case .yearIndividual:
            name = "Năm Cá Nhân \(targetYear) (Personal Year)"
            meaning = "Năm số \(value) trong chu kỳ 9 năm: \(personalYearTheme(value))"
        case .attitude:
            name = "Số Thái Độ (Attitude Number)"
            meaning = "Phản xạ đầu tiên và tâm thế của bạn khi đối diện biến cố hay cơ hội (Số \(value))."
        default:
            preconditionFailure("Unsupported React Native agent indicator: \(key.rawValue)")
        }
        return NumerologyIndicator(key: key.rawValue, name: name, value: .number(value), meaning: meaning)
    }

    private static func personalYearTheme(_ value: Int) -> String {
        switch value {
        case 1: return "Khởi đầu mới, tiên phong, đặt nền móng cho chu kỳ 9 năm tiếp theo."
        case 2: return "Hợp tác, hòa giải, kiên nhẫn, phát triển trực giác và các mối quan hệ."
        case 3: return "Mở rộng giao tiếp, sáng tạo, lan tỏa cảm hứng và học hỏi kỹ năng mới."
        case 4: return "Kỷ luật, củng cố nền tảng, làm việc kiên trì và quản lý tài chính vững chắc."
        case 5: return "Thay đổi, bứt phá giới hạn, linh hoạt, du lịch và đón nhận cơ hội bất ngờ."
        case 6: return "Gia đình, trách nhiệm, yêu thương, phụng sự và chăm sóc những người thân yêu."
        case 7: return "Chiêm nghiệm, tĩnh lặng, đào sâu tâm linh, nâng cao tri thức và nhìn lại chính mình."
        case 8: return "Gặt hái tài chính, quyền lực cá nhân, thành tựu sự nghiệp và đền đáp công sức."
        case 9: return "Khép lại chu kỳ, buông bỏ những điều không còn phù hợp, bao dung và chuẩn bị tái sinh."
        default: return "Chu kỳ phát triển cá nhân."
        }
    }
}
