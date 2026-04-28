import SwiftUI

@main
struct QTrackApp: App {
    @StateObject private var store = TrackingStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}
