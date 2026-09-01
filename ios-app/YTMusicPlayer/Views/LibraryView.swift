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
    
    private var cardBackgroundColor: Color {
        #if canImport(UIKit)
        return Color(UIColor.secondarySystemGroupedBackground)
        #else
        return Color.gray.opacity(0.15)
        #endif
    }
    
    var filteredItems: [MediaItem] {
        downloadManager.library.filter { item in
            let matchesType = item.mediaType == selectedSegment
            let matchesSearch = searchText.isEmpty || item.title.localizedCaseInsensitiveContains(searchText) || item.artist.localizedCaseInsensitiveContains(searchText)
            return matchesType && matchesSearch
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Media Filter Picker
                Picker("Phân loại", selection: $selectedSegment) {
                    Text("🎵 Âm thanh (\(audioCount))").tag(MediaType.audio)
                    Text("🎬 Video (\(videoCount))").tag(MediaType.video)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Tìm kiếm bài hát / video...", text: $searchText)
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(10)
                .background(cardBackgroundColor)
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.bottom, 8)
                
                // Media List
                if filteredItems.isEmpty {
                    VStack(spacing: 12) {
                        Spacer()
                        Image(systemName: selectedSegment == .audio ? "music.note.house" : "video.slash")
                            .font(.system(size: 56))
                            .foregroundColor(.gray.opacity(0.6))
                        Text(emptyStateText)
                            .font(.headline)
                            .foregroundColor(.gray)
                        Text("Hãy qua tab Tải về để dán link YouTube và tải file offline.")
                            .font(.subheadline)
                            .foregroundColor(.gray.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                        Spacer()
                    }
                } else {
                    List {
                        ForEach(filteredItems) { item in
                            MediaRowView(item: item) {
                                handleItemTap(item)
                            }
                        }
                        .onDelete(perform: deleteItems)
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Thư viện Offline")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $selectedVideoItem) { videoItem in
                if let videoURL = videoItem.localURL {
                    VideoPlayerView(videoURL: videoURL, title: videoItem.title)
                }
            }
            .sheet(isPresented: $showAudioPlayerModal) {
                AudioPlayerView()
            }
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
            return "Không tìm thấy kết quả phù hợp"
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
    
    private func deleteItems(at offsets: IndexSet) {
        let itemsToDelete = offsets.map { filteredItems[$0] }
        for item in itemsToDelete {
            downloadManager.deleteMediaItem(item)
        }
    }
}

struct MediaRowView: View {
    let item: MediaItem
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Icon / Art
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(item.mediaType == .audio ? Color.purple.opacity(0.15) : Color.blue.opacity(0.15))
                    Image(systemName: item.mediaType.iconName)
                        .foregroundColor(item.mediaType == .audio ? .purple : .blue)
                        .font(.title3)
                }
                .frame(width: 48, height: 48)
                
                // Title & Artist
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    HStack(spacing: 6) {
                        Text(item.artist)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(item.formattedDuration)
                            .font(.caption.monospacedDigit())
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: item.mediaType == .audio ? "play.circle.fill" : "play.rectangle.fill")
                    .font(.title2)
                    .foregroundColor(item.mediaType == .audio ? .purple : .blue)
            }
            .padding(.vertical, 4)
        }
    }
}
