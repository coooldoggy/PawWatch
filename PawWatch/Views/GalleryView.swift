import SwiftUI
import AVKit
import KakaoSDKTalk

struct GalleryView: View {
    @StateObject private var viewModel = GalleryViewModel()
    @State private var selectedVideo: VideoItem?
    @State private var showPlayer = false

    var body: some View {
        NavigationView {
            VStack {
                if viewModel.videos.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "film")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        Text("녹화된 영상이 없습니다")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(viewModel.videos) { video in
                            VideoRow(
                                video: video,
                                onPlay: {
                                    selectedVideo = video
                                    showPlayer = true
                                },
                                onShare: {
                                    shareVideo(video)
                                },
                                onDelete: {
                                    viewModel.deleteVideo(at: video.url)
                                }
                            )
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("갤러리")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                viewModel.loadVideos()
            }
            .sheet(isPresented: $showPlayer) {
                if let video = selectedVideo {
                    VideoPlayerView(url: video.url)
                }
            }
        }
    }

    private func shareVideo(_ video: VideoItem) {
        let videoURL = video.url
        let message = "녹화된 영상을 공유합니다! 🐱"

        // Try to open KakaoTalk
        if let urlStr = "kakaoopen://talk".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
           let url = URL(string: urlStr) {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }

        // Share via KakaoTalk with file
        TalkApiClient.shared.sendDefaultMemo(text: message) { error in
            if let error = error {
                print("KakaoTalk share failed: \(error)")
            } else {
                print("KakaoTalk auto-share success")
            }
        }

        // Alternative: Use standard iOS share sheet
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let activityViewController = UIActivityViewController(
                activityItems: [videoURL],
                applicationActivities: nil
            )
            UIApplication.shared.windows.first?.rootViewController?.present(
                activityViewController,
                animated: true
            )
        }
    }
}

struct VideoRow: View {
    let video: VideoItem
    let onPlay: () -> Void
    let onShare: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(video.fileName)
                    .font(.headline)
                    .lineLimit(1)
                Text(video.formattedDate)
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            HStack(spacing: 8) {
                Button(action: onPlay) {
                    HStack(spacing: 4) {
                        Image(systemName: "play.circle.fill")
                        Text("재생")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }

                Button(action: onShare) {
                    HStack(spacing: 4) {
                        Image(systemName: "square.and.arrow.up")
                        Text("공유")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

struct VideoPlayerView: View {
    let url: URL
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            VideoPlayer(player: AVPlayer(url: url))
                .ignoresSafeArea()

            VStack {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                    }
                    .padding()

                    Spacer()
                }

                Spacer()
            }
        }
    }
}

#Preview {
    GalleryView()
}
