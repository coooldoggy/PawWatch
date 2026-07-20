import AVFoundation
import Combine
import UIKit

class CameraService: NSObject, ObservableObject {
    @Published var streamingInfo: StreamingInfo?

    private var captureSession: AVCaptureSession?
    private var videoOutput: AVCaptureVideoDataOutput?
    private var cloudStreamingService: CloudStreamingService?
    private let pairingManager = PairingManager()

    func startRecording() {
        // Initialize capture session
        let captureSession = AVCaptureSession()
        captureSession.sessionPreset = .medium

        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: camera) else {
            print("Cannot access camera")
            return
        }

        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }

        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        let queue = DispatchQueue(label: "cameraQueue")
        videoOutput.setSampleBufferDelegate(self, queue: queue)

        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }

        self.captureSession = captureSession
        self.videoOutput = videoOutput

        // Setup streaming
        let pairingCode = pairingManager.generatePairingCode()
        cloudStreamingService = CloudStreamingService(pairingCode: pairingCode)

        // Create streaming info
        let info = StreamingInfo(
            deviceId: UIDevice.current.identifierForVendor?.uuidString ?? "unknown",
            deviceName: UIDevice.current.name,
            isLocalAvailable: true,
            isCloudAvailable: true,
            localAddress: getLocalIPAddress(),
            streamingPort: 8888,
            pairingCode: pairingCode
        )

        DispatchQueue.main.async {
            self.streamingInfo = info
        }

        DispatchQueue.global().async {
            captureSession.startRunning()
        }
    }

    func stopRecording() {
        if let session = captureSession, session.isRunning {
            session.stopRunning()
        }
        cloudStreamingService?.stop()
        DispatchQueue.main.async {
            self.streamingInfo = nil
        }
    }

    private func getLocalIPAddress() -> String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?

        if getifaddrs(&ifaddr) == 0 {
            var ptr = ifaddr
            while ptr != nil {
                defer { ptr = ptr?.pointee.ifa_next }

                guard let interface = ptr?.pointee else { return nil }
                let addrFamily = interface.ifa_addr.pointee.sa_family

                if addrFamily == UInt8(AF_INET) {
                    if let name = String(cString: interface.ifa_name, encoding: .utf8),
                       name == "en0" {
                        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                        getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                                   &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST)
                        address = String(cString: hostname)
                    }
                }
            }
            freeifaddrs(ifaddr)
        }

        return address
    }
}

extension CameraService: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Process video frames
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        // Send to cloud streaming
        cloudStreamingService?.broadcastFrame(pixelBuffer)
    }
}
