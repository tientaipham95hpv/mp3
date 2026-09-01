import Foundation

public enum MediaType: String, Codable {
    case audio = "mp3"
    case video = "mp4"
    
    public var iconName: String {
        switch self {
        case .audio: return "music.note"
        case .video: return "film"
        }
    }
}

public struct MediaItem: Identifiable, Codable, Hashable {
    public let id: String
    public var title: String
    public var artist: String
    public var duration: Double
    public var mediaType: MediaType
    public var localFileName: String
    public var thumbnailURL: String?
    public var downloadedAt: Date
    
    public init(
        id: String = UUID().uuidString,
        title: String,
        artist: String,
        duration: Double,
        mediaType: MediaType,
        localFileName: String,
        thumbnailURL: String? = nil,
        downloadedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.artist = artist
        self.duration = duration
        self.mediaType = mediaType
        self.localFileName = localFileName
        self.thumbnailURL = thumbnailURL
        self.downloadedAt = downloadedAt
    }
    
    public var localURL: URL? {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        let subfolder = mediaType == .audio ? "Audio" : "Videos"
        return documents?.appendingPathComponent(subfolder).appendingPathComponent(localFileName)
    }
    
    public var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
