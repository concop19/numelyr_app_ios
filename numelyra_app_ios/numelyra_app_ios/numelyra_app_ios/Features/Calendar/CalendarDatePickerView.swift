import ComposableArchitecture
import SwiftUI

struct CalendarDatePickerView: View {
    @Bindable var store: StoreOf<CalendarDatePickerFeature>

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
    private let weekdays = ["T2", "T3", "T4", "T5", "T6", "T7", "CN"]

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Chọn ngày")
                    .font(.system(size: 17, weight: .heavy, design: .rounded))
                    .foregroundStyle(CalendarPalette.text)
                Spacer()
                Button { store.send(.closeTapped) } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(CalendarPalette.text)
                        .frame(width: 34, height: 34)
                        .background(.white.opacity(0.08))
                        .clipShape(Circle())
                }
                .accessibilityLabel("Đóng")
            }

            HStack {
                monthButton(systemName: "chevron.left", label: "Tháng trước") {
                    store.send(.previousMonthTapped)
                }
                Spacer()
                Text(monthYearText(store.displayedMonth))
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundStyle(CalendarPalette.gold)
                Spacer()
                monthButton(systemName: "chevron.right", label: "Tháng sau") {
                    store.send(.nextMonthTapped)
                }
            }
            .frame(height: 42)

            LazyVGrid(columns: columns, spacing: 0) {
                ForEach(weekdays, id: \.self) { weekday in
                    Text(weekday)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(calendarHex: 0xC8A9DF))
                        .frame(maxWidth: .infinity, minHeight: 32)
                }

                ForEach(store.days, id: \.self) { date in
                    let selected = sameDay(date, store.selectedDate)
                    let today = sameDay(date, Date())
                    Button {
                        store.send(.dateTapped(date))
                    } label: {
                        Text("\(day(date))")
                            .font(.system(size: 14, weight: selected || today ? .heavy : .semibold, design: .rounded))
                            .foregroundStyle(dayColor(date, selected: selected, today: today))
                            .frame(maxWidth: .infinity, minHeight: 42)
                            .background(selected ? Color(calendarHex: 0x8D4FB6) : .clear)
                            .clipShape(Circle())
                            .opacity(isDisplayedMonth(date) ? 1 : 0.45)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(accessibilityDate(date, today: today))
                }
            }

            Button { store.send(.todayTapped) } label: {
                Text("Hôm nay")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color(calendarHex: 0x2A1938))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 8)
                    .background(Color(calendarHex: 0xF2BC64))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 12)
        .background(Color(calendarHex: 0x211246).ignoresSafeArea())
    }

    private func monthButton(systemName: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(CalendarPalette.gold)
                .frame(width: 36, height: 36)
                .background(Color(calendarHex: 0x3A2069))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    private func sameDay(_ lhs: Date, _ rhs: Date) -> Bool {
        LunarService.defaultCalendar.isDate(lhs, inSameDayAs: rhs)
    }

    private func day(_ date: Date) -> Int {
        LunarService.defaultCalendar.component(.day, from: date)
    }

    private func isDisplayedMonth(_ date: Date) -> Bool {
        let calendar = LunarService.defaultCalendar
        return calendar.component(.month, from: date) == calendar.component(.month, from: store.displayedMonth)
            && calendar.component(.year, from: date) == calendar.component(.year, from: store.displayedMonth)
    }

    private func dayColor(_ date: Date, selected: Bool, today: Bool) -> Color {
        if selected { return .white }
        if today { return CalendarPalette.gold }
        return isDisplayedMonth(date) ? CalendarPalette.text : Color(calendarHex: 0xB79BCB)
    }

    private func monthYearText(_ date: Date) -> String {
        let calendar = LunarService.defaultCalendar
        return "Tháng \(calendar.component(.month, from: date)) · \(calendar.component(.year, from: date))"
    }

    private func accessibilityDate(_ date: Date, today: Bool) -> String {
        let calendar = LunarService.defaultCalendar
        let values = calendar.dateComponents([.day, .month, .year], from: date)
        return "\(values.day ?? 1) tháng \(values.month ?? 1) năm \(values.year ?? 1)\(today ? ", hôm nay" : "")"
    }
}
