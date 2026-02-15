import SwiftUI

struct ProjectLibraryView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                headerBar
                filterTabs
                Divider()
                contentArea
            }
            .navigationTitle("DocMark")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: openFolder) {
                        Label("Open Folder", systemImage: "folder.badge.plus")
                    }
                }
            }
        }
    }
    
    private var headerBar: some View {
        HStack {
            Text("DocMark")
                .font(.title2)
                .fontWeight(.bold)
            
            Spacer()
            
            HStack(spacing: 8) {
                Button(action: {
                    withAnimation {
                        appState.libraryViewMode = .grid
                    }
                }) {
                    Image(systemName: "square.grid.2x2")
                        .font(.system(size: 16))
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.borderless)
                .background(
                    appState.libraryViewMode == .grid
                        ? Color(nsColor: .selectedControlColor)
                        : Color.clear
                )
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .help("Grid view")
                
                Button(action: {
                    withAnimation {
                        appState.libraryViewMode = .list
                    }
                }) {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 16))
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.borderless)
                .background(
                    appState.libraryViewMode == .list
                        ? Color(nsColor: .selectedControlColor)
                        : Color.clear
                )
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .help("List view")
            }
            .padding(4)
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            Spacer()
                .frame(width: 16)
            
            Button(action: openFolder) {
                Label("Open Folder", systemImage: "folder.badge.plus")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    private var filterTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(AppState.LibraryFilter.allCases) { filter in
                    FilterTab(
                        filter: filter,
                        isSelected: appState.libraryFilter == filter,
                        action: {
                            withAnimation {
                                appState.libraryFilter = filter
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
        }
    }
    
    private var contentArea: some View {
        Group {
            if appState.filteredProjects.isEmpty {
                emptyState
            } else {
                switch appState.libraryViewMode {
                case .grid:
                    gridView
                case .list:
                    listView
                }
            }
        }
    }
    
    private var gridView: some View {
        ScrollView {
            LazyVGrid(
                columns: [
                    GridItem(.adaptive(minimum: 280), spacing: 16)
                ],
                spacing: 16
            ) {
                ForEach(appState.filteredProjects) { project in
                    ProjectCard(project: project)
                }
            }
            .padding(20)
        }
    }
    
    private var listView: some View {
        List(appState.filteredProjects) { project in
            ProjectListRow(project: project)
                .contentShape(Rectangle())
                .onTapGesture {
                    appState.selectProject(project)
                }
                .contextMenu {
                    ProjectContextMenu(project: project)
                }
        }
        .listStyle(.plain)
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: emptyStateIcon)
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            
            Text(emptyStateTitle)
                .font(.headline)
                .foregroundStyle(.primary)
            
            Text(emptyStateMessage)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            if appState.libraryFilter == .all {
                Button(action: openFolder) {
                    Text("Open Folder")
                        .fontWeight(.medium)
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
    
    private var emptyStateIcon: String {
        switch appState.libraryFilter {
        case .all:
            return "folder.badge.plus"
        case .recent:
            return "clock"
        case .favorites:
            return "star"
        case .pinned:
            return "pin"
        }
    }
    
    private var emptyStateTitle: String {
        switch appState.libraryFilter {
        case .all:
            return "No Projects"
        case .recent:
            return "No Recent Projects"
        case .favorites:
            return "No Favorites"
        case .pinned:
            return "No Pinned Projects"
        }
    }
    
    private var emptyStateMessage: String {
        switch appState.libraryFilter {
        case .all:
            return "Open a folder to add your first documentation project."
        case .recent:
            return "Projects you open will appear here."
        case .favorites:
            return "Star projects to add them to your favorites."
        case .pinned:
            return "Pin projects to keep them at the top of your library."
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

struct FilterTab: View {
    let filter: AppState.LibraryFilter
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: filter.icon)
                    .font(.system(size: 14))
                Text(filter.rawValue)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
        .buttonStyle(.borderless)
        .foregroundStyle(isSelected ? .white : .primary)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? Color.accentColor : Color.clear)
        )
    }
}

struct ProjectListRow: View {
    let project: Project
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "folder.fill")
                .font(.system(size: 24))
                .foregroundStyle(.blue)
                .frame(width: 40, height: 40)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(project.name)
                    .font(.body)
                    .fontWeight(.medium)
                
                Text(project.path)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                if project.isFavorite {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.yellow)
                }
                
                if project.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.blue)
                        .rotationEffect(.degrees(45))
                }
                
                if let lastOpened = project.lastOpenedAt {
                    Text(formatRelativeTime(lastOpened))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatRelativeTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    ProjectLibraryView()
        .environmentObject(AppState())
        .frame(width: 800, height: 600)
}
