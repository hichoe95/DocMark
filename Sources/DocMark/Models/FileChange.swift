import Foundation

enum FileChangeType {
    case created
    case modified
    case deleted
    case renamed
}

struct FileChange {
    let path: String
    let type: FileChangeType
    let timestamp: Date
}
