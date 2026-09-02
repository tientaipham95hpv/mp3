import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

public enum LibraryFilter: String, CaseIterable, Identifiable {
    case all = "Tất cả"
    case audio = "🎵 MP3"
    case video = "🎬 MP4"
    case favorites = "❤️ Yêu thích"
    case topPlayed = "🔥 Nghe Nhiều"
    
    public var id: String { rawValue }
}

struct LibraryView: View {
    @ObservedObject var downloadManager = DownloadManager.shared
    @ObservedObject var audioPlayerManager = AudioPlayerManager.shared
    
    @State private var selectedFilter: LibraryFilter = .all
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
            let matchesFilter: Bool
            switch selectedFilter {
            case .all: matchesFilter = true
            case .audio: matchesFilter = item.mediaType == .audio
            case .video: matchesFilter = item.mediaType == .video
            case .favorites: matchesFilter = item.isFavorite
            case .topPlayed: matchesFilter = item.playCount > 0
            }
            
            let matchesSearch = searchText.isEmpty || item.title.localizedCaseInsensitiveContains(searchText) || item.artist.localizedCaseInsensitiveContains(searchText)
            return matchesFilter && matchesSearch
        }.sorted {
            if selectedFilter == .topPlayed {
                return $0.playCount > $1.playCount
            }
            return $0.downloadedAt > $1.downloadedAt
        }
    }
    
    var body: some View {
        ZStack {
            // Full Screen Obsidian Background
            Color(red: 0.05, green: 0.04, blue: 0.09).ignoresSafeArea()
            
            VStack(spacing: 14) {
                // Top Navigation Title Bar
                HStack {
                    Text("THƯ VIỆN OFFLINE PRO")
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .tracking(1.0)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                
                // Category Filter Pills Scrollable
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(LibraryFilter.allCases) { filter in
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedFilter = filter
                                }
                            }) {
                                Text(filter.rawValue)
                                    .font(.system(size: 13, weight: .bold))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(selectedFilter == filter ? AnyView(primaryGradient) : AnyView(Color.white.opacity(0.06)))
                                    .foregroundColor(.white)
                                    .cornerRadius(16)
                                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(selectedFilter == filter ? Color.clear : Color.white.opacity(0.1), lineWidth: 1))
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
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
                            Image(systemName: "music.note.house.fill")
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
                                    onToggleFavorite: { downloadManager.toggleFavorite(item) },
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
    
    private var emptyStateText: String {
        if !searchText.isEmpty {
            return "Không tìm thấy kết quả nào"
        }
        switch selectedFilter {
        case .all: return "Chưa có bài hát hoặc video nào"
        case .audio: return "Chưa có bài hát MP3 nào"
        case .video: return "Chưa có video MP4 nào"
        case .favorites: return "Chưa có bài hát Yêu thích nào"
        case .topPlayed: return "Chưa có lịch sử phát nhạc"
        }
    }
    
    private func handleItemTap(_ item: MediaItem) {
        downloadManager.incrementPlayCount(item)
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
    let onToggleFavorite: () -> Void
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
                
                // Favorite Heart Button
                Button(action: onToggleFavorite) {
                    Image(systemName: item.isFavorite ? "heart.fill" : "heart")
                        .font(.system(size: 18))
                        .foregroundColor(item.isFavorite ? Color.red : Color.white.opacity(0.4))
                        .padding(6)
                }
                
                // Play Action Circle Button
                Button(action: onTap) {
                    ZStack {
                        Circle()
                            .fill(isPlaying ? primaryGradient : LinearGradient(colors: [Color.white.opacity(0.15)], startPoint: .leading, endPoint: .trailing))
                            .frame(width: 36, height: 36)
                        
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
