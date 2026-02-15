import Foundation
import GRDB

final class GRDBManager {
    static let shared = GRDBManager()

    let dbQueue: DatabaseQueue

    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dbDir = appSupport.appendingPathComponent("DocMark", isDirectory: true)
        try? FileManager.default.createDirectory(at: dbDir, withIntermediateDirectories: true)
        let dbURL = dbDir.appendingPathComponent("docmark.sqlite")

        do {
            var config = Configuration()
            config.foreignKeysEnabled = true
            dbQueue = try DatabaseQueue(path: dbURL.path, configuration: config)
            try migrator.migrate(dbQueue)
        } catch {
            fatalError("Database initialization failed: \(error)")
        }
    }

    private var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

        #if DEBUG
        migrator.eraseDatabaseOnSchemaChange = true
        #endif

        migrator.registerMigration("v1_initial_schema") { db in
            try db.create(table: "projects") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("uuid", .text).notNull().unique()
                t.column("name", .text).notNull()
                t.column("path", .text).notNull().unique()
                t.column("isFavorite", .boolean).notNull().defaults(to: false)
                t.column("isPinned", .boolean).notNull().defaults(to: false)
                t.column("createdAt", .datetime).notNull()
                t.column("lastOpenedAt", .datetime)
                t.column("documentCount", .integer).notNull().defaults(to: 0)
            }

            try db.create(table: "documents") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("uuid", .text).notNull().unique()
                t.column("projectId", .integer).notNull()
                    .indexed()
                    .references("projects", onDelete: .cascade)
                t.column("title", .text).notNull()
                t.column("path", .text).notNull()
                t.column("relativePath", .text).notNull()
                t.column("content", .text).notNull().defaults(to: "")
                t.column("headings", .text).notNull().defaults(to: "")
                t.column("fileSize", .integer).notNull().defaults(to: 0)
                t.column("lastModified", .datetime).notNull()
                t.column("frontmatterJson", .text)
            }

            try db.create(virtualTable: "documents_fts", using: FTS5()) { t in
                t.synchronize(withTable: "documents")
                t.column("title")
                t.column("headings")
                t.column("content")
                t.tokenizer = .unicode61()
            }

            try db.create(table: "projectState") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("projectId", .integer).notNull().unique()
                    .references("projects", onDelete: .cascade)
                t.column("lastDocumentPath", .text)
                t.column("sidebarExpansionJson", .text)
                t.column("scrollPositionJson", .text)
                t.column("updatedAt", .datetime).notNull()
            }
        }

        return migrator
    }
}
