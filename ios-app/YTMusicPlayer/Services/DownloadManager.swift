import Foundation
import Combine

public enum DownloadState {
    case idle
    case fetchingInfo
    case downloading(progress: Double)
    case completed(MediaItem)
    case failed(String)
}

public class DownloadManager: NSObject, ObservableObject, URLSessionDownloadDelegate {
    public static let shared = DownloadManager()
    
    @Published public var state: DownloadState = .idle
    @Published public var library: [MediaItem] = []
    
    private var downloadTask: URLSessionDownloadTask?
    private var currentInfo: YouTubeVideoInfo?
    private var currentMediaType: MediaType = .audio
    
    private var libraryFileURL: URL? {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        return documents?.appendingPathComponent("library.json")
    }
    
    override public init() {
        super.init()
        createDirectoriesIfNeeded()
        loadLibrary()
    }
    
    private func createDirectoriesIfNeeded() {
        guard let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let audioDir = documents.appendingPathComponent("Audio")
        let videoDir = documents.appendingPathComponent("Videos")
        
        try? FileManager.default.createDirectory(at: audioDir, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: videoDir, withIntermediateDirectories: true)
    }
    
    public func startDownload(youtubeURL: String, mediaType: MediaType, quality: String = "720p") {
        Task { @MainActor in
            self.state = .fetchingInfo
            do {
                let info = try await APIClient.shared.fetchVideoInfo(url: youtubeURL)
                self.currentInfo = info
                self.currentMediaType = mediaType
                
                guard let downloadURL = APIClient.shared.getDownloadURL(youtubeURL: youtubeURL, mediaType: mediaType, quality: quality) else {
                    self.state = .failed("Mã hóa URL không hợp lệ")
                    return
                }
                
                let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
                self.downloadTask = session.downloadTask(with: downloadURL)
                self.state = .downloading(progress: 0.0)
                self.downloadTask?.resume()
            } catch {
                self.state = .failed("Không thể lấy thông tin video: \(error.localizedDescription)")
            }
        }
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        if totalBytesExpectedToWrite > 0 {
            let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
            DispatchQueue.main.async {
                self.state = .downloading(progress: progress)
            }
        }
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let info = currentInfo else {
            DispatchQueue.main.async { self.state = .failed("Thiếu thông tin bài hát") }
            return
        }
        
        let ext = currentMediaType == .audio ? "mp3" : "mp4"
        let sanitizedTitle = info.title.components(separatedBy: CharacterSet.alphanumerics.inverted).joined(separator: "_")
        let filename = "\(sanitizedTitle)_\(info.id).\(ext)"
        
        guard let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let subfolder = currentMediaType == .audio ? "Audio" : "Videos"
        let targetURL = documents.appendingPathComponent(subfolder).appendingPathComponent(filename)
        
        do {
            if FileManager.default.fileExists(atPath: targetURL.path) {
                try FileManager.default.removeItem(at: targetURL)
            }
            try FileManager.default.moveItem(at: location, to: targetURL)
            
            let newItem = MediaItem(
                id: info.id,
                title: info.title,
                artist: info.artist,
                duration: info.duration,
                mediaType: currentMediaType,
                localFileName: filename,
                thumbnailURL: info.thumbnail,
                downloadedAt: Date()
            )
            
            DispatchQueue.main.async {
                self.addMediaItem(newItem)
                self.state = .completed(newItem)
            }
        } catch {
            DispatchQueue.main.async {
                self.state = .failed("Không thể lưu file: \(error.localizedDescription)")
            }
        }
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            DispatchQueue.main.async {
                self.state = .failed("Lỗi tải xuống: \(error.localizedDescription)")
            }
        }
    }
    
    public func addMediaItem(_ item: MediaItem) {
        // Remove duplicate if exists
        library.removeAll { $0.id == item.id && $0.mediaType == item.mediaType }
        library.insert(item, at: 0)
        saveLibrary()
    }
    
    public func deleteMediaItem(_ item: MediaItem) {
        if let fileURL = item.localURL {
            try? FileManager.default.removeItem(at: fileURL)
        }
        library.removeAll { $0.id == item.id }
        saveLibrary()
    }
    
    private func saveLibrary() {
        guard let url = libraryFileURL else { return }
        do {
            let data = try JSONEncoder().encode(library)
            try data.write(to: url)
        } catch {
            print("Failed to save library: \(error)")
        }
    }
    
    private func loadLibrary() {
        guard let url = libraryFileURL, FileManager.default.fileExists(atPath: url.path) else { return }
        do {
            let data = try Data(contentsOf: url)
            self.library = try JSONDecoder().decode([MediaItem].self, from: data)
        } catch {
            print("Failed to load library: \(error)")
        }
    }
}
