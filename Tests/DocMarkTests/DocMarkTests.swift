import XCTest
@testable import DocMark

final class DocMarkTests: XCTestCase {
    func testMarkdownScannerFindsFiles() {
        let scanner = MarkdownScanner()
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let testFile = tempDir.appendingPathComponent("README.md")
        try? "# Test".write(to: testFile, atomically: true, encoding: .utf8)

        let nodes = scanner.scan(rootURL: tempDir)
        XCTAssertFalse(nodes.isEmpty, "Scanner should find at least one markdown file")
        XCTAssertEqual(nodes.first?.name, "README")
    }

    func testDocumentContentLoading() {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let content = "# Hello World\n\nThis is a test."
        let filePath = tempDir.appendingPathComponent("test.md")
        try? content.write(to: filePath, atomically: true, encoding: .utf8)

        let doc = Document(
            id: UUID(),
            title: "test",
            path: filePath.path,
            relativePath: "test.md",
            lastModified: Date(),
            fileSize: content.utf8.count,
            frontmatter: [:],
            content: content,
            lineCount: content.components(separatedBy: .newlines).count,
            hasMermaid: false,
            hasMath: false
        )
        XCTAssertEqual(doc.content, content)
        XCTAssertFalse(doc.hasMermaid)
        XCTAssertFalse(doc.hasMath)
    }
}
