import SwiftUI
import KakaoSDKCommon
import KakaoSDKAuth

@main
struct PawWatchApp: App {
    init() {
        // Initialize Kakao SDK
        if let appKey = Bundle.main.infoDictionary?["KAKAO_APP_KEY"] as? String {
            KakaoSDK.initSDK(appKey: appKey)
        }

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
