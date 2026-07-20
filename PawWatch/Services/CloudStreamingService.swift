import Foundation
import AVFoundation
import UIKit

class CloudStreamingService {
    private let pairingCode: String
    private let deviceId: String

    init(pairingCode: String, deviceId: String = UIDevice.current.identifierForVendor?.uuidString ?? "unknown") {
        self.pairingCode = pairingCode
        self.deviceId = deviceId
    }

    func broadcastFrame(_ pixelBuffer: CVPixelBuffer) {
        // Firebase streaming disabled for now
    }

    func stop() {
        // Firebase cleanup disabled for now
    }
}

extension CVPixelBuffer {
    func jpegData(compression: CGFloat = 0.6) -> Data? {
        let ciImage = CIImage(cvPixelBuffer: self)
        guard let cgImage = CIContext().createCGImage(ciImage, from: ciImage.extent) else { return nil }
        let uiImage = UIImage(cgImage: cgImage)
        return uiImage.jpegData(compressionQuality: compression)
    }
}
