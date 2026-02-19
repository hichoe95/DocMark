# AI Agent Integration

DocMark works with AI coding agents like Claude Code and OpenCode. Install a skill so the agent knows how to write documentation that fits your project structure.

---

## How It Works

```
You define structure   →   Agent writes docs   →   You read in DocMark
(.docsconfig.yaml)         (following your config)    (beautifully rendered)
```

1. You create a `.docsconfig.yaml` in your project root to define sections, paths, and frontmatter schemas
2. You install the DocMark skill into your project (sidebar button or `⌘I`)
3. The AI agent reads both files and writes documentation accordingly
4. DocMark auto-reloads — you see the new docs instantly

## Installing the Skill

### Project-Level (Recommended)

Click **"Install AI Skill"** at the bottom of the sidebar, or press `⌘I`.

This creates `.claude/skills/docmark/SKILL.md` inside your project. Both Claude Code and OpenCode detect this path automatically — one file covers both agents.

### Global

For system-wide installation: menu bar → **Tools** → **Install Skill Globally** → choose Claude Code or OpenCode.

| Scope | Path |
|-------|------|
| Project | `{project}/.claude/skills/docmark/SKILL.md` |
| Global (Claude Code) | `~/.claude/skills/docmark/SKILL.md` |
| Global (OpenCode) | `~/.opencode/skills/docmark/skill.yaml` |

## What the Agent Does After Installation

Once the skill is installed, the agent will:

### 1. Read Your Config

The agent checks `.docsconfig.yaml` to learn your project's documentation structure — which sections exist, where files go, and what frontmatter is required.

### 2. Place Files in the Right Location

Instead of dumping docs in random locations, the agent follows your configured paths:

| Document Type | Default Path | Example |
|---------------|-------------|---------|
| ADRs | `docs/adr/` | `docs/adr/0003-switch-to-postgres.md` |
| Guides | `docs/guides/` | `docs/guides/getting-started.md` |
| API Docs | `docs/api/` | `docs/api/create-user.md` |
| Changelog | project root | `CHANGELOG.md` |

### 3. Include Correct Frontmatter

Each document type gets proper YAML frontmatter:

**ADR (Architecture Decision Record):**
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

**Guide:**
```markdown
---
title: Getting Started
difficulty: beginner
estimated_time: 10 minutes
---

# Getting Started

## Prerequisites
...
```

**API Documentation:**
```markdown
---
title: Create User
endpoint: /api/v1/users
method: POST
auth_required: true
---

# Create User

## Request
...

## Response
...
```

### 4. Follow Templates

The agent uses consistent templates for each document type, so all your ADRs have the same structure (Context → Decision → Consequences), all guides have prerequisites, and all API docs have request/response sections.

## Example Workflow

You tell Claude Code:

> "Create an ADR for switching our database to PostgreSQL"

The agent:
1. Reads `.docsconfig.yaml` → finds ADR section at `docs/adr/`
2. Checks existing ADRs → determines next number is `0003`
3. Creates `docs/adr/0003-switch-to-postgres.md` with status/date/deciders frontmatter
4. Fills in Context, Decision, and Consequences sections

DocMark auto-reloads. The new ADR appears in your sidebar immediately.

Another example:

> "Add a changelog entry for the new export feature in v1.2.0"

The agent:
1. Opens `CHANGELOG.md`
2. Adds entry under `[Unreleased]` → `### Added`
3. Writes: "Export functionality for documentation in PDF, HTML, and Markdown formats"

## Setting Up `.docsconfig.yaml`

```yaml
version: "1.0"
project:
  name: "My Project"
documentation:
  root: "."
  sections:
    - id: "adr"
      title: "Architecture Decision Records"
      path: "docs/adr"
      pattern: "*.md"
      frontmatter_schema: "adr"
    - id: "guides"
      title: "Guides"
      path: "docs/guides"
      pattern: "*.md"
      frontmatter_schema: "guide"
    - id: "api"
      title: "API Documentation"
      path: "docs/api"
      pattern: "*.md"
      frontmatter_schema: "api"
frontmatter_schemas:
  adr:
    required: [status, date, deciders]
    status_values: [proposed, accepted, deprecated, superseded]
  guide:
    required: [title]
    optional: [difficulty, estimated_time]
    difficulty_values: [beginner, intermediate, advanced]
  api:
    required: [title, endpoint, method]
    optional: [auth_required, version]
```

## Without `.docsconfig.yaml`

The skill still works without a config file. The agent falls back to sensible defaults:
- ADRs → `docs/adr/`
- Guides → `docs/guides/`
- API docs → `docs/api/`
- Changelog → project root

## This Is Optional

Skills and `.docsconfig.yaml` are entirely opt-in. DocMark works perfectly as a standalone documentation reader without any AI integration. Just open any folder with markdown files.
