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
    
    // Server IP / Host - Update this to your local server IP (e.g., http://192.168.1.50:8000) when testing on a physical iPhone!
    @Published public var baseURL: String = "http://localhost:8000"
    
    public init() {}
    
    public func fetchVideoInfo(url: String) async throws -> YouTubeVideoInfo {
        guard let encodedURL = url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let requestURL = URL(string: "\(baseURL)/api/info?url=\(encodedURL)") else {
            throw URLError(.badURL)
        }
        
        let (data, response) = try await URLSession.shared.data(from: requestURL)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(YouTubeVideoInfo.self, from: data)
    }
    
    public func getDownloadURL(youtubeURL: String, mediaType: MediaType, quality: String = "720p") -> URL? {
        guard let encodedURL = youtubeURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return nil
        }
        let urlString = "\(baseURL)/api/download?url=\(encodedURL)&media_type=\(mediaType.rawValue)&quality=\(quality)"
        return URL(string: urlString)
    }
}
