import SwiftUI

struct CalendarView: View {
    @EnvironmentObject var store: TrackingStore

    @State private var displayedMonth: Date = Date()

    private let hijriCalendar = Calendar(identifier: .islamicCivil)
    private let gregorianCalendar = Calendar(identifier: .gregorian)

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                monthHeader
                weekdayHeader
                daysGrid
                Spacer()
                legend
            }
            .padding()
            .navigationTitle("Progress")
        }
    }

    // MARK: - Month Header

    private var monthHeader: some View {
        HStack {
            Button {
                shiftMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
            }
            Spacer()
            Text(hijriMonthTitle)
                .font(.headline)
            Spacer()
            Button {
                shiftMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
            }
        }
        .padding(.bottom, 12)
    }

    private var hijriMonthTitle: String {
        let comps = hijriCalendar.dateComponents([.year, .month], from: displayedMonth)
        let formatter = DateFormatter()
        formatter.calendar = hijriCalendar
        formatter.dateFormat = "MMMM yyyy"
        guard let date = hijriCalendar.date(from: comps) else { return "" }
        return formatter.string(from: date)
    }

    private func shiftMonth(by offset: Int) {
        if let newDate = hijriCalendar.date(byAdding: .month, value: offset, to: displayedMonth) {
            displayedMonth = newDate
        }
    }

    // MARK: - Weekday Header

    private var weekdayHeader: some View {
        let symbols = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        return HStack {
            ForEach(symbols, id: \.self) { day in
                Text(day)
                    .font(.caption2)
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.bottom, 4)
    }

    // MARK: - Days Grid

    private var daysGrid: some View {
        let days = daysInMonth()
        let columns = Array(repeating: GridItem(.flexible()), count: 7)

        return LazyVGrid(columns: columns, spacing: 8) {
            ForEach(days, id: \.offset) { item in
                if let date = item.date {
                    let hijriDay = hijriCalendar.component(.day, from: date)
                    let completions = store.completions(for: date)
                    let isToday = gregorianCalendar.isDateInToday(date)

                    VStack(spacing: 2) {
                        Text("\(hijriDay)")
                            .font(.caption)
                            .fontWeight(isToday ? .bold : .regular)
                            .foregroundStyle(isToday ? .primary : .secondary)

                        HStack(spacing: 2) {
                            Circle()
                                .fill(completions.contains(.tilawa) ? .blue : .clear)
                                .frame(width: 6, height: 6)
                            Circle()
                                .fill(completions.contains(.hifz) ? .green : .clear)
                                .frame(width: 6, height: 6)
                            Circle()
                                .fill(completions.contains(.murajaa) ? .orange : .clear)
                                .frame(width: 6, height: 6)
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 36)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(isToday ? Color.accentColor.opacity(0.1) : .clear)
                    )
                } else {
                    Color.clear
                        .frame(maxWidth: .infinity, minHeight: 36)
                }
            }
        }
    }

    private struct DayItem {
        let offset: Int
        let date: Date?
    }

    private func daysInMonth() -> [DayItem] {
        let comps = hijriCalendar.dateComponents([.year, .month], from: displayedMonth)
        guard let firstOfMonth = hijriCalendar.date(from: comps),
              let range = hijriCalendar.range(of: .day, in: .month, for: firstOfMonth) else {
            return []
        }

        let firstWeekday = hijriCalendar.component(.weekday, from: firstOfMonth)
        let leadingBlanks = (firstWeekday - hijriCalendar.firstWeekday + 7) % 7

        var items: [DayItem] = []
        for i in 0..<leadingBlanks {
            items.append(DayItem(offset: i, date: nil))
        }
        for day in range {
            var dc = comps
            dc.day = day
            let date = hijriCalendar.date(from: dc)
            items.append(DayItem(offset: leadingBlanks + day, date: date))
        }
        return items
    }

    // MARK: - Legend

    private var legend: some View {
        HStack(spacing: 16) {
            legendItem(color: .blue, label: "Tilawa")
            legendItem(color: .green, label: "Hifz")
            legendItem(color: .orange, label: "Muraja'a")
        }
        .font(.caption)
        .padding(.top, 12)
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label)
        }
    }
}

#Preview {
    CalendarView()
        .environmentObject(TrackingStore())
}
