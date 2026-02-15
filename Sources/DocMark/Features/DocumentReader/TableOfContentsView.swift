import SwiftUI

// MARK: - Heading Item

struct HeadingItem: Identifiable {
    let id = UUID()
    let level: Int
    let text: String
    let anchor: String
}

// MARK: - Table of Contents View

struct TableOfContentsView: View {
    let document: Document
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) private var colorScheme

    @State private var headings: [HeadingItem] = []
    @State private var selectedHeadingId: UUID?
    @State private var hoveredHeadingId: UUID?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView

            Divider()

            // Content
            if headings.isEmpty {
                emptyStateView
            } else {
                headingsListView
            }

            Divider()

            // Footer
            footerView
        }
        .frame(width: 240)
        .background(backgroundColor)
        .onAppear {
            parseHeadings()
        }
        .onChange(of: document.renderableContent) {
            parseHeadings()
        }
    }

    // MARK: - Subviews

    private var headerView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Table of Contents")
                .font(.headline)
                .foregroundStyle(.primary)

            Text(document.displayTitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var headingsListView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(headings) { heading in
                    HeadingRow(
                        heading: heading,
                        isSelected: selectedHeadingId == heading.id,
                        isHovered: hoveredHeadingId == heading.id
                    )
                    .onTapGesture {
                        selectedHeadingId = heading.id
                        // Placeholder: scroll-to-heading will be implemented later
                    }
                    .onHover { hovering in
                        withAnimation(.easeInOut(duration: 0.1)) {
                            hoveredHeadingId = hovering ? heading.id : nil
                        }
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Image(systemName: "text.alignleft")
                .font(.system(size: 32))
                .foregroundStyle(.tertiary)

            Text("No headings found")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private var footerView: some View {
        HStack {
            Text("\(headings.count) heading\(headings.count == 1 ? "" : "s")")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    // MARK: - Colors

    private var backgroundColor: Color {
        colorScheme == .dark
            ? Color(nsColor: NSColor(white: 0.1, alpha: 1.0))
            : Color(nsColor: NSColor(white: 0.98, alpha: 1.0))
    }

    // MARK: - Actions

    private func parseHeadings() {
        headings = Self.parseHeadings(from: document.renderableContent)
        // Select first heading by default if available
        if let first = headings.first {
            selectedHeadingId = first.id
        }
    }

    // MARK: - Static Parser

    static func parseHeadings(from markdown: String) -> [HeadingItem] {
        let lines = markdown.components(separatedBy: .newlines)
        var headings: [HeadingItem] = []
        var inCodeBlock = false

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Track code block fences
            if trimmed.hasPrefix("```") {
                inCodeBlock.toggle()
                continue
            }

            // Skip if inside code block
            if inCodeBlock {
                continue
            }

            // Check for heading pattern: 1-6 # followed by space
            guard trimmed.hasPrefix("#") else { continue }

            // Count leading hashes
            var hashCount = 0
            for char in trimmed {
                if char == "#" {
                    hashCount += 1
                } else {
                    break
                }
            }

            // Must be 1-6 hashes and followed by a space
            guard hashCount >= 1 && hashCount <= 6 else { continue }

            let afterHashes = trimmed.dropFirst(hashCount)
            guard afterHashes.first == " " else { continue }

            // Extract heading text
            let text = String(afterHashes.dropFirst()).trimmingCharacters(in: .whitespaces)
            guard !text.isEmpty else { continue }

            // Generate anchor (slugify)
            let anchor = slugify(text)

            let heading = HeadingItem(
                level: hashCount,
                text: text,
                anchor: anchor
            )
            headings.append(heading)
        }

        return headings
    }

    private static func slugify(_ text: String) -> String {
        // Convert to lowercase
        var result = text.lowercased()

        // Replace spaces with hyphens
        result = result.replacingOccurrences(of: " ", with: "-")

        // Remove non-alphanumeric characters except hyphens
        let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-"))
        result = result.components(separatedBy: allowedCharacters.inverted).joined()

        // Remove consecutive hyphens
        while result.contains("--") {
            result = result.replacingOccurrences(of: "--", with: "-")
        }

        // Trim leading/trailing hyphens
        result = result.trimmingCharacters(in: CharacterSet(charactersIn: "-"))

        return result
    }
}

// MARK: - Heading Row

private struct HeadingRow: View {
    let heading: HeadingItem
    let isSelected: Bool
    let isHovered: Bool
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 0) {
            Text(heading.text)
                .font(fontForLevel(heading.level))
                .foregroundStyle(foregroundStyleForLevel(heading.level))
                .lineLimit(1)
                .padding(.leading, leadingPaddingForLevel(heading.level))

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, verticalPaddingForLevel(heading.level))
        .background(backgroundColor)
        .contentShape(Rectangle())
    }

    private var backgroundColor: Color {
        if isSelected {
            return colorScheme == .dark
                ? Color(nsColor: NSColor(white: 0.2, alpha: 1.0))
                : Color(nsColor: NSColor(white: 0.9, alpha: 1.0))
        }
        if isHovered {
            return colorScheme == .dark
                ? Color(nsColor: NSColor(white: 0.15, alpha: 1.0))
                : Color(nsColor: NSColor(white: 0.95, alpha: 1.0))
        }
        return Color.clear
    }

    private func fontForLevel(_ level: Int) -> Font {
        switch level {
        case 1:
            return .body.bold()
        case 2:
            return .body
        case 3:
            return .callout
        case 4, 5, 6:
            return .caption
        default:
            return .body
        }
    }

    private func foregroundStyleForLevel(_ level: Int) -> some ShapeStyle {
        if isSelected {
            return .primary
        }
        switch level {
        case 1, 2:
            return .primary
        case 3:
            return .secondary
        case 4, 5, 6:
            return .secondary
        default:
            return .primary
        }
    }

    private func leadingPaddingForLevel(_ level: Int) -> CGFloat {
        switch level {
        case 1:
            return 0
        case 2:
            return 12
        case 3:
            return 24
        case 4, 5, 6:
            return 36
        default:
            return 0
        }
    }

    private func verticalPaddingForLevel(_ level: Int) -> CGFloat {
        switch level {
        case 1:
            return 6
        case 2:
            return 4
        case 3, 4, 5, 6:
            return 3
        default:
            return 4
        }
    }
}

// MARK: - Preview

#Preview("With Headings") {
    let sampleContent = """
    # Introduction
    Some intro text here.

    ## Getting Started
    More content here.

    ### Installation
    Steps to install.

    ## Usage
    How to use.

    ### Basic Example
    Simple example.
    """

    let document = Document(
        id: UUID(),
        title: "Sample Document",
        path: "/tmp/sample.md",
        relativePath: "sample.md",
        lastModified: Date(),
        fileSize: 1024,
        frontmatter: [:],
        content: sampleContent,
        lineCount: 16,
        hasMermaid: false,
        hasMath: false
    )

    TableOfContentsView(document: document)
        .environmentObject(AppState())
        .frame(height: 500)
}

#Preview("Empty State") {
    let document = Document(
        id: UUID(),
        title: "Empty Document",
        path: "/tmp/empty.md",
        relativePath: "empty.md",
        lastModified: Date(),
        fileSize: 256,
        frontmatter: [:],
        content: "",
        lineCount: 0,
        hasMermaid: false,
        hasMath: false
    )

    TableOfContentsView(document: document)
        .environmentObject(AppState())
        .frame(height: 500)
}
