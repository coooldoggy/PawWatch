import SwiftUI
import AVFoundation

struct QRScannerView: UIViewControllerRepresentable {
    @Binding var pairingCode: String
    @Binding var ipAddress: String
    @Binding var port: String
    @Binding var isShowing: Bool

    func makeUIViewController(context: Context) -> QRScannerViewController {
        let controller = QRScannerViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: QRScannerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, QRScannerDelegate {
        var parent: QRScannerView

        init(_ parent: QRScannerView) {
            self.parent = parent
        }

        func qrCodeDidRead(_ code: String) {
            let parts = code.split(separator: ":")
            if parts.count == 3 {
                parent.ipAddress = String(parts[0])
                parent.port = String(parts[1])
                parent.pairingCode = String(parts[2])
            }
            parent.isShowing = false
        }
    }
}

protocol QRScannerDelegate: AnyObject {
    func qrCodeDidRead(_ code: String)
}

class QRScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    weak var delegate: QRScannerDelegate?
    var captureSession = AVCaptureSession()
    var previewLayer: AVCaptureVideoPreviewLayer?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupScanner()
    }

    func setupScanner() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            guard let self = self, granted else {
                print("Camera permission denied")
                return
            }

            DispatchQueue.main.async {
                self.initializeCamera()
            }
        }
    }

    func initializeCamera() {
        guard let captureDevice = AVCaptureDevice.default(for: .video) else { return }

        do {
            let input = try AVCaptureDeviceInput(device: captureDevice)
            captureSession.addInput(input)

            let metadataOutput = AVCaptureMetadataOutput()
            captureSession.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]

            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer?.frame = view.bounds
            previewLayer?.videoGravity = .resizeAspectFill
            view.layer.addSublayer(previewLayer!)

            let qrQueue = DispatchQueue(label: "qrQueue")
            qrQueue.async {
                self.captureSession.startRunning()
            }
        } catch {
            print("Camera setup error: \(error)")
        }
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              metadataObject.type == .qr,
              let qrCode = metadataObject.stringValue else { return }

        delegate?.qrCodeDidRead(qrCode)
        captureSession.stopRunning()
    }
}
