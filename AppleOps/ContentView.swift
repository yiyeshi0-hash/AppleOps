import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            BuildsView()
                .tabItem {
                    Label("云构建", systemImage: "hammer")
                }
            DevicesView()
                .tabItem {
                    Label("签名/设备", systemImage: "iphone.and.arrow.forward")
                }
            MachinesView()
                .tabItem {
                    Label("远程机器", systemImage: "desktopcomputer")
                }
        }
    }
}
