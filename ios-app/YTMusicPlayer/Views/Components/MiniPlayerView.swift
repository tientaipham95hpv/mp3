import SwiftUI

struct MiniPlayerView: View {
    @ObservedObject var playerManager = AudioPlayerManager.shared
    @Binding var isExpanded: Bool
    
    var body: some View {
        if let track = playerManager.currentTrack, track.mediaType == .audio {
            HStack(spacing: 12) {
                // Thumbnail / Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.purple.opacity(0.2))
                    Image(systemName: "music.note")
                        .foregroundColor(.purple)
                }
                .frame(width: 44, height: 44)
                
                // Track Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(track.title)
                        .font(.system(size: 14, weight: .semibold))
                        .lineLimit(1)
                    Text(track.artist)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Play / Pause Button
                Button(action: {
                    playerManager.togglePlayPause()
                }) {
                    Image(systemName: playerManager.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.primary)
                        .frame(width: 44, height: 44)
                }
                
                // Next Track Button
                Button(action: {
                    playerManager.playNext()
                }) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.gray)
                        .frame(width: 40, height: 44)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
                    .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 3)
            )
            .padding(.horizontal, 8)
            .onTapGesture {
                isExpanded = true
            }
        }
    }
}
