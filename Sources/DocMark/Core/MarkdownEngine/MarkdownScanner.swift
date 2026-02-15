import Foundation

final class MarkdownScanner {
    private let fileManager = FileManager.default
    private let skippedDirectories: Set<String> = [
        ".git", ".svn", ".hg", "node_modules", ".build",
        "__pycache__", ".venv", "venv", ".idea", ".vscode",
        "Pods", "DerivedData", ".next", "dist", "build",
        ".docmark", ".claude", ".cursor", ".github"
    ]

    private let skippedFiles: Set<String> = [
        ".docsconfig.yaml", ".docsconfig.yml"
    ]

    private(set) var allDocuments: [Document] = []

    func scan(rootURL: URL) -> [FolderNode] {
        allDocuments = []
        return buildTree(from: rootURL, relativeTo: rootURL)
    }

    func flatDocumentList() -> [Document] {
        allDocuments
    }

    private func buildTree(from url: URL, relativeTo rootURL: URL) -> [FolderNode] {
        guard let contents = try? fileManager.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey, .contentModificationDateKey, .fileSizeKey],
            options: .skipsHiddenFiles
        ) else { return [] }

        var folderNodes: [FolderNode] = []
        var fileNodes: [FolderNode] = []

        let sorted = contents.sorted {
            $0.lastPathComponent.localizedCaseInsensitiveCompare($1.lastPathComponent) == .orderedAscending
        }

        for item in sorted {
            let isDirectory = (try? item.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false

            if isDirectory {
                let dirName = item.lastPathComponent
                guard !dirName.hasPrefix(".") else { continue }
                guard !skippedDirectories.contains(dirName) else { continue }

                let children = buildTree(from: item, relativeTo: rootURL)
                guard !children.isEmpty else { continue }

                let readmeChild = children.first {
                    $0.isFile && $0.name.lowercased() == "readme"
                }

                folderNodes.append(FolderNode(
                    name: dirName,
                    path: item.path,
                    isFile: false,
                    children: children,
                    document: readmeChild?.document
                ))
            } else if item.pathExtension.lowercased() == "md" {
                let filename = item.lastPathComponent
                guard !skippedFiles.contains(filename.lowercased()) else { continue }

                let document = Document.from(url: item, relativeTo: rootURL)
                allDocuments.append(document)

                fileNodes.append(FolderNode(
                    name: document.displayTitle,
                    path: item.path,
                    isFile: true,
                    children: [],
                    document: document
                ))
            }
        }

        return sortNodes(folders: folderNodes, files: fileNodes)
    }

    private func sortNodes(folders: [FolderNode], files: [FolderNode]) -> [FolderNode] {
        var sortedFiles = files

        if let readmeIdx = sortedFiles.firstIndex(where: { $0.name.lowercased() == "readme" }) {
            let readme = sortedFiles.remove(at: readmeIdx)
            sortedFiles.insert(readme, at: 0)
        }

        return folders + sortedFiles
    }
}
