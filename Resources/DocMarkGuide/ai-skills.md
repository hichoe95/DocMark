# AI Agent Integration

DocMark can install **skills** for AI coding agents like Claude Code and OpenCode. A skill is an instruction file that teaches the agent how to write documentation that matches your project's structure.

---

## What Is a Skill?

A skill is a markdown file (`SKILL.md`) that gets **injected into the AI agent's context**. It contains instructions the agent follows when working on your project.

Without a skill, the agent writes documentation in whatever format it guesses. File locations, frontmatter, structure — all ad-hoc.

With the DocMark skill installed, the agent follows consistent rules for placement, formatting, and structure. And it can **customize itself** to fit your specific project.

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
3. When your request matches, the agent loads the full instructions
4. The agent follows those instructions while completing your task

No configuration needed. The file's presence is enough.

### Skill File Format

A `SKILL.md` file has two parts:

**1. YAML Frontmatter** — metadata that tells the agent when to use the skill:

```yaml
---
name: docmark
description: Follow DocMark documentation standards when creating
  or editing project documentation.
---
```

| Field | Purpose |
|-------|---------|
| `name` | Skill name. Becomes the `/slash-command` (e.g., `/docmark`) |
| `description` | Tells the agent **when** to activate. Matched against your request. |

**2. Markdown Body** — the actual instructions. Rules, templates, examples — anything you'd tell a colleague about how to write docs for your project.

The frontmatter is always loaded (so the agent knows the skill exists). The full body only loads when activated.

### Automatic vs Manual Activation

The DocMark skill activates **automatically** when you ask the agent to:
- Create or edit documentation
- Generate changelogs or any doc type
- Work with `.docsconfig.yaml`
- Set up documentation standards

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

For system-wide installation: menu bar → **Tools** → **Install Skill Globally** → choose your agent.

| Scope | Path | Applies To |
|-------|------|------------|
| Project | `{project}/.claude/skills/docmark/SKILL.md` | This project only |
| Personal (Claude Code) | `~/.claude/skills/docmark/SKILL.md` | All your projects |
| Personal (OpenCode) | `~/.opencode/skills/docmark/skill.yaml` | All your projects |

Project-level skills take precedence if the same skill exists globally.

## What the Skill Does

The DocMark skill works in two layers: **base rules** that apply to every project, and **project customization** that the agent builds with you.

### Layer 1: Base Rules (Always Active)

Out of the box, the skill gives the agent these rules:

- **Check `.docsconfig.yaml`** first — if it exists, follow its configuration
- **Core documents**: README.md (always), CHANGELOG.md (Keep a Changelog format), CONTRIBUTING.md (if needed)
- **YAML frontmatter** on all docs with at least `title` and `date`
- **Kebab-case filenames**, consistent formatting, never modify released changelog versions

This is enough for basic documentation tasks. You ask "update the changelog" and the agent knows the format. You ask "write a README" and it follows a clean structure.

### Layer 2: Project Customization (Agent-Driven)

Here's what makes this skill different: **the agent customizes itself to your project**.

When you ask the agent to "set up documentation standards" or request a document type not in the base rules (like an ADR, runbook, or API doc), the agent starts a conversation:

```
You:   "Set up documentation for this project"
Agent: "What kind of project is this?"
You:   "Backend REST API, team of 4"
Agent: "I'd suggest API docs, ADRs for architecture decisions, and a
        changelog. Would runbooks or guides be useful too?"
You:   "Runbooks yes, guides no."
Agent: *updates SKILL.md with API doc, ADR, and runbook sections*
Agent: *creates .docsconfig.yaml with the agreed structure*
```

After this conversation, the skill file contains document types, templates, and conventions tailored to **your** project. Future documentation tasks follow these customized standards automatically.

The agent uses reference templates from DocMark's `templates/` directory as starting points, adapting them to your answers.

### Why This Approach?

Every project is different. A backend API needs API docs and runbooks. An open-source library needs CONTRIBUTING guides and tutorials. A solo CLI tool might just need a README and changelog.

Instead of shipping a bloated skill with every possible document type, the skill stays lean and grows with your project. You only get what you actually need.

## Example Workflows

### Example 1: Basic Documentation (No Customization)

> "Add a changelog entry for the new export feature"

The agent uses base rules:
1. Opens `CHANGELOG.md`
2. Adds entry under `[Unreleased]` → `### Added`
3. Done. No customization needed.

### Example 2: First-Time Setup

> "Set up documentation standards for this project"

The agent starts the customization interview:
1. Asks about project type, team, needs
2. Based on your answers, updates `SKILL.md` with relevant document types
3. Creates `.docsconfig.yaml` with paths and frontmatter schemas
4. From now on, all documentation follows the agreed structure

### Example 3: After Customization

> "Create an ADR for switching to PostgreSQL"

The agent follows the customized skill:
1. Checks `docs/adr/` for existing files → next number is `0003`
2. Creates `docs/adr/0003-switch-to-postgresql.md`
3. Uses the ADR template with correct frontmatter (`status`, `date`, `deciders`)
4. Fills in Context → Decision → Consequences structure

DocMark auto-reloads via file watching. The new ADR appears in your sidebar immediately.

### Example 4: Without the Skill (Comparison)

Same request without the skill:

> "Create an ADR for switching to PostgreSQL"

The agent might:
- Create `adr-postgres.md` in the project root (wrong location)
- Skip frontmatter entirely
- Use a random format
- Not check for existing ADR numbers

**The skill is the difference between consistent documentation and ad-hoc guesswork.**

## Setting Up `.docsconfig.yaml`

This optional config file defines your documentation structure. The agent can create it during the customization interview, or you can write it manually:

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
frontmatter_schemas:
  adr:
    required: [status, date, deciders]
    status_values: [proposed, accepted, deprecated, superseded]
  guide:
    required: [title]
    optional: [difficulty, estimated_time]
```

Without `.docsconfig.yaml`, the skill uses its built-in defaults. The config just lets you customize paths and add project-specific requirements.

## Reference Templates

DocMark includes starter templates in the `templates/` directory. These serve as raw material for the agent during customization — it adapts them to your project rather than copying them verbatim.

| Template | Purpose |
|----------|---------|
| `adr.md` | Architecture Decision Record |
| `changelog.md` | Keep a Changelog format |
| `api-doc.md` | API endpoint documentation |
| `guide.md` | Step-by-step tutorial |
| `design-doc.md` | Design document / RFC |
| `runbook.md` | Operational runbook |
| `postmortem.md` | Incident postmortem |
| `release-notes.md` | Version release notes |
| `troubleshooting.md` | Troubleshooting guide |
| `docsconfig-template.yaml` | Starter `.docsconfig.yaml` |

You can also use these templates manually, independent of any AI agent.

## This Is Optional

Skills and `.docsconfig.yaml` are entirely opt-in. DocMark works perfectly as a standalone documentation reader without any AI integration. Just open any folder with markdown files.
