import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            BuildsView()
                .tabItem {
                    Label("云构建", systemImage: "hammer")
                }
                .tag(0)
            DevicesView()
                .tabItem {
                    Label("签名/设备", systemImage: "iphone.and.arrow.forward")
                }
                .tag(1)
            MachinesView()
                .tabItem {
                    Label("远程机器", systemImage: "desktopcomputer")
                }
                .tag(2)
        }
        .onReceive(NotificationCenter.default.publisher(for: .openToolsScreen)) { note in
            if let screen = note.object as? String {
                switch screen {
                case "machines":
                    selectedTab = 2
                case "devices":
                    selectedTab = 1
                default:
                    selectedTab = 0
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .searchTools)) { _ in
            selectedTab = 0
        }
    }
}
