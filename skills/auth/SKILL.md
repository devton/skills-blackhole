---
name: auth
description: Reusable authentication API contract — email/password login returning JWT tokens. Covers registration, login, refresh token rotation, and auth middleware. Usable by any backend (Golang/Gorilla Mux, Node, etc.) and frontend. Stack reference: Golang + CouchDB.
version: 1.0.0
author: skills-blackhole
license: MIT
metadata:
  hermes:
    tags: [auth, jwt, authentication, login, register, refresh-token, bcrypt, middleware, couchdb, golang]
    related_skills: []
---

# Auth — Login/Senha → JWT

## Goal

Provide a stack-agnostic, reusable API contract for email+password authentication that issues JWT access tokens and refresh tokens, covering registration, login, token refresh, user info, and auth middleware — consumable by any backend or frontend project.

## Scope

- Applies to: any project that needs email/password authentication with JWT
- Covers: user registration, login (email+senha → JWT), refresh token rotation, authenticated user info endpoint, auth middleware
- Does NOT cover: OAuth2/Social login, password reset flows, email verification, role-based access control beyond the `role` claim, multi-factor authentication (MFA)

## Triggers

- "Implement authentication"
- "Add login/signup API"
- "Set up JWT auth"
- "Create auth middleware"
- "Integrate auth with CouchDB"
- "Need refresh token rotation"

## Inputs

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `JWT_SECRET` | env var | yes | Secret key for signing JWT tokens (HS256) |
| `JWT_EXPIRY` | env var | no | Access token TTL (default: `15m`) |
| `REFRESH_EXPIRY` | env var | no | Refresh token TTL (default: `7d`) |
| `BCRYPT_COST` | env var | no | bcrypt cost factor (default: `12`) |
| `DATABASE_URL` | env var | yes | Database connection string |
| `TENANT_ID` | context | no | Tenant identifier for multi-tenant systems |

## Outputs

### REST API Endpoints

#### `POST /auth/register`

Register a new user.

**Request:**

```json
{
  "name": "João Silva",
  "email": "joao@example.com",
  "password": "S3cur3P@ss!",
  "tenant_id": "tenant_abc123"
}
```

**Response `201 Created`:**

```json
{
  "user": {
    "id": "usr_01HXYZ...",
    "name": "João Silva",
    "email": "joao@example.com",
    "tenant_id": "tenant_abc123",
    "role": "user",
    "created_at": "2026-05-16T16:30:00Z"
  },
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIs...",
  "expires_in": 900
}
```

**Error `409 Conflict`:** email already registered
**Error `422 Unprocessable Entity`:** validation failure (email format, password strength)

#### `POST /auth/login`

Authenticate with email and password.

**Request:**

```json
{
  "email": "joao@example.com",
  "password": "S3cur3P@ss!"
}
```

**Response `200 OK`:**

```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIs...",
  "expires_in": 900,
  "token_type": "Bearer"
}
```

**Error `401 Unauthorized`:** invalid credentials

#### `POST /auth/refresh`

Exchange a valid refresh token for a new token pair (rotation).

**Request:**

```json
{
  "refresh_token": "eyJhbGciOiJIUzI1NiIs..."
}
```

**Response `200 OK`:**

```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIs...",
  "expires_in": 900,
  "token_type": "Bearer"
}
```

**Error `401 Unauthorized`:** invalid or expired refresh token

> **Rotation:** the old refresh token is invalidated and a new one is issued on every refresh call.

#### `GET /auth/me`

Return the authenticated user's profile. Requires `Authorization: Bearer <access_token>` header.

**Response `200 OK`:**

```json
{
  "id": "usr_01HXYZ...",
  "name": "João Silva",
  "email": "joao@example.com",
  "tenant_id": "tenant_abc123",
  "role": "user",
  "created_at": "2026-05-16T16:30:00Z"
}
```

**Error `401 Unauthorized`:** missing or invalid token

## Invariants (guardrails)

1. **Password hashing:** All passwords MUST be hashed with bcrypt (cost ≥ 12) before storage. Plaintext passwords MUST NEVER be stored or logged.
2. **JWT signing:** Tokens MUST be signed with HS256 using a cryptographically secure secret (`JWT_SECRET` ≥ 256 bits).
3. **JWT claims — mandatory fields:**
   - `sub` (subject) → `user_id`
   - `email` → user email
   - `tenant_id` → tenant scope
   - `role` → authorization role (`user`, `admin`, etc.)
   - `exp` → expiry timestamp (Unix epoch)
   - `iat` → issued-at timestamp
   - `jti` → unique token identifier (for revocation support)
4. **Refresh token rotation:** On every `POST /auth/refresh`, the old refresh token MUST be invalidated and a new one issued. Refresh tokens MUST be single-use.
5. **Access token TTL:** Default 15 minutes. MUST be short-lived.
6. **Refresh token TTL:** Default 7 days. MUST be longer than access token.
7. **Middleware injection:** Auth middleware MUST extract user identity from the verified JWT and inject it into the request context (not modify the request body).
8. **No secrets in URLs:** Tokens MUST be transmitted via `Authorization` header or request body — never in query strings.
9. **HTTPS only:** All auth endpoints MUST only be served over HTTPS in production.
10. **Rate limiting:** `POST /auth/login` and `POST /auth/register` MUST be rate-limited to prevent brute-force attacks.

## Procedure

### 1) Registration (`POST /auth/register`)

1. Validate input: email format, password strength (≥ 8 chars, mixed case + digit), required fields.
2. Check for existing user with same email. Return `409 Conflict` if found.
3. Hash password with bcrypt (`BCRYPT_COST` or 12).
4. Create user record in database with: `id`, `name`, `email`, `password_hash`, `tenant_id`, `role` (default: `"user"`), `created_at`, `updated_at`.
5. Generate JWT access token with claims: `sub`, `email`, `tenant_id`, `role`, `exp`, `iat`, `jti`.
6. Generate refresh token (opaque or JWT) and store it in database linked to user.
7. Return `201 Created` with user object, tokens, and `expires_in`.

### 2) Login (`POST /auth/login`)

1. Validate input: email and password are present.
2. Look up user by email. Return `401 Unauthorized` if not found.
3. Compare password with stored bcrypt hash. Return `401 Unauthorized` if mismatch.
4. Generate new JWT access token with claims.
5. Generate new refresh token, store it, invalidate any previous refresh tokens for this user (optional: keep N most recent).
6. Return `200 OK` with tokens and `expires_in`.

### 3) Refresh Token (`POST /auth/refresh`)

1. Validate input: `refresh_token` is present.
2. Verify refresh token signature and expiry. Return `401` if invalid.
3. Look up refresh token in database. Return `401` if not found or already used.
4. **Invalidate** the consumed refresh token (delete or mark used).
5. Generate new access token + new refresh token (rotation pair).
6. Store new refresh token in database.
7. Return `200 OK` with new token pair.

### 4) Auth Middleware

1. Extract `Authorization` header from incoming request.
2. Verify format: `Bearer <token>`. Return `401` if missing or malformed.
3. Parse and validate JWT: verify signature (`JWT_SECRET`), check `exp` is in the future.
4. Extract claims: `sub` (user_id), `email`, `tenant_id`, `role`.
5. Inject claims into request context:
   - Go: `context.WithValue(r.Context(), userCtxKey, claims)`
   - Node/Express: `req.user = decoded`
   - Generic: set a typed context object accessible to downstream handlers.
6. Call next handler. If token is invalid, return `401 Unauthorized` with no body details (prevent information leakage).

### 5) Get Current User (`GET /auth/me`)

1. Middleware runs first — user context is available.
2. Extract user_id from context.
3. Fetch user from database by ID.
4. Return `200 OK` with user profile (exclude `password_hash` and any internal fields).

## Review Gate (must pass)

- [ ] All 4 endpoints documented with request/response examples
- [ ] Password is never stored or returned in plaintext
- [ ] JWT contains all mandatory claims (`sub`, `email`, `tenant_id`, `role`, `exp`, `iat`, `jti`)
- [ ] Refresh token rotation is implemented (old token invalidated on use)
- [ ] Middleware injects user into request context, never into body
- [ ] Rate limiting documented for login and register endpoints
- [ ] HTTPS-only invariant is documented
- [ ] Error responses use appropriate HTTP status codes (401, 409, 422)
- [ ] All secrets come from environment variables, not hardcoded
- [ ] Reference docs link correctly to `reference/jwt-patterns.md` and `reference/couchdb-auth.md`

## References

- JWT patterns (HS256, claims, refresh rotation): [reference/jwt-patterns.md](reference/jwt-patterns.md)
- CouchDB auth reference (user docs, design docs): [reference/couchdb-auth.md](reference/couchdb-auth.md)
- RFC 7519 — JSON Web Token: https://tools.ietf.org/html/rfc7519
- OWASP Auth Cheat Sheet: https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html
