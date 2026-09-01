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
    
    // Default production backend on Vercel
    @Published public var baseURL: String = "https://mp3-two-swart.vercel.app"
    
    public init() {}
    
    private func encodeQueryParam(_ value: String) -> String {
        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: "?&=+#/")
        return value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value
    }
    
    public func fetchVideoInfo(url: String) async throws -> YouTubeVideoInfo {
        let encodedURL = encodeQueryParam(url)
        let cleanBaseURL = baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        
        guard let requestURL = URL(string: "\(cleanBaseURL)/api/info?url=\(encodedURL)") else {
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
        let encodedURL = encodeQueryParam(youtubeURL)
        let cleanBaseURL = baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let urlString = "\(cleanBaseURL)/api/download?url=\(encodedURL)&media_type=\(mediaType.rawValue)&quality=\(quality)"
        return URL(string: urlString)
    }
}
