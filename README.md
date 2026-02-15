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

DocMark is designed for the workflow where **AI agents write your docs, and you just read them**.

### How It Works

```
┌─────────────────────────────────────────────────────────┐
│  1. You define structure        .docsconfig.yaml        │
│  2. AI agent writes docs        Following your config   │
│  3. You open in DocMark         Read beautifully        │
└─────────────────────────────────────────────────────────┘
```

**Step 1 — Define your documentation structure** with `.docsconfig.yaml`:

```yaml
version: "1.0"
project:
  name: "My Project"
documentation:
  root: "."
  sections:
    - id: "guides"
      title: "Guides"
      path: "docs/guides"
      pattern: "*.md"
      frontmatter_schema: "guide"
    - id: "adr"
      title: "Architecture Decision Records"
      path: "docs/adr"
      pattern: "*.md"
      frontmatter_schema: "adr"
frontmatter_schemas:
  adr:
    required: [status, date, deciders]
    status_values: [proposed, accepted, deprecated, superseded]
  guide:
    required: [title]
    optional: [difficulty, estimated_time]
    difficulty_values: [beginner, intermediate, advanced]
```

**Step 2 — Install the skill** for your AI coding agent:

| Agent | Install | Skill Location |
|-------|---------|----------------|
| Claude Code | Tools → Install Claude Code Skill | `~/.claude/skills/docmark/SKILL.md` |
| OpenCode | Tools → Install OpenCode Skill | `~/.opencode/skills/docmark/skill.yaml` |

Once installed, the agent automatically:
- Reads your `.docsconfig.yaml` to understand the project structure
- Places new docs in the correct directories (`docs/adr/`, `docs/guides/`, etc.)
- Includes required frontmatter fields (status, date, title, etc.)
- Follows consistent formatting and templates

**Step 3 — Open your project in DocMark and read.** That's it.

The agent creates `docs/adr/0003-switch-to-postgres.md` with proper frontmatter. You open DocMark, navigate to the ADR section in the sidebar, and read a beautifully rendered architecture decision record. No editing, no formatting — just reading.

### Example: Ask Your Agent to Create an ADR

You tell Claude Code:

> "Create an ADR for switching our database to PostgreSQL"

The agent (with DocMark skill installed) reads your `.docsconfig.yaml`, finds the ADR schema, and creates:

```markdown
---
status: proposed
date: 2025-02-15
deciders: [Engineering Team]
---

# Switch to PostgreSQL

## Context
Our current SQLite database is reaching scalability limits...

## Decision
We will migrate to PostgreSQL for production...

## Consequences
**Positive:** Better concurrent write performance, advanced query capabilities
**Negative:** Increased infrastructure complexity
```

This file lands in `docs/adr/0003-switch-to-postgres.md` — exactly where your config says it should go. Open DocMark and it's already in your sidebar, rendered with proper styling.

### Skills Are Optional

All of this is opt-in. DocMark works perfectly as a standalone documentation reader without any AI integration. No `.docsconfig.yaml` needed — just open any folder with markdown files.

### Document Templates

DocMark includes starter templates in the `templates/` directory:

| Template | Purpose |
|----------|---------|
| `adr.md` | Architecture Decision Record with status, context, decision, consequences |
| `changelog.md` | Keep a Changelog format for version history |
| `api-doc.md` | API endpoint documentation with request/response examples |
| `guide.md` | Step-by-step tutorial with difficulty level and prerequisites |
| `docsconfig-template.yaml` | Starter `.docsconfig.yaml` for your project |

AI agents use these templates as reference. You can also use them manually.

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

## Contributing

Pull requests are welcome! For major changes, please open an issue first to discuss what you'd like to change.

Please follow the existing code style and ensure your changes work on macOS 14+.

## License

MIT License — see [LICENSE](LICENSE) for details.

---

Built with ❤️ for developers who read docs
