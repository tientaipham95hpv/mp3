import Foundation

public struct YouTubeVideoInfo: Codable {
    public let id: String
    public let title: String
    public let artist: String
    public let duration: Double
    public let thumbnail: String?
    public let webpage_url: String
}

public class APIClient: ObservableObject {
    public static let shared = APIClient()
    
    // Default 24/7 Cloudflare Tunnel URL with persistent storage
    @Published public var baseURL: String {
        didSet {
            UserDefaults.standard.set(baseURL, forKey: "custom_backend_url")
        }
    }
    
    public init() {
        self.baseURL = "https://cookbook-inn-tea-converted.trycloudflare.com"
        UserDefaults.standard.set(self.baseURL, forKey: "custom_backend_url")
    }
    
    private func cleanYouTubeID(_ url: String) -> String {
        let pattern = #"(?:v=|\/([0-9A-Za-z_-]{11})|embed\/|youtu\.be\/)([0-9A-Za-z_-]{11})"#
        if let regex = try? NSRegularExpression(pattern: pattern) {
            let nsString = url as NSString
            let results = regex.matches(in: url, range: NSRange(location: 0, length: nsString.length))
            if let match = results.first {
                let r2 = match.range(at: 2)
                if r2.location != NSNotFound {
                    return nsString.substring(with: r2)
                }
                let r1 = match.range(at: 1)
                if r1.location != NSNotFound {
                    return nsString.substring(with: r1)
                }
            }
        }
        return url
    }
    
    public func fetchVideoInfo(url: String) async throws -> YouTubeVideoInfo {
        let videoID = cleanYouTubeID(url)
        let cleanURL = "https://www.youtube.com/watch?v=\(videoID)"
        
        // 1. Direct Client-Side oEmbed Metadata Extraction (100% IP resilient on iPhone)
        if let encodedClean = cleanURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
           let oembedURL = URL(string: "https://www.youtube.com/oembed?url=\(encodedClean)&format=json") {
            do {
                let (data, response) = try await URLSession.shared.data(from: oembedURL)
                if let httpRes = response as? HTTPURLResponse, httpRes.statusCode == 200,
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    let title = json["title"] as? String ?? "YouTube Video"
                    let author = json["author_name"] as? String ?? "YouTube Artist"
                    let thumbnail = json["thumbnail_url"] as? String
                    
                    return YouTubeVideoInfo(
                        id: videoID,
                        title: title,
                        artist: author,
                        duration: 0.0,
                        thumbnail: thumbnail,
                        webpage_url: cleanURL
                    )
                }
            } catch {}
        }
        
        // 2. Fallback to Backend Server
        let cleanBaseURL = baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let encodedParam = cleanURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? cleanURL
        guard let requestURL = URL(string: "\(cleanBaseURL)/api/info?url=\(encodedParam)") else {
            throw URLError(.badURL)
        }
        
        let (data, response) = try await URLSession.shared.data(from: requestURL)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        return try JSONDecoder().decode(YouTubeVideoInfo.self, from: data)
    }
    
    public func getDownloadURL(youtubeURL: String, mediaType: MediaType, quality: String = "720p") -> URL? {
        let videoID = cleanYouTubeID(youtubeURL)
        let cleanURL = "https://www.youtube.com/watch?v=\(videoID)"
        let encodedClean = cleanURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? cleanURL
        let cleanBaseURL = baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let urlString = "\(cleanBaseURL)/api/download?url=\(encodedClean)&media_type=\(mediaType.rawValue)&quality=\(quality)"
        return URL(string: urlString)
    }
}
