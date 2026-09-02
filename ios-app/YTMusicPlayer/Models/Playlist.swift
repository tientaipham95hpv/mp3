import Foundation

public struct Playlist: Identifiable, Codable, Hashable {
    public let id: String
    public var name: String
    public var iconName: String
    public var itemIDs: [String]
    public var createdAt: Date
    
    public init(
        id: String = UUID().uuidString,
        name: String,
        iconName: String = "music.note.list",
        itemIDs: [String] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.itemIDs = itemIDs
        self.createdAt = createdAt
    }
}
