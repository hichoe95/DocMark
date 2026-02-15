import Foundation

struct Project: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let path: String
    let createdAt: Date
    var lastOpenedAt: Date?
    var isFavorite: Bool = false
    var isPinned: Bool = false
    var tags: [String] = []
    var category: String?
}
