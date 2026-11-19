---
name: pagarme-v5
description: Use when integrating Pagar.me API v5 for payments (credit card, Pix, boleto), subscriptions, marketplace split, or any Brazilian payment flow. Guides operator/agent through auth, endpoint selection, request construction, and webhook handling.
version: 1.0.0
author: skills-blackhole
license: MIT
metadata:
  hermes:
    tags: [pagarme, payments, brazil, api, pix, credit-card, boleto, subscription, marketplace, webhook]
    related_skills: []
---

# Pagar.me API v5

## Goal

Complete operational reference for the Pagar.me API v5 — Brazilian payment gateway by Stone. Enables agents/operators to authenticate, construct requests, select correct endpoints, handle webhooks, and implement any payment flow (one-time, recurring, marketplace split).

## Scope

- Applies to: any project integrating Pagar.me v5 for payments
- API version: **V5 (2021-09-01)**
- Base URL: `https://api.pagar.me/core/v5`
- Covers: Auth, Orders, Charges, Customers, Cards, Subscriptions, Plans, Invoices, Recipients, Marketplace/Split, Webhooks, Transfers, Anticipations, Settlements
- Does NOT cover: Pagar.me Dashboard UI operations, v4 (legacy) API

## Quick Reference

### Authentication

**Method:** HTTP Basic Auth

```
Authorization: Basic base64(SecretKey + ":")
```

- User = your Secret Key, Password = empty
- Sandbox key prefix: `sk_test_*` / `pk_test_*`
- Production key prefix: `sk_*` / `pk_*`
- Same base URL for both sandbox and production — the key type determines the environment
- **Never expose Secret Key client-side** — use Public Key (`pk_*`) for Checkout/Tokenization

```bash
# Example with curl
curl -u "sk_test_abc123:" https://api.pagar.me/core/v5/customers \
  -H "Content-Type: application/json"
```

### HTTP Status Codes

- `200` OK — Success
- `400` Bad Request — Invalid request
- `401` Unauthorized — Invalid API key
- `403` Forbidden — IP/Domain blocked
- `404` Not Found — Resource does not exist
- `412` Precondition Failed — Valid params but request failed
- `422` Unprocessable Entity — Invalid params (check `errors` field)
- `429` Too Many Requests — Rate limit exceeded
- `500` Internal Server Error — Pagar.me server error

### Error Response Format

```json
{
  "message": "The request is invalid.",
  "errors": {
    "order.customer.name": ["The name field is required."],
    "card.number": ["The number field is not a valid card number"]
  }
}
```

### Pagination

List endpoints accept `page`, `size`, and `status` query params.
Default page size varies by endpoint. Use `size` to control results per page.

### Common Headers

```
Content-Type: application/json
Authorization: Basic <base64(secretKey:)>
```

## Operational CLI (mise + curl)

Read-only debug CLI for operators and agents. Source: [`.agents/skills/pagarme-v5/scripts/pagarme.sh`](scripts/pagarme.sh).

### Prerequisites

1. Install [mise](https://mise.jdx.dev/) and run `mise install` (installs `argc` + `jq` when using repo `mise.toml`).
2. Configure env (any file with `SKILL_PAGARME_V5_*`, or `--env-file`):
   - `SKILL_PAGARME_V5_SECRET_KEY` — required (never pass as CLI flag)
   - `SKILL_PAGARME_V5_BASE_URL` — optional (default `https://api.pagar.me`; `/core/v5` appended automatically)
   - Only `SKILL_PAGARME_V5_*` keys are read from the env file — no database or worker vars are loaded.

### Quick start

```bash
mise run pagarme -- ping
mise run pagarme -- order get or_abc123
mise run pagarme -- payable list --charge-id=ch_xyz --size=10
bash .agents/skills/pagarme-v5/scripts/pagarme.sh --help
```

Full task ↔ endpoint map: [`reference/cli-tasks.md`](reference/cli-tasks.md).

### Safety

- Phase 1 is **GET-only** (no capture, cancel, or create).
- Init logs sandbox (`sk_test_*`) vs production (`sk_*`) key prefix on stderr.
- **No database** — only `SKILL_PAGARME_V5_*` env vars are loaded; no application worker or ORM dependency.

## Domain Groups & Routing

### When operator asks about...

Read-only inspection: use [`reference/cli-tasks.md`](reference/cli-tasks.md) (canonical command map). Integration flows: [`reference/routing-matrix.md`](reference/routing-matrix.md).

| Intent | Domain Group | Reference |
|--------|-------------|-----------|
| Create/manage buyers | Clientes | `reference/endpoint-map.md` → Clientes |
| Store cards, tokenize | Cartões | `reference/endpoint-map.md` → Cartões |
| Shipping addresses | Endereços | `reference/endpoint-map.md` → Endereços |
| Process payment (one-time) | Pedidos + Cobranças | `reference/endpoint-map.md` → Pedidos, Cobranças |
| Credit card / Pix / Boleto | Pagamentos | `reference/endpoint-map.md` → Pedidos |
| Recurring billing | Planos + Assinaturas + Faturas | `reference/endpoint-map.md` → Recorrência |
| Split payments between sellers | Marketplace → Split | `reference/endpoint-map.md` → Marketplace |
| Onboard sellers, manage payouts | Recebedores | `reference/endpoint-map.md` → Recebedores |
| Track receivables, balance | Financeiro | `reference/endpoint-map.md` → Financeiro |
| Receive payment notifications | Webhooks | `reference/endpoint-map.md` → Webhooks |
| Antifraud | Antifraude | `reference/endpoint-map.md` → Antifraude |
| Payment links (no code) | Link de Pagamento | `reference/endpoint-map.md` → Link de Pagamento |
| Early payout (anticipation) | Antecipações | `reference/endpoint-map.md` → Antecipações |
| Transfer between accounts | Transferências | `reference/endpoint-map.md` → Transferências |
| Settlement reports | Liquidações | `reference/endpoint-map.md` → Liquidações |
| BIN lookup (card info) | BIN | `reference/endpoint-map.md` → BIN |
| Tokenize card (client-side) | Tokenização | `reference/endpoint-map.md` → Tokenização |

## Payment Methods

### Cartão de Crédito (Credit Card)

Order with credit card payment:

```json
{
  "items": [
    {
      "amount": 1000,
      "description": "Product A",
      "quantity": 1
    }
  ],
  "customer": {
    "name": "João Silva",
    "email": "joao@example.com",
    "document": "12345678900",
    "type": "individual",
    "phones": { "mobile_phone": { "country_code": "55", "area_code": "11", "number": "999999999" } }
  },
  "payments": [
    {
      "payment_method": "credit_card",
      "credit_card": {
        "card": {
          "number": "4000000000000010",
          "holder_name": "JOAO SILVA",
          "exp_month": 12,
          "exp_year": 2027,
          "cvv": "123"
        },
        "operation_type": "auth_and_capture",
        "installments": 1
      }
    }
  ]
}
```

**Or use a saved card token:**

```json
"credit_card": {
  "card_id": "card_abc123",
  "operation_type": "auth_and_capture",
  "installments": 3
}
```

### Pix

```json
"payments": [
  {
    "payment_method": "pix",
    "pix": {
      "expires_in": 3600
    }
  }
]
```

Response includes `qr_code`, `qr_code_url`, `expires_at`.

### Boleto

```json
"payments": [
  {
    "payment_method": "boleto",
    "boleto": {
      "instructions": ["Pay until due date"],
      "due_at": "2026-06-15T23:59:59-03:00",
      "document_number": "123456"
    }
  }
]
```

Response includes `line`, `pdf`, `barcode`.

### Other Methods

- **Voucher** — meal/food vouchers (VR, Sodexo)
- **Google Pay™** — via tokenized card
- **Cash** — confirm manually via `POST /charges/{id}/confirm-payment`
- **SafetyPay** — bank transfer (international)
- **Cartão private label** — store-branded cards
- **Cartão de débito** — debit cards (requires authentication flow)

## Key Objects

### Order (Pedido)

Core entity. An order contains `items`, `customer`, `payments` (charges).
Statuses: `created`, `paid`, `canceled`, `failed`, `closed`

### Charge (Cobrança)

Individual payment attempt within an order. One order can have multiple charges.
Statuses: `pending`, `paid`, `failed`, `canceled`, `processing`, `chargedback`, `refunded`, `overpaid`, `underpaid`, `partial_canceled`

### Customer (Cliente)

Buyer entity. Required fields: `name`, `email`, `document`, `type` (`individual` or `company`).
PSP integration requires `phones` object.

### Subscription (Assinatura)

Recurring billing. Two types:
- **Assinatura de Plano** — linked to a pre-defined Plan
- **Assinatura Avulsa** — standalone, no plan needed

### Recipient (Recebedor)

Seller/sub-merchant in marketplace. Has bank account, transfer settings, anticipation config.

## Webhook Events

Register webhook URL via Dashboard or API (`POST /webhooks`).

### Key Events

**Orders:** `order.created`, `order.paid`, `order.payment_failed`, `order.canceled`, `order.closed`, `order.updated`
**Charges:** `charge.created`, `charge.paid`, `charge.payment_failed`, `charge.refunded`, `charge.pending`, `charge.processing`, `charge.chargedback`, `charge.underpaid`, `charge.overpaid`, `charge.partial_canceled`
**Subscriptions:** `subscription.created`, `subscription.canceled`
**Invoices:** `invoice.created`, `invoice.paid`, `invoice.payment_failed`, `invoice.canceled`
**Customers:** `customer.created`, `customer.updated`
**Cards:** `card.created`, `card.updated`, `card.deleted`, `card.expired`

### Webhook Security

Validate webhook signature using the `Signature` header (HMAC-SHA256 with your hub secret).

### Webhook Management Endpoints

- `POST /webhooks` — Create webhook subscription
- `GET /webhooks` — List webhooks
- `GET /webhooks/{id}` — Get webhook details

## Tokenization (Client-Side)

**Pagar.me JS (Tokenizecard):** Frontend library for secure card tokenization.
**Direct API:** `POST /tokens` with card data — returns `token_id` for use in orders.

## Marketplace / Split

Split payment across multiple recipients at order creation:

- `POST /orders` with split rules in payment object
- `POST /charges/{id}/capture` with split for auth-and-capture flow
- `DEL /charges/{id}` with split for cancellation refunds

Split rules define: `recipient_id`, `amount` (cents), `type` (`flat` or `percentage`), `options` (charge_processing_fee, liable, charge_remainder).

## Recebedores (Recipients) — Seller Onboarding

1. `POST /recipients` — Create recipient with KYB data
2. `POST /recipients/{id}/kyc-link` — Generate KYC proof-of-life link
3. `PATCH /recipients/{id}/bank-account` — Update bank details
4. `GET /recipients/{id}/balance` — Check balance
5. `PATCH /recipients/{id}/transfer-settings` — Configure auto-transfer
6. `PATCH /recipients/{id}/anticipation-settings` — Configure anticipation

## Anti-Fraud

`POST /orders` with anti-fraud provider (ClearSale, Konduto) integration.
Additional fields: `antifraud_enabled: true`, `review`, provider-specific fields.

## PSP vs Gateway Integration

- **PSP** (Payment Service Provider): Pagar.me processes the full payment. Requires `phones` on customer.
- **Gateway**: Pagar.me routes to your acquirer. Less data requirements.
- Your integration type affects required fields — confirm with Pagar.me support.

## Common Pitfalls

1. **Forgetting `phones` on customer (PSP)** — Returns 422: "At least one customer phone is required."
2. **Amount in cents** — All monetary values are in **cents** (R$ 10,00 = 1000).
3. **Using wrong key type** — `sk_test_*` hits sandbox, `sk_*` hits production. Same URL.
4. **Missing Basic Auth colon** — Must be `base64(secretKey + ":")` — password is empty, not omitted.
5. **Card token expiry** — Card tokens expire quickly (~minutes). Use immediately or save `card_id` instead.
6. **Not handling async payments** — Pix and Boleto are async; rely on webhooks, not API response.
7. **422 errors** — Always check the `errors` object for field-specific messages.
8. **Installments** — `installments: 1` = upfront (à vista). For installment plans, set the count.
9. **Split requires recipient_id** — All recipients must exist before creating split orders.

## Verification Checklist

- [ ] Using correct base URL: `https://api.pagar.me/core/v5`
- [ ] Auth header: `Basic base64(secretKey:)`
- [ ] Amount in cents (multiply by 100)
- [ ] Customer has `name`, `email`, `document`, `type`, and `phones` (PSP)
- [ ] Async payments (Pix/Boleto) have webhook handler
- [ ] Sandbox testing with `sk_test_*` key before production
- [ ] Card data never touches your server (use tokenization)
- [ ] Webhook signature validation implemented

## References

- Official API Docs: https://docs.pagar.me/reference/introdução-1
- API Reference: https://docs.pagar.me/reference/getting-started-with-your-api
- Endpoint map: `reference/endpoint-map.md`
- Ops CLI tasks: `reference/cli-tasks.md`
- Scripts: `scripts/pagarme.sh`, `mise.toml` (`mise run pagarme -- …`)
