import Foundation

class PairingManager {
    private let defaults = UserDefaults.standard
    private let deviceIdKey = "device_id"
    private let pairedDevicesKey = "paired_devices"

    var deviceId: String {
        if let id = defaults.string(forKey: deviceIdKey) {
            return id
        }
        let newId = UUID().uuidString
        defaults.set(newId, forKey: deviceIdKey)
        return newId
    }

    func generatePairingCode() -> String {
        let random = Int.random(in: 100000..<1000000)
        return String(format: "%06d", random)
    }

    func addPairedDevice(_ id: String, name: String, code: String) {
        var devices = getPairedDevices()
        let device = PairedDevice(id: id, name: name, code: code, pairedAt: Date(), lastSeen: Date())
        devices[id] = device
        savePairedDevices(devices)
    }

    func getPairedDevices() -> [String: PairedDevice] {
        guard let data = defaults.data(forKey: pairedDevicesKey),
              let devices = try? JSONDecoder().decode([String: PairedDevice].self, from: data) else {
            return [:]
        }
        return devices
    }

    private func savePairedDevices(_ devices: [String: PairedDevice]) {
        if let data = try? JSONEncoder().encode(devices) {
            defaults.set(data, forKey: pairedDevicesKey)
        }
    }
}

struct PairedDevice: Codable {
    let id: String
    let name: String
    let code: String
    let pairedAt: Date
    let lastSeen: Date
}
