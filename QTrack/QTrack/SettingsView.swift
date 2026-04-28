import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: TrackingStore
    @FocusState private var focusedField: Field?

    @State private var tilawaText: String = ""
    @State private var hifzText: String = ""
    @State private var murajaaText: String = ""

    private enum Field {
        case tilawa, hifz, murajaa
    }

    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack {
                        Text("Current: Hizb \(store.state.tilawaHizb) of 60")
                        Spacer()
                    }
                    HStack {
                        TextField("Hizb (1-60)", text: $tilawaText)
                            .keyboardType(.numberPad)
                            .focused($focusedField, equals: .tilawa)
                        Button("Set") {
                            if let val = Int(tilawaText) {
                                store.setTilawaHizb(val)
                                tilawaText = ""
                            }
                            focusedField = nil
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } header: {
                    Text("Tilawa (Reading)")
                }

                Section {
                    HStack {
                        Text("Current: Page \(store.state.hifzPage) of 604")
                        Spacer()
                    }
                    HStack {
                        TextField("Page (1-604)", text: $hifzText)
                            .keyboardType(.numberPad)
                            .focused($focusedField, equals: .hifz)
                        Button("Set") {
                            if let val = Int(hifzText) {
                                store.setHifzPage(val)
                                hifzText = ""
                            }
                            focusedField = nil
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } header: {
                    Text("Hifz (Memorization)")
                } footer: {
                    Text("This also updates the muraja'a range (\(store.state.totalHizbMemorized) hizb memorized)")
                }

                Section {
                    if store.state.totalHizbMemorized > 0 {
                        HStack {
                            Text("Current: Hizb \(store.state.murajaaHizb) of \(store.state.totalHizbMemorized)")
                            Spacer()
                        }
                        HStack {
                            TextField("Hizb (1-\(store.state.totalHizbMemorized))", text: $murajaaText)
                                .keyboardType(.numberPad)
                                .focused($focusedField, equals: .murajaa)
                            Button("Set") {
                                if let val = Int(murajaaText) {
                                    store.setMurajaaHizb(val)
                                    murajaaText = ""
                                }
                                focusedField = nil
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    } else {
                        Text("No memorized portion yet")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Muraja'a (Review)")
                }
            }
            .navigationTitle("Settings")
            .onTapGesture {
                focusedField = nil
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(TrackingStore())
}
