import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct LibraryView: View {
    @ObservedObject var downloadManager = DownloadManager.shared
    @ObservedObject var audioPlayerManager = AudioPlayerManager.shared
    
    @State private var selectedSegment: MediaType = .audio
    @State private var searchText: String = ""
    @State private var selectedVideoItem: MediaItem? = nil
    @State private var showAudioPlayerModal: Bool = false
    
    private var primaryGradient: LinearGradient {
        LinearGradient(
            colors: [Color(red: 0.68, green: 0.22, blue: 0.98), Color(red: 0.98, green: 0.18, blue: 0.52)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    var filteredItems: [MediaItem] {
        downloadManager.library.filter { item in
            let matchesType = item.mediaType == selectedSegment
            let matchesSearch = searchText.isEmpty || item.title.localizedCaseInsensitiveContains(searchText) || item.artist.localizedCaseInsensitiveContains(searchText)
            return matchesType && matchesSearch
        }
    }
    
    var body: some View {
        ZStack {
            // Full Screen Obsidian Background
            Color(red: 0.05, green: 0.04, blue: 0.09).ignoresSafeArea()
            
            VStack(spacing: 16) {
                // Top Navigation Title Bar
                HStack {
                    Text("THƯ VIỆN OFFLINE")
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .tracking(1.0)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                
                // Category Filter Pills
                HStack(spacing: 12) {
                    Button(action: { selectedSegment = .audio }) {
                        HStack(spacing: 6) {
                            Image(systemName: "music.note")
                            Text("Âm thanh (\(audioCount))")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(selectedSegment == .audio ? AnyView(primaryGradient) : AnyView(Color.white.opacity(0.06)))
                        .foregroundColor(.white)
                        .cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(selectedSegment == .audio ? Color.clear : Color.white.opacity(0.1), lineWidth: 1))
                    }
                    
                    Button(action: { selectedSegment = .video }) {
                        HStack(spacing: 6) {
                            Image(systemName: "film.fill")
                            Text("Video (\(videoCount))")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(selectedSegment == .video ? AnyView(primaryGradient) : AnyView(Color.white.opacity(0.06)))
                        .foregroundColor(.white)
                        .cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(selectedSegment == .video ? Color.clear : Color.white.opacity(0.1), lineWidth: 1))
                    }
                }
                .padding(.horizontal, 20)
                
                // Glassmorphic Search Bar
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(Color.white.opacity(0.5))
                    
                    TextField("Tìm kiếm tên bài hát, ca sĩ...", text: $searchText)
                        .foregroundColor(.white)
                        .accentColor(.purple)
                    
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(12)
                .background(Color.white.opacity(0.06))
                .cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1), lineWidth: 1))
                .padding(.horizontal, 20)
                
                // Media List Container
                if filteredItems.isEmpty {
                    VStack(spacing: 14) {
                        Spacer()
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.05))
                                .frame(width: 90, height: 90)
                            Image(systemName: selectedSegment == .audio ? "music.note.house.fill" : "video.slash.fill")
                                .font(.system(size: 40))
                                .foregroundColor(Color.white.opacity(0.4))
                        }
                        Text(emptyStateText)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.white)
                        Text("Nhấp vào tab Tải về để dán link YouTube và lưu file vào máy.")
                            .font(.system(size: 13))
                            .foregroundColor(Color.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 36)
                        Spacer()
                    }
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredItems) { item in
                                MediaCardRowView(
                                    item: item,
                                    isPlaying: audioPlayerManager.currentTrack?.id == item.id && audioPlayerManager.isPlaying,
                                    onTap: { handleItemTap(item) },
                                    onDelete: { downloadManager.deleteMediaItem(item) }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 160)
                    }
                }
            }
        }
        .sheet(item: $selectedVideoItem) { videoItem in
            if let videoURL = videoItem.localURL {
                VideoPlayerView(videoURL: videoURL, title: videoItem.title)
            }
        }
        .sheet(isPresented: $showAudioPlayerModal) {
            AudioPlayerView()
        }
    }
    
    private var audioCount: Int {
        downloadManager.library.filter { $0.mediaType == .audio }.count
    }
    
    private var videoCount: Int {
        downloadManager.library.filter { $0.mediaType == .video }.count
    }
    
    private var emptyStateText: String {
        if !searchText.isEmpty {
            return "Không tìm thấy bài hát nào"
        }
        return selectedSegment == .audio ? "Chưa có bài hát MP3 nào" : "Chưa có video MP4 nào"
    }
    
    private func handleItemTap(_ item: MediaItem) {
        if item.mediaType == .audio {
            let audioPlaylist = downloadManager.library.filter { $0.mediaType == .audio }
            audioPlayerManager.playTrack(item, inPlaylist: audioPlaylist)
            showAudioPlayerModal = true
        } else {
            selectedVideoItem = item
        }
    }
}

struct MediaCardRowView: View {
    let item: MediaItem
    let isPlaying: Bool
    let onTap: () -> Void
    let onDelete: () -> Void
    
    private var primaryGradient: LinearGradient {
        LinearGradient(
            colors: [Color(red: 0.68, green: 0.22, blue: 0.98), Color(red: 0.98, green: 0.18, blue: 0.52)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // Art Thumbnail with Soundwave/Icon overlay
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            item.mediaType == .audio
                            ? LinearGradient(colors: [Color.purple.opacity(0.4), Color.indigo.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
                            : LinearGradient(colors: [Color.blue.opacity(0.4), Color.teal.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                    
                    if isPlaying {
                        Image(systemName: "waveform")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: item.mediaType == .audio ? "music.note" : "play.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .frame(width: 52, height: 52)
                .shadow(color: item.mediaType == .audio ? Color.purple.opacity(0.3) : Color.blue.opacity(0.3), radius: 6, x: 0, y: 3)
                
                // Track Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    HStack(spacing: 6) {
                        Text(item.artist)
                            .font(.system(size: 12))
                            .foregroundColor(Color.white.opacity(0.6))
                            .lineLimit(1)
                        
                        Text("•")
                            .font(.system(size: 10))
                            .foregroundColor(Color.white.opacity(0.4))
                        
                        Text(item.formattedDuration)
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(Color(red: 0.75, green: 0.35, blue: 0.98))
                    }
                }
                
                Spacer()
                
                // Play Action Circle Button
                Button(action: onTap) {
                    ZStack {
                        Circle()
                            .fill(isPlaying ? primaryGradient : LinearGradient(colors: [Color.white.opacity(0.15)], startPoint: .leading, endPoint: .trailing))
                            .frame(width: 38, height: 38)
                        
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .offset(x: isPlaying ? 0 : 1)
                    }
                }
            }
            .padding(12)
            .background(Color.white.opacity(isPlaying ? 0.1 : 0.06))
            .cornerRadius(18)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(isPlaying ? Color.purple.opacity(0.6) : Color.white.opacity(0.08), lineWidth: 1)
            )
        }
    }
}
