import SwiftUI

struct SettingsView: View {
    @State private var isCloudStreamingEnabled = false
    @State private var videoQuality = 1

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Streaming")) {
                    Toggle("Cloud Streaming", isOn: $isCloudStreamingEnabled)

                    Picker("Video Quality", selection: $videoQuality) {
                        Text("Low").tag(0)
                        Text("Medium").tag(1)
                        Text("High").tag(2)
                    }
                }

                Section(header: Text("Detection")) {
                    Slider(value: .constant(0.7), in: 0...1)
                    Text("Sensitivity: 70%")
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.gray)
                    }

                    HStack {
                        Text("Build")
                        Spacer()
                        Text("1")
                            .foregroundColor(.gray)
                    }
                }

                Section(header: Text("Legal")) {
                    NavigationLink("Privacy Policy", destination: Text("Privacy Policy"))
                    NavigationLink("Terms of Service", destination: Text("Terms of Service"))
                }
            }
            .navigationTitle("Settings")
        }
    }
}
