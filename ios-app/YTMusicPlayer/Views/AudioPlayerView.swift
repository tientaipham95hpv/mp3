import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct AudioPlayerView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var playerManager = AudioPlayerManager.shared
    
    @State private var isDraggingSeekbar: Bool = false
    @State private var dragTime: Double = 0.0
    
    private var backgroundColor: Color {
        #if canImport(UIKit)
        return Color(UIColor.systemBackground)
        #else
        return Color.black
        #endif
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Dismiss Bar
            Capsule()
                .fill(Color.gray.opacity(0.4))
                .frame(width: 40, height: 5)
                .padding(.top, 12)
            
            Spacer()
            
            // Large Album Art / Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.purple.opacity(0.6), Color.indigo.opacity(0.8)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: Color.purple.opacity(0.4), radius: 20, x: 0, y: 10)
                
                Image(systemName: "music.note")
                    .font(.system(size: 80))
                    .foregroundColor(.white)
            }
            .frame(width: 240, height: 240)
            
            Spacer()
            
            // Track Info
            if let track = playerManager.currentTrack {
                VStack(spacing: 6) {
                    Text(track.title)
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .padding(.horizontal)
                    
                    Text(track.artist)
                        .font(.headline)
                        .foregroundColor(.purple)
                }
            } else {
                Text("Không có bài hát nào")
                    .font(.title3)
                    .foregroundColor(.gray)
            }
            
            // Seekbar (Slider)
            VStack(spacing: 8) {
                Slider(
                    value: Binding(
                        get: { isDraggingSeekbar ? dragTime : playerManager.currentTime },
                        set: { newValue in
                            dragTime = newValue
                            isDraggingSeekbar = true
                        }
                    ),
                    in: 0...(playerManager.duration > 0 ? playerManager.duration : 1.0),
                    onEditingChanged: { editing in
                        if !editing {
                            playerManager.seek(to: dragTime)
                            isDraggingSeekbar = false
                        }
                    }
                )
                .accentColor(.purple)
                
                HStack {
                    Text(formatTime(isDraggingSeekbar ? dragTime : playerManager.currentTime))
                        .font(.caption.monospacedDigit())
                        .foregroundColor(.gray)
                    Spacer()
                    Text(formatTime(playerManager.duration))
                        .font(.caption.monospacedDigit())
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 28)
            
            // Control Buttons (Prev / Play-Pause / Next)
            HStack(spacing: 40) {
                Button(action: { playerManager.playPrevious() }) {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.primary)
                }
                
                Button(action: { playerManager.togglePlayPause() }) {
                    ZStack {
                        Circle()
                            .fill(Color.purple)
                            .frame(width: 72, height: 72)
                            .shadow(color: Color.purple.opacity(0.4), radius: 10, x: 0, y: 5)
                        Image(systemName: playerManager.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                    }
                }
                
                Button(action: { playerManager.playNext() }) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.primary)
                }
            }
            .padding(.vertical, 12)
            
            Spacer()
        }
        .padding()
        .background(backgroundColor.ignoresSafeArea())
    }
    
    private func formatTime(_ seconds: Double) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
