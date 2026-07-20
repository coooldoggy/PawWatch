import Foundation
import Combine
import UIKit

class RemoteViewerViewModel: ObservableObject {
    @Published var streamingState: StreamingState = .disconnected
    @Published var frameImage: UIImage?
    @Published var fps: Int = 0

    private var frameCount = 0
    private var lastFpsTime = Date()

    func connectToCloud(pairingCode: String) {
        streamingState = .connecting
        // Firebase cloud streaming disabled for now
    }

    func connectToLocal(deviceName: String, ipAddress: String, port: Int) {
        streamingState = .connecting
        // Local WiFi streaming implementation
    }

    func disconnect() {
        streamingState = .disconnected
    }

    deinit {
        disconnect()
    }
}

enum StreamingState {
    case connecting
    case connected
    case disconnected
    case error(String)
}
