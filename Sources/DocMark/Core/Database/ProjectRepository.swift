import Foundation
import GRDB

struct ProjectRepository {
    let dbQueue: DatabaseQueue

    init(dbQueue: DatabaseQueue) {
        self.dbQueue = dbQueue
    }

    func insertOrUpdate(_ project: Project, documentCount: Int = 0) throws -> Project {
        let projectRow = ProjectRow.from(project, documentCount: documentCount)

        return try dbQueue.write { db in
            if let existing = try ProjectRow.filter(Column("path") == projectRow.path).fetchOne(db) {
                var updated = existing
                updated.uuid = projectRow.uuid
                updated.name = projectRow.name
                updated.path = projectRow.path
                updated.isFavorite = projectRow.isFavorite
                updated.isPinned = projectRow.isPinned
                updated.createdAt = projectRow.createdAt
                updated.lastOpenedAt = projectRow.lastOpenedAt
                updated.documentCount = projectRow.documentCount
                try updated.update(db)
                return updated.toProject()
            }

            var inserted = projectRow
            try inserted.insert(db)
            return inserted.toProject()
        }
    }

    func delete(uuid: String) throws {
        _ = try dbQueue.write { db in
            try ProjectRow.filter(Column("uuid") == uuid).deleteAll(db)
        }
    }

    func fetchAll() throws -> [Project] {
        try dbQueue.read { db in
            try ProjectRow
                .order(Column("lastOpenedAt").desc, Column("name").asc)
                .fetchAll(db)
                .map { $0.toProject() }
        }
    }

    func fetch(uuid: String) throws -> Project? {
        try dbQueue.read { db in
            try ProjectRow.filter(Column("uuid") == uuid).fetchOne(db)?.toProject()
        }
    }

    func fetchByPath(_ path: String) throws -> Project? {
        try dbQueue.read { db in
            try ProjectRow.filter(Column("path") == path).fetchOne(db)?.toProject()
        }
    }

    func toggleFavorite(uuid: String) throws {
        try dbQueue.write { db in
            if var project = try ProjectRow.filter(Column("uuid") == uuid).fetchOne(db) {
                project.isFavorite.toggle()
                try project.update(db)
            }
        }
    }

    func togglePin(uuid: String) throws {
        try dbQueue.write { db in
            if var project = try ProjectRow.filter(Column("uuid") == uuid).fetchOne(db) {
                project.isPinned.toggle()
                try project.update(db)
            }
        }
    }

    func fetchFavorites() throws -> [Project] {
        try dbQueue.read { db in
            try ProjectRow
                .filter(Column("isFavorite") == true)
                .order(Column("name").asc)
                .fetchAll(db)
                .map { $0.toProject() }
        }
    }

    func fetchPinned() throws -> [Project] {
        try dbQueue.read { db in
            try ProjectRow
                .filter(Column("isPinned") == true)
                .order(Column("name").asc)
                .fetchAll(db)
                .map { $0.toProject() }
        }
    }

    func updateLastOpened(uuid: String, date: Date = Date()) throws {
        try dbQueue.write { db in
            if var project = try ProjectRow.filter(Column("uuid") == uuid).fetchOne(db) {
                project.lastOpenedAt = date
                try project.update(db)
            }
        }
    }

    func fetchRecent(limit: Int = 20) throws -> [Project] {
        try dbQueue.read { db in
            try ProjectRow
                .filter(Column("lastOpenedAt") != nil)
                .order(Column("lastOpenedAt").desc)
                .limit(limit)
                .fetchAll(db)
                .map { $0.toProject() }
        }
    }

    func updateDocumentCount(projectId: Int64, count: Int) throws {
        try dbQueue.write { db in
            if var project = try ProjectRow.filter(Column("id") == projectId).fetchOne(db) {
                project.documentCount = count
                try project.update(db)
            }
        }
    }

    func getProjectRowId(uuid: String) throws -> Int64? {
        try dbQueue.read { db in
            try ProjectRow.filter(Column("uuid") == uuid).fetchOne(db)?.id
        }
    }
}
