# AGENTS.md

> Coding agent guidelines for the DocMark codebase.

## Project Overview

DocMark is a native macOS documentation reader built with SwiftUI. It renders markdown
beautifully with features like full-text search (FTS5), file watching, Mermaid diagrams,
KaTeX math, and AI agent skill integration. macOS 14+, Swift 5.9, Swift Package Manager.

## Build & Run

```bash
swift build                        # Debug build
swift build -c release             # Release build
swift run DocMark                  # Build and run
open .build/debug/DocMark          # Run debug binary directly
./scripts/build-dmg.sh             # Full release: build + .app bundle + DMG
./scripts/build-dmg.sh --version 2.0.0 --sign "Developer ID Application: Name"
```

## Test Commands

```bash
swift test                                              # All tests
swift test --filter DocMarkTests                        # Single test file
swift test --filter DocMarkTests.testMarkdownScannerFindsFiles  # Single test method
swift test --verbose                                    # Verbose output
```

Tests use XCTest. Test target: `DocMarkTests` (path: `Tests/DocMarkTests/`).
No CI configured — run tests locally before committing.

## Project Structure

```
Sources/DocMark/
  App/              # DocMarkApp entry point, AppState (central ObservableObject), ContentView
  Core/
    Database/       # GRDB repositories, row types, migrations (GRDBManager singleton)
    DocsConfig/     # .docsconfig.yaml parsing (DocsConfig model, DocsConfigParser)
    FileWatcher/    # FSEvents-based file watcher service
    Git/            # GitService (static methods wrapping /usr/bin/git)
    MarkdownEngine/ # MarkdownScanner, AdmonitionProcessor, WebViewTemplate
  Features/
    DocumentReader/ # DocumentReaderView, TableOfContentsView, WebViewDocumentRenderer
    Onboarding/     # First-launch onboarding flow
    Paywall/        # LicenseManager, pro feature gating
    ProjectLibrary/ # Multi-project management UI
    Search/         # QuickOpenPanel (Cmd+P), SearchPanel (Cmd+K)
    Sidebar/        # SidebarView (folder tree navigation)
  Extensions/       # Swift extensions (currently empty)
  Models/           # Document, Project, FolderNode, SearchResult, FileChange, Theme
  Utilities/        # Utility helpers (currently empty)
  Resources/        # Bundled assets processed by SPM
Tests/DocMarkTests/ # XCTest suite
scripts/            # build-dmg.sh (release packaging)
templates/          # Document templates (ADR, changelog, API doc, guide)
skills/             # AI agent skill definitions (Claude Code, OpenCode)
Resources/          # DocMarkGuide (bundled welcome project)
```

## Dependencies

| Package | Import | Purpose |
|---------|--------|---------|
| MarkdownView | `import MarkdownView` | Native SwiftUI markdown rendering |
| GRDB.swift | `import GRDB` | SQLite database + FTS5 full-text search |
| Yams | `import Yams` | YAML parsing for .docsconfig.yaml |
| Highlightr | `import Highlightr` | Code syntax highlighting (conditional) |

## Code Style

### Imports

System frameworks first, then third-party. No blank lines between groups.

```swift
import SwiftUI
import Combine
import GRDB
```

Conditional imports use `#if canImport`:

```swift
#if canImport(Highlightr)
import Highlightr
#endif
```

### Naming

- **Types**: `PascalCase` — `DocumentReaderView`, `FileWatcherService`, `AdmonitionType`
- **Functions/methods**: `camelCase` — `openProject(at:)`, `performSearch(_:)`, `buildTree(from:relativeTo:)`
- **Variables/properties**: `camelCase` — `selectedDocument`, `isShowingSearch`, `allDocuments`
- **Enum cases**: `camelCase` — `.created`, `.modified`, `.favorites`
- **Constants**: `camelCase` — `private static let gitExecutablePath = "/usr/bin/git"`
- **Raw-value enums** use display strings: `case all = "All"`, `case recent = "Recent"`

### Types — Struct vs Class

- **Structs** for models and stateless services: `Document`, `Project`, `GitService`, `DocumentRepository`
- **Classes** for stateful/observable objects: `AppState`, `FileWatcherService`, `LicenseManager`
- **`final class`** for singletons and classes not designed for subclassing

### Access Control

- Types default to `internal` (implicit). Don't write `internal` explicitly.
- Mark implementation details `private`. Use `private(set)` for read-only external access.
- `fileprivate` is not used in this codebase — prefer `private`.
- Private extensions for small helpers scoped to a file:

```swift
private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
```

### File Organization — MARK Sections

Every file with multiple logical sections uses `// MARK: -` for structure.
Follow this ordering within a type:

```swift
final class AppState: ObservableObject {
    // MARK: - Properties (grouped by domain)
    @Published var projects: [Project] = []

    // MARK: - Services
    private let db = GRDBManager.shared

    // MARK: - Types (nested enums/structs)
    enum LibraryFilter: String, CaseIterable { ... }

    // MARK: - Computed Properties
    var filteredProjects: [Project] { ... }

    // MARK: - Init
    init() { ... }

    // MARK: - Public Methods (grouped by feature)
    func openProject(at url: URL) { ... }

    // MARK: - Helpers
    private func findFirstDocument(in nodes: [FolderNode]) -> Document? { ... }
}
```

### Error Handling

- **`try?`** for non-critical operations (most common pattern):
  ```swift
  let modDate = (try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date()
  ```
- **`do-catch`** for critical paths, always log with `[DocMark]` prefix:
  ```swift
  do {
      projects = try projectRepo.fetchAll()
  } catch {
      print("[DocMark] Failed to load projects: \(error)")
  }
  ```
- **`guard`** for early returns on precondition failures:
  ```swift
  guard let project = selectedProject else { return }
  ```
- Never use `try!` except in `fatalError`-worthy initialization (e.g., database setup).

### Logging

All log messages use the `[DocMark]` prefix:

```swift
print("[DocMark] Failed to load projects: \(error)")
print("[DocMark] DB fallback: \(error)")
```

### Singleton Pattern

```swift
final class GRDBManager {
    static let shared = GRDBManager()
    let dbQueue: DatabaseQueue
    private init() { ... }
}
```

### Reactive / State

- `ObservableObject` + `@Published` for state management
- `Combine` publishers with `sink` + `store(in: &cancellables)`
- `@EnvironmentObject` to pass `AppState` through SwiftUI view hierarchy
- `@StateObject` for view-owned observable objects
- `lazy var` for deferred service initialization

### SwiftUI Views

- Extract computed sub-views as `private var` properties (not separate types) for small pieces
- Use separate `struct` types for reusable or complex subviews
- Place `// MARK: -` comments above distinct view sections
- Prefer `.frame(maxWidth: .infinity)` over hardcoded widths

### Database (GRDB)

- Row types conform to `Codable, FetchableRecord, MutablePersistableRecord`
- Repository structs take `DatabaseQueue` via init, use `dbQueue.read/write` closures
- Migrations registered in `GRDBManager.migrator` with versioned names: `"v1_initial_schema"`
- `#if DEBUG` enables `eraseDatabaseOnSchemaChange` for development

### Test Conventions

- Test class: `final class XxxTests: XCTestCase`
- Test methods: `func testDescriptiveName()` — no underscores
- Use temp directories with `defer` cleanup:
  ```swift
  let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
  try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
  defer { try? FileManager.default.removeItem(at: tempDir) }
  ```
- Assertions: `XCTAssertEqual`, `XCTAssertFalse`, `XCTAssertTrue`
- Import production code with `@testable import DocMark`
- Empty test subdirectories exist for future tests: `DatabaseTests/`, `FileWatcherTests/`,
  `MarkdownEngineTests/`, `IntegrationTests/`

## Architecture Notes

- **AppState** is the central state hub — all navigation, search, and project management flows through it
- **Repository pattern** for database access: `ProjectRepository`, `DocumentRepository`, `SearchRepository`
- **Row types** (`DocumentRow`, `ProjectRow`) map between domain models and GRDB database rows
- **Services** are stateless structs with static methods (`GitService`) or singletons (`GRDBManager`)
- **Features** are organized by UI concern, each in its own subdirectory under `Features/`
- Single executable target — all source code lives in one SPM module (`DocMark`)
