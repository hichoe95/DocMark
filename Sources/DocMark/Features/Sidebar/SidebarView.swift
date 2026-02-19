import SwiftUI

struct SidebarView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Group {
            if appState.sidebarNodes.isEmpty {
                emptySidebar
            } else {
                documentTree
            }
        }
        .frame(minWidth: 240)
    }

    private var emptySidebar: some View {
        VStack(spacing: 12) {
            Image(systemName: "sidebar.left")
                .font(.title)
                .foregroundStyle(.tertiary)
            Text("No project open")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var documentTree: some View {
        List(selection: Binding(
            get: { appState.selectedDocument },
            set: { appState.selectedDocument = $0 }
        )) {
            if let project = appState.selectedProject {
                Section(project.name) {
                    ForEach(appState.sidebarNodes) { node in
                        FolderNodeView(node: node)
                    }
                }
            }
        }
        .listStyle(.sidebar)
    }
}

struct FolderNodeView: View {
    let node: FolderNode
    @EnvironmentObject var appState: AppState
    @State private var isExpanded = true

    private var isSelected: Bool {
        guard let selected = appState.selectedDocument,
              let nodeDoc = node.document else { return false }
        return selected.id == nodeDoc.id
    }

    private var gitStatusForNode: GitFileStatus? {
        guard node.isFile, let doc = node.document else { return nil }
        return appState.isFileChanged(doc.relativePath)
    }

    var body: some View {
        if node.isFile, let doc = node.document {
            Label {
                HStack(spacing: 4) {
                    Text(node.name)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Spacer()
                    if let status = gitStatusForNode {
                        Text(status.shortLabel)
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundStyle(status.color)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(status.color.opacity(0.15), in: RoundedRectangle(cornerRadius: 3))
                    }
                }
            } icon: {
                Image(systemName: iconForFile(node.name))
                    .foregroundStyle(iconColor(for: node.name))
            }
            .tag(doc)
        } else if !node.isFile {
            DisclosureGroup(isExpanded: $isExpanded) {
                ForEach(node.children) { child in
                    FolderNodeView(node: child)
                }
            } label: {
                Label {
                    Text(node.name)
                        .lineLimit(1)
                } icon: {
                    Image(systemName: "folder.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func iconForFile(_ name: String) -> String {
        let lower = name.lowercased()
        if lower == "readme" { return "doc.text.fill" }
        if lower.contains("changelog") || lower.contains("changes") { return "clock.fill" }
        if lower.contains("contributing") { return "person.2.fill" }
        if lower.contains("license") { return "checkmark.seal.fill" }
        if lower.contains("api") { return "curlybraces" }
        if lower.contains("guide") || lower.contains("tutorial") { return "book.fill" }
        if lower.contains("adr") || lower.contains("architecture") { return "building.columns.fill" }
        if lower.contains("install") || lower.contains("setup") { return "wrench.fill" }
        return "doc.text"
    }

    private func iconColor(for name: String) -> Color {
        let lower = name.lowercased()
        if lower == "readme" { return .blue }
        if lower.contains("changelog") { return .orange }
        if lower.contains("contributing") { return .green }
        if lower.contains("license") { return .purple }
        return .secondary
    }
}
