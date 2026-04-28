import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem {
                    Label("Today", systemImage: "checkmark.circle")
                }
            CalendarView()
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "slider.horizontal.3")
                }
        }
    }
}

// MARK: - Today Tab

struct TodayView: View {
    @EnvironmentObject var store: TrackingStore

    private var todayCompletions: Set<TrackerType> {
        store.completions(for: Date())
    }

    var body: some View {
        NavigationView {
            List {
                Section {
                    TrackerRow(
                        title: "Read Hizb \(store.state.tilawaHizb) of 60",
                        subtitle: tilawaJuzInfo(),
                        doneToday: todayCompletions.contains(.tilawa),
                        tint: .blue,
                        action: store.completeTilawa,
                        undoAction: store.undoTilawa
                    )
                } header: {
                    Text("Tilawa (Reading)")
                } footer: {
                    Text("1 hizb per day, cycling through the entire Quran")
                }

                Section {
                    TrackerRow(
                        title: "Memorize Page \(store.state.hifzPage) of 604",
                        subtitle: hifzJuzInfo(),
                        doneToday: todayCompletions.contains(.hifz),
                        tint: .green,
                        action: store.completeHifz,
                        undoAction: store.undoHifz
                    )
                } header: {
                    Text("Hifz (Memorization)")
                } footer: {
                    Text("1 page per day")
                }

                Section {
                    if store.state.totalHizbMemorized > 0 {
                        TrackerRow(
                            title: "Review Hizb \(store.state.murajaaHizb) of \(store.state.totalHizbMemorized)",
                            subtitle: "Looping over memorized portion",
                            doneToday: todayCompletions.contains(.murajaa),
                            tint: .orange,
                            action: store.completeMurajaa,
                            undoAction: store.undoMurajaa
                        )
                    } else {
                        Text("Start memorizing to unlock review tracking")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Muraja'a (Review)")
                } footer: {
                    Text("1 hizb per day, cycling over what you've memorized")
                }

                Section("Progress") {
                    ProgressRow(label: "Tilawa cycle", value: store.state.tilawaHizb - 1, total: 60)
                    ProgressRow(label: "Pages memorized", value: store.state.hifzPage - 1, total: 604)
                }
            }
            .navigationTitle("QTrack")
        }
    }

    private func tilawaJuzInfo() -> String {
        let juz = ((store.state.tilawaHizb - 1) / 2) + 1
        let half = (store.state.tilawaHizb - 1) % 2 == 0 ? "1st" : "2nd"
        return "Juz \(juz), \(half) half"
    }

    private func hifzJuzInfo() -> String {
        let juz = ((store.state.hifzPage - 1) / 20) + 1
        return "Juz \(juz)"
    }
}

struct TrackerRow: View {
    let title: String
    let subtitle: String
    let doneToday: Bool
    let tint: Color
    let action: () -> Void
    let undoAction: () -> Void

    @State private var justCompleted = false

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: justCompleted ? "checkmark.circle.fill" : (doneToday ? "checkmark.circle.fill" : "circle"))
                .font(.title2)
                .foregroundStyle(justCompleted ? .green : (doneToday ? tint : .gray))
                .padding(8)
                .contentShape(Rectangle())
                .onTapGesture {
                    if doneToday && !justCompleted {
                        undoAction()
                    } else {
                        iterate()
                    }
                }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            iterate()
        }
        .listRowBackground(doneToday ? tint.opacity(0.1) : Color.clear)
    }

    private func iterate() {
        withAnimation(.easeInOut(duration: 0.3)) {
            justCompleted = true
        }
        action()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            withAnimation { justCompleted = false }
        }
    }
}

struct ProgressRow: View {
    let label: String
    let value: Int
    let total: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                Spacer()
                Text("\(value)/\(total)")
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: Double(value), total: Double(total))
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(TrackingStore())
}
