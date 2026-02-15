# DocMark

A beautiful, Mac-native documentation reader for the AI coding era.

[English](README.md) | [한국어](README.ko.md)

![macOS](https://img.shields.io/badge/macOS-14%2B-blue) ![Swift](https://img.shields.io/badge/Swift-5.9-orange) ![License](https://img.shields.io/badge/license-MIT-green) ![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen)

<p align="center">
  <img src="docs/assets/screenshot.png" width="800" alt="DocMark Screenshot" />
  <br>
  <em>(screenshot coming soon)</em>
</p>

## Why DocMark?

We're living in the era of "vibe coding" — LLMs write the code, developers read the docs. AI coding agents like Claude Code, Cursor, and OpenCode are transforming how we build software. But when these agents generate documentation, where do you read it?

Most markdown viewers are editors first, readers second. DocMark is different. It's read-only by design, built specifically for developers who need a beautiful way to consume project documentation.

No Electron. No web wrappers. Just pure SwiftUI, native to macOS. Fast, lightweight, and feels like home.

## Features

### Core (Free)

- **Beautiful markdown rendering** — Native SwiftUI via MarkdownView, optimized for readability
- **Project folder scanning** — Sidebar tree navigation that understands your documentation structure
- **Syntax-highlighted code blocks** — One-click copy for every code snippet
- **Quick Open (⌘P)** — Fuzzy file search like VS Code, instant navigation
- **Full-text search (⌘K)** — Powered by SQLite FTS5, search across all your docs
- **Dark & Light mode** — Follows system preference automatically
- **GitHub-style admonitions** — NOTE, TIP, WARNING, IMPORTANT, CAUTION rendered beautifully
- **Breadcrumb navigation** — Previous/Next document navigation (⌘[ / ⌘])
- **File watching** — Auto-reloads when docs change on disk
- **`.docsconfig.yaml` support** — Define your documentation structure, sections, and metadata

### Pro

- **Mermaid diagram rendering** — Flowcharts, sequence diagrams, class diagrams, and more
- **KaTeX math equation rendering** — Beautiful mathematical notation
- **Table of Contents panel (⌘T)** — Navigate long documents with ease
- **Git branch & file change indicators** — See what's changed at a glance
- **Multi-project library** — Manage multiple documentation projects with favorites and pinning (⇧⌘L)
- **Cross-project search** — Search across all your documentation libraries

## AI Agent Integration

DocMark provides optional skills for AI coding agents. When installed, agents learn to follow your `.docsconfig.yaml` structure and can intelligently organize documentation as they write it.

**Supported agents:** Claude Code, OpenCode

**Installation:** Tools menu → Install Skill (one-click)

Skills are completely opt-in — DocMark works perfectly without them. They simply enhance the experience when you're using AI agents to generate or maintain documentation.

### Example `.docsconfig.yaml`

```yaml
version: "1.0"
project:
  name: "My Project"
documentation:
  root: "."
  sections:
    - id: "guides"
      path: "docs/guides"
      pattern: "*.md"
    - id: "adr"
      path: "docs/adr"
      pattern: "*.md"
      frontmatter_schema: "adr"
```

## Installation

### Download DMG

Download the latest release from [GitHub Releases](https://github.com/hichoe95/DocMark/releases).

1. Open the DMG file
2. Drag DocMark.app to your Applications folder
3. Launch DocMark

**Note:** This is an unsigned build. macOS Gatekeeper may show a warning. Right-click the app → Open → Open to bypass.

### Build from Source

```bash
git clone https://github.com/hichoe95/DocMark.git
cd DocMark
swift build -c release
./scripts/build-dmg.sh
open build/DocMark.app
```

## Quick Start

1. **Launch DocMark** from your Applications folder
2. **Open a project folder** (⌘O) — select any folder containing markdown files
3. **Browse docs** in the sidebar — click any file to read
4. **Use ⌘P** for Quick Open, **⌘K** for full-text search
5. **Enjoy** reading your docs beautifully rendered

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| ⌘O | Open project folder |
| ⌘P | Quick Open (fuzzy file search) |
| ⌘K | Full-text search |
| ⌘T | Toggle Table of Contents |
| ⌘[ / ⌘] | Previous / Next document |
| ⇧⌘L | Project Library |

## Project Structure

```
DocMark/
├── Sources/DocMark/
│   ├── App/          # App entry, state management
│   ├── Core/         # Rendering, database, file watching
│   ├── Features/     # UI: sidebar, reader, search, library
│   └── Models/       # Document, Project, FolderNode
├── Resources/        # Guide, sample project
├── skills/           # AI agent skills
├── templates/        # Document templates
└── scripts/          # Build scripts
```

## Tech Stack

| Component | Technology |
|-----------|-----------|
| UI Framework | SwiftUI (macOS 14+) |
| Markdown | MarkdownView 2.6.0 |
| Database | GRDB.swift (SQLite + FTS5) |
| YAML | Yams 5.4.0 |
| Diagrams | Mermaid.js (via WKWebView) |
| Math | KaTeX (via WKWebView) |
| Build | Swift Package Manager |

## Templates

DocMark includes document templates for common documentation types. Use them to quickly scaffold new documentation with consistent structure.

Available templates:

- **ADR (Architecture Decision Records)** — Document architectural decisions with context and consequences
- **Changelog** — Keep a Changelog format for version history
- **API Documentation** — Structured API reference documentation
- **Guide / Tutorial** — Step-by-step instructional content

Find them in the `templates/` directory.

## Contributing

Pull requests are welcome! For major changes, please open an issue first to discuss what you'd like to change.

Please follow the existing code style and ensure your changes work on macOS 14+.

## License

MIT License — see [LICENSE](LICENSE) for details.

---

Built with ❤️ for developers who read docs
