import Foundation
import GRDB

struct DocumentRepository {
    let dbQueue: DatabaseQueue

    init(dbQueue: DatabaseQueue) {
        self.dbQueue = dbQueue
    }

    func indexDocuments(_ documents: [Document], projectId: Int64) throws {
        try dbQueue.write { db in
            try DocumentRow.filter(Column("projectId") == projectId).deleteAll(db)

            for document in documents {
                var row = DocumentRow.from(document, projectId: projectId)
                try row.insert(db)
            }
        }
    }

    func reindexDocument(_ document: Document, projectId: Int64) throws {
        try dbQueue.write { db in
            if var existing = try DocumentRow.filter(Column("path") == document.path).fetchOne(db) {
                let updated = DocumentRow.from(document, projectId: projectId)
                existing.title = updated.title
                existing.content = updated.content
                existing.headings = updated.headings
                existing.fileSize = updated.fileSize
                existing.lastModified = updated.lastModified
                existing.frontmatterJson = updated.frontmatterJson
                try existing.update(db)
            } else {
                var inserted = DocumentRow.from(document, projectId: projectId)
                try inserted.insert(db)
            }
        }
    }

    func removeDocumentsForProject(projectId: Int64) throws {
        _ = try dbQueue.write { db in
            try DocumentRow.filter(Column("projectId") == projectId).deleteAll(db)
        }
    }

    func removeDocument(path: String) throws {
        _ = try dbQueue.write { db in
            try DocumentRow.filter(Column("path") == path).deleteAll(db)
        }
    }

    func fetchAll(projectId: Int64) throws -> [DocumentRow] {
        try dbQueue.read { db in
            try DocumentRow
                .filter(Column("projectId") == projectId)
                .order(Column("relativePath").asc)
                .fetchAll(db)
        }
    }

    func fetch(path: String) throws -> DocumentRow? {
        try dbQueue.read { db in
            try DocumentRow.filter(Column("path") == path).fetchOne(db)
        }
    }

    func fetchByRelativePath(_ relativePath: String, projectId: Int64) throws -> DocumentRow? {
        try dbQueue.read { db in
            try DocumentRow
                .filter(Column("projectId") == projectId)
                .filter(Column("relativePath") == relativePath)
                .fetchOne(db)
        }
    }

    func needsReindex(path: String, lastModified: Date, fileSize: Int) throws -> Bool {
        try dbQueue.read { db in
            guard let row = try DocumentRow.filter(Column("path") == path).fetchOne(db) else {
                return true
            }

            return row.lastModified != lastModified || row.fileSize != fileSize
        }
    }

    func documentCount(projectId: Int64) throws -> Int {
        try dbQueue.read { db in
            try DocumentRow.filter(Column("projectId") == projectId).fetchCount(db)
        }
    }
}
