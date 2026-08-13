import SwiftUI

@main
struct AppleOpsApp: App {
    @StateObject private var store = AppleOpsStore.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}
