import ComposableArchitecture
import SwiftUI

struct AstrologyDetailView: View {
    let store: StoreOf<AstrologyDetailFeature>
    let metadata: AstroFeatureMetadata?

    var body: some View {
        switch store.target {
        case let .planet(planet):
            planetView(planet)
        case let .sign(sign):
            signView(sign)
        }
    }

    private func planetView(_ planet: AstrologyPlanetID) -> some View {
        AstrologyBackground(asset: .astrologyBackgroundPlanetDetail) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    header(title: planet.nameVi, subtitle: store.mode == .natal ? "HÀNH TINH · BẢN MỆNH" : "HÀNH TINH · HIỆN TẠI")
                    Picker("Chế độ", selection: Binding(get: { store.mode }, set: { store.send(.modeChanged($0)) })) {
                        Text("Bản mệnh").tag(AstrologyPlanetDetailMode.natal)
                        Text("Hiện tại").tag(AstrologyPlanetDetailMode.transit)
                    }
                    .pickerStyle(.segmented)

                    planetHero(planet)

                    if let metadata {
                        if metadata.birthDataPrecision != .complete {
                            Button { store.send(.editBirthDataTapped) } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "compass.drawing").foregroundStyle(AstrologyPalette.cyan)
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text("Chưa thể xác định nhà").font(.subheadline.bold())
                                        Text(precisionMessage(metadata)).font(.caption).foregroundStyle(AstrologyPalette.muted)
                                    }
                                    Spacer(); Text("Bổ sung").font(.caption.bold()).foregroundStyle(AstrologyPalette.gold)
                                }
                                .padding(12).background(AstrologyPalette.navy.opacity(0.88), in: RoundedRectangle(cornerRadius: 17))
                            }.buttonStyle(.plain)
                        }

                        AstrologySectionTitle(eyebrow: store.mode == .natal ? "NATAL PLACEMENT" : "TRANSIT PLACEMENT", title: store.mode == .natal ? "Vị trí & năng lượng bản mệnh" : "Vị trí & năng lượng hiện tại")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        placementCard(planet, metadata: metadata)

                        if store.mode == .natal {
                            AstrologySectionTitle(eyebrow: "NATAL ASPECTS", title: "Góc trong lá số").frame(maxWidth: .infinity, alignment: .leading)
                            natalAspectList(planet, metadata: metadata)
                            AstrologySectionTitle(eyebrow: "INCOMING TRANSITS", title: "Tác động từ hiện tại").frame(maxWidth: .infinity, alignment: .leading)
                            transitAspectList((metadata.transitAspects ?? []).filter { $0.natalPlanet == planet.rawValue }, empty: "Hiện không có hành tinh quá cảnh tạo góc chính với \(planet.nameVi) bản mệnh.")
                        } else {
                            AstrologySectionTitle(eyebrow: "OUTGOING TRANSITS", title: "Đang tác động lên bản mệnh").frame(maxWidth: .infinity, alignment: .leading)
                            transitAspectList((metadata.transitAspects ?? []).filter { $0.transitPlanet == planet.rawValue }, empty: "\(planet.nameVi) hiện không tạo góc chính với hành tinh bản mệnh nào.")
                        }

                        AstrologySectionTitle(eyebrow: "STRUCTURED INTERPRETATION", title: "Luận giải tổng hợp").frame(maxWidth: .infinity, alignment: .leading)
                        AstrologyPaperCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Label(planet.nameVi, systemImage: "sparkles").font(.headline).foregroundStyle(AstrologyPalette.paperText)
                                Text(modeSummary(planet, metadata: metadata)).font(.subheadline).foregroundStyle(Color(hex: 0x5D5271))
                                Text("Luận giải được ghép từ vị trí hành tinh, cung, nhà và các góc chính do engine tính toán.").font(.caption2).foregroundStyle(Color(hex: 0x745E94))
                            }
                        }
                    } else {
                        AstrologyCard { Text("Chưa có dữ liệu lá số hợp lệ để hiển thị chi tiết hành tinh.").font(.subheadline).foregroundStyle(.secondary) }
                    }
                }
                .frame(maxWidth: 720).padding(.horizontal, 12).padding(.top, 8).padding(.bottom, 38).frame(maxWidth: .infinity)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private func signView(_ sign: AstrologyZodiacID) -> some View {
        AstrologyBackground(asset: .astrologyBackgroundDetail) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    header(title: "Chi tiết năng lượng", subtitle: "CUNG HOÀNG ĐẠO")
                    ZStack(alignment: .bottom) {
                        Image(appAsset: .astrologyBackgroundDetail).resizable().scaledToFill().frame(height: 330).clipped()
                        LinearGradient(colors: [.clear, AstrologyPalette.deep.opacity(0.78)], startPoint: .top, endPoint: .bottom)
                        VStack(spacing: 8) {
                            Image(appAsset: AppAsset.astrologyZodiac(sign)).resizable().scaledToFit().frame(width: 132, height: 132)
                            Text("\(sign.nameVi) \(sign.symbol)").font(.system(size: 27, weight: .bold, design: .serif))
                            Text(zodiacDescription(sign)).font(.subheadline).foregroundStyle(AstrologyPalette.muted).multilineTextAlignment(.center)
                            Image(appAsset: AppAsset.astrologyConstellation(sign)).resizable().scaledToFit().frame(height: 90).accessibilityLabel("Chòm sao \(sign.nameVi)")
                        }.padding(18)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 28))
                    .overlay(RoundedRectangle(cornerRadius: 28).stroke(AstrologyPalette.violetBorder.opacity(0.48)))

                    if let metadata {
                        AstrologySectionTitle(eyebrow: "ENERGY FOCUS", title: "Trọng tâm năng lượng").frame(maxWidth: .infinity, alignment: .leading)
                        AstrologyCard {
                            HStack(spacing: 12) {
                                scoreRing("Hài hòa", value: metadata.scores.harmony, color: Color(hex: 0x52E2D0))
                                scoreRing("Thử thách", value: metadata.scores.tension, color: Color(hex: 0xFF7B9C))
                                scoreRing("Hội tụ", value: metadata.scores.conjunction, color: Color(hex: 0xFFD166))
                            }.frame(maxWidth: .infinity)
                        }
                        AstrologySectionTitle(eyebrow: "ACTIVE INFLUENCES", title: "Ảnh hưởng đang hoạt động").frame(maxWidth: .infinity, alignment: .leading)
                        let influences = (metadata.transitAspects ?? []).filter { aspect in
                            metadata.transitPlanets?.first(where: { $0.name == aspect.transitPlanet })?.sign == sign.rawValue
                                || metadata.natalPlanets?.first(where: { $0.name == aspect.natalPlanet })?.sign == sign.rawValue
                        }
                        transitAspectList(influences, empty: "Chưa có góc chính đang hoạt động trực tiếp qua \(sign.nameVi).")
                        AstrologySectionTitle(eyebrow: "TODAY", title: "Luận giải hiện tại").frame(maxWidth: .infinity, alignment: .leading)
                        AstrologyPaperCard { Text(metadata.vibeSummary).font(.subheadline).foregroundStyle(AstrologyPalette.paperText) }
                    } else {
                        AstrologyCard { Text("Chưa có dữ liệu lá số hợp lệ để hiển thị ảnh hưởng.").font(.subheadline).foregroundStyle(.secondary) }
                    }
                }
                .frame(maxWidth: 720).padding(.horizontal, 12).padding(.top, 8).padding(.bottom, 38).frame(maxWidth: .infinity)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private func header(title: String, subtitle: String) -> some View {
        HStack {
            Button { store.send(.backTapped) } label: {
                Image(systemName: "arrow.left").frame(width: 44, height: 44).background(AstrologyPalette.navy.opacity(0.72), in: Circle()).overlay(Circle().stroke(AstrologyPalette.gold.opacity(0.3)))
            }
            Spacer()
            VStack(spacing: 3) { Text(title).font(.system(size: 23, weight: .bold, design: .serif)); Text(subtitle).font(.caption2.bold()).tracking(1.3).foregroundStyle(.secondary) }
            Spacer(); Color.clear.frame(width: 44, height: 44)
        }
    }

    private func planetHero(_ planet: AstrologyPlanetID) -> some View {
        let placement = selectedPlacement(planet)
        let sign = placement.flatMap { AstrologyZodiacID(rawValue: $0.sign) } ?? .pisces
        let house = selectedHouse(planet)
        return ZStack(alignment: .bottom) {
            Image(appAsset: .astrologyBackgroundPlanetDetail).resizable().scaledToFill().frame(height: 350).clipped()
            LinearGradient(colors: [.clear, AstrologyPalette.deep.opacity(0.9)], startPoint: .top, endPoint: .bottom)
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Image(appAsset: AppAsset.astrologyPlanetArtwork(planet)).resizable().scaledToFit().frame(width: 150, height: 150)
                    VStack(alignment: .leading, spacing: 7) {
                        Image(appAsset: AppAsset.astrologyConstellation(sign)).resizable().scaledToFit().frame(width: 120, height: 86).opacity(0.7)
                        Text(store.mode == .natal ? "VỊ TRÍ BẢN MỆNH" : "VỊ TRÍ HIỆN TẠI").font(.caption2.bold()).foregroundStyle(AstrologyPalette.cyan)
                        Text(planet.nameVi).font(.system(size: 26, weight: .bold, design: .serif))
                        Text(zodiacLabel(sign.rawValue)).font(.headline).foregroundStyle(AstrologyPalette.gold)
                    }
                }
                HStack(spacing: 10) {
                    Image(appAsset: AppAsset.astrologyPlanetGlyph(planet)).resizable().scaledToFit().frame(width: 32, height: 32)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(store.mode == .natal ? "BẢN MỆNH · LÚC SINH" : "HIỆN TẠI · QUÁ CẢNH").font(.caption2.bold()).foregroundStyle(AstrologyPalette.cyan)
                        Text((placement.map { "\(zodiacLabel($0.sign)) · \(String(format: "%.1f", $0.degreeInSign))°" } ?? "Chưa có dữ liệu vị trí") + (house.map { " · Nhà \($0)" } ?? "")).font(.subheadline.bold())
                    }
                    Spacer()
                }
                .padding(12).background(AstrologyPalette.navy.opacity(0.82), in: RoundedRectangle(cornerRadius: 16))
            }.padding(16)
        }
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .overlay(RoundedRectangle(cornerRadius: 28).stroke(AstrologyPalette.violetBorder.opacity(0.5)))
    }

    private func placementCard(_ planet: AstrologyPlanetID, metadata: AstroFeatureMetadata) -> some View {
        let placement = selectedPlacement(planet)
        let house = selectedHouse(planet)
        return AstrologyCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(appAsset: AppAsset.astrologyPlanetGlyph(planet)).resizable().scaledToFit().frame(width: 42, height: 42)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(placement.map { "\(planet.nameVi) ở \(zodiacLabel($0.sign))" } ?? planet.nameVi).font(.headline)
                        Text(house.map { "Nhà \($0)" } ?? "Nhà chưa xác định").font(.caption).foregroundStyle(AstrologyPalette.cyan)
                    }
                }
                Text(placementInterpretation(planet, sign: placement?.sign, house: house)).font(.subheadline).foregroundStyle(AstrologyPalette.muted)
            }
        }
    }

    private func natalAspectList(_ planet: AstrologyPlanetID, metadata: AstroFeatureMetadata) -> some View {
        let aspects = (metadata.natalAspects ?? []).filter { $0.planetA == planet.rawValue || $0.planetB == planet.rawValue }
        return AstrologyCard {
            aspectRows(aspects.map { aspect in
                let other = aspect.planetA == planet.rawValue ? aspect.planetB : aspect.planetA
                return ("\(planet.nameVi) \(aspect.symbol) \(AstrologyPlanetID(rawValue: other)?.nameVi ?? other)", "\(aspect.nameVi) · góc \(String(format: "%.1f", aspect.actualAngle))° · orb \(String(format: "%.1f", aspect.orb))°", aspect.nature)
            }, empty: "Không có góc chính nổi bật của \(planet.nameVi) trong lá số bản mệnh.")
        }
    }

    private func transitAspectList(_ aspects: [DetectedAstroAspect], empty: String) -> some View {
        AstrologyCard {
            aspectRows(aspects.map { aspect in
                let transit = AstrologyPlanetID(rawValue: aspect.transitPlanet)?.nameVi ?? aspect.transitPlanet
                let natal = AstrologyPlanetID(rawValue: aspect.natalPlanet)?.nameVi ?? aspect.natalPlanet
                return ("\(transit) \(aspect.symbol) \(natal)", "\(aspect.nameVi) · góc \(String(format: "%.1f", aspect.actualAngle))° · orb \(String(format: "%.1f", aspect.orb))°", aspect.nature)
            }, empty: empty)
        }
    }

    @ViewBuilder
    private func aspectRows(_ rows: [(String, String, AstroAspectNature)], empty: String) -> some View {
        if rows.isEmpty {
            Text(empty).font(.subheadline).foregroundStyle(.secondary).frame(maxWidth: .infinity).padding(.vertical, 12)
        } else {
            VStack(spacing: 0) {
                ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                    HStack(alignment: .top, spacing: 10) {
                        Circle().fill(natureColor(row.2)).frame(width: 8, height: 8).padding(.top, 5)
                        VStack(alignment: .leading, spacing: 4) { Text(row.0).font(.subheadline.bold()); Text(row.1).font(.caption).foregroundStyle(AstrologyPalette.muted) }
                        Spacer()
                    }.padding(.vertical, 10)
                    if index < rows.count - 1 { Divider().overlay(.white.opacity(0.12)) }
                }
            }
        }
    }

    private func scoreRing(_ title: String, value: Double, color: Color) -> some View {
        VStack(spacing: 6) {
            ZStack {
                Circle().stroke(.white.opacity(0.12), lineWidth: 7)
                Circle().trim(from: 0, to: CGFloat(max(0, min(1, value)))).stroke(color, style: StrokeStyle(lineWidth: 7, lineCap: .round)).rotationEffect(.degrees(-90))
                Text("\(Int((value * 100).rounded()))%").font(.caption.bold())
            }.frame(width: 70, height: 70)
            Text(title).font(.caption2.bold()).foregroundStyle(.secondary)
        }.frame(maxWidth: .infinity)
    }

    private func selectedPlacement(_ planet: AstrologyPlanetID) -> AstroPlanetPosition? {
        let list = store.mode == .natal ? metadata?.natalPlanets : metadata?.transitPlanets
        return list?.first { $0.name == planet.rawValue }
    }

    private func selectedHouse(_ planet: AstrologyPlanetID) -> Int? {
        switch store.mode {
        case .natal: metadata?.natalContext?.planetHouses[planet.rawValue]
        case .transit: metadata?.dailyContext?.transitHouses[planet.rawValue]
        }
    }

    private func natureColor(_ nature: AstroAspectNature) -> Color {
        switch nature { case .harmony: Color(hex: 0x52E2D0); case .tension: Color(hex: 0xFF7B9C); case .neutral: Color(hex: 0xFFD166) }
    }

    private func placementInterpretation(_ planet: AstrologyPlanetID, sign: String?, house: Int?) -> String {
        var parts = ["\(planet.nameVi) đại diện cho \(planet.themes.lowercased())."]
        if let sign { parts.append("Vị trí ở \(zodiacLabel(sign)) cho biết nguồn lực này đang biểu đạt theo sắc thái của cung đó.") }
        if let house { parts.append("Nhà \(house) là lĩnh vực đời sống nơi năng lượng này được thể hiện rõ nhất.") }
        return parts.joined(separator: " ")
    }

    private func modeSummary(_ planet: AstrologyPlanetID, metadata: AstroFeatureMetadata) -> String {
        let placement = selectedPlacement(planet)
        let house = selectedHouse(planet)
        let aspectCount: Int
        if store.mode == .natal { aspectCount = (metadata.natalAspects ?? []).filter { $0.planetA == planet.rawValue || $0.planetB == planet.rawValue }.count }
        else { aspectCount = (metadata.transitAspects ?? []).filter { $0.transitPlanet == planet.rawValue }.count }
        return "\(placementInterpretation(planet, sign: placement?.sign, house: house)) Có \(aspectCount) góc chính được engine ghi nhận trong chế độ đang xem."
    }

    private func zodiacDescription(_ sign: AstrologyZodiacID) -> String {
        switch sign {
        case .aries: "Nguồn lực khởi đầu, trực diện và sẵn sàng hành động."
        case .taurus: "Năng lượng bền bỉ, cảm nhận giá trị và xây nền ổn định."
        case .gemini: "Sự linh hoạt của tư duy, ngôn ngữ và trao đổi thông tin."
        case .cancer: "Chiều sâu cảm xúc, bản năng chăm sóc và nhu cầu thuộc về."
        case .leo: "Ánh sáng sáng tạo, biểu đạt bản thân và lòng tự trọng."
        case .virgo: "Khả năng quan sát, cải thiện và chăm chút điều thiết thực."
        case .libra: "Nhu cầu cân bằng, hợp tác và tạo nên sự hài hòa."
        case .scorpio: "Năng lực đi sâu, chuyển hóa và bảo vệ điều cốt lõi."
        case .sagittarius: "Động lực mở rộng trải nghiệm, niềm tin và tầm nhìn."
        case .capricorn: "Tính kỷ luật, trách nhiệm và định hướng thành tựu."
        case .aquarius: "Tư duy độc lập, cải tiến và kết nối với cộng đồng."
        case .pisces: "Độ nhạy cảm, tưởng tượng và khả năng đồng cảm sâu."
        }
    }
}
