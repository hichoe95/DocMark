import SwiftUI
import Combine
import GRDB

final class AppState: ObservableObject {
    // MARK: - Projects
    @Published var projects: [Project] = []
    @Published var selectedProject: Project?

    // MARK: - Documents
    @Published var selectedDocument: Document?
    @Published var sidebarNodes: [FolderNode] = []
    private(set) var allDocuments: [Document] = []

    // MARK: - UI State
    @Published var isLoading: Bool = false
    @Published var isShowingProjectLibrary: Bool = true
    @Published var isShowingQuickOpen: Bool = false
    @Published var isShowingSearch: Bool = false

    // MARK: - Search
    @Published var searchQuery: String = ""
    @Published var searchResults: [SearchResult] = []
    @Published var quickOpenQuery: String = ""
    @Published var quickOpenResults: [SearchResult] = []

    // MARK: - Library
    @Published var libraryFilter: LibraryFilter = .all
    @Published var libraryViewMode: LibraryViewMode = .grid

    // MARK: - TOC & Git
    @Published var isShowingTOC: Bool = false
    @Published var isShowingGitChanges: Bool = false
    @Published var gitBranch: String?
    @Published var gitHasChanges: Bool = false
    @Published var gitChangedFiles: [GitFileChange] = []
    @Published var selectedGitChange: GitFileChange?

    // MARK: - Skill
    @Published var isSkillInstalledInProject: Bool = false

    // MARK: - Services
    private let db = GRDBManager.shared
    private lazy var projectRepo = ProjectRepository(dbQueue: db.dbQueue)
    private lazy var documentRepo = DocumentRepository(dbQueue: db.dbQueue)
    private lazy var searchRepo = SearchRepository(dbQueue: db.dbQueue)
    private let fileWatcher = FileWatcherService()
    private let scanner = MarkdownScanner()

    // MARK: - Combine
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Types

    enum LibraryFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case recent = "Recent"
        case favorites = "Favorites"
        case pinned = "Pinned"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .all: return "square.grid.2x2"
            case .recent: return "clock"
            case .favorites: return "star"
            case .pinned: return "pin"
            }
        }
    }

    enum LibraryViewMode: String {
        case grid
        case list
    }

    // MARK: - Computed Properties

    var filteredProjects: [Project] {
        switch libraryFilter {
        case .all:
            return projects
        case .recent:
            return projects
                .filter { $0.lastOpenedAt != nil }
                .sorted { ($0.lastOpenedAt ?? .distantPast) > ($1.lastOpenedAt ?? .distantPast) }
        case .favorites:
            return projects.filter { $0.isFavorite }
        case .pinned:
            return projects.filter { $0.isPinned }
        }
    }

    var currentDocumentIndex: Int? {
        guard let doc = selectedDocument else { return nil }
        return allDocuments.firstIndex(where: { $0.id == doc.id })
    }

    var canGoToPrevious: Bool {
        guard let idx = currentDocumentIndex else { return false }
        return idx > 0
    }

    var canGoToNext: Bool {
        guard let idx = currentDocumentIndex else { return false }
        return idx < allDocuments.count - 1
    }

    // MARK: - Init

    init() {
        loadProjects()
        registerBundledGuideIfNeeded()
        setupFileWatcher()
        setupAutoSave()
    }

    // MARK: - Project Management

    func loadProjects() {
        do {
            projects = try projectRepo.fetchAll()
        } catch {
            print("[DocMark] Failed to load projects: \(error)")
        }
    }

    func openProject(at url: URL) {
        isLoading = true

        let project = Project(
            id: UUID(),
            name: url.lastPathComponent,
            path: url.path,
            createdAt: Date(),
            lastOpenedAt: Date()
        )

        do {
            let saved = try projectRepo.insertOrUpdate(project)

            sidebarNodes = scanner.scan(rootURL: url)
            allDocuments = scanner.flatDocumentList()

            if let rowId = try projectRepo.getProjectRowId(uuid: saved.id.uuidString) {
                try documentRepo.indexDocuments(allDocuments, projectId: rowId)
                try projectRepo.updateDocumentCount(projectId: rowId, count: allDocuments.count)
            }

            selectedProject = saved
            isShowingProjectLibrary = false
            loadProjects()

            fileWatcher.startWatching(path: url.path)
            loadGitInfo()
            checkSkillInstallation()

            restoreState(for: saved)
            if selectedDocument == nil, let first = findFirstDocument(in: sidebarNodes) {
                selectedDocument = first
            }
        } catch {
            print("[DocMark] DB fallback: \(error)")
            selectedProject = project
            sidebarNodes = scanner.scan(rootURL: url)
            allDocuments = scanner.flatDocumentList()
            isShowingProjectLibrary = false
            checkSkillInstallation()

            if let first = findFirstDocument(in: sidebarNodes) {
                selectedDocument = first
            }
        }

        isLoading = false
    }

    func selectProject(_ project: Project) {
        guard FileManager.default.fileExists(atPath: project.path) else {
            try? projectRepo.delete(uuid: project.id.uuidString)
            loadProjects()
            return
        }

        isLoading = true

        try? projectRepo.updateLastOpened(uuid: project.id.uuidString)

        let url = URL(fileURLWithPath: project.path)
        sidebarNodes = scanner.scan(rootURL: url)
        allDocuments = scanner.flatDocumentList()
        selectedProject = project
        selectedDocument = nil
        isShowingProjectLibrary = false

        if let rowId = try? projectRepo.getProjectRowId(uuid: project.id.uuidString) {
            try? documentRepo.indexDocuments(allDocuments, projectId: rowId)
            try? projectRepo.updateDocumentCount(projectId: rowId, count: allDocuments.count)
        }

        fileWatcher.startWatching(path: url.path)
        loadGitInfo()
        checkSkillInstallation()

        restoreState(for: project)
        if selectedDocument == nil, let first = findFirstDocument(in: sidebarNodes) {
            selectedDocument = first
        }

        loadProjects()
        isLoading = false
    }

    func removeProject(_ project: Project) {
        do {
            try projectRepo.delete(uuid: project.id.uuidString)
            if selectedProject?.id == project.id {
                selectedProject = nil
                selectedDocument = nil
                sidebarNodes = []
                allDocuments = []
                isShowingProjectLibrary = true
                fileWatcher.stopWatching()
            }
            loadProjects()
        } catch {
            print("[DocMark] Failed to remove project: \(error)")
        }
    }

    func toggleFavorite(_ project: Project) {
        try? projectRepo.toggleFavorite(uuid: project.id.uuidString)
        loadProjects()
    }

    func togglePin(_ project: Project) {
        try? projectRepo.togglePin(uuid: project.id.uuidString)
        loadProjects()
    }

    func showProjectLibrary() {
        saveState()
        isShowingProjectLibrary = true
    }

    func restoreLastProject() {
        guard let recent = (try? projectRepo.fetchRecent(limit: 1))?.first else { return }
        selectProject(recent)
    }

    // MARK: - Document Navigation

    func goToPreviousDocument() {
        guard let idx = currentDocumentIndex, idx > 0 else { return }
        selectedDocument = allDocuments[idx - 1]
    }

    func goToNextDocument() {
        guard let idx = currentDocumentIndex, idx < allDocuments.count - 1 else { return }
        selectedDocument = allDocuments[idx + 1]
    }

    func navigateToDocument(withRelativePath relativePath: String) {
        guard let project = selectedProject else { return }
        let projectURL = URL(fileURLWithPath: project.path)

        var targetPath = relativePath
        if !targetPath.hasSuffix(".md") {
            targetPath += ".md"
        }

        let targetURL = projectURL.appendingPathComponent(targetPath)
        let resolvedPath = targetURL.standardizedFileURL.path

        if let doc = allDocuments.first(where: { $0.path == resolvedPath }) {
            selectedDocument = doc
        }
    }

    func navigateToDocument(fromCurrentDocument linkPath: String) {
        guard let currentDoc = selectedDocument else { return }
        let currentDir = URL(fileURLWithPath: currentDoc.path).deletingLastPathComponent()

        var targetPath = linkPath
        if !targetPath.hasSuffix(".md") {
            targetPath += ".md"
        }

        let targetURL = currentDir.appendingPathComponent(targetPath).standardized
        let resolvedPath = targetURL.path

        if let doc = allDocuments.first(where: { $0.path == resolvedPath }) {
            selectedDocument = doc
        }
    }

    // MARK: - Search

    func performSearch(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            searchResults = []
            return
        }

        do {
            var projectRowId: Int64?
            if let project = selectedProject {
                projectRowId = try projectRepo.getProjectRowId(uuid: project.id.uuidString)
            }
            searchResults = try searchRepo.search(query: trimmed, projectId: projectRowId)
        } catch {
            print("[DocMark] Search failed: \(error)")
            searchResults = []
        }
    }

    func performQuickOpen(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            quickOpenResults = []
            return
        }

        do {
            var projectRowId: Int64?
            if let project = selectedProject {
                projectRowId = try projectRepo.getProjectRowId(uuid: project.id.uuidString)
            }
            quickOpenResults = try searchRepo.quickOpen(query: trimmed, projectId: projectRowId)
        } catch {
            print("[DocMark] Quick open failed: \(error)")
            quickOpenResults = []
        }
    }

    func openSearchResult(_ result: SearchResult) {
        if let doc = allDocuments.first(where: { $0.id == result.documentId }) {
            selectedDocument = doc
        }
        isShowingSearch = false
        isShowingQuickOpen = false
    }

    // MARK: - Overlay Toggles

    func toggleQuickOpen() {
        isShowingQuickOpen.toggle()
        if isShowingQuickOpen {
            isShowingSearch = false
            quickOpenQuery = ""
            quickOpenResults = []
        }
    }

    func toggleSearch() {
        isShowingSearch.toggle()
        if isShowingSearch {
            isShowingQuickOpen = false
            searchQuery = ""
            searchResults = []
        }
    }

    func toggleTOC() {
        isShowingTOC.toggle()
    }

    func loadGitInfo() {
        guard let project = selectedProject else {
            gitBranch = nil
            gitHasChanges = false
            gitChangedFiles = []
            return
        }
        gitBranch = GitService.currentBranch(at: project.path)
        gitHasChanges = GitService.hasUncommittedChanges(at: project.path)
        loadGitChanges()
    }

    func loadGitChanges() {
        guard let project = selectedProject else {
            gitChangedFiles = []
            return
        }
        let changes = GitService.changedFilesWithStatus(at: project.path)
        gitChangedFiles = changes.map { GitFileChange(relativePath: $0.relativePath, status: $0.status) }
    }

    func toggleGitChanges() {
        isShowingGitChanges.toggle()
        if isShowingGitChanges {
            isShowingQuickOpen = false
            isShowingSearch = false
            loadGitChanges()
        }
    }

    func gitDiff(for change: GitFileChange) -> String? {
        guard let project = selectedProject else { return nil }
        return GitService.diff(
            for: change.relativePath,
            in: project.path,
            isUntracked: change.status == .untracked || change.status == .added
        )
    }

    func navigateToGitChange(_ change: GitFileChange) {
        guard change.isMarkdown else { return }
        navigateToDocument(withRelativePath: change.relativePath)
        isShowingGitChanges = false
    }

    func isFileChanged(_ relativePath: String) -> GitFileStatus? {
        gitChangedFiles.first(where: { $0.relativePath == relativePath })?.status
    }

    // MARK: - File Watching

    private func setupFileWatcher() {
        fileWatcher.$lastChange
            .compactMap { $0 }
            .receive(on: RunLoop.main)
            .sink { [weak self] change in
                self?.handleFileChange(change)
            }
            .store(in: &cancellables)

        fileWatcher.$needsFullRescan
            .filter { $0 }
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.handleFullRescan()
            }
            .store(in: &cancellables)
    }

    private func handleFileChange(_ change: FileChange) {
        guard let project = selectedProject else { return }
        let projectURL = URL(fileURLWithPath: project.path)

        switch change.type {
        case .modified:
            if let sel = selectedDocument, sel.path == change.path {
                let url = URL(fileURLWithPath: change.path)
                let newDoc = Document.from(url: url, relativeTo: projectURL)
                if let idx = allDocuments.firstIndex(where: { $0.path == change.path }) {
                    allDocuments[idx] = newDoc
                }
                selectedDocument = newDoc
            }
            if let rowId = try? projectRepo.getProjectRowId(uuid: project.id.uuidString) {
                let url = URL(fileURLWithPath: change.path)
                let doc = Document.from(url: url, relativeTo: projectURL)
                try? documentRepo.reindexDocument(doc, projectId: rowId)
            }

        case .created, .renamed:
            rescanCurrentProject()

        case .deleted:
            allDocuments.removeAll { $0.path == change.path }
            if selectedDocument?.path == change.path {
                selectedDocument = allDocuments.first
            }
            try? documentRepo.removeDocument(path: change.path)
            rescanCurrentProject()
        }

        loadGitChanges()
    }

    private func handleFullRescan() {
        fileWatcher.needsFullRescan = false
        rescanCurrentProject()
    }

    private func rescanCurrentProject() {
        guard let project = selectedProject else { return }
        let url = URL(fileURLWithPath: project.path)
        let currentPath = selectedDocument?.path

        sidebarNodes = scanner.scan(rootURL: url)
        allDocuments = scanner.flatDocumentList()

        if let rowId = try? projectRepo.getProjectRowId(uuid: project.id.uuidString) {
            try? documentRepo.indexDocuments(allDocuments, projectId: rowId)
            try? projectRepo.updateDocumentCount(projectId: rowId, count: allDocuments.count)
        }

        if let currentPath, let doc = allDocuments.first(where: { $0.path == currentPath }) {
            selectedDocument = doc
        } else {
            selectedDocument = findFirstDocument(in: sidebarNodes)
        }
    }

    // MARK: - State Persistence

    func saveState() {
        guard let project = selectedProject,
              let rowId = try? projectRepo.getProjectRowId(uuid: project.id.uuidString) else { return }

        do {
            try db.dbQueue.write { db in
                if var existing = try ProjectStateRow
                    .filter(Column("projectId") == rowId)
                    .fetchOne(db) {
                    existing.lastDocumentPath = self.selectedDocument?.path
                    existing.updatedAt = Date()
                    try existing.update(db)
                } else {
                    var state = ProjectStateRow(
                        id: nil,
                        projectId: rowId,
                        lastDocumentPath: self.selectedDocument?.path,
                        sidebarExpansionJson: nil,
                        scrollPositionJson: nil,
                        updatedAt: Date()
                    )
                    try state.insert(db)
                }
            }
        } catch {
            print("[DocMark] Failed to save state: \(error)")
        }
    }

    private func restoreState(for project: Project) {
        guard let rowId = try? projectRepo.getProjectRowId(uuid: project.id.uuidString) else { return }

        do {
            let state = try db.dbQueue.read { db in
                try ProjectStateRow.filter(Column("projectId") == rowId).fetchOne(db)
            }

            if let lastPath = state?.lastDocumentPath,
               let doc = allDocuments.first(where: { $0.path == lastPath }) {
                selectedDocument = doc
            }
        } catch {
            print("[DocMark] Failed to restore state: \(error)")
        }
    }

    // MARK: - Auto Save

    private func setupAutoSave() {
        $selectedDocument
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.saveState()
            }
            .store(in: &cancellables)
    }

    // MARK: - Bundled Guide Project

    private func registerBundledGuideIfNeeded() {
        let guideRegistered = UserDefaults.standard.bool(forKey: "guideProjectRegistered")
        guard !guideRegistered else { return }

        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let guideDir = appSupport.appendingPathComponent("DocMark/DocMarkGuide", isDirectory: true)

        if !FileManager.default.fileExists(atPath: guideDir.path) {
            if let bundledGuide = Bundle.main.url(forResource: "DocMarkGuide", withExtension: nil) {
                try? FileManager.default.createDirectory(at: guideDir.deletingLastPathComponent(), withIntermediateDirectories: true)
                try? FileManager.default.copyItem(at: bundledGuide, to: guideDir)
            } else {
                try? FileManager.default.createDirectory(at: guideDir, withIntermediateDirectories: true)
                let readmePath = guideDir.appendingPathComponent("README.md")
                let skillsPath = guideDir.appendingPathComponent("ai-skills.md")
                try? Self.guideReadme.write(to: readmePath, atomically: true, encoding: .utf8)
                try? Self.guideAISkills.write(to: skillsPath, atomically: true, encoding: .utf8)
            }
        }

        if FileManager.default.fileExists(atPath: guideDir.path) {
            let project = Project(
                id: UUID(),
                name: "DocMark Guide",
                path: guideDir.path,
                createdAt: Date(),
                lastOpenedAt: Date(),
                isPinned: true
            )
            _ = try? projectRepo.insertOrUpdate(project)
            loadProjects()
            UserDefaults.standard.set(true, forKey: "guideProjectRegistered")
        }
    }

    private static let guideReadme = """
    # Welcome to DocMark

    A beautiful, read-only documentation reader for your projects.

    ---

    ## Quick Start

    1. **Open a project folder** — `⌘O` or click "Open Folder" in the toolbar
    2. **Browse your docs** — Navigate using the sidebar tree
    3. **Search everything** — Press `⌘K` to search across all documents
    4. **Quick Open** — Press `⌘P` to jump to any file by name

    ## Keyboard Shortcuts

    | Shortcut | Action |
    |----------|--------|
    | `⌘O` | Open project folder |
    | `⌘P` | Quick Open (jump to file) |
    | `⌘K` | Full-text search |
    | `⌘T` | Toggle Table of Contents |
    | `⌘[` / `⌘]` | Previous / Next document |
    | `⇧⌘L` | Project Library |

    ## Features

    **Free**
    - Markdown rendering with syntax-highlighted code blocks
    - Project folder scanning with sidebar navigation
    - Quick Open and full-text search (FTS5)
    - Dark mode support
    - File watching — changes reload automatically
    - GitHub-style admonitions (NOTE, TIP, WARNING, ...)
    - Breadcrumb navigation and prev/next document

    **Pro**
    - Mermaid diagram rendering
    - KaTeX math equation rendering
    - Table of Contents panel
    - Git branch & status display
    - Multi-project library with favorites and pins

    ## What's Next?

    - Browse the [AI Agent Integration](ai-skills.md) guide to set up skills for Claude Code or OpenCode
    - Open your own project folder with `⌘O`
    """

    private static let guideAISkills = """
    # AI Agent Integration

    DocMark can install **skills** for AI coding agents like Claude Code and OpenCode. A skill is an instruction file that teaches the agent how to write documentation that matches your project's structure.

    ---

    ## What Is a Skill?

    A skill is a markdown file (`SKILL.md`) that gets **injected into the AI agent's context**. It contains instructions the agent follows when working on your project.

    Without a skill, the agent writes docs in random formats and locations. With the skill, every document follows your configured structure.

    ### How the Agent Discovers Skills

    ```
    Project root
    └── .claude/
        └── skills/
            └── docmark/
                └── SKILL.md    ← Agent finds and reads this
    ```

    1. The agent scans `.claude/skills/` for subdirectories containing `SKILL.md`
    2. It reads the skill's `description` to know **when** to activate it
    3. When your request matches (e.g., "create an ADR"), the agent loads the full instructions
    4. The agent follows those instructions while completing your task

    ## Installing the Skill

    **Project-Level (Recommended):** Click "Install AI Skill" at the bottom of the sidebar, or press `⌘I`.

    This creates `.claude/skills/docmark/SKILL.md` inside your project. Both Claude Code and OpenCode detect this path automatically. The file gets committed to git — every team member gets the skill automatically.

    **Global:** Menu bar → Tools → Install Skill Globally → choose Claude Code or OpenCode.

    ## What Happens After Installation

    ### 1. Agent reads your config
    The skill tells the agent to check `.docsconfig.yaml` for your documentation structure.

    ### 2. Agent places files correctly
    ADRs in `docs/adr/`, guides in `docs/guides/`, API docs in `docs/api/` — not random locations.

    ### 3. Agent includes frontmatter
    Each document type gets proper YAML frontmatter (status, date, deciders for ADRs; title, difficulty for guides).

    ### 4. Agent follows templates
    Consistent structure: all ADRs have Context → Decision → Consequences, all guides have prerequisites.

    ## Example: With vs Without

    You ask: "Create an ADR for switching to PostgreSQL"

    **With skill:** Creates `docs/adr/0003-switch-to-postgresql.md` with correct frontmatter and template.
    **Without skill:** Might create `adr-postgres.md` in the project root, skip frontmatter, use random format.

    ```markdown
    ---
    status: proposed
    date: 2026-02-19
    deciders: [Engineering Team]
    ---

    # Switch to PostgreSQL

    ## Context
    Our current database is reaching scalability limits...

    ## Decision
    We will migrate to PostgreSQL...

    ## Consequences
    **Positive:** Better concurrent writes, advanced queries
    **Negative:** Increased infrastructure complexity
    ```

    DocMark auto-reloads. The new ADR appears in your sidebar immediately.

    ## This Is Optional

    Skills and `.docsconfig.yaml` are entirely opt-in. DocMark works perfectly as a standalone reader without any AI integration.
    """

    // MARK: - Skill Installation

    func checkSkillInstallation() {
        guard let project = selectedProject else {
            isSkillInstalledInProject = false
            return
        }
        let skillPath = URL(fileURLWithPath: project.path)
            .appendingPathComponent(".claude/skills/docmark/SKILL.md").path
        isSkillInstalledInProject = FileManager.default.fileExists(atPath: skillPath)
    }

    func installSkillToProject() {
        guard let project = selectedProject else { return }

        let projectURL = URL(fileURLWithPath: project.path)
        let destDir = projectURL.appendingPathComponent(".claude/skills/docmark")
        let destFile = destDir.appendingPathComponent("SKILL.md")

        guard !FileManager.default.fileExists(atPath: destFile.path) else {
            isSkillInstalledInProject = true
            return
        }

        do {
            try FileManager.default.createDirectory(at: destDir, withIntermediateDirectories: true)
            let content = Self.loadSkillContent(forResource: "SKILL", withExtension: "md", fallback: SkillContent.claudeCode)
            try content.write(to: destFile, atomically: true, encoding: .utf8)
            isSkillInstalledInProject = true
            print("[DocMark] Skill installed to \(destFile.path)")
        } catch {
            print("[DocMark] Failed to install skill: \(error)")
        }
    }

    static func loadSkillContent(forResource name: String, withExtension ext: String, fallback: String) -> String {
        if let bundled = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: "skills/claude-code")
            ?? Bundle.main.url(forResource: name, withExtension: ext, subdirectory: "skills/opencode"),
           let content = try? String(contentsOf: bundled, encoding: .utf8) {
            return content
        }
        return fallback
    }

    // MARK: - Helpers

    private func findFirstDocument(in nodes: [FolderNode]) -> Document? {
        for node in nodes {
            if node.isFile, let doc = node.document {
                return doc
            }
            if let found = findFirstDocument(in: node.children) {
                return found
            }
        }
        return nil
    }
}
