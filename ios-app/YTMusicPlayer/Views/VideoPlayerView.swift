import SwiftUI
import AVKit

struct VideoPlayerView: View {
    @Environment(\.dismiss) var dismiss
    let videoURL: URL
    let title: String
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                CustomVideoPlayer(url: videoURL)
                    .ignoresSafeArea()
            }
            .navigationTitle(title)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Đóng") {
                        dismiss()
                    }
                }
            }
            #else
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Đóng") {
                        dismiss()
                    }
                }
            }
            #endif
        }
    }
}

#if os(iOS)
struct CustomVideoPlayer: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        let player = AVPlayer(url: url)
        controller.player = player
        controller.allowsPictureInPicturePlayback = true
        controller.canStartPictureInPictureAutomaticallyFromInline = true
        player.play()
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {}
}
#else
struct CustomVideoPlayer: View {
    let url: URL
    var body: some View {
        VideoPlayer(player: AVPlayer(url: url))
    }
}
#endif
