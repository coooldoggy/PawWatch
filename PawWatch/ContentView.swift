import SwiftUI

struct ContentView: View {
    @State private var isRecording = false
    @State private var selectedTab = 0

    var body: some View {
        ZStack(alignment: .center) {
            TabView(selection: $selectedTab) {
                HomeView(isRecording: $isRecording)
                    .ignoresSafeArea(.container, edges: [.horizontal, .bottom])
                    .tabItem {
                        Label("Home", systemImage: "house.fill")
                    }
                    .tag(0)

                RemoteViewerView()
                    .ignoresSafeArea(.container, edges: [.horizontal, .bottom])
                    .tabItem {
                        Label("Remote", systemImage: "video.circle.fill")
                    }
                    .tag(1)

                SettingsView()
                    .ignoresSafeArea(.container, edges: [.horizontal, .bottom])
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
                    .tag(2)
            }
            .accentColor(.orange)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea(.container, edges: [.horizontal, .bottom])
    }
}
