---
name: docmark
description: Follow DocMark documentation standards when creating or editing project documentation. Activates when the user asks to document, update docs, add changelog entries, create any documentation, set up documentation standards, or when .docsconfig.yaml is present.
---

# DocMark Documentation Standard

This skill provides base rules for consistent project documentation. It is designed to be **customized per-project** — the agent interviews the user about their project and updates this skill with the right document types, templates, and conventions.

## Base Rules

These apply to every project regardless of customization.

### 1. Check for Configuration

Always check for `.docsconfig.yaml` in the project root first. If present, follow its configuration for paths, frontmatter schemas, and templates. It overrides defaults in this skill.

### 2. Core Documents

| Document | Location | Notes |
|----------|----------|-------|
| README | `README.md` | Always exists. What it does, how to install, how to use. |
| CHANGELOG | `CHANGELOG.md` | [Keep a Changelog](https://keepachangelog.com/) format. Entries under `[Unreleased]`. |
| CONTRIBUTING | `CONTRIBUTING.md` | Only if the project accepts contributions. |

### 3. Frontmatter

All documentation files use YAML frontmatter between `---` delimiters. At minimum:

```yaml
---
title: "Document Title"
date: YYYY-MM-DD
---
```

Dates are ISO 8601 (YYYY-MM-DD). Additional fields depend on document type.

### 4. General Conventions

- Check `.docsconfig.yaml` before creating any documentation
- Use kebab-case filenames (e.g., `setup-local-dev.md`)
- Changelogs: add under `[Unreleased]`, never modify released versions
- Match formatting with existing project documentation
- Prefer creating new files over editing existing ones unless explicitly updating

## Customizing This Skill

This skill ships minimal. **You are expected to customize it** by talking to the user about their project.

### First Activation Notice

On the **first activation** of this skill, check if the CUSTOMIZATION AREA at the bottom of this file is empty. If it is, briefly offer customization before proceeding with the user's request:

> "This project's documentation skill hasn't been customized yet. I can set up documentation standards tailored to this project. Would you like to do that now, or should I proceed with the defaults?"

- If the user wants to customize → start the interview (see below)
- If the user declines → proceed with base rules, handle their request normally

**Do not ask again** after the first time. If the user said no, respect that and just use base rules going forward.

### Other Customization Triggers

- User mentions "set up docs", "documentation standards", or "customize skill"
- User asks for a document type not covered above (ADR, API doc, runbook, etc.)
- Project has no `.docsconfig.yaml` and no established doc structure

### How It Works

1. **Ask the user** about their project — don't assume. Have a conversation:
   - What kind of project is this? (API, library, CLI, frontend, infra, etc.)
   - Solo or team? Open source?
   - What kinds of documents do they need?
   - Any existing conventions they want to keep?

2. **Based on answers**, append to the `CUSTOMIZATION AREA` at the bottom of this file:
   - Document types with paths, frontmatter specs, and templates
   - Project-specific conventions or rules
   - Optionally create a `.docsconfig.yaml`

3. **Reference templates** are available in the project's `templates/` directory (if DocMark is installed). Use them as starting points — don't copy them verbatim. Adapt to what the user described.

4. **Keep it lean** — only add document types the user actually needs. A backend API project doesn't need a CONTRIBUTING guide. A solo tool doesn't need ADRs.

### Example Customization Flow

```
User: "Set up documentation for this project"
Agent: "What kind of project is this?"
User: "It's a backend REST API, team of 4"
Agent: "Got it. I'd suggest: API docs, ADRs for architecture decisions, 
        and a changelog. Do you also need runbooks or guides?"
User: "Yeah, runbooks would be good. No guides."
Agent: *updates this SKILL.md with API doc, ADR, and runbook sections*
Agent: *creates .docsconfig.yaml with the agreed structure*
```

After customization, the agent follows the updated skill for all future documentation tasks in this project.

---

<!-- 
CUSTOMIZATION AREA
After interviewing the user, append project-specific document types, 
templates, and conventions below this line.
-->
