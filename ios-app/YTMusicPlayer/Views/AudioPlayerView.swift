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
    
    private var primaryGradient: LinearGradient {
        LinearGradient(
            colors: [Color(red: 0.65, green: 0.25, blue: 0.98), Color(red: 0.95, green: 0.20, blue: 0.55)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var body: some View {
        ZStack {
            // Dark Atmospheric Backdrop
            Color(red: 0.05, green: 0.05, blue: 0.08).ignoresSafeArea()
            
            // Blurred Artwork Ambient Glow
            VStack {
                Circle()
                    .fill(Color.purple.opacity(0.35))
                    .frame(width: 320, height: 320)
                    .blur(radius: 90)
                    .offset(y: -40)
            }
            
            VStack(spacing: 20) {
                // Top Grab Bar & Dismiss Button
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(12)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 2) {
                        Text("ĐANG PHÁT TỪ THƯ VIỆN")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color.purple.opacity(0.9))
                            .tracking(1.5)
                        if let track = playerManager.currentTrack {
                            Text(track.mediaType == .audio ? "MP3 Audio High-Res" : "MP4 Audio Track")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: {}) {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(12)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                
                Spacer()
                
                // Floating 3D Artwork Container
                ZStack {
                    RoundedRectangle(cornerRadius: 28)
                        .fill(primaryGradient)
                        .frame(width: 280, height: 280)
                        .shadow(color: Color.purple.opacity(0.5), radius: 30, x: 0, y: 15)
                        .scaleEffect(playerManager.isPlaying ? 1.0 : 0.9)
                        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: playerManager.isPlaying)
                    
                    Image(systemName: "music.note")
                        .font(.system(size: 96, weight: .light))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                
                Spacer()
                
                // Track Metadata Info
                VStack(spacing: 8) {
                    if let track = playerManager.currentTrack {
                        Text(track.title)
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .padding(.horizontal, 24)
                        
                        Text(track.artist)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(red: 0.75, green: 0.35, blue: 0.98))
                    } else {
                        Text("Chưa chọn bài hát")
                            .font(.title3.bold())
                            .foregroundColor(.gray)
                    }
                }
                
                // Progress Slider Container
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
                    .accentColor(Color(red: 0.75, green: 0.35, blue: 0.98))
                    
                    HStack {
                        Text(formatTime(isDraggingSeekbar ? dragTime : playerManager.currentTime))
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.6))
                        Spacer()
                        Text(formatTime(playerManager.duration))
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding(.horizontal, 28)
                
                // Modern Controller Bar
                HStack(spacing: 36) {
                    Button(action: { playerManager.playPrevious() }) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 26))
                            .foregroundColor(.white)
                    }
                    
                    Button(action: { playerManager.togglePlayPause() }) {
                        ZStack {
                            Circle()
                                .fill(primaryGradient)
                                .frame(width: 76, height: 76)
                                .shadow(color: Color.purple.opacity(0.6), radius: 15, x: 0, y: 8)
                            
                            Image(systemName: playerManager.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 32, weight: .semibold))
                                .foregroundColor(.white)
                                .offset(x: playerManager.isPlaying ? 0 : 2)
                        }
                    }
                    
                    Button(action: { playerManager.playNext() }) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 26))
                            .foregroundColor(.white)
                    }
                }
                .padding(.vertical, 16)
                
                Spacer()
            }
        }
    }
    
    private func formatTime(_ seconds: Double) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
