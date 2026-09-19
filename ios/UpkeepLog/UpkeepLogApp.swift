import SwiftUI

@main
struct UpkeepLogApp: App {
    @StateObject private var store = UpkeepStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}
