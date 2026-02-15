# AI Agent Integration

DocMark provides optional skills for AI coding agents so they follow consistent documentation structures.

---

## What Are Skills?

Skills are instruction files that teach AI agents how to create and manage documentation in your project. When installed, agents will:

- Follow your `.docsconfig.yaml` structure
- Use correct frontmatter schemas for ADRs, guides, and API docs
- Place files in the right directories
- Use consistent formatting and templates

## Supported Agents

### Claude Code

**Install via:** DocMark menu → `Tools` → `Install Claude Code Skill`

This copies `SKILL.md` to `~/.claude/skills/docmark/SKILL.md`. Claude Code will automatically pick it up when working on projects with `.docsconfig.yaml`.

### OpenCode

**Install via:** DocMark menu → `Tools` → `Install OpenCode Skill`

This copies `skill.yaml` to the OpenCode skills directory. OpenCode activates the skill when it detects `.docsconfig.yaml` or documentation-related keywords.

## `.docsconfig.yaml`

Add this file to your project root to define your documentation structure:

```yaml
version: "1.0"
project:
  name: "My Project"
documentation:
  root: "."
  sections:
    - id: "adr"
      path: "docs/adr"
      pattern: "*.md"
      frontmatter:
        required: [status, date, deciders]
    - id: "guides"
      path: "docs/guides"
      pattern: "*.md"
      frontmatter:
        required: [title]
    - id: "api"
      path: "docs/api"
      pattern: "*.md"
      frontmatter:
        required: [title, endpoint, method]
```

AI agents read this file to understand where to create docs and what frontmatter to include.

## Usage Is Optional

Skills and `.docsconfig.yaml` are entirely opt-in. DocMark works perfectly as a standalone reader without any AI integration.
