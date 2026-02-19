import SwiftUI

struct GitDiffView: View {
    let change: GitFileChange
    let repoPath: String

    @Environment(\.dismiss) private var dismiss
    @State private var diffContent: String? = nil
    @State private var isLoading: Bool = true

    private struct DiffLine: Identifiable {
        let id = UUID()
        let lineType: LineType
        let content: String

        enum LineType {
            case added
            case removed
            case context
            case header
            case hunkHeader
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            headerBar

            Divider()

            diffContentView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 700, minHeight: 500, idealHeight: 600)
        .onAppear {
            loadDiff()
        }
    }

    // MARK: - Subviews

    private var headerBar: some View {
        HStack(spacing: 12) {
            Image(systemName: change.status.icon)
                .foregroundColor(change.status.color)
                .font(.title3)

            VStack(alignment: .leading, spacing: 2) {
                Text(change.filename)
                    .font(.headline)
                    .lineLimit(1)

                Text(change.directory)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Text(change.status.shortLabel)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(change.status.color.opacity(0.15))
                .foregroundColor(change.status.color)
                .clipShape(Capsule())

            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding()
    }

    private var diffContentView: some View {
        Group {
            if isLoading {
                ProgressView()
                    .scaleEffect(1.2)
            } else if let content = diffContent {
                diffScrollView(content: content)
            } else {
                emptyStateView
            }
        }
    }

    private func diffScrollView(content: String) -> some View {
        let lines = parseDiff(content)

        return ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(lines) { line in
                    diffLineView(for: line)
                }
            }
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .textSelection(.enabled)
    }

    private func diffLineView(for line: DiffLine) -> some View {
        HStack(spacing: 0) {
            Text(line.content)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(foregroundColor(for: line.lineType))
                .padding(.vertical, 1)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(backgroundColor(for: line.lineType))
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("No changes")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("Could not load diff for this file")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Helpers

    private func loadDiff() {
        isLoading = true

        DispatchQueue.global(qos: .userInitiated).async {
            let diff = GitService.diff(
                for: change.relativePath,
                in: repoPath,
                isUntracked: change.status == .untracked || change.status == .added
            )

            DispatchQueue.main.async {
                self.diffContent = diff
                self.isLoading = false
            }
        }
    }

    private func parseDiff(_ raw: String) -> [DiffLine] {
        var lines: [DiffLine] = []
        let rawLines = raw.components(separatedBy: .newlines)

        for line in rawLines {
            let trimmed = line
            if trimmed.isEmpty {
                continue
            }

            if trimmed.hasPrefix("diff ") ||
               trimmed.hasPrefix("index ") ||
               trimmed.hasPrefix("--- ") ||
               trimmed.hasPrefix("+++ ") {
                lines.append(DiffLine(lineType: .header, content: trimmed))
            } else if trimmed.hasPrefix("@@") {
                lines.append(DiffLine(lineType: .hunkHeader, content: trimmed))
            } else if trimmed.hasPrefix("+") && !trimmed.hasPrefix("+++") {
                lines.append(DiffLine(lineType: .added, content: trimmed))
            } else if trimmed.hasPrefix("-") && !trimmed.hasPrefix("---") {
                lines.append(DiffLine(lineType: .removed, content: trimmed))
            } else {
                lines.append(DiffLine(lineType: .context, content: trimmed))
            }
        }

        return lines
    }

    private func foregroundColor(for lineType: DiffLine.LineType) -> Color {
        switch lineType {
        case .added:
            return .green
        case .removed:
            return .red
        case .hunkHeader:
            return .blue
        case .header:
            return .secondary
        case .context:
            return .primary
        }
    }

    private func backgroundColor(for lineType: DiffLine.LineType) -> Color {
        switch lineType {
        case .added:
            return Color.green.opacity(0.15)
        case .removed:
            return Color.red.opacity(0.15)
        case .hunkHeader:
            return Color.blue.opacity(0.1)
        case .header:
            return Color.gray.opacity(0.05)
        case .context:
            return Color.clear
        }
    }
}
