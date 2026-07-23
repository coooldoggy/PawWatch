import Foundation
import Combine

class GalleryViewModel: ObservableObject {
    @Published var videos: [VideoItem] = []

    init() {
        loadVideos()
    }

    func loadVideos() {
        let fileManager = FileManager.default
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let videosPath = (documentsPath as NSString).appendingPathComponent("Videos")

        guard fileManager.fileExists(atPath: videosPath) else {
            videos = []
            return
        }

        do {
            let files = try fileManager.contentsOfDirectory(atPath: videosPath)
            videos = files
                .filter { $0.lowercased().hasSuffix(".mov") || $0.lowercased().hasSuffix(".mp4") }
                .compactMap { fileName in
                    let filePath = (videosPath as NSString).appendingPathComponent(fileName)
                    let attributes = try? fileManager.attributesOfItem(atPath: filePath)
                    let timestamp = (attributes?[.modificationDate] as? Date)?.timeIntervalSince1970 ?? 0

                    return VideoItem(
                        fileName: fileName,
                        path: filePath,
                        timestamp: timestamp
                    )
                }
                .sorted { $0.timestamp > $1.timestamp }
        } catch {
            print("Error loading videos: \(error)")
            videos = []
        }
    }

    func deleteVideo(at url: URL) {
        let fileManager = FileManager.default
        do {
            try fileManager.removeItem(at: url)
            loadVideos()
        } catch {
            print("Error deleting video: \(error)")
        }
    }
}

struct VideoItem: Identifiable {
    let id = UUID()
    let fileName: String
    let path: String
    let timestamp: TimeInterval

    var url: URL {
        URL(fileURLWithPath: path)
    }

    var formattedDate: String {
        let date = Date(timeIntervalSince1970: timestamp)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: date)
    }
}
