---
name: docmark
description: Follow DocMark documentation standards when creating or editing docs, changelogs, ADRs, API documentation, or guides. Activates when the user asks to document, update docs, add changelog entries, create ADRs, or when .docsconfig.yaml is present.
---

# DocMark Documentation Standard

This skill helps follow the DocMark documentation structure defined in `.docsconfig.yaml`. It provides a standardized approach to project documentation with consistent frontmatter schemas, templates, and organization patterns.

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

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- New features go here

### Changed
- Changes to existing functionality

### Deprecated
- Soon-to-be removed features

### Removed
- Removed features

### Fixed
- Bug fixes

### Security
- Security fixes

## [1.0.0] - YYYY-MM-DD

### Added
- Initial release
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

### Headers

```
Authorization: Bearer <token>
Content-Type: application/json
```

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| id | string | Yes | Resource identifier |

### Example Request

```bash
curl -X GET https://api.example.com/api/v1/resource/123 \
  -H "Authorization: Bearer <token>"
```

## Response

### Success Response (200 OK)

```json
{
  "id": "123",
  "name": "Example",
  "created_at": "2026-02-15T10:00:00Z"
}
```

### Response Fields

| Field | Type | Description |
|-------|------|-------------|
| id | string | Resource identifier |
| name | string | Resource name |
| created_at | string | ISO 8601 timestamp |

## Errors

| Status Code | Description |
|-------------|-------------|
| 400 | Bad Request - Invalid parameters |
| 401 | Unauthorized - Invalid or missing token |
| 404 | Not Found - Resource does not exist |
| 500 | Internal Server Error |

### Error Response Example

```json
{
  "error": "Resource not found",
  "code": "NOT_FOUND"
}
```
```

## Examples

### Example 1: Creating an ADR

User request: "Create an ADR for switching to PostgreSQL"

Steps:
1. Check for `.docsconfig.yaml`
2. Create `docs/adr/0001-switch-to-postgresql.md`
3. Use ADR template with filled frontmatter:

```markdown
---
status: proposed
date: 2026-02-15
deciders: [Engineering Team]
---

# Switch to PostgreSQL

## Context

Our current SQLite database is reaching scalability limits as our user base grows. We need a more robust solution that supports concurrent writes and better query performance.

## Decision

We will migrate from SQLite to PostgreSQL for our production database.

## Consequences

**Positive:**
- Better concurrent write performance
- Advanced query capabilities (JSON, full-text search)
- Industry-standard tooling and support

**Negative:**
- Increased infrastructure complexity
- Migration effort required
- Higher operational costs
```

### Example 2: Updating Changelog

User request: "Add changelog entry for new authentication feature"

Steps:
1. Open `CHANGELOG.md`
2. Add entry under `[Unreleased]` > `### Added`:

```markdown
## [Unreleased]

### Added
- OAuth2 authentication support for third-party integrations
```

### Example 3: Creating API Documentation

User request: "Document the user creation endpoint"

Steps:
1. Create `docs/api/create-user.md`
2. Use API template with complete details:

```markdown
---
title: Create User
endpoint: /api/v1/users
method: POST
auth_required: true
---

# Create User

## Description

Creates a new user account in the system.

## Request

### Headers

```
Authorization: Bearer <token>
Content-Type: application/json
```

### Body

```json
{
  "email": "user@example.com",
  "name": "John Doe",
  "role": "member"
}
```

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| email | string | Yes | User email address |
| name | string | Yes | User full name |
| role | string | No | User role (default: member) |

## Response

### Success Response (201 Created)

```json
{
  "id": "usr_123",
  "email": "user@example.com",
  "name": "John Doe",
  "role": "member",
  "created_at": "2026-02-15T10:00:00Z"
}
```

## Errors

| Status Code | Description |
|-------------|-------------|
| 400 | Bad Request - Invalid email or missing required fields |
| 401 | Unauthorized - Invalid or missing token |
| 409 | Conflict - Email already exists |
```

## Notes

- Always check for `.docsconfig.yaml` first before creating documentation
- If no configuration exists, use the default paths and templates provided here
- Prefer creating new files over editing existing ones unless explicitly updating
- Maintain consistency with existing documentation style in the project
- ADR numbers should be sequential (check existing ADRs for the next number)
- Keep changelog entries concise but descriptive
- API documentation should include realistic examples
