import ComposableArchitecture
import SwiftUI

struct AstrologyNatalChartView: View {
    let store: StoreOf<AstrologyNatalFeature>
    let profile: UserProfile?
    let metadata: AstroFeatureMetadata?
    let calculationError: String?

    var body: some View {
        AstrologyBackground(asset: .astrologyBackgroundNatal) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    header
                    birthChips

                    if let metadata, metadata.birthDataPrecision != .complete {
                        Button { store.send(.editBirthDataTapped) } label: {
                            HStack(spacing: 9) {
                                Image(systemName: "compass.drawing").foregroundStyle(AstrologyPalette.cyan)
                                Text(precisionMessage(metadata)).font(.caption).foregroundStyle(AstrologyPalette.muted)
                                Spacer()
                                Text("Bổ sung").font(.caption.bold()).foregroundStyle(AstrologyPalette.gold)
                            }
                            .padding(12)
                            .background(Color(hex: 0x0D1F4B).opacity(0.88), in: RoundedRectangle(cornerRadius: 16))
                        }
                        .buttonStyle(.plain)
                    }

                    if let metadata {
                        AstrologyCard {
                            VStack(spacing: 12) {
                                AstrologyNatalWheel(metadata: metadata) { target in
                                    store.send(.detailTapped(target))
                                }
                                HStack(spacing: 14) {
                                    legend("Hỗ trợ", color: Color(hex: 0x52E2D0))
                                    legend("Thử thách", color: Color(hex: 0xFF7B9C))
                                    legend("Hội tụ", color: Color(hex: 0xFFD166))
                                }
                                if metadata.natalContext == nil {
                                    Text("Vòng 12 nhà, ASC và MC được ẩn vì dữ liệu sinh chưa đủ chính xác.")
                                        .font(.caption2).foregroundStyle(.secondary).multilineTextAlignment(.center)
                                }
                            }
                        }

                        AstrologySectionTitle(eyebrow: "CORE ENERGIES", title: "Năng lượng cốt lõi")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        coreCards(metadata)

                        if let context = metadata.natalContext {
                            AstrologyCard {
                                VStack(spacing: 12) {
                                    Text("TRỤC LÁ SỐ · PORPHYRY")
                                        .font(.caption2.bold()).tracking(1.1).foregroundStyle(AstrologyPalette.cyan)
                                    HStack {
                                        axis("Cung Mọc · ASC", longitude: context.angles.ascendant)
                                        Divider().overlay(.white.opacity(0.18))
                                        axis("Thiên Đỉnh · MC", longitude: context.angles.midheaven)
                                    }
                                }
                            }
                        }

                        AstrologySectionTitle(eyebrow: "NATAL PLACEMENTS", title: "Vị trí hành tinh")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        placements(metadata)
                    } else {
                        AstrologyCard {
                            VStack(spacing: 10) {
                                Image(systemName: "exclamationmark.triangle").font(.title).foregroundStyle(.pink)
                                Text("Chưa có dữ liệu lá số hợp lệ").font(.headline)
                                Text(calculationError ?? "Hãy kiểm tra hồ sơ và thử lại.")
                                    .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
                                Button("Chỉnh dữ liệu sinh") { store.send(.editBirthDataTapped) }
                                    .buttonStyle(.borderedProminent).tint(AstrologyPalette.purple)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                        }
                    }
                }
                .frame(maxWidth: 720)
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .padding(.bottom, 38)
                .frame(maxWidth: .infinity)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var header: some View {
        HStack {
            Button { store.send(.backTapped) } label: {
                Image(systemName: "arrow.left").frame(width: 44, height: 44)
                    .background(AstrologyPalette.navy.opacity(0.72), in: Circle())
                    .overlay(Circle().stroke(AstrologyPalette.gold.opacity(0.3)))
            }
            Spacer()
            VStack(spacing: 3) {
                Text("Natal Chart").font(.system(size: 23, weight: .bold, design: .serif))
                Text("LÁ SỐ BẢN MỆNH").font(.caption2.bold()).tracking(1.35).foregroundStyle(.secondary)
            }
            Spacer()
            Button { store.send(.editBirthDataTapped) } label: {
                Image(systemName: "pencil").frame(width: 44, height: 44)
                    .background(AstrologyPalette.navy.opacity(0.72), in: Circle())
                    .overlay(Circle().stroke(AstrologyPalette.gold.opacity(0.3)))
            }
        }
    }

    private var birthChips: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 7) { chip(.astrologyCalendarIcon, profile?.birthDate ?? "Chưa có ngày sinh"); chip(.astrologyClockIcon, profile?.birthTime ?? "Giờ tạm tính"); chip(.astrologyLocationIcon, profile?.birthLocation?.userLabel ?? "Chưa có nơi sinh") }
            VStack(spacing: 7) { chip(.astrologyCalendarIcon, profile?.birthDate ?? "Chưa có ngày sinh"); chip(.astrologyClockIcon, profile?.birthTime ?? "Giờ tạm tính"); chip(.astrologyLocationIcon, profile?.birthLocation?.userLabel ?? "Chưa có nơi sinh") }
        }
    }

    private func chip(_ asset: AppAsset, _ text: String) -> some View {
        HStack(spacing: 6) {
            Image(appAsset: asset).resizable().scaledToFit().frame(width: 16, height: 16)
            Text(text).font(.caption2.bold()).lineLimit(1)
        }
        .padding(.horizontal, 10).frame(height: 34)
        .background(AstrologyPalette.navy.opacity(0.78), in: Capsule())
        .overlay(Capsule().stroke(AstrologyPalette.violetBorder.opacity(0.24)))
    }

    private func legend(_ title: String, color: Color) -> some View {
        HStack(spacing: 5) { Capsule().fill(color).frame(width: 18, height: 2); Text(title).font(.caption2).foregroundStyle(.secondary) }
    }

    private func coreCards(_ metadata: AstroFeatureMetadata) -> some View {
        VStack(spacing: 10) {
            ForEach([AstrologyPlanetID.sun, .moon], id: \.self) { planet in
                if let placement = metadata.natalPlanets?.first(where: { $0.name == planet.rawValue }) {
                    Button { store.send(.detailTapped(.planet(planet))) } label: {
                        AstrologyPaperCard {
                            HStack(spacing: 12) {
                                Image(appAsset: AppAsset.astrologyPlanetGlyph(planet)).resizable().scaledToFit().frame(width: 50, height: 50)
                                VStack(alignment: .leading, spacing: 5) {
                                    Text("\(planet.nameVi) ở \(zodiacLabel(placement.sign))").font(.headline).foregroundStyle(AstrologyPalette.paperText)
                                    Text("\(String(format: "%.1f", placement.degreeInSign))° · \(planet.themes)").font(.caption2.bold()).foregroundStyle(Color(hex: 0x745E94))
                                    if let house = metadata.natalContext?.planetHouses[planet.rawValue] {
                                        Text("Nhà \(house)").font(.caption.bold()).foregroundStyle(Color(hex: 0x7D3E82))
                                    }
                                }
                                Spacer()
                                Image(systemName: "chevron.right").foregroundStyle(Color(hex: 0x745E94))
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            AstrologyPaperCard {
                HStack(spacing: 12) {
                    Image(systemName: "paintpalette.fill").font(.title2).foregroundStyle(AstrologyPalette.gold).frame(width: 50, height: 50).background(Color(hex: 0x4E347D), in: Circle())
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Khí chất nổi trội").font(.headline).foregroundStyle(AstrologyPalette.paperText)
                        Text("\(metadata.temperament.dominantElement) · \(metadata.temperament.dominantModality)").font(.subheadline.bold()).foregroundStyle(Color(hex: 0x714FA0))
                        Text("Tổng hợp từ phân bố nguyên tố và tính chất của 10 hành tinh bản mệnh.").font(.caption).foregroundStyle(Color(hex: 0x5D5271))
                    }
                }
            }
        }
    }

    private func axis(_ title: String, longitude: Double) -> some View {
        VStack(spacing: 5) {
            Text(title).font(.caption2).foregroundStyle(.secondary)
            Text(zodiacLabel(AstrologyEngine.longitudeToZodiac(longitude).sign)).font(.subheadline.bold())
        }.frame(maxWidth: .infinity)
    }

    private func placements(_ metadata: AstroFeatureMetadata) -> some View {
        AstrologyCard {
            VStack(spacing: 0) {
                ForEach(Array((metadata.natalPlanets ?? []).enumerated()), id: \.element.name) { index, placement in
                    if let planet = AstrologyPlanetID(rawValue: placement.name) {
                        Button { store.send(.detailTapped(.planet(planet))) } label: {
                            HStack(spacing: 10) {
                                Image(appAsset: AppAsset.astrologyPlanetGlyph(planet)).resizable().scaledToFit().frame(width: 27, height: 27)
                                Text(planet.nameVi).font(.subheadline.bold()).frame(width: 88, alignment: .leading)
                                Text("\(zodiacLabel(placement.sign)) · \(String(format: "%.1f", placement.degreeInSign))°").font(.caption).foregroundStyle(AstrologyPalette.muted)
                                Spacer()
                                if let house = metadata.natalContext?.planetHouses[planet.rawValue] { Text("H\(house)").font(.caption2.bold()).foregroundStyle(AstrologyPalette.cyan) }
                            }
                            .frame(minHeight: 56)
                        }
                        .buttonStyle(.plain)
                        if index < (metadata.natalPlanets?.count ?? 0) - 1 { Divider().overlay(.white.opacity(0.12)) }
                    }
                }
            }
        }
    }
}

private struct AstrologyNatalWheel: View {
    let metadata: AstroFeatureMetadata
    let onOpenDetail: (AstrologyDetailTarget) -> Void

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, 460)
            let center = CGPoint(x: size / 2, y: size / 2)
            let planets = metadata.natalPlanets ?? []
            let planetPoints = Dictionary(uniqueKeysWithValues: planets.map { ($0.name, point(center: center, radius: size * 0.31, longitude: $0.longitude)) })

            ZStack {
                Canvas { context, canvasSize in
                    let c = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
                    for ratio in [0.96, 0.74, 0.51] {
                        let diameter = size * ratio
                        context.stroke(Path(ellipseIn: CGRect(x: c.x - diameter / 2, y: c.y - diameter / 2, width: diameter, height: diameter)), with: .color(AstrologyPalette.violetBorder.opacity(ratio == 0.96 ? 0.72 : 0.32)), lineWidth: ratio == 0.96 ? 1.8 : 1)
                    }
                    for index in 0 ..< 12 {
                        var path = Path()
                        path.move(to: point(center: c, radius: size * 0.37, longitude: Double(index * 30 - 15)))
                        path.addLine(to: point(center: c, radius: size * 0.48, longitude: Double(index * 30 - 15)))
                        context.stroke(path, with: .color(.white.opacity(0.3)), lineWidth: 1)
                    }
                    for cusp in metadata.natalContext?.houseCusps ?? [] {
                        var path = Path()
                        path.move(to: point(center: c, radius: size * 0.15, longitude: cusp.longitude))
                        path.addLine(to: point(center: c, radius: size * 0.365, longitude: cusp.longitude))
                        context.stroke(path, with: .color(AstrologyPalette.gold.opacity(0.38)), lineWidth: cusp.house == 1 || cusp.house == 10 ? 1.8 : 0.8)
                    }
                    for aspect in (metadata.natalAspects ?? []).prefix(20) {
                        guard let from = planetPoints[aspect.planetA], let to = planetPoints[aspect.planetB] else { continue }
                        var path = Path(); path.move(to: from); path.addLine(to: to)
                        context.stroke(path, with: .color(aspectColor(aspect.nature).opacity(0.36 + aspect.weight * 0.48)), lineWidth: aspect.weight >= 0.6 ? 1.4 : 0.8)
                    }
                }
                .frame(width: size, height: size)

                ForEach(Array(AstrologyZodiacID.allCases.enumerated()), id: \.element) { index, sign in
                    let p = point(center: center, radius: size * 0.425, longitude: Double(index * 30))
                    Button(sign.symbol) { onOpenDetail(.sign(sign)) }
                        .font(.system(size: 22)).foregroundStyle(Color(hex: 0xE8C8FF))
                        .frame(width: 30, height: 30).position(p)
                        .accessibilityLabel("Mở chi tiết \(sign.nameVi)")
                }

                ForEach(planets) { placement in
                    if let planet = AstrologyPlanetID(rawValue: placement.name), let p = planetPoints[placement.name] {
                        Button { onOpenDetail(.planet(planet)) } label: {
                            Image(appAsset: AppAsset.astrologyPlanetGlyph(planet)).resizable().scaledToFit().frame(width: 28, height: 28).padding(3)
                                .background(Color(hex: 0x212370).opacity(0.96), in: Circle())
                                .overlay(Circle().stroke(AstrologyPalette.cyan))
                        }
                        .position(p)
                        .accessibilityLabel("Mở chi tiết \(planet.nameVi)")
                    }
                }

                Text("✦").font(.title).foregroundStyle(AstrologyPalette.gold).frame(width: 42, height: 42).background(AstrologyPalette.purple.opacity(0.8), in: Circle()).position(center)
            }
            .frame(width: size, height: size)
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .contain)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func point(center: CGPoint, radius: CGFloat, longitude: Double) -> CGPoint {
        let radians = (longitude - 90) * .pi / 180
        return CGPoint(x: center.x + cos(radians) * radius, y: center.y + sin(radians) * radius)
    }

    private func aspectColor(_ nature: AstroAspectNature) -> Color {
        switch nature {
        case .harmony: Color(hex: 0x52E2D0)
        case .tension: Color(hex: 0xFF7B9C)
        case .neutral: Color(hex: 0xFFD166)
        }
    }
}
