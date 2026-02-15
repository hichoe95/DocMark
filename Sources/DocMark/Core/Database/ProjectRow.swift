import Foundation
import GRDB

struct ProjectRow: Codable, FetchableRecord, MutablePersistableRecord {
    static let databaseTableName = "projects"

    var id: Int64?
    var uuid: String
    var name: String
    var path: String
    var isFavorite: Bool
    var isPinned: Bool
    var createdAt: Date
    var lastOpenedAt: Date?
    var documentCount: Int

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }

    func toProject() -> Project {
        Project(
            id: UUID(uuidString: uuid) ?? UUID(),
            name: name,
            path: path,
            createdAt: createdAt,
            lastOpenedAt: lastOpenedAt,
            isFavorite: isFavorite,
            isPinned: isPinned
        )
    }

    static func from(_ project: Project, documentCount: Int = 0) -> ProjectRow {
        ProjectRow(
            id: nil,
            uuid: project.id.uuidString,
            name: project.name,
            path: project.path,
            isFavorite: project.isFavorite,
            isPinned: project.isPinned,
            createdAt: project.createdAt,
            lastOpenedAt: project.lastOpenedAt,
            documentCount: documentCount
        )
    }
}
