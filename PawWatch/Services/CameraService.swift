import AVFoundation
import Combine
import UIKit
import Vision
import KakaoSDKTalk

class CameraService: NSObject, ObservableObject {
    @Published var streamingInfo: StreamingInfo?

    private var captureSession: AVCaptureSession?
    private var movieFileOutput: AVCaptureMovieFileOutput?
    private var cloudStreamingService: CloudStreamingService?
    private let pairingManager = PairingManager()
    private var isRecordingVideo = false
    private var lastCatDetectionTime: Date?

    func startRecording() {
        let captureSession = AVCaptureSession()
        captureSession.sessionPreset = .high

        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: camera) else {
            print("Cannot access camera")
            return
        }

        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }

        guard let audioDevice = AVCaptureDevice.default(for: .audio),
              let audioInput = try? AVCaptureDeviceInput(device: audioDevice) else {
            print("Cannot access microphone")
            return
        }

        if captureSession.canAddInput(audioInput) {
            captureSession.addInput(audioInput)
        }

        // Video output for cat detection
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        let queue = DispatchQueue(label: "detectionQueue")
        videoOutput.setSampleBufferDelegate(self, queue: queue)

        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }

        // Movie file output for recording
        let movieFileOutput = AVCaptureMovieFileOutput()
        if captureSession.canAddOutput(movieFileOutput) {
            captureSession.addOutput(movieFileOutput)
        }

        self.captureSession = captureSession
        self.movieFileOutput = movieFileOutput

        // Setup streaming
        let pairingCode = pairingManager.generatePairingCode()
        cloudStreamingService = CloudStreamingService(pairingCode: pairingCode)

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
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        // Send to cloud streaming
        cloudStreamingService?.broadcastFrame(pixelBuffer)

        // Cat detection (simplified - detect motion/objects)
        detectAndRecord(pixelBuffer: pixelBuffer)
    }

    private func detectAndRecord(pixelBuffer: CVPixelBuffer) {
        let request = VNDetectObjectsRequest { [weak self] request, error in
            guard let results = request.results as? [VNRecognizedObjectObservation] else { return }

            let catDetected = results.contains { observation in
                observation.labels.contains { label in
                    label.identifier.lowercased().contains("cat") || label.identifier.lowercased().contains("animal")
                }
            }

            if catDetected {
                self?.handleCatDetection()
            }
        }

        request.usesCPUOnly = true
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        try? handler.perform([request])
    }

    private func handleCatDetection() {
        // Auto-record for 10 seconds when cat is detected
        let now = Date()
        if let lastTime = lastCatDetectionTime, now.timeIntervalSince(lastTime) < 15 {
            return
        }

        lastCatDetectionTime = now

        guard !isRecordingVideo, let movieFileOutput = movieFileOutput else { return }

        // Save to Documents/Videos directory
        let fileManager = FileManager.default
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let videosPath = (documentsPath as NSString).appendingPathComponent("Videos")

        // Create Videos directory if it doesn't exist
        if !fileManager.fileExists(atPath: videosPath) {
            try? fileManager.createDirectory(atPath: videosPath, withIntermediateDirectories: true)
        }

        let fileName = "cat_\(Int(Date().timeIntervalSince1970)).mov"
        let outputPath = (videosPath as NSString).appendingPathComponent(fileName)
        let outputURL = URL(fileURLWithPath: outputPath)

        DispatchQueue.main.async {
            movieFileOutput.startRecording(to: outputURL, recordingDelegate: self)
            self.isRecordingVideo = true

            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                movieFileOutput.stopRecording()
                self.isRecordingVideo = false
                self.uploadVideo(url: outputURL)
            }
        }
    }

    private func uploadVideo(url: URL) {
        // Simulate video upload and auto-share
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.autoShareToKakaoTalk()
        }
    }

    private func autoShareToKakaoTalk() {
        let text = "고양이가 감지되었습니다! 🐱\n새로운 영상이 업로드되었습니다!"

        if let urlStr = "kakaoopen://talk".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
           let url = URL(string: urlStr) {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }

        TalkApiClient.shared.sendDefaultMemo(text: text) { error in
            if let error = error {
                print("KakaoTalk share failed: \(error)")
            } else {
                print("KakaoTalk auto-share success")
            }
        }
    }
}

extension CameraService: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            print("Recording error: \(error)")
        } else {
            print("Video recorded successfully: \(outputFileURL)")
        }
    }
}
