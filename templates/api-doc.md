---
title: "Endpoint Name"
endpoint: "/api/v1/resource"
method: GET
auth_required: true
deprecated: false
---

# Endpoint Name

## Description

Brief description of what this endpoint does and when to use it.

## Request

### Endpoint

```
GET /api/v1/resource
```

### Headers

| Header | Required | Description |
|--------|----------|-------------|
| Authorization | Yes | Bearer token for authentication |
| Content-Type | Yes | application/json |

### Query Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| param1 | string | Yes | Description of param1 |
| param2 | integer | No | Description of param2 |

### Request Body

```json
{
  "field1": "value",
  "field2": 123
}
```

## Response

### Success Response (200 OK)

```json
{
  "status": "success",
  "data": {
    "id": "123",
    "field1": "value",
    "field2": 123
  }
}
```

### Response Fields

| Field | Type | Description |
|-------|------|-------------|
| status | string | Response status |
| data | object | Response data object |

## Errors

| Status Code | Description |
|-------------|-------------|
| 400 | Bad Request - Invalid parameters |
| 401 | Unauthorized - Invalid or missing authentication |
| 404 | Not Found - Resource does not exist |
| 500 | Internal Server Error |

### Error Response Example

```json
{
  "status": "error",
  "message": "Error description",
  "code": "ERROR_CODE"
}
```

## Example

```bash
curl -X GET "https://api.example.com/api/v1/resource?param1=value" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json"
```
