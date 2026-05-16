# JWT Patterns — HS256, Claims, Refresh Token Rotation

## Overview

This reference documents the JWT patterns used by the auth skill. It is stack-agnostic but provides concrete examples in Go where helpful.

## Signing Algorithm: HS256

HS256 (HMAC-SHA256) is the default symmetric signing algorithm.

- **Secret key:** MUST be ≥ 256 bits (32 bytes). Generate with `openssl rand -hex 32`.
- **Key storage:** `JWT_SECRET` environment variable. NEVER commit to source control.
- **Key rotation:** Support key rotation by accepting an array of secrets (try newest first, then fallback to previous).

```
Header:  { "alg": "HS256", "typ": "JWT" }
```

## Token Structure

### Access Token

Short-lived token authorizing API access.

**Payload (claims):**

```json
{
  "sub": "usr_01HXYZ...",
  "email": "joao@example.com",
  "tenant_id": "tenant_abc123",
  "role": "user",
  "exp": 1747412400,
  "iat": 1747411500,
  "jti": "tok_01HABC..."
}
```

| Claim | Type | Description |
|-------|------|-------------|
| `sub` | string | User ID — the subject of the token |
| `email` | string | User email address |
| `tenant_id` | string | Tenant scope for multi-tenant isolation |
| `role` | string | Authorization role (`user`, `admin`, `superadmin`) |
| `exp` | integer | Expiration time (Unix timestamp) |
| `iat` | integer | Issued-at time (Unix timestamp) |
| `jti` | string | Unique token ID for revocation/blacklist support |

**TTL:** 15 minutes (configurable via `JWT_EXPIRY`).

### Refresh Token

Long-lived token used to obtain new access tokens.

Two implementation strategies:

#### Strategy A: Opaque Token

- Generate a cryptographically random string (e.g., 256-bit hex).
- Store in database: `token_hash`, `user_id`, `expires_at`, `created_at`, `revoked_at`.
- On refresh: look up token, verify not revoked, verify not expired, issue new pair.

**Pros:** Fully revocable, no secret exposure if DB is compromised.
**Cons:** Requires DB lookup on every refresh.

#### Strategy B: JWT Refresh Token

- Same structure as access token but with longer TTL and a `type: "refresh"` claim.
- Store `jti` in database for revocation tracking.

**Pros:** Stateless verification.
**Cons:** Cannot fully revoke without a blacklist.

**Recommended:** Strategy A (opaque) for most use cases.

**TTL:** 7 days (configurable via `REFRESH_EXPIRY`).

## Refresh Token Rotation

Every refresh call produces a **new token pair**. The old refresh token is invalidated.

```
Client                         Server
  |                              |
  |--- POST /auth/refresh ----->|
  |    { refresh_token: "old" } |
  |                              |
  |                              |-- Verify "old" token
  |                              |-- Invalidate "old" token (mark used/revoked)
  |                              |-- Generate new access_token
  |                              |-- Generate new refresh_token
  |                              |
  |<-- 200 OK ------------------|
  |    { access_token,          |
  |      refresh_token: "new",  |
  |      expires_in }           |
```

### Rotation Rules

1. **Single use:** Each refresh token can only be used once.
2. **Invalidate on use:** Mark as revoked in database immediately after verification.
3. **Reuse detection:** If a revoked token is presented, revoke ALL refresh tokens for that user (potential theft — force re-login).
4. **Grace period (optional):** Allow a 60-second window where both old and new tokens work to handle race conditions from concurrent requests.

## Token Generation Pseudocode

```
function generateAccessToken(user):
  claims = {
    sub:      user.id,
    email:    user.email,
    tenant_id: user.tenant_id,
    role:     user.role,
    exp:      now() + JWT_EXPIRY,
    iat:      now(),
    jti:      randomUUID()
  }
  return JWT.sign(claims, JWT_SECRET, { algorithm: "HS256" })

function generateRefreshToken(user):
  token = randomBytes(32).hex()
  hash = sha256(token)           // store hash, not plaintext
  store in DB:
    token_hash: hash
    user_id:    user.id
    expires_at: now() + REFRESH_EXPIRY
    revoked_at: null
  return token                    // return plaintext to client
```

## Token Validation Pseudocode

```
function validateAccessToken(token):
  try:
    claims = JWT.verify(token, JWT_SECRET, { algorithms: ["HS256"] })
    if claims.exp < now():
      return Invalid("token expired")
    return claims
  catch:
    return Invalid("invalid token")

function validateRefreshToken(token):
  hash = sha256(token)
  record = DB.findRefreshTokenByHash(hash)
  if not record:
    return Invalid("token not found")
  if record.revoked_at:
    // Reuse detected! Revoke all tokens for this user
    DB.revokeAllRefreshTokens(record.user_id)
    return Invalid("token reuse detected — all sessions revoked")
  if record.expires_at < now():
    return Invalid("token expired")
  return record
```

## Security Considerations

- **Never store refresh tokens in plaintext.** Always hash (SHA-256) before storage.
- **Use constant-time comparison** when looking up tokens to prevent timing attacks.
- **Set `exp` claim** — never issue tokens without expiration.
- **Use `jti` for revocation** — maintain a lightweight revocation list if needed.
- **Transmit tokens only over HTTPS.**
- **Store tokens client-side carefully:**
  - Access token: in-memory only (JavaScript variable or memory store).
  - Refresh token: `HttpOnly`, `Secure`, `SameSite=Strict` cookie (preferred) or secure storage.
- **Do not log tokens** — mask or redact in application logs.

## Go (golang-jwt) Example

```go
import (
    "time"
    "github.com/golang-jwt/jwt/v5"
)

type TokenClaims struct {
    Sub      string `json:"sub"`
    Email    string `json:"email"`
    TenantID string `json:"tenant_id"`
    Role     string `json:"role"`
    jwt.RegisteredClaims
}

func GenerateAccessToken(user User, secret string, expiry time.Duration) (string, error) {
    now := time.Now()
    claims := TokenClaims{
        Sub:      user.ID,
        Email:    user.Email,
        TenantID: user.TenantID,
        Role:     user.Role,
        RegisteredClaims: jwt.RegisteredClaims{
            ExpiresAt: jwt.NewNumericDate(now.Add(expiry)),
            IssuedAt:  jwt.NewNumericDate(now),
            ID:        uuid.New().String(),
        },
    }
    token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
    return token.SignedString([]byte(secret))
}
```
