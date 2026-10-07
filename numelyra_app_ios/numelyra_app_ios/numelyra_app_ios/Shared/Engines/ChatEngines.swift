import Foundation

enum ChatDecisionEngine {
    static let trashReply = """
    ✦ TIỂU LINH MIÊU NHẮN BẠN:
    Câu hỏi của bạn dường như chưa có chủ đề hoặc mục đích rõ ràng.

    Bạn hãy thử hỏi cụ thể hơn, ví dụ: “Sự nghiệp trong 6 tháng tới của tôi sẽ ra sao?”
    """

    static func evaluate(_ question: String, profiles: [UserProfile]) -> AgentDecision {
        let q = question.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if isTrash(q) {
            return AgentDecision(mode: .single, intent: .trash, needsTarot: false, thoughtProcess: "Câu hỏi chưa rõ chủ đề.", replyText: trashReply)
        }
        if profiles.count >= 2 {
            return AgentDecision(mode: .compatibility, intent: .loveMatch, needsTarot: false, targetIndicators: ["walksOfLife", "soul", "ziwei_compatibility_v2"], thoughtProcess: "Phân tích tương hợp hai hồ sơ bằng Tử Vi ruleset v2 và Thần số học.")
        }
        if ColorGuidanceEngine.isColorQuestion(q) {
            return AgentDecision(mode: .single, intent: .colorGuidance, needsTarot: true, spreadId: .single, cardCount: 1, thoughtProcess: "Rút một lá để ưu tiên hai màu trong bảng màu hợp mệnh.")
        }
        if matches(q, #"(hay|hoặc|vs|phân vân|lựa chọn|ở lại hay|mua hay|đi hay ở)"#), matches(q, #"(nên|chọn|giữa|a hay b)"#) {
            return AgentDecision(mode: .single, intent: .twoChoices, needsTarot: true, spreadId: .twoOptions, cardCount: 5, targetIndicators: ["rationalThinking", "attitude"], thoughtProcess: "So sánh hai lựa chọn bằng trải bài năm lá.")
        }
        if matches(q, #"(đi đâu|chỗ nào|nơi nào|quán nào|cà phê nào|cafe nào|địa điểm|đi chơi|hẹn hò ở đâu|dạo ở đâu|tham quan)"#) {
            return AgentDecision(mode: .single, intent: .whereToGo, needsTarot: true, spreadId: .single, cardCount: 1, targetIndicators: ["attitude", "soul"], thoughtProcess: "Lọc vị trí và dùng một lá Tarot để chọn không khí phù hợp.")
        }
        if matches(q, #"(tính cách|bản thân tôi|điểm mạnh|điểm yếu|sứ mệnh|nợ nghiệp|số thiếu|linh hồn|ý nghĩa tên|ngày sinh nói lên|con người tôi|phong cách)"#), !matches(q, #"(tương lai|sau này|sắp tới|người yêu|hôm nay)"#) {
            let keys = q.contains("sứ mệnh") ? ["mission", "walksOfLife", "soul"] : ["walksOfLife", "soul", "personality", "attitude", "rationalThinking"]
            return AgentDecision(mode: .single, intent: .corePersonality, needsTarot: false, targetIndicators: keys, thoughtProcess: "Đối chiếu trực tiếp các chỉ số cốt lõi, không rút Tarot.")
        }
        if matches(q, #"(tương lai|sắp tới|tiến trình|dạo này|thời gian tới|xu hướng|phát triển|sau này|năm nay|tháng này)"#) {
            return AgentDecision(mode: .single, intent: .timingTrajectory, needsTarot: true, spreadId: .threeCard, cardCount: 3, targetIndicators: ["attitude", "rationalThinking"], thoughtProcess: "Đọc tiến trình quá khứ, hiện tại và tương lai gần.")
        }
        if matches(q, #"(hôm nay|ngày mai|lúc này|bây giờ|có nên không|lời khuyên|thông điệp|dẫn lối|nhắn nhủ)"#) {
            return AgentDecision(mode: .single, intent: .dailyGuidance, needsTarot: true, spreadId: .single, cardCount: 1, targetIndicators: ["attitude", "soul"], thoughtProcess: "Rút một lá cho lời khuyên trước mắt.")
        }
        return AgentDecision(mode: .single, intent: .general, needsTarot: true, spreadId: .single, cardCount: 1, targetIndicators: ["attitude", "soul"], thoughtProcess: "Rút một lá và tham khảo nhu cầu nội tâm.")
    }

    private static func isTrash(_ q: String) -> Bool {
        if q.count <= 2 || matches(q, #"^(\d{1,8}|[!?.,\s]+)$"#) { return true }
        if matches(q, #"^(test|testing|alo|alô|hello|hi|hey|abc|xyz|không biết hỏi gì|chưa biết hỏi gì)$"#) { return true }
        return matches(q, #"(asdf|ghjk|qwerty|zxcv|poiuy|lkjh|mnbv)"#)
    }

    private static func matches(_ value: String, _ pattern: String) -> Bool {
        value.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil
    }
}

enum ColorGuidanceEngine {
    static let sourceURL = "https://apx-security-de.audible.de/podcast/Phong-Thy-Vit/B0GXTYN66R"

    static func isColorQuestion(_ text: String) -> Bool {
        text.range(of: #"\bmàu\b|màu\s+(hợp|may mắn|gì|nào|nên|sắc)|phối\s+màu|mặc\s+màu|sơn\s+màu"#, options: [.regularExpression, .caseInsensitive]) != nil
    }

    static func create(birthDate: String, card: DrawnTarotCard) throws -> ColorGuidanceContext {
        let parts = birthDate.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { throw ChatError.invalidProfile }
        let lunarYear = LunarService.solarToLunar(day: parts[2], month: parts[1], year: parts[0]).year
        let element: FengShuiElement
        switch abs(lunarYear) % 10 { case 0, 1: element = .kim; case 2, 3: element = .thuy; case 4, 5: element = .moc; case 6, 7: element = .hoa; default: element = .tho }
        let palette = palettes[element] ?? []
        let tarotElement = elementForCard(card.card.id)
        var priority = priorities[tarotElement] ?? []
        if card.isReversed { priority.reverse() }
        let ids = priority.filter { id in palette.contains(where: { $0.id == id }) }
        guard ids.count >= 2 else { throw ChatError.invalidResponse }
        return ColorGuidanceContext(ruleVersion: "v1", sourceUrl: sourceURL, lunarYear: lunarYear, element: element, palette: palette, selectedColorIds: .init(first: ids[0], second: ids[1]), tarotElement: tarotElement, cardId: card.card.id, isReversed: card.isReversed)
    }

    private static func elementForCard(_ id: String) -> TarotElement {
        if id.hasPrefix("cups-") { return .water }; if id.hasPrefix("swords-") { return .air }; if id.hasPrefix("pentacles-") { return .earth }; if id.hasPrefix("wands-") { return .fire }
        if ["0-fool", "1-magician", "6-lovers", "11-justice", "17-star"].contains(id) { return .air }
        if ["2-high-priestess", "7-chariot", "12-hanged-man", "13-death", "18-moon"].contains(id) { return .water }
        if ["3-empress", "5-hierophant", "9-hermit", "15-devil", "21-world"].contains(id) { return .earth }
        return .fire
    }

    private static let colors: [FengShuiColorID: FengShuiColor] = [
        .white: .init(id: .white, name: "Trắng", hex: "#F7F5F0"), .gray: .init(id: .gray, name: "Xám", hex: "#8A8D91"), .silver: .init(id: .silver, name: "Bạc", hex: "#C0C5C9"), .yellow: .init(id: .yellow, name: "Vàng", hex: "#E8C547"), .beige: .init(id: .beige, name: "Be", hex: "#D9C4A3"), .black: .init(id: .black, name: "Đen", hex: "#15171A"), .navy: .init(id: .navy, name: "Xanh đậm", hex: "#183A63"), .purple: .init(id: .purple, name: "Tím", hex: "#6D4C9B"), .green: .init(id: .green, name: "Xanh lá", hex: "#3C8D45"), .blue: .init(id: .blue, name: "Xanh lam", hex: "#2878B8"), .moss: .init(id: .moss, name: "Xanh rêu", hex: "#647A3C"), .red: .init(id: .red, name: "Đỏ", hex: "#C93434"), .orange: .init(id: .orange, name: "Cam", hex: "#E97824"), .pink: .init(id: .pink, name: "Hồng", hex: "#D85B8E"), .coral: .init(id: .coral, name: "Cam san hô", hex: "#F07D63"), .brown: .init(id: .brown, name: "Nâu", hex: "#7A4E32")
    ]
    private static let palettes: [FengShuiElement: [FengShuiColor]] = [
        .kim: [.white, .gray, .silver, .yellow, .beige].compactMap { colors[$0] }, .thuy: [.black, .navy, .purple, .white, .gray].compactMap { colors[$0] }, .moc: [.green, .blue, .black, .purple, .moss].compactMap { colors[$0] }, .hoa: [.red, .orange, .pink, .green, .coral].compactMap { colors[$0] }, .tho: [.yellow, .brown, .beige, .red, .orange].compactMap { colors[$0] }
    ]
    private static let priorities: [TarotElement: [FengShuiColorID]] = [
        .fire: [.red, .orange, .coral, .pink, .yellow, .green, .black, .navy, .purple, .blue, .white, .gray, .silver, .beige, .brown, .moss], .water: [.black, .navy, .purple, .blue, .white, .gray, .silver, .green, .moss, .pink, .coral, .red, .orange, .yellow, .beige, .brown], .air: [.white, .gray, .silver, .blue, .purple, .black, .navy, .green, .moss, .yellow, .beige, .brown, .orange, .coral, .pink, .red], .earth: [.brown, .beige, .yellow, .orange, .red, .moss, .green, .black, .navy, .purple, .blue, .white, .gray, .silver, .pink, .coral]
    ]
}

enum ChatSynthesisEngine {
    static func make(prompt: String, decision: AgentDecision, profiles: [UserProfile], indicators: [NumerologyIndicator], cards: [DrawnTarotCard], color: ColorGuidanceContext? = nil, ziWeiCompatibility: ChatZiWeiCompatibilityPayload? = nil) -> (String, AgentSynthesisPayload) {
        let person = profiles.first?.fullName ?? "bạn"
        let text: String
        switch decision.intent {
        case .loveMatch:
            if let compatibility = ziWeiCompatibility {
                text = "✦ KẾT LUẬN TƯƠNG HỢP:\nMức độ hòa hợp theo Tử Vi mới là \(compatibility.analysis.score)/100.\n\n✦ VÌ SAO:\n\(compatibility.analysis.summaryVi)\n\n✦ NÊN LÀM GÌ:\n\(compatibility.analysis.disclaimerVi)"
            } else {
                text = "✦ CHƯA THỂ LẬP ĐỦ HAI LÁ SỐ:\nHãy kiểm tra ngày sinh, giới tính và giờ sinh của hai hồ sơ rồi thử lại."
            }
        case .corePersonality:
            let lines = indicators.map { "• \($0.name) = \($0.value.displayValue): \($0.meaning)" }.joined(separator: "\n")
            text = "✦ KẾT LUẬN NHANH:\nBản đồ của \(person) cho thấy những thế mạnh riêng cần được phát huy.\n\n✦ VÌ SAO:\n\(lines)\n\n✦ NÊN LÀM GÌ:\nHãy chọn một thế mạnh để thực hành đều đặn trong 7 ngày tới."
        case .colorGuidance:
            let names = color?.palette.filter { [$0.id].contains(color?.selectedColorIds.first) || [$0.id].contains(color?.selectedColorIds.second) }.map(\.name).joined(separator: " và ") ?? "màu hợp mệnh"
            text = "✦ KẾT LUẬN NHANH:\nHôm nay bạn có thể ưu tiên \(names).\n\n✦ NÊN LÀM GÌ:\nDùng hai gam màu này làm điểm nhấn và giữ phần còn lại trung tính."
        case .whereToGo:
            text = "✦ CHƯA THỂ TÌM ĐỊA ĐIỂM:\nKết nối đang gián đoạn nên Numelyra không tạo địa điểm giả. Hãy thử lại khi có mạng."
        default:
            if let card = cards.first {
                let meaning = card.isReversed ? card.card.meaningReversed : card.card.meaningUpright
                text = "✦ KẾT LUẬN NHANH:\nThông điệp dành cho \(person): \(meaning)\n\n✦ NÊN LÀM GÌ:\nChậm lại một nhịp, đối chiếu trực giác với hoàn cảnh thực tế rồi mới quyết định."
            } else {
                text = "✦ KẾT LUẬN NHANH:\nNumelyra đã đối chiếu câu hỏi với hồ sơ của bạn.\n\n✦ NÊN LÀM GÌ:\nHãy bắt đầu từ một hành động nhỏ, cụ thể và có thể kiểm chứng."
            }
        }
        return (text, AgentSynthesisPayload(decision: decision, profiles: profiles, drawnCards: cards, indicators1: indicators, ziWeiCompatibility: ziWeiCompatibility, colorGuidance: color, compatibilityScore: ziWeiCompatibility?.analysis.score, questionText: prompt))
    }
}

enum ChatError: LocalizedError, Equatable, Sendable {
    case invalidProfile, invalidResponse, server(String), permissionDenied(String)
    var errorDescription: String? {
        switch self { case .invalidProfile: return "Hồ sơ không hợp lệ."; case .invalidResponse: return "Dữ liệu Chat không hợp lệ."; case let .server(message), let .permissionDenied(message): return message }
    }
}
