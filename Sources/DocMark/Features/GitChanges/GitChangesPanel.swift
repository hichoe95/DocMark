import SwiftUI

struct GitChangesPanel: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var licenseManager = LicenseManager.shared

    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture { appState.toggleGitChanges() }

            VStack(spacing: 0) {
                headerBar
                Divider()
                contentArea
            }
            .frame(width: 650)
            .frame(maxHeight: 500)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
            .padding(.top, 80)
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.97)))
        .onKeyPress(.escape) {
            appState.toggleGitChanges()
            return .handled
        }
        .sheet(item: $appState.selectedGitChange) { change in
            if let project = appState.selectedProject {
                GitDiffView(change: change, repoPath: project.path)
            }
        }
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "arrow.triangle.branch")
                .foregroundStyle(.secondary)
                .font(.title3)

            VStack(alignment: .leading, spacing: 2) {
                Text(headerTitle)
                    .font(.headline)
                if let branch = appState.gitBranch {
                    Text(branch)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Button(action: { appState.loadGitChanges() }) {
                Image(systemName: "arrow.clockwise")
                    .font(.caption)
            }
            .buttonStyle(.borderless)
            .help("Refresh")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var headerTitle: String {
        let count = appState.gitChangedFiles.count
        if count == 0 { return "No Changes" }
        return "\(count) Changed File\(count == 1 ? "" : "s")"
    }

    // MARK: - Content

    private var contentArea: some View {
        Group {
            if !licenseManager.isEnabled(.gitIntegration) {
                proFeatureState
            } else if appState.gitChangedFiles.isEmpty {
                emptyState
            } else {
                changesList
            }
        }
    }

    private var changesList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(appState.gitChangedFiles) { change in
                    GitChangeRow(
                        change: change,
                        onNavigate: { appState.navigateToGitChange(change) },
                        onShowDiff: { appState.selectedGitChange = change }
                    )
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.circle")
                .font(.title)
                .foregroundStyle(.green)
            Text("No uncommitted changes")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private var proFeatureState: some View {
        VStack(spacing: 8) {
            Image(systemName: "lock.fill")
                .font(.title)
                .foregroundStyle(.secondary)
            Text("Git Integration is a Pro feature")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Row

private struct GitChangeRow: View {
    let change: GitFileChange
    let onNavigate: () -> Void
    let onShowDiff: () -> Void
    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: change.status.icon)
                .foregroundStyle(change.status.color)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(change.filename)
                    .font(.body)
                    .lineLimit(1)

                if !change.directory.isEmpty {
                    Text(change.directory)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            if isHovering {
                Button(action: onShowDiff) {
                    Image(systemName: "chevron.left.forwardslash.chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
                .help("Show diff")
            }

            Text(change.status.shortLabel)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(change.status.color)
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(change.status.color.opacity(0.15), in: RoundedRectangle(cornerRadius: 4))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(isHovering ? Color.accentColor.opacity(0.08) : Color.clear)
        .contentShape(Rectangle())
        .onTapGesture {
            if change.isMarkdown {
                onNavigate()
            } else {
                onShowDiff()
            }
        }
        .onHover { hovering in
            isHovering = hovering
        }
    }
}
