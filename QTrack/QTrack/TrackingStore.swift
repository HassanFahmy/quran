import Foundation

enum TrackerType: String, Codable, CaseIterable {
    case tilawa
    case hifz
    case murajaa
}

struct TrackerState: Codable {
    var tilawaHizb: Int // 1-60
    var hifzPage: Int // 1-604
    var murajaaHizb: Int // 1-based, relative to memorized range
    var totalHizbMemorized: Int
    var completionLog: [String: [String]] // "yyyy-MM-dd" -> ["tilawa", "hifz", ...]
}

class TrackingStore: ObservableObject {
    @Published var state: TrackerState

    static let totalHizbs = 60
    static let totalPages = 604
    static let pagesPerHizb = 10

    private let saveKey = "trackerState"

    init() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let saved = try? JSONDecoder().decode(TrackerState.self, from: data) {
            self.state = saved
        } else {
            self.state = TrackerState(
                tilawaHizb: 1,
                hifzPage: 1,
                murajaaHizb: 1,
                totalHizbMemorized: 0,
                completionLog: [:]
            )
        }
    }

    private var todayString: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }

    private func save() {
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: saveKey)
        }
    }

    private func logCompletion(_ type: TrackerType) {
        let today = todayString
        var entries = state.completionLog[today] ?? []
        entries.append(type.rawValue)
        state.completionLog[today] = entries
    }

    func completions(for date: Date) -> Set<TrackerType> {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        let key = f.string(from: date)
        guard let entries = state.completionLog[key] else { return [] }
        return Set(entries.compactMap { TrackerType(rawValue: $0) })
    }

    private func removeCompletion(_ type: TrackerType) {
        let today = todayString
        var entries = state.completionLog[today] ?? []
        if let idx = entries.firstIndex(of: type.rawValue) {
            entries.remove(at: idx)
        }
        state.completionLog[today] = entries
    }

    // MARK: - Tilawa

    func completeTilawa() {
        logCompletion(.tilawa)
        state.tilawaHizb = (state.tilawaHizb % Self.totalHizbs) + 1
        save()
    }

    func undoTilawa() {
        guard completions(for: Date()).contains(.tilawa) else { return }
        removeCompletion(.tilawa)
        state.tilawaHizb = state.tilawaHizb == 1 ? Self.totalHizbs : state.tilawaHizb - 1
        save()
    }

    // MARK: - Hifz

    func completeHifz() {
        logCompletion(.hifz)
        if state.hifzPage < Self.totalPages {
            state.hifzPage += 1
        }
        updateMurajaaRange()
        save()
    }

    func undoHifz() {
        guard completions(for: Date()).contains(.hifz) else { return }
        removeCompletion(.hifz)
        if state.hifzPage > 1 {
            state.hifzPage -= 1
        }
        updateMurajaaRange()
        save()
    }

    private func updateMurajaaRange() {
        let memorizedPages = state.hifzPage - 1
        state.totalHizbMemorized = max(memorizedPages / Self.pagesPerHizb, 1)
        if state.murajaaHizb > state.totalHizbMemorized {
            state.murajaaHizb = 1
        }
    }

    // MARK: - Muraja'a

    func completeMurajaa() {
        guard state.totalHizbMemorized > 0 else { return }
        logCompletion(.murajaa)
        state.murajaaHizb = (state.murajaaHizb % state.totalHizbMemorized) + 1
        save()
    }

    func undoMurajaa() {
        guard completions(for: Date()).contains(.murajaa), state.totalHizbMemorized > 0 else { return }
        removeCompletion(.murajaa)
        state.murajaaHizb = state.murajaaHizb == 1 ? state.totalHizbMemorized : state.murajaaHizb - 1
        save()
    }

    // MARK: - Manual Setters

    func setTilawaHizb(_ value: Int) {
        state.tilawaHizb = max(1, min(value, Self.totalHizbs))
        save()
    }

    func setHifzPage(_ value: Int) {
        state.hifzPage = max(1, min(value, Self.totalPages))
        updateMurajaaRange()
        save()
    }

    func setMurajaaHizb(_ value: Int) {
        guard state.totalHizbMemorized > 0 else { return }
        state.murajaaHizb = max(1, min(value, state.totalHizbMemorized))
        save()
    }
}
