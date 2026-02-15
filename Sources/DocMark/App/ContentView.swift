import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var licenseManager = LicenseManager.shared

    var body: some View {
        ZStack {
            if appState.isShowingProjectLibrary {
                ProjectLibraryView()
            } else {
                projectReaderView
            }

            if appState.isShowingQuickOpen {
                QuickOpenPanel()
            }

            if appState.isShowingSearch {
                SearchPanel()
            }
        }
    }

    private var projectReaderView: some View {
        NavigationSplitView {
            SidebarView()
        } detail: {
            HStack(spacing: 0) {
                if let document = appState.selectedDocument {
                    DocumentReaderView(document: document)

                    if appState.isShowingTOC && licenseManager.isEnabled(.tableOfContents) {
                        Divider()
                        TableOfContentsView(document: document)
                    }
                } else {
                    EmptyDocumentView()
                }
            }
        }
        .navigationSplitViewStyle(.balanced)
        .toolbar {
            ToolbarItem(placement: .navigation) {
                HStack(spacing: 4) {
                    Button(action: { appState.showProjectLibrary() }) {
                        Label("Library", systemImage: "square.grid.2x2")
                    }
                    .help("Project Library")

                    Button(action: openFolder) {
                        Label("Open Folder", systemImage: "folder.badge.plus")
                    }
                }
            }

            ToolbarItemGroup(placement: .primaryAction) {
                if let branch = appState.gitBranch, licenseManager.isEnabled(.gitIntegration) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.triangle.branch")
                            .font(.caption)
                        Text(branch)
                            .font(.caption)
                            .lineLimit(1)
                        if appState.gitHasChanges {
                            Circle()
                                .fill(.orange)
                                .frame(width: 6, height: 6)
                        }
                    }
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.quaternary, in: Capsule())
                }

                Button(action: { appState.toggleTOC() }) {
                    Label("Table of Contents", systemImage: "list.bullet.indent")
                }
                .help("Toggle Table of Contents (\u{2318}T)")

                Button(action: appState.goToPreviousDocument) {
                    Label("Previous", systemImage: "chevron.left")
                }
                .disabled(!appState.canGoToPrevious)
                .help("Previous document")

                Button(action: appState.goToNextDocument) {
                    Label("Next", systemImage: "chevron.right")
                }
                .disabled(!appState.canGoToNext)
                .help("Next document")
            }
        }
    }

    private func openFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.message = "Select a project folder containing markdown files"

        if panel.runModal() == .OK, let url = panel.url {
            appState.openProject(at: url)
        }
    }
}

struct EmptyDocumentView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            Text("Select a document from the sidebar")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("or press ⌘O to open a project folder")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
