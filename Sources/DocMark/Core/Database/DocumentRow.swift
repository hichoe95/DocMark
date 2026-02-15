import Foundation
import GRDB

struct DocumentRow: Codable, FetchableRecord, MutablePersistableRecord {
    static let databaseTableName = "documents"

    var id: Int64?
    var uuid: String
    var projectId: Int64
    var title: String
    var path: String
    var relativePath: String
    var content: String
    var headings: String
    var fileSize: Int
    var lastModified: Date
    var frontmatterJson: String?

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }

    static func from(_ document: Document, projectId: Int64) -> DocumentRow {
        let headings = extractHeadings(from: document.renderableContent)
        let fmJson = encodeFrontmatter(document.frontmatter)

        return DocumentRow(
            id: nil,
            uuid: document.id.uuidString,
            projectId: projectId,
            title: document.displayTitle,
            path: document.path,
            relativePath: document.relativePath,
            content: document.renderableContent,
            headings: headings,
            fileSize: document.fileSize,
            lastModified: document.lastModified,
            frontmatterJson: fmJson
        )
    }

    private static func extractHeadings(from content: String) -> String {
        content.components(separatedBy: .newlines)
            .filter { $0.hasPrefix("#") }
            .map { $0.trimmingCharacters(in: CharacterSet(charactersIn: "# ")) }
            .joined(separator: " ")
    }

    private static func encodeFrontmatter(_ fm: [String: String]) -> String? {
        guard !fm.isEmpty else { return nil }
        guard let data = try? JSONEncoder().encode(fm) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

struct ProjectStateRow: Codable, FetchableRecord, MutablePersistableRecord {
    static let databaseTableName = "projectState"

    var id: Int64?
    var projectId: Int64
    var lastDocumentPath: String?
    var sidebarExpansionJson: String?
    var scrollPositionJson: String?
    var updatedAt: Date

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
