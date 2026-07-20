import SwiftUI

@main
struct PawWatchApp: App {
    init() {
        // Hide status bar
        UIApplication.shared.isIdleTimerDisabled = true
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                Color.black
                    .ignoresSafeArea()

                ContentView()
                    .ignoresSafeArea(.all)
            }
        }
    }
}
