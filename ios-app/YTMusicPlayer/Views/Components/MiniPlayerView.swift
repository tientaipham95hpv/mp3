import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct MiniPlayerView: View {
    @ObservedObject var playerManager = AudioPlayerManager.shared
    @Binding var isExpanded: Bool
    
    private var primaryGradient: LinearGradient {
        LinearGradient(
            colors: [Color(red: 0.65, green: 0.25, blue: 0.98), Color(red: 0.95, green: 0.20, blue: 0.55)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    private var progressRatio: CGFloat {
        guard playerManager.duration > 0 else { return 0.0 }
        return CGFloat(min(max(playerManager.currentTime / playerManager.duration, 0.0), 1.0))
    }
    
    var body: some View {
        if let track = playerManager.currentTrack, track.mediaType == .audio {
            VStack(spacing: 0) {
                // Top Thin Progress Line
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.white.opacity(0.1))
                        Rectangle()
                            .fill(primaryGradient)
                            .frame(width: max(geometry.size.width * progressRatio, 4))
                    }
                }
                .frame(height: 3)
                
                HStack(spacing: 12) {
                    // Artwork Icon Container
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(primaryGradient)
                            .shadow(color: Color.purple.opacity(0.4), radius: 6, x: 0, y: 3)
                        
                        Image(systemName: playerManager.isPlaying ? "waveform" : "music.note")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .frame(width: 44, height: 44)
                    
                    // Track Title & Artist
                    VStack(alignment: .leading, spacing: 2) {
                        Text(track.title)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Text(track.artist)
                            .font(.system(size: 12))
                            .foregroundColor(Color.white.opacity(0.6))
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    // Play/Pause Action Button
                    Button(action: {
                        playerManager.togglePlayPause()
                    }) {
                        ZStack {
                            Circle()
                                .fill(primaryGradient)
                                .frame(width: 36, height: 36)
                            
                            Image(systemName: playerManager.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .offset(x: playerManager.isPlaying ? 0 : 1)
                        }
                    }
                    
                    // Next Track Action Button
                    Button(action: {
                        playerManager.playNext()
                    }) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color.white.opacity(0.8))
                            .frame(width: 32, height: 36)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
            }
            .background(Color(red: 0.12, green: 0.10, blue: 0.20))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.4), radius: 12, x: 0, y: 6)
            .padding(.horizontal, 12)
            .onTapGesture {
                isExpanded = true
            }
        }
    }
}
