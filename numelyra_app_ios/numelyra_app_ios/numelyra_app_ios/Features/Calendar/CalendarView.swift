import ComposableArchitecture
import SwiftUI

struct CalendarView: View {
    @Bindable var store: StoreOf<CalendarFeature>

    private let quickColumns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]
    // cột co dãn chia đều phần trống conf lại

    var body: some View {
        GeometryReader { proxy in
            let contentWidth = min(max(proxy.size.width - 28, 0), 560)
            // min 560
                // lay gia tri lon nhat cua chieu rong man hinh -28
            // tai sao 28
            // vi le trai va le phai ban than la 14 va 14

            ZStack {
                CalendarPalette.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 10) {
                        header
                        dateNavigation

                        if let snapshot = store.snapshot {
                            hero(snapshot, contentWidth)
                            quickGrid(snapshot)
                            topicCard
                            weekRail(snapshot.weekInfo)
                            pager
                        } else {
                            ProgressView("Đang mở lịch…")
                                .tint(CalendarPalette.gold)
                                .foregroundStyle(CalendarPalette.text)
                                .frame(maxWidth: .infinity, minHeight: 420)
                        }
                    }
                    .frame(width: contentWidth)
                    .padding(.bottom, 48)
                    .frame(maxWidth: .infinity)
                }
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    culturePullButton
                }
            }
        }
        .preferredColorScheme(.dark)
        .task { store.send(.onAppear) }
        /*if let datePickerStore = binding {      // có giá trị
         showSheet {
             CalendarDatePickerView(store: datePickerStore)
         }
     } else {                                // nil
         hideSheet()
     }*/
        .sheet(item: $store.scope(\.datePicker, action: \.datePicker)) { datePickerStore in
            CalendarDatePickerView(store: datePickerStore)
                .presentationDetents([.height(520)])
                .presentationDragIndicator(.hidden)
                .presentationCornerRadius(28)
        }
        .sheet(item: $store.scope(\.detail, action: \.detail)) { detailStore in
            CalendarDetailView(store: detailStore)
                .presentationDetents([.fraction(0.82), .large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(28)
        }
    }

    private var header: some View {
        HStack {
            Button(action: {}) {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 22, weight: .medium))
                    .frame(width: 38, height: 38)
            }
            .accessibilityLabel("Mở menu")

            Spacer()

            HStack(spacing: 4) {
                Text("Numelyra")
                    .foregroundStyle(CalendarPalette.text)
                Text("✦")
                    .foregroundStyle(CalendarPalette.gold)
            }
            .font(.system(size: 24, weight: .medium, design: .rounded))

            Spacer()

            Button(action: {}) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 21, weight: .medium))
                    .foregroundStyle(CalendarPalette.pink)
                    .frame(width: 38, height: 38)
            }
            .accessibilityLabel("Lịch sử")
        }
        .foregroundStyle(CalendarPalette.text)
        .frame(height: 54)
    }

    private var dateNavigation: some View {
        HStack(spacing: 7) {
            roundNavigationButton(systemName: "chevron.left", label: "Ngày trước") {
                store.send(.previousDayTapped)
            }

            Button {
                store.send(.datePickerTapped)
            } label: {
                HStack(spacing: 5) {
                    Text(monthYearText)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .lineLimit(1)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(CalendarPalette.gold)
                }
                .foregroundStyle(CalendarPalette.text)
                .frame(maxWidth: .infinity, minHeight: 37)
                .background(CalendarPalette.monthChip)
                .clipShape(Capsule())
                .overlay { Capsule().stroke(CalendarPalette.purpleBorder, lineWidth: 1) }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Chọn ngày")

            roundNavigationButton(systemName: "chevron.right", label: "Ngày sau") {
                store.send(.nextDayTapped)
            }

            Button {
                store.send(.todayTapped)
            } label: {
                HStack(spacing: 3) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12, weight: .bold))
                    Text("Hôm nay")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                }
                .foregroundStyle(Color(calendarHex: 0x2A1938))
                .frame(width: 97, height: 35)
                .background(CalendarPalette.goldGradient)
                .clipShape(Capsule())
                .shadow(color: Color(calendarHex: 0xE4A039).opacity(0.36), radius: 8, y: 3)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Hôm nay")
        }
    }

    private func roundNavigationButton(
        systemName: String,
        label: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(CalendarPalette.gold)
                .frame(width: 36, height: 36)
                .background(CalendarPalette.circleGradient)
                .clipShape(Circle())
                .shadow(color: Color(calendarHex: 0x15092F).opacity(0.44), radius: 7, y: 3)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    private func hero(_ snapshot: LunarDaySnapshot,_ size: CGFloat) -> some View {
        ZStack(alignment: .leading) {
            Image(appAsset: .calendarHero)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: size, maxHeight: 202)
                .clipped()

            LinearGradient(
                colors: [Color(calendarHex: 0x0F0735).opacity(0.82), .clear],
                startPoint: .leading,
                endPoint: .trailing
            )

            LinearGradient(
                colors: [.clear, Color(calendarHex: 0x0A0527).opacity(0.45)],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(snapshot.weekdayVi)
                    .font(.system(size: 21, weight: .heavy, design: .rounded))
                    .foregroundStyle(CalendarPalette.text)
                Text(snapshot.heroLunarText)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color(calendarHex: 0xFFD8A5))
                Text("\(snapshot.day)")
                    .font(.system(size: 78, weight: .black, design: .rounded))
                    .tracking(-5)
                    .foregroundStyle(CalendarPalette.text)
                    .shadow(color: Color(calendarHex: 0xC071D4), radius: 9)
                    .minimumScaleFactor(0.75)
                Text("Năm \(snapshot.canChiYear) · Ngày \(snapshot.canChiDay)")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color(calendarHex: 0xF1A6E4))
                    .lineLimit(1)
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 15)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
        .frame(height: .infinity)
        .background(Color(calendarHex: 0x26115D))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color(calendarHex: 0xB570DF).opacity(0.72), lineWidth: 1)
        }
        .shadow(color: Color(calendarHex: 0x32105E).opacity(0.86), radius: 18, y: 10)
        .accessibilityElement(children: .combine)
    }

    private func quickGrid(_ snapshot: LunarDaySnapshot) -> some View {
        LazyVGrid(columns: quickColumns, spacing: 10) {
            QuickCalendarCard(
                icon: "sun.max",
                iconColor: CalendarPalette.gold,
                label: "Giờ đại cát",
                value: snapshot.bestDepartureHour.map { "Giờ \($0.name)" } ?? "Đang cập nhật",
                detail: snapshot.bestDepartureHour?.range
            ) { store.send(.auspiciousCardTapped) }

            QuickCalendarCard(
                icon: "safari",
                iconColor: CalendarPalette.hotPink,
                label: snapshot.direction.than,
                value: "Hướng tốt",
                detail: snapshot.direction.huong
            ) { store.send(.auspiciousCardTapped) }

            QuickCalendarCard(
                icon: "checkmark",
                iconColor: Color(calendarHex: 0xA7E8A0),
                label: "Việc nên làm",
                value: snapshot.activities.yi.prefix(2).joined(separator: ", ")
            ) { store.send(.auspiciousCardTapped) }

            QuickCalendarCard(
                icon: "minus",
                iconColor: CalendarPalette.hotPink,
                label: "Việc kiêng cữ",
                value: snapshot.activities.ji.prefix(2).joined(separator: ", ")
            ) { store.send(.auspiciousCardTapped) }
        }
    }

    private var topicCard: some View {
        Button {
            store.send(.cultureTapped)
        } label: {
            HStack(spacing: 0) {
                Image(appAsset: .calendarTopic)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 142, height: 128)
                    .clipped()

                VStack(alignment: .leading, spacing: 3) {
                    Text("✦ CHỦ ĐỀ HÔM NAY")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color(calendarHex: 0xFFC66F))

                    Text(topicTitle)
                        .font(.system(size: 17, weight: .black, design: .rounded))
                        .foregroundStyle(CalendarPalette.text)
                        .lineLimit(1)

                    Text("“\(topicExcerpt)”")
                        .font(.system(size: 11, weight: .regular, design: .rounded))
                        .foregroundStyle(Color(calendarHex: 0xD6A9EE))
                        .lineLimit(2)

                    HStack(spacing: 2) {
                        Text("Đọc toàn văn & ý nghĩa")
                        Image(systemName: "chevron.right")
                    }
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color(calendarHex: 0xFFD28A))
                }
                .padding(11)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .background(
                    LinearGradient(
                        colors: [Color(calendarHex: 0x4E2380).opacity(0.5), Color(calendarHex: 0x120836)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            }
            .frame(height: 128)
            .background(Color(calendarHex: 0x2A1658))
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color(calendarHex: 0xB266D5).opacity(0.66), lineWidth: 1)
            }
            .shadow(color: Color(calendarHex: 0x32105E).opacity(0.84), radius: 17, y: 9)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Mở điển tích và nguyên tác văn học")
    }

    private func weekRail(_ week: CalendarWeekInfo) -> some View {
        HStack(spacing: 0) {
            VStack(spacing: 2) {
                Text("Tuần")
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundStyle(Color(calendarHex: 0xD9B5E9))
                Text("\(week.weekNumber)")
                    .font(.system(size: 19, weight: .heavy, design: .rounded))
                    .foregroundStyle(CalendarPalette.text)
            }
            .frame(width: 52)
            .frame(maxHeight: .infinity)
            .background(Color(calendarHex: 0x4B267D).opacity(0.78))

            ForEach(week.days) { item in
                Button {
                    store.send(.weekDayTapped(item.date))
                } label: {
                    VStack(spacing: 2) {
                        Text(item.dayOfWeekShort)
                            .font(.system(size: 10, design: .rounded))
                        Text("\(item.dayNumber)")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(item.isCurrentDay ? CalendarPalette.text : Color(calendarHex: 0xCBA7E7))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(item.isCurrentDay ? Color(calendarHex: 0xA4377F).opacity(0.74) : .clear)
                    .overlay(alignment: .leading) {
                        Rectangle().fill(Color(calendarHex: 0xA972D0).opacity(0.3)).frame(width: 1)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(item.dayOfWeekVi), ngày \(item.dayNumber)")
            }
        }
        .frame(height: 74)
        .background(CalendarPalette.cardGradient)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color(calendarHex: 0xA460CD).opacity(0.68), lineWidth: 1)
        }
        .shadow(color: Color(calendarHex: 0x2D0B57).opacity(0.84), radius: 15, y: 8)
    }

    private var pager: some View {
        HStack {
            Button { store.send(.previousDayTapped) } label: {
                Label("Ngày trước", systemImage: "chevron.left")
            }
            Spacer()
            Button { store.send(.nextDayTapped) } label: {
                Label("Ngày sau", systemImage: "chevron.right")
                    .labelStyle(CalendarTrailingIconLabelStyle())
            }
        }
        .font(.system(size: 12, weight: .semibold, design: .rounded))
        .foregroundStyle(Color(calendarHex: 0xC69CE6))
        .padding(.horizontal, 8)
        .buttonStyle(.plain)
    }

    private var culturePullButton: some View {
        Button { store.send(.cultureTapped) } label: {
            Capsule()
                .fill(Color(calendarHex: 0x281452).opacity(0.96))
                .frame(width: 218, height: 31)
                .overlay {
                    Capsule().stroke(Color(calendarHex: 0xFBC469).opacity(0.48), lineWidth: 1)
                }
                .overlay {
                    Capsule()
                        .fill(Color(calendarHex: 0xFFD98A))
                        .frame(width: 34, height: 2)
                }
                .shadow(color: Color(calendarHex: 0x09031F).opacity(0.4), radius: 6, y: 3)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 10)
                .onEnded { value in
                    if value.translation.height < -20 {
                        store.send(.cultureTapped)
                    }
                }
        )
        .accessibilityLabel("Kéo lên hoặc chạm để mở điển tích và nguyên tác văn học")
        .padding(.bottom, 5)
    }

    private var monthYearText: String {
        guard let snapshot = store.snapshot else { return "Đang tải" }
        return "Tháng \(snapshot.month) · \(snapshot.year)"
    }

    private var topicTitle: String {
        if let category = store.caDao?.category, !category.isEmpty { return category }
        return "Tình yêu đôi lứa"
    }

    private var topicExcerpt: String {
        if let content = store.caDao?.content, !content.isEmpty { return content }
        return store.art?.literature.excerpt ?? ""
    }
}

private struct QuickCalendarCard: View {
    let icon: String
    let iconColor: Color
    let label: String
    let value: String
    var detail: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 7) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(iconColor)
                    .frame(width: 38, height: 38)
                    .overlay { Circle().stroke(iconColor, lineWidth: 2) }

                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(Color(calendarHex: 0xD0A7E8))
                        .lineLimit(1)
                    Text(value)
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .foregroundStyle(CalendarPalette.text)
                        .lineLimit(2)
                    if let detail {
                        Text(detail)
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color(calendarHex: 0xFFCC8D))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(CalendarPalette.text)
            }
            .padding(10)
            .frame(maxWidth: .infinity, minHeight: 92, maxHeight: 92)
            .background(CalendarPalette.cardGradient)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color(calendarHex: 0x985EC4).opacity(0.62), lineWidth: 1)
            }
            .shadow(color: Color(calendarHex: 0x2D0B57).opacity(0.88), radius: 15, y: 8)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }
}

private struct CalendarTrailingIconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 3) {
            configuration.title
            configuration.icon
        }
    }
}

enum CalendarPalette {
    static let background = Color(calendarHex: 0x171044)
    static let text = Color(calendarHex: 0xFFF0FF)
    static let gold = Color(calendarHex: 0xFFD793)
    static let pink = Color(calendarHex: 0xF5B8E8)
    static let hotPink = Color(calendarHex: 0xFF88C6)
    static let monthChip = Color(calendarHex: 0x301464)
    static let purpleBorder = Color(calendarHex: 0x9147C6)
    static let goldGradient = LinearGradient(
        colors: [Color(calendarHex: 0xFFE8AA), Color(calendarHex: 0xF5BD55), Color(calendarHex: 0xD98B2E)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let circleGradient = LinearGradient(
        colors: [Color(calendarHex: 0x4A2D82), Color(calendarHex: 0x30195F), Color(calendarHex: 0x1D103F)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let cardGradient = LinearGradient(
        colors: [Color(calendarHex: 0x43236F), Color(calendarHex: 0x28144F)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

extension Color {
    init(calendarHex: UInt32) {
        self.init(
            red: Double((calendarHex >> 16) & 0xFF) / 255,
            green: Double((calendarHex >> 8) & 0xFF) / 255,
            blue: Double(calendarHex & 0xFF) / 255
        )
    }
}

#Preview {
    CalendarView(
        store: Store(
            initialState: CalendarFeature.State(
                profile: UserProfile(fullName: "Minh Anh", birthDate: "1998-10-20")
            )
        ) {
            CalendarFeature()
        } withDependencies: {
            $0.caDaoClient = .liveValue
            $0.calendarArtClient = .liveValue
        }
    )
}
