# CouchDB Auth Reference — User Docs, Design Docs

## Overview

This reference documents how to store and query authentication data in Apache CouchDB, specifically for the auth skill. It covers user document schema, design docs for lookups, refresh token storage, and index patterns.

## Database: `_users` vs Dedicated DB

**Recommended:** Use a dedicated database (e.g., `auth_db`) rather than CouchDB's built-in `_users` DB. This gives full control over document schema, validation, and avoids conflicts with CouchDB's internal auth.

## User Document Schema

Each user is stored as a single document:

```json
{
  "_id": "usr_01HXYZ123456",
  "_rev": "1-abc...",
  "type": "user",
  "name": "João Silva",
  "email": "joao@example.com",
  "password_hash": "$2a$12$LJ3m4ys3Gzl0W9YW...",
  "tenant_id": "tenant_abc123",
  "role": "user",
  "active": true,
  "created_at": "2026-05-16T16:30:00Z",
  "updated_at": "2026-05-16T16:30:00Z",
  "metadata": {}
}
```

| Field | Type | Description |
|-------|------|-------------|
| `_id` | string | User ID with prefix `usr_` (user-friendly) or UUID |
| `type` | string | Always `"user"` — for Mango queries filtering by type |
| `name` | string | Full display name |
| `email` | string | Unique email address (lowercase, trimmed) |
| `password_hash` | string | bcrypt hash — NEVER store plaintext |
| `tenant_id` | string | Tenant scope for multi-tenant isolation |
| `role` | string | Authorization role (`user`, `admin`, `superadmin`) |
| `active` | boolean | Soft-disable flag — set `false` to block without deleting |
| `created_at` | string | ISO 8601 timestamp |
| `updated_at` | string | ISO 8601 timestamp (update on every mutation) |
| `metadata` | object | Extensible field for app-specific data |

## Refresh Token Document Schema

Store refresh tokens as separate documents for independent lifecycle management:

```json
{
  "_id": "refresh_01HABC...",
  "_rev": "1-abc...",
  "type": "refresh_token",
  "user_id": "usr_01HXYZ123456",
  "token_hash": "a3f2b8c1d4e5f6...",
  "expires_at": "2026-05-23T16:30:00Z",
  "revoked_at": null,
  "created_at": "2026-05-16T16:30:00Z",
  "device_info": "Mozilla/5.0 ..."
}
```

| Field | Type | Description |
|-------|------|-------------|
| `_id` | string | Token ID with prefix `refresh_` |
| `type` | string | Always `"refresh_token"` |
| `user_id` | string | Reference to user document `_id` |
| `token_hash` | string | SHA-256 hash of the plaintext refresh token |
| `expires_at` | string | ISO 8601 expiration timestamp |
| `revoked_at` | string or null | ISO 8601 when revoked, or `null` if active |
| `created_at` | string | ISO 8601 creation timestamp |
| `device_info` | string | Optional: user-agent or device identifier |

## Design Docs

### By Email (login lookup)

```json
{
  "_id": "_design/auth",
  "views": {
    "by_email": {
      "map": "function(doc) { if (doc.type === 'user' && doc.email) { emit(doc.email.toLowerCase(), { id: doc._id, name: doc.name, role: doc.role, tenant_id: doc.tenant_id, active: doc.active }); } }"
    }
  }
}
```

**Query:**
```
GET /auth_db/_design/auth/_view/by_email?key=%22joao@example.com%22
```

### By Tenant (tenant-scoped user listing)

```json
{
  "_id": "_design/auth",
  "views": {
    "by_tenant": {
      "map": "function(doc) { if (doc.type === 'user' && doc.tenant_id) { emit([doc.tenant_id, doc.role], { id: doc._id, name: doc.name, email: doc.email, role: doc.role }); } }"
    }
  }
}
```

**Query:**
```
GET /auth_db/_design/auth/_view/by_tenant?startkey=[%22tenant_abc123%22]&endkey=[%22tenant_abc123%22,{}]
```

### Refresh Tokens by User

```json
{
  "_id": "_design/auth",
  "views": {
    "refresh_by_user": {
      "map": "function(doc) { if (doc.type === 'refresh_token') { emit([doc.user_id, doc.revoked_at === null ? 0 : 1], { id: doc._id, expires_at: doc.expires_at, revoked_at: doc.revoked_at }); } }"
    }
  }
}
```

**Query active tokens for a user:**
```
GET /auth_db/_design/auth/_view/refresh_by_user?startkey=[%22usr_01HXYZ123456%22,0]&endkey=[%22usr_01HXYZ123456%22,0]
```

### Refresh Token by Hash

```json
{
  "_id": "_design/auth",
  "views": {
    "refresh_by_hash": {
      "map": "function(doc) { if (doc.type === 'refresh_token' && doc.token_hash) { emit(doc.token_hash, { user_id: doc.user_id, expires_at: doc.expires_at, revoked_at: doc.revoked_at }); } }"
    }
  }
}
```

**Query:**
```
GET /auth_db/_design/auth/_view/refresh_by_hash?key=%22a3f2b8c1d4e5f6...%22
```

## Mango Queries (Alternative to Views)

CouchDB 2.0+ supports Mango queries for ad-hoc lookups:

### Find user by email

```json
{
  "selector": {
    "type": "user",
    "email": "joao@example.com"
  },
  "fields": ["_id", "name", "email", "password_hash", "role", "tenant_id", "active"]
}
```

### Find active refresh tokens for user

```json
{
  "selector": {
    "type": "refresh_token",
    "user_id": "usr_01HXYZ123456",
    "revoked_at": null
  },
  "fields": ["_id", "token_hash", "expires_at", "created_at"]
}
```

## Go (Kivik) Integration Example

```go
import (
    "github.com/go-kivik/kivik/v3"
    "context"
)

type UserDB struct {
    db *kivik.DB
}

func (u *UserDB) FindByEmail(ctx context.Context, email string) (*User, error) {
    row := u.db.Get(ctx, "user:"+email) // alternative: use _design/auth/_view/by_email
    var user User
    if err := row.ScanDoc(&user); err != nil {
        return nil, err
    }
    return &user, nil
}

func (u *UserDB) StoreRefreshToken(ctx context.Context, token RefreshToken) error {
    _, err := u.db.Put(ctx, token.ID, token)
    return err
}

func (u *UserDB) RevokeAllUserTokens(ctx context.Context, userID string) error {
    rows := u.db.Query(ctx, "_design/auth", "refresh_by_user",
        kivik.Options{"startkey": []string{userID, "0"}, "endkey": []string{userID, "0"}})
    for rows.Next() {
        var rev string
        doc, _ := rows.Value()
        doc.Scan(&rev)
        // Update each token's revoked_at
    }
    return rows.Err()
}
```

## Common Operations

### Create User

1. Generate `usr_` prefixed ID (UUID or ULID).
2. Hash password with bcrypt.
3. Normalize email: `strings.ToLower(strings.TrimSpace(email))`.
4. Store document in CouchDB.
5. Handle `409 Conflict` — email uniqueness is enforced by the view/lookup, not CouchDB natively. Check with `by_email` view before inserting.

### Login Flow

1. Query `by_email` view with normalized email.
2. If no result → return `401`.
3. Compare bcrypt hash: `bcrypt.CompareHashAndPassword([]byte(hash), []byte(inputPassword))`.
4. If mismatch → return `401`.
5. Generate tokens, store refresh token doc, return response.

### Refresh Token Cleanup

Run a periodic cleanup (cron/scheduler) to remove expired refresh tokens:

```json
{
  "selector": {
    "type": "refresh_token",
    "expires_at": { "$lt": "2026-05-16T16:30:00Z" }
  }
}
```

Delete matching documents in bulk.

## Invariants

- Email MUST be normalized to lowercase before storage and lookup.
- Password hash field MUST NEVER be included in API responses.
- Refresh token lookup MUST use the SHA-256 hash, never the plaintext token.
- User `_id` SHOULD use a prefix (`usr_`) to avoid conflicts with refresh token docs.
- Design docs SHOULD be version-controlled and deployed alongside application code.
