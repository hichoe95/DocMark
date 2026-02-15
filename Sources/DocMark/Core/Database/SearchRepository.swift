import Foundation
import GRDB

struct SearchRepository {
    let dbQueue: DatabaseQueue

    init(dbQueue: DatabaseQueue) {
        self.dbQueue = dbQueue
    }

    func search(query: String, projectId: Int64? = nil) throws -> [SearchResult] {
        guard let matchPattern = buildMatchPattern(from: query) else {
            return []
        }

        return try dbQueue.read { db in
            let rows = try Row.fetchAll(
                db,
                sql: """
                SELECT d.uuid, d.title, d.path,
                       snippet(documents_fts, 2, '<b>', '</b>', '...', 32) as snippet,
                       bm25(documents_fts, 5.0, 2.0, 1.0) as rank
                FROM documents_fts
                JOIN documents d ON d.id = documents_fts.rowid
                WHERE documents_fts MATCH ?
                  AND (? IS NULL OR d.projectId = ?)
                ORDER BY rank
                LIMIT 100
                """,
                arguments: [matchPattern, projectId, projectId]
            )

            return rows.compactMap { row in
                guard
                    let uuidString: String = row["uuid"],
                    let documentId = UUID(uuidString: uuidString),
                    let title: String = row["title"],
                    let path: String = row["path"],
                    let snippet: String = row["snippet"],
                    let rank: Double = row["rank"]
                else {
                    return nil
                }

                return SearchResult(documentId: documentId, title: title, path: path, snippet: snippet, rank: rank)
            }
        }
    }

    func quickOpen(query: String, projectId: Int64? = nil) throws -> [SearchResult] {
        guard let matchPattern = buildMatchPattern(from: query) else {
            return []
        }

        return try dbQueue.read { db in
            let rows = try Row.fetchAll(
                db,
                sql: """
                SELECT d.uuid, d.title, d.path, d.relativePath,
                       bm25(documents_fts, 10.0, 3.0, 0.5) as rank
                FROM documents_fts
                JOIN documents d ON d.id = documents_fts.rowid
                WHERE documents_fts MATCH ?
                  AND (? IS NULL OR d.projectId = ?)
                ORDER BY rank
                LIMIT 20
                """,
                arguments: [matchPattern, projectId, projectId]
            )

            return rows.compactMap { row in
                guard
                    let uuidString: String = row["uuid"],
                    let documentId = UUID(uuidString: uuidString),
                    let title: String = row["title"],
                    let path: String = row["path"],
                    let snippet: String = row["relativePath"],
                    let rank: Double = row["rank"]
                else {
                    return nil
                }

                return SearchResult(documentId: documentId, title: title, path: path, snippet: snippet, rank: rank)
            }
        }
    }

    private func buildMatchPattern(from query: String) -> String? {
        let terms = query.split(whereSeparator: { $0.isWhitespace })
            .map { String($0) + "*" }
            .filter { !$0.isEmpty }

        guard !terms.isEmpty else {
            return nil
        }

        return terms.joined(separator: " ")
    }
}
