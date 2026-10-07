import ComposableArchitecture
import SwiftUI
import UIKit

struct CalendarDetailView: View {
    let store: StoreOf<CalendarDetailFeature>

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView(showsIndicators: true) {
                Group {
                    switch store.mode {
                    case .auspicious:
                        auspiciousContent
                    case .culture:
                        cultureContent
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 60)
            }
        }
        .background(Color(calendarHex: 0x120C29).ignoresSafeArea())
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: store.mode.icon)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Color(calendarHex: 0x2B1642))
                .frame(width: 36, height: 36)
                .background(CalendarPalette.goldGradient)
                .clipShape(Circle())
                .shadow(color: Color(calendarHex: 0xF7C66B).opacity(0.38), radius: 6, y: 3)

            VStack(alignment: .leading, spacing: 2) {
                Text("NUMELYRA CALENDAR")
                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                    .tracking(1.2)
                    .foregroundStyle(Color(calendarHex: 0xD8B9FF))
                Text(store.mode.title)
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color(calendarHex: 0xFFF3D6))
                    .lineLimit(2)
            }

            Spacer()

            Button { store.send(.closeTapped) } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color(calendarHex: 0xFFE4A2))
                    .frame(width: 32, height: 32)
                    .background(Color(calendarHex: 0xFFF0CB).opacity(0.1))
                    .clipShape(Circle())
                    .overlay { Circle().stroke(Color(calendarHex: 0xFFDE99).opacity(0.25), lineWidth: 1) }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Đóng chi tiết")
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(
            LinearGradient(
                colors: [Color(calendarHex: 0x3B1D69), Color(calendarHex: 0x24124A), Color(calendarHex: 0x120B2B)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color(calendarHex: 0xFADB9B).opacity(0.24)).frame(height: 1)
        }
    }

    private var auspiciousContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let bestHour = store.snapshot.bestDepartureHour {
                VStack(alignment: .leading, spacing: 8) {
                    DetailSectionTitle(icon: "sun.max", title: "GIỜ XUẤT HÀNH ĐẠI CÁT", tone: .green)
                    Text("Giờ \(bestHour.name) (\(bestHour.range)) • Sao \(bestHour.label)")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color(calendarHex: 0xF8FAFC))
                    Label(
                        "\(store.snapshot.direction.than): Hướng \(store.snapshot.direction.huong)",
                        systemImage: "location.north"
                    )
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(calendarHex: 0x99F6E4))
                }
                .padding(14)
                .background(
                    LinearGradient(
                        colors: [Color(calendarHex: 0x183D39), Color(calendarHex: 0x17302E), Color(calendarHex: 0x1B1A39)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 17, style: .continuous)
                        .stroke(Color(calendarHex: 0x5EEAD4).opacity(0.58), lineWidth: 1)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                DetailSectionTitle(icon: "clock", title: "BẢNG 12 GIỜ HOÀNG ĐẠO & HẮC ĐẠO")
                Text("* Biểu tượng ⚠️ đánh dấu khung giờ xung khắc (Tứ Hành Xung) với tuổi \(store.snapshot.userZodiac) của bạn.")
                    .font(.system(size: 11, design: .rounded))
                    .italic()
                    .foregroundStyle(Color(calendarHex: 0x94A3B8))
                hourTable
            }

            activitiesCard
        }
    }

    private var hourTable: some View {
        Grid(horizontalSpacing: 6, verticalSpacing: 0) {
            GridRow {
                tableHeader("Giờ")
                tableHeader("Khung giờ")
                tableHeader("Sao")
                tableHeader("Cát/Hung")
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                LinearGradient(
                    colors: [Color(calendarHex: 0x42226F), Color(calendarHex: 0x2A164E)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )

            ForEach(store.snapshot.hours) { hour in
                GridRow {
                    Text("\(hour.isClash ? "⚠️ " : "")\(hour.name)")
                        .foregroundStyle(hour.isClash ? Color(calendarHex: 0xF87171) : Color(calendarHex: 0xE2E8F0))
                    Text(hour.range)
                    Text(hour.label)
                        .font(.system(size: 10, design: .rounded))
                    Text(hour.isHoangDao ? "Hoàng Đạo" : "Hắc Đạo")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(hour.isHoangDao ? Color(calendarHex: 0xBBF7D0) : Color(calendarHex: 0xFCA5A5))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 3)
                        .background(hour.isHoangDao ? Color(calendarHex: 0x166534) : Color(calendarHex: 0x7F1D1D))
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                }
                .font(.system(size: 11, design: .rounded))
                .foregroundStyle(Color(calendarHex: 0xE2E8F0))
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(hourRowColor(hour))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .stroke(Color(calendarHex: 0xA572DC).opacity(0.42), lineWidth: 1)
        }
    }

    private var activitiesCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            DetailSectionTitle(icon: "calendar", title: "VIỆC NÊN LÀM & KIÊNG CỮ HÔM NAY", tone: .pink)
            HStack(alignment: .top, spacing: 12) {
                activityColumn(
                    title: "NÊN LÀM",
                    icon: "checkmark.circle.fill",
                    items: store.snapshot.activities.yi,
                    color: Color(calendarHex: 0x6EE7B7)
                )
                Divider().overlay(Color(calendarHex: 0x2D2852))
                activityColumn(
                    title: "KIÊNG CỮ",
                    icon: "xmark.circle.fill",
                    items: store.snapshot.activities.ji,
                    color: Color(calendarHex: 0xFDA4AF)
                )
            }
        }
        .padding(14)
        .background(
            LinearGradient(
                colors: [Color(calendarHex: 0x251640), Color(calendarHex: 0x17112E)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .stroke(Color(calendarHex: 0xBA81F3).opacity(0.38), lineWidth: 1)
        }
    }

    private var cultureContent: some View {
        VStack(spacing: 14) {
            ZStack(alignment: .topTrailing) {
                artImage
                    .frame(maxWidth: .infinity, minHeight: 240, maxHeight: 240)
                    .background(Color(calendarHex: 0x1B1736))
                    .clipped()

                LinearGradient(
                    colors: [.clear, Color(calendarHex: 0x0F0826).opacity(0.64)],
                    startPoint: .top,
                    endPoint: .bottom
                )

                Text(store.art.seasonLabel)
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color(calendarHex: 0xFEF3C7))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color(calendarHex: 0x1C140A).opacity(0.85))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay { RoundedRectangle(cornerRadius: 8).stroke(Color(calendarHex: 0xF5BA5B), lineWidth: 1) }
                    .padding(10)
            }
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color(calendarHex: 0xC2A676), lineWidth: 1.5)
            }

            VStack(spacing: 3) {
                Text(store.art.literature.title)
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color(calendarHex: 0xF5BA5B))
                    .multilineTextAlignment(.center)
                if let hanTitle = store.art.literature.hanTitle {
                    Text(hanTitle)
                        .font(.system(size: 15, design: .serif))
                        .tracking(2)
                        .foregroundStyle(Color(calendarHex: 0xCBD5E1))
                }
                Text(authorText)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color(calendarHex: 0x94A3B8))
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 7) {
                Image(systemName: "quote.bubble")
                    .foregroundStyle(Color(calendarHex: 0xFFD990))
                Text(store.art.literature.fullContent ?? store.art.literature.excerpt)
                    .font(.system(size: 14, design: .rounded))
                    .italic()
                    .foregroundStyle(Color(calendarHex: 0xFFF8EA))
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    colors: [Color(calendarHex: 0x302052), Color(calendarHex: 0x1D1539)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 17, style: .continuous)
                    .stroke(Color(calendarHex: 0xECC9FF).opacity(0.32), lineWidth: 1)
            }

            VStack(alignment: .leading, spacing: 9) {
                DetailSectionTitle(icon: "books.vertical", title: "TÍCH XƯA & Ý NGHĨA VĂN HÓA")
                Text(store.art.literature.description)
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(Color(calendarHex: 0xCBD5E1))
                    .lineSpacing(5)
                if let location = store.art.literature.location {
                    Label("Lưu giữ: \(location)", systemImage: "mappin.and.ellipse")
                        .font(.system(size: 11, design: .rounded))
                        .italic()
                        .foregroundStyle(Color(calendarHex: 0xCBB5FF))
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(
                    colors: [Color(calendarHex: 0x241B45), Color(calendarHex: 0x151129)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 17, style: .continuous)
                    .stroke(Color(calendarHex: 0xA07EE0).opacity(0.3), lineWidth: 1)
            }

            if let caDao = store.caDao {
                VStack(alignment: .leading, spacing: 8) {
                    DetailSectionTitle(icon: "text.book.closed", title: "CA DAO TỤC NGỮ TRONG NGÀY", tone: .pink)
                    Text("“\(caDao.content)”")
                        .font(.system(size: 13, design: .rounded))
                        .italic()
                        .foregroundStyle(Color(calendarHex: 0xE2E8F0))
                        .lineSpacing(5)
                    if !caDao.category.isEmpty {
                        Text("Chủ đề: \(caDao.category)")
                            .font(.system(size: 11, design: .rounded))
                            .foregroundStyle(Color(calendarHex: 0x94A3B8))
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    LinearGradient(
                        colors: [Color(calendarHex: 0x352050), Color(calendarHex: 0x1A1535)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 17, style: .continuous)
                        .stroke(Color(calendarHex: 0xD1A0FF).opacity(0.34), lineWidth: 1)
                }
            }
        }
    }

    @ViewBuilder
    private var artImage: some View {
        if let data = store.remoteImageData, let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
        } else {
            Image(appAsset: store.art.season.fallbackAsset)
                .resizable()
                .scaledToFit()
        }
    }

    private var authorText: String {
        if let period = store.art.literature.period {
            return "\(store.art.literature.author) (\(period))"
        }
        return store.art.literature.author
    }

    private func tableHeader(_ value: String) -> some View {
        Text(value)
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .foregroundStyle(Color(calendarHex: 0xF5BA5B))
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func hourRowColor(_ hour: LunarHourInfo) -> Color {
        if hour.isClash { return Color(calendarHex: 0x571F37).opacity(0.76) }
        if hour.isHoangDao { return Color(calendarHex: 0x194B3E).opacity(0.72) }
        return Color(calendarHex: 0x22193D).opacity(0.92)
    }

    private func activityColumn(
        title: String,
        icon: String,
        items: [String],
        color: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: icon)
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .foregroundStyle(color)
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                Text("• \(item)")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(color.opacity(0.88))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct DetailSectionTitle: View {
    enum Tone { case gold, green, pink }

    let icon: String
    let title: String
    var tone: Tone = .gold

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color(calendarHex: 0x241335))
                .frame(width: 25, height: 25)
                .background(gradient)
                .clipShape(Circle())
            Text(title)
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .foregroundStyle(Color(calendarHex: 0xFFE2A5))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var gradient: LinearGradient {
        let colors: [Color]
        switch tone {
        case .gold:
            colors = [Color(calendarHex: 0xFFE29A), Color(calendarHex: 0xEAB45D)]
        case .green:
            colors = [Color(calendarHex: 0x5EEAD4), Color(calendarHex: 0x34D399)]
        case .pink:
            colors = [Color(calendarHex: 0xF9A8D4), Color(calendarHex: 0xC084FC)]
        }
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}
