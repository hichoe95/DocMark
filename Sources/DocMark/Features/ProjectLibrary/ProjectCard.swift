import SwiftUI

struct ProjectCard: View {
    @EnvironmentObject var appState: AppState
    let project: Project
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: {
            appState.selectProject(project)
        }) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Spacer()
                    
                    if project.isFavorite {
                        Image(systemName: "star.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.yellow)
                    }
                    
                    if project.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.blue)
                            .rotationEffect(.degrees(45))
                    }
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(project.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                        .foregroundStyle(.primary)
                    
                    Text(project.path)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    
                    if let lastOpened = project.lastOpenedAt {
                        Text("Last opened \(formatRelativeTime(lastOpened))")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    } else {
                        Text("Never opened")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                
                Spacer()
            }
            .padding(16)
            .frame(height: 120)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(nsColor: .controlBackgroundColor))
                    .shadow(
                        color: Color.black.opacity(isHovered ? 0.1 : 0.05),
                        radius: isHovered ? 8 : 4,
                        x: 0,
                        y: isHovered ? 4 : 2
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isHovered ? Color.accentColor.opacity(0.5) : Color.clear,
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .contextMenu {
            ProjectContextMenu(project: project)
        }
    }
    
    private func formatRelativeTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct ProjectContextMenu: View {
    @EnvironmentObject var appState: AppState
    let project: Project
    
    var body: some View {
        Button(action: {
            appState.selectProject(project)
        }) {
            Label("Open", systemImage: "arrow.right.circle")
        }
        
        Divider()
        
        Button(action: {
            appState.toggleFavorite(project)
        }) {
            Label(
                project.isFavorite ? "Remove from Favorites" : "Add to Favorites",
                systemImage: project.isFavorite ? "star.slash" : "star"
            )
        }
        
        Button(action: {
            appState.togglePin(project)
        }) {
            Label(
                project.isPinned ? "Unpin" : "Pin",
                systemImage: project.isPinned ? "pin.slash" : "pin"
            )
        }
        
        Divider()
        
        Button(role: .destructive, action: {
            appState.removeProject(project)
        }) {
            Label("Remove", systemImage: "trash")
        }
    }
}

#Preview {
    ProjectCard(project: Project(
        id: UUID(),
        name: "Documentation",
        path: "/Users/docs/project",
        createdAt: Date(),
        lastOpenedAt: Date(),
        isFavorite: true,
        isPinned: true
    ))
    .frame(width: 300)
    .padding()
}
