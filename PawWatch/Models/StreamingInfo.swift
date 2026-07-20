import Foundation

struct StreamingInfo: Codable {
    let deviceId: String
    let deviceName: String
    let isLocalAvailable: Bool
    let isCloudAvailable: Bool
    let localAddress: String?
    let streamingPort: Int
    let pairingCode: String

    var pairingData: String {
        let address = localAddress ?? "192.168.1.1"
        return "\(address):\(streamingPort):\(pairingCode)"
    }
}
