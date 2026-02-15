import Foundation

struct FolderNode: Identifiable, Hashable {
    let id: UUID
    let name: String
    let path: String
    let isFile: Bool
    var children: [FolderNode]
    var document: Document?

    init(
        name: String,
        path: String,
        isFile: Bool = false,
        children: [FolderNode] = [],
        document: Document? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.path = path
        self.isFile = isFile
        self.children = children
        self.document = document
    }

    static func == (lhs: FolderNode, rhs: FolderNode) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
