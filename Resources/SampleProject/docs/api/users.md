---
title: "Users API"
endpoint: "/api/users"
method: "GET"
auth_required: true
---

# Users API

## Description

Retrieve a list of users or a specific user by ID.

## Endpoints

### List Users

```
GET /api/users
```

Returns a paginated list of all users.

**Query Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `page` | integer | No | Page number (default: 1) |
| `limit` | integer | No | Items per page (default: 20, max: 100) |
| `sort` | string | No | Sort field (`name`, `created_at`) |

**Response:**

```json
{
  "data": [
    {
      "id": "usr_abc123",
      "name": "Jane Smith",
      "email": "jane@example.com",
      "created_at": "2026-01-15T10:30:00Z"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 42
  }
}
```

### Get User

```
GET /api/users/:id
```

Returns a single user by ID.

**Response:**

```json
{
  "id": "usr_abc123",
  "name": "Jane Smith",
  "email": "jane@example.com",
  "role": "admin",
  "created_at": "2026-01-15T10:30:00Z",
  "updated_at": "2026-02-01T14:20:00Z"
}
```

## Error Responses

| Status | Code | Description |
|--------|------|-------------|
| 401 | `unauthorized` | Missing or invalid authentication |
| 403 | `forbidden` | Insufficient permissions |
| 404 | `not_found` | User does not exist |
| 429 | `rate_limited` | Too many requests |

**Error Response Format:**

```json
{
  "error": {
    "code": "not_found",
    "message": "User with ID 'usr_xyz' does not exist"
  }
}
```
