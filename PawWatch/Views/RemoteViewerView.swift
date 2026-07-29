import SwiftUI

struct RemoteViewerView: View {
    @State private var selectedMode: ConnectionMode = .local
    @State private var pairingCode = ""
    @State private var ipAddress = ""
    @State private var port = "8888"
    @State private var deviceName = ""
    @State private var isConnecting = false
    @State private var showQRScanner = false
    @StateObject private var remoteViewer = RemoteViewerViewModel()

    enum ConnectionMode {
        case local
        case cloud
    }

    var body: some View {
        VStack(spacing: 16) {
                // Mode Selector
                Picker("Connection Mode", selection: $selectedMode) {
                    Text("Local").tag(ConnectionMode.local)
                    Text("Cloud").tag(ConnectionMode.cloud)
                }
                .pickerStyle(.segmented)
                .padding()

                if selectedMode == .cloud {
                    // Cloud Mode
                    VStack(spacing: 12) {
                        Text("Enter the pairing code from the broadcaster device")
                            .font(.body)
                            .foregroundColor(.gray)

                        TextField("000000", text: $pairingCode)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)
                            .padding(.horizontal)

                        Button(action: connectToCloud) {
                            if isConnecting {
                                ProgressView()
                                    .progressViewStyle(.circular)
                            } else {
                                Text("Connect to Cloud")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(pairingCode.count == 6 ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .disabled(pairingCode.count != 6 || isConnecting)
                        .padding(.horizontal)
                    }
                    .padding()
                } else {
                    // Local Mode
                    VStack(spacing: 12) {
                        Text("Scan QR code or enter details manually:")
                            .font(.body)
                            .foregroundColor(.gray)

                        if showQRScanner {
                            ZStack {
                                QRScannerView(
                                    pairingCode: $pairingCode,
                                    ipAddress: $ipAddress,
                                    port: $port,
                                    isShowing: $showQRScanner
                                )
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .ignoresSafeArea()

                                VStack {
                                    HStack {
                                        Button(action: { showQRScanner = false }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.title)
                                                .foregroundColor(.white)
                                        }
                                        Spacer()
                                    }
                                    .padding()

                                    Spacer()
                                }
                            }
                        } else {
                            Button(action: { showQRScanner = true }) {
                                Text("Scan QR Code")
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                        }

                        Text("Or enter manually:")
                            .font(.caption)
                            .foregroundColor(.gray)

                        TextField("Device Name", text: $deviceName)
                            .textFieldStyle(.roundedBorder)

                        TextField("192.168.1.100", text: $ipAddress)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.roundedBorder)

                        TextField("8888", text: $port)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)

                        Button(action: connectToLocal) {
                            if isConnecting {
                                ProgressView()
                                    .progressViewStyle(.circular)
                            } else {
                                Text("Connect")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(!deviceName.isEmpty && !ipAddress.isEmpty ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .disabled(deviceName.isEmpty || ipAddress.isEmpty || isConnecting)
                    }
                    .padding()
                }

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onChange(of: showQRScanner) { isShowing in
                if !isShowing && !ipAddress.isEmpty && deviceName.isEmpty {
                    deviceName = "Broadcaster"
                }
            }
    }

    func connectToCloud() {
        isConnecting = true
        remoteViewer.connectToCloud(pairingCode: pairingCode)
        // In real implementation, this would navigate to CloudViewerView
    }

    func connectToLocal() {
        isConnecting = true
        if let portNum = Int(port) {
            let code = pairingCode.isEmpty ? nil : pairingCode
            remoteViewer.connectToLocal(deviceName: deviceName, ipAddress: ipAddress, port: portNum, pairingCode: code)
            // In real implementation, this would navigate to StreamViewerView
        }
    }
}