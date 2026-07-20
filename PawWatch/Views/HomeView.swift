import SwiftUI

struct HomeView: View {
    @Binding var isRecording: Bool
    @State private var showPreview = false
    @State private var streamingInfo: StreamingInfo?
    @StateObject private var cameraService = CameraService()

    var body: some View {
        ZStack {
            if isRecording {
                if showPreview {
                    CameraPreviewView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .ignoresSafeArea(.container, edges: [.horizontal, .bottom])

                    VStack(alignment: .leading) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Recording")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                HStack(spacing: 4) {
                                    Image(systemName: "circle.fill")
                                        .foregroundColor(.red)
                                        .font(.caption2)
                                    Text("LIVE")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                }
                            }
                            Spacer()
                            Button(action: closePreview) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(12)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(8)
                        .padding()

                        Spacer()

                        if let info = streamingInfo {
                            VStack(spacing: 12) {
                                Text("Share QR Code")
                                    .font(.caption)
                                    .foregroundColor(.white)

                                if let qrImage = generateQRCode(from: info.pairingData) {
                                    Image(uiImage: qrImage)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(maxWidth: 150)
                                        .background(Color.white)
                                        .cornerRadius(8)
                                }

                                Text(info.pairingCode)
                                    .font(.system(.body, design: .monospaced))
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(8)
                            .padding()
                        }

                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea(.container, edges: [.horizontal, .bottom])
                } else {
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Recording Status")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Text("Active")
                                        .font(.title)
                                        .fontWeight(.bold)
                                }
                                Spacer()
                                Image(systemName: "circle.fill")
                                    .foregroundColor(.orange)
                            }

                            Button(action: { showPreview = true }) {
                                Text("Show Camera")
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(Color.orange)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }

                            Button(action: { isRecording = false }) {
                                Text("Stop Watching")
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(Color.red)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)

                        Spacer()
                    }
                    .padding()
                }
            } else {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Recording Status")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Text("Inactive")
                                    .font(.title)
                                    .fontWeight(.bold)
                            }
                            Spacer()
                            Image(systemName: "circle.fill")
                                .foregroundColor(.gray)
                        }

                        Button(action: startRecording) {
                            Text("Start Watching")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.orange)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)

                    Spacer()
                }
                .padding()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea(.container, edges: [.horizontal, .bottom])
    }

    func startRecording() {
        isRecording = true
        showPreview = true
        cameraService.startRecording()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            streamingInfo = cameraService.streamingInfo
        }
    }

    func closePreview() {
        showPreview = false
    }

    func generateQRCode(from data: String) -> UIImage? {
        let data = data.data(using: .ascii)
        let filter = CIFilter(name: "CIQRCodeGenerator")
        filter?.setValue(data, forKey: "inputMessage")

        if let outputImage = filter?.outputImage {
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            let scaledImage = outputImage.transformed(by: transform)
            return UIImage(ciImage: scaledImage)
        }
        return nil
    }
}
