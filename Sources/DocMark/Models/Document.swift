import Foundation

struct Document: Identifiable, Hashable {
    let id: UUID
    let title: String
    let path: String
    let relativePath: String
    let lastModified: Date
    let fileSize: Int
    var frontmatter: [String: String]
    let content: String
    let lineCount: Int
    let hasMermaid: Bool
    let hasMath: Bool

    var directoryURL: URL {
        URL(fileURLWithPath: path).deletingLastPathComponent()
    }

    var renderableContent: String {
        guard content.hasPrefix("---") else { return content }
        let lines = content.components(separatedBy: "\n")
        guard lines.count > 1 else { return content }

        for i in 1..<lines.count {
            if lines[i].trimmingCharacters(in: .whitespaces) == "---" {
                let bodyLines = Array(lines[(i + 1)...])
                let body = bodyLines.joined(separator: "\n")
                return body.drop(while: { $0.isNewline }).description
            }
        }
        return content
    }

    var displayTitle: String {
        frontmatter["title"] ?? title
    }

    // MARK: - Hashable

    static func == (lhs: Document, rhs: Document) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    // MARK: - Factory

    static func from(url: URL, relativeTo rootURL: URL) -> Document {
        let modDate = (try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date()
        let fileSize = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
        let relativePath = url.path.replacingOccurrences(of: rootURL.path + "/", with: "")
        let displayName = url.deletingPathExtension().lastPathComponent
        let frontmatter = parseFrontmatter(from: url)
        let content = (try? String(contentsOfFile: url.path, encoding: .utf8)) ?? ""

        return Document(
            id: UUID(),
            title: displayName,
            path: url.path,
            relativePath: relativePath,
            lastModified: modDate,
            fileSize: fileSize,
            frontmatter: frontmatter,
            content: content,
            lineCount: content.components(separatedBy: .newlines).count,
            hasMermaid: content.contains("```mermaid"),
            hasMath: content.contains("$$") || content.range(of: #"\$[^$]+\$"#, options: .regularExpression) != nil
        )
    }

    private static func parseFrontmatter(from url: URL) -> [String: String] {
        guard let raw = try? String(contentsOf: url, encoding: .utf8),
              raw.hasPrefix("---") else { return [:] }

        let lines = raw.components(separatedBy: "\n")
        guard lines.count > 1 else { return [:] }

        var result: [String: String] = [:]
        for i in 1..<lines.count {
            let line = lines[i].trimmingCharacters(in: .whitespaces)
            if line == "---" { break }
            let parts = line.split(separator: ":", maxSplits: 1)
            if parts.count == 2 {
                let key = parts[0].trimmingCharacters(in: .whitespaces)
                let value = parts[1].trimmingCharacters(in: .whitespaces)
                    .trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
                result[key] = value
            }
        }
        return result
    }
}
