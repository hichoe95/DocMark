# AI Agent Integration

DocMark can install **skills** for AI coding agents like Claude Code and OpenCode. A skill is an instruction file that teaches the agent how to write documentation that matches your project's structure.

---

## What Is a Skill?

A skill is a markdown file (`SKILL.md`) that gets **injected into the AI agent's context**. It contains instructions the agent follows when working on your project.

Without a skill, if you ask Claude Code "Create an ADR for switching to PostgreSQL", the agent writes a generic markdown file wherever it guesses is appropriate. The format, frontmatter, and file location are all up to chance.

With the DocMark skill installed, the same request produces a properly structured ADR with correct frontmatter (`status`, `date`, `deciders`), placed in the right directory (`docs/adr/`), following a consistent template (Context → Decision → Consequences).

### How the Agent Discovers Skills

AI agents automatically scan for skills on startup:

```
Project root
└── .claude/
    └── skills/
        └── docmark/
            └── SKILL.md    ← Agent finds and reads this
```

1. The agent scans `.claude/skills/` for subdirectories containing `SKILL.md`
2. It reads each skill's `description` field to know **when** to activate it
3. When your request matches a skill's description, the agent loads the full instructions
4. The agent follows those instructions while completing your task

No configuration needed. The agent discovers the skill automatically just because the file exists in the right path.

### Skill File Format

A `SKILL.md` file has two parts:

**1. YAML Frontmatter** (between `---` markers) — metadata that tells the agent when to use the skill:

```yaml
---
name: docmark
description: Follow DocMark documentation standards when creating
  or editing docs, changelogs, ADRs, API documentation, or guides.
---
```

| Field | Purpose |
|-------|---------|
| `name` | Skill name. Becomes the `/slash-command` (e.g., `/docmark`) |
| `description` | Tells the agent **when** to activate. The agent matches your request against this text. |

**2. Markdown Body** — the actual instructions the agent follows. This can include rules, templates, examples, tables — anything you'd tell a human colleague about how to write docs for your project.

The frontmatter is always loaded so the agent knows the skill exists. The full body only loads when the skill activates, keeping context usage efficient.

### Automatic vs Manual Activation

The DocMark skill activates **automatically** when you ask the agent to:
- Create or edit documentation
- Generate changelogs, ADRs, or API docs
- Work with `.docsconfig.yaml`

You can also invoke it manually:
```
/docmark Create an ADR for switching to PostgreSQL
```

## Installing the Skill

### Project-Level (Recommended)

Click **"Install AI Skill"** at the bottom of the sidebar, or press `⌘I`.

This creates `.claude/skills/docmark/SKILL.md` inside your project. Both Claude Code and OpenCode detect this path automatically — one file covers both agents.

**Why project-level?** The skill file gets committed to git with your project. Every team member who clones the repo gets the skill automatically. No per-machine setup needed.

### Global

For system-wide installation (applies to all projects): menu bar → **Tools** → **Install Skill Globally** → choose your agent.

| Scope | Path | Applies To |
|-------|------|------------|
| Project | `{project}/.claude/skills/docmark/SKILL.md` | This project only |
| Personal (Claude Code) | `~/.claude/skills/docmark/SKILL.md` | All your projects |
| Personal (OpenCode) | `~/.opencode/skills/docmark/skill.yaml` | All your projects |

Project-level skills take precedence if the same skill exists globally.

## What Happens After Installation

Here's the exact sequence when you give the agent a documentation task:

### Step 1: Agent Reads Your Config

The skill tells the agent to first check for `.docsconfig.yaml` in your project root:

```bash
cat .docsconfig.yaml
```

This file defines your documentation structure — which sections exist, where files go, and what frontmatter each document type requires. If no config exists, the skill provides sensible defaults.

### Step 2: Agent Places Files Correctly

Instead of dumping docs in random locations, the agent follows your configured paths:

| Document Type | Default Path | Naming Pattern |
|---------------|-------------|----------------|
| README | `README.md` | Project root |
| CHANGELOG | `CHANGELOG.md` | Project root |
| ADRs | `docs/adr/` | `NNNN-title.md` (e.g., `0001-use-postgres.md`) |
| Guides | `docs/guides/` | `topic-name.md` |
| API Docs | `docs/api/` | `endpoint-name.md` |

The skill also tells the agent to check existing files to determine the next sequential number for ADRs.

### Step 3: Agent Includes Correct Frontmatter

Each document type gets proper YAML frontmatter. The skill specifies exactly which fields are required:

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

### Step 4: Agent Follows Templates

The skill includes complete templates for each document type. This ensures consistency:
- All ADRs have the same structure: Context → Decision → Consequences
- All guides have prerequisites and step-by-step sections
- All API docs have request/response examples with error codes

Without the skill, every document has a different structure depending on the agent's mood. With the skill, they're all consistent.

## Full Workflow Example

### Example 1: Creating an ADR

You tell Claude Code:

> "Create an ADR for switching our database to PostgreSQL"

What the agent does internally:

1. **Skill activates** — your request matches "creating ADRs" in the skill description
2. **Reads `.docsconfig.yaml`** — finds ADR section configured at `docs/adr/` with required frontmatter: `status`, `date`, `deciders`
3. **Checks existing files** — scans `docs/adr/` and sees `0001-...md`, `0002-...md` exist, so the next number is `0003`
4. **Creates file** — writes `docs/adr/0003-switch-to-postgresql.md` using the ADR template
5. **Fills content** — applies the Context → Decision → Consequences structure with relevant content

DocMark auto-reloads via file watching. The new ADR appears in your sidebar immediately.

### Example 2: Updating the Changelog

> "Add a changelog entry for the new export feature"

The agent:
1. **Skill activates** — matches "generating changelogs"
2. **Opens `CHANGELOG.md`** — finds the `[Unreleased]` section
3. **Adds entry** under `### Added`:
   ```markdown
   - Export functionality for documentation in PDF, HTML, and Markdown formats
   ```

### Example 3: Without the Skill (Comparison)

Same request without the skill installed:

> "Create an ADR for switching our database to PostgreSQL"

The agent might:
- Create `adr-postgres.md` in the project root (wrong location)
- Skip frontmatter entirely (no `status`, `date`, `deciders`)
- Use a random format instead of Context → Decision → Consequences
- Not check for existing ADR numbers

**The skill is the difference between consistent, structured documentation and ad-hoc guesswork.**

## Setting Up `.docsconfig.yaml`

This optional config file lets you customize paths and frontmatter requirements:

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

The agent reads this file because the skill tells it to. Without the skill, the agent wouldn't know to look for `.docsconfig.yaml` at all.

## Without `.docsconfig.yaml`

The skill still works. The agent falls back to defaults defined in the skill itself:
- ADRs → `docs/adr/`
- Guides → `docs/guides/`
- API docs → `docs/api/`
- Changelog → project root

The config file just lets you customize these paths and add additional frontmatter requirements specific to your project.

## This Is Optional

Skills and `.docsconfig.yaml` are entirely opt-in. DocMark works perfectly as a standalone documentation reader without any AI integration. Just open any folder with markdown files.

---

## Appendix: Full Skill Content

Below is the complete DocMark skill that gets installed. This is exactly what the AI agent reads when the skill activates.

````markdown
---
name: docmark
description: Follow DocMark documentation standards when creating or editing docs,
  changelogs, ADRs, API documentation, or guides. Activates when the user asks to
  document, update docs, add changelog entries, create ADRs, or when .docsconfig.yaml
  is present.
---

# DocMark Documentation Standard

This skill helps follow the DocMark documentation structure defined in
`.docsconfig.yaml`. It provides a standardized approach to project documentation
with consistent frontmatter schemas, templates, and organization patterns.

## Instructions

### 1. Check for Configuration

Always start by checking for `.docsconfig.yaml` in the project root:

```bash
cat .docsconfig.yaml
```

If present, read and follow the configuration for:
- `frontmatter_schemas`: Required fields for each document type
- `templates`: Template paths or inline templates
- `paths`: Custom locations for documentation files

### 2. Document Placement Rules

Follow these default paths unless overridden in `.docsconfig.yaml`:

| Document Type | Default Location | Pattern |
|---------------|------------------|---------|
| README | `README.md` | Project root |
| CHANGELOG | `CHANGELOG.md` | Project root |
| CONTRIBUTING | `CONTRIBUTING.md` | Project root |
| ADRs | `docs/adr/` | `NNNN-title.md` (e.g., `0001-use-postgres.md`) |
| Guides | `docs/guides/` | `topic-name.md` |
| API Docs | `docs/api/` | `endpoint-name.md` |

### 3. Frontmatter Requirements

Each document type has required frontmatter fields:

**ADRs (Architecture Decision Records):**
- `status`: One of `proposed`, `accepted`, `rejected`, `deprecated`, `superseded`
- `date`: ISO 8601 format (YYYY-MM-DD)
- `deciders`: List of people who made the decision

**Guides:**
- `title`: Guide title

**API Documentation:**
- `title`: API endpoint title
- `endpoint`: API path (e.g., `/api/v1/users`)
- `method`: HTTP method (GET, POST, PUT, DELETE, PATCH)
- `auth_required`: Boolean indicating if authentication is required

**General Rules:**
- Always use ISO 8601 date format (YYYY-MM-DD)
- Frontmatter must be valid YAML enclosed in `---` delimiters
- Required fields must always be present

### 4. Creating Documents

When creating new documentation:

1. Check `.docsconfig.yaml` for templates
2. Use the appropriate template for the document type
3. Fill in all required frontmatter fields
4. Place the file in the correct location
5. Use descriptive, kebab-case filenames

### 5. Updating Documents

When updating existing documentation:

1. Preserve existing frontmatter structure
2. Update `date` field if modifying ADRs
3. For changelogs, add entries under the `[Unreleased]` section
4. Maintain consistent formatting with existing content

## Templates

### ADR Template

```markdown
---
status: proposed
date: YYYY-MM-DD
deciders: [Name1, Name2]
---

# Title

## Context

What is the issue that we're seeing that is motivating this decision or change?

## Decision

What is the change that we're proposing and/or doing?

## Consequences

What becomes easier or more difficult to do because of this change?
```

### Changelog Template

Use the Keep a Changelog format:

```markdown
# Changelog

## [Unreleased]

### Added
- New features go here

### Changed
- Changes to existing functionality

### Fixed
- Bug fixes
```

### API Documentation Template

```markdown
---
title: Endpoint Name
endpoint: /api/v1/resource
method: GET
auth_required: true
---

# Endpoint Name

## Description

Brief description of what this endpoint does.

## Request

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| id | string | Yes | Resource identifier |

## Response

### Success Response (200 OK)

```json
{
  "id": "123",
  "name": "Example"
}
```

## Errors

| Status Code | Description |
|-------------|-------------|
| 400 | Bad Request |
| 401 | Unauthorized |
| 404 | Not Found |
```

## Notes

- Always check for `.docsconfig.yaml` first before creating documentation
- If no configuration exists, use the default paths and templates provided here
- Prefer creating new files over editing existing ones unless explicitly updating
- ADR numbers should be sequential (check existing ADRs for the next number)
- Keep changelog entries concise but descriptive
- API documentation should include realistic examples
````

You can customize this skill by editing `.claude/skills/docmark/SKILL.md` directly. Changes take effect in the next agent session.
