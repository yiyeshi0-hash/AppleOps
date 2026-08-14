import SwiftUI
import Foundation

@main
struct AppleOpsApp: App {
    @StateObject private var store = AppleOpsStore.shared

    init() {
        let defaults = UserDefaults.standard
        if let current = defaults.string(forKey: "MinecraftServerBaseURL"),
           current.hasPrefix("http://") || current.isEmpty {
            defaults.set(OPanelConfig.baseURL, forKey: "MinecraftServerBaseURL")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}
