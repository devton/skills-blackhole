# Pagar.me v5 — Routing Matrix

Task → Endpoint Group mapping for agent routing.

## Ops CLI (read-only debug)

Before manual curl or code changes, prefer the CLI when inspecting existing resources (`mise install` then `mise run pagarme -- ping`).

**Canonical command map:** [`cli-tasks.md`](./cli-tasks.md) — do not duplicate subcommand tables here.

## Payment Flows

### "I need to charge a customer once"
→ **Pedidos** → `POST /orders`
0. Debug existing: `mise run pagarme -- order get {id}`, `mise run pagarme -- charge get {id}`
1. Create/retrieve Customer
2. Create Order with items + payment method
3. If async (Pix/Boleto): listen for `order.paid` webhook
4. If sync (Credit Card): check response status

### "I need recurring billing"
→ **Planos + Assinaturas + Faturas**
1. Create Plan (`POST /plans`) — if not exists
2. Create Subscription (`POST /subscriptions`) linked to plan
3. Invoices auto-generate per cycle
4. Listen for `invoice.paid` / `invoice.payment_failed` webhooks

### "I need to split payments between sellers"
→ **Marketplace / Split**
0. Debug recipient: `mise run pagarme -- recipient get {id}`
1. Create Recipients (`POST /recipients`)
2. Create Order with split rules (`POST /orders` with split)
3. Each recipient gets their share automatically

### "I need to tokenize a card"
→ **Tokenização**
1. Frontend: Use Pagar.me JS (Tokenizecard)
2. Backend alternative: `POST /tokens`
3. Use returned `token_id` in Order creation

### "I need to create a payment link (no code)"
→ **Link de Pagamento**
1. `POST /checkouts` — creates hosted payment page
2. Share the URL with customer
3. Listen for webhooks

### "I need early payout"
→ **Antecipações**
1. `GET /anticipations/limits` — check available limit
2. `GET /anticipations/spot-simulation` — simulate cost
3. `POST /anticipations` — create anticipation

### "I need to transfer funds"
→ **Transferências**
0. Debug: `mise run pagarme -- transfer list`, `mise run pagarme -- transfer get {id}`
1. `POST /transfers` — initiate transfer
2. Listen for confirmation webhook

### "I need to reconcile payables / import"
→ **Payables**
0. `mise run pagarme -- payable list --charge-id={ch}` or `--recipient-id={re}`
1. Cross-check with `mise run pagarme -- order get {or}` for charge_id
2. See [endpoint-map.md](./endpoint-map.md) → Payables

## CRUD Quick Routes

| Resource | Create | Read | Update | Delete | List |
|----------|--------|------|--------|--------|------|
| Customer | `POST /customers` | `GET /customers/{id}` | `PUT /customers/{id}` | — | `GET /customers` |
| Card | `POST /customers/{id}/cards` | `GET /customers/{id}/cards/{id}` | `PUT ...cards/{id}` | `DELETE ...cards/{id}` | `GET ...cards` |
| Address | `POST ...addresses` | `GET ...addresses/{id}` | `PUT ...addresses/{id}` | `DELETE ...addresses/{id}` | `GET ...addresses` |
| Order | `POST /orders` | `GET /orders/{id}` | — | — | `GET /orders` |
| Charge | (auto via Order) | `GET /charges/{id}` | `PATCH /charges/{id}/*` | `DELETE /charges/{id}` | `GET /charges` |
| Payable | — | `GET /payables/{id}` | — | — | `GET /payables` |
| Plan | `POST /plans` | `GET /plans/{id}` | `PUT /plans/{id}` | `DELETE /plans/{id}` | `GET /plans` |
| Subscription | `POST /subscriptions` | `GET /subscriptions/{id}` | `PATCH /subscriptions/{id}/*` | `DELETE /subscriptions/{id}` | `GET /subscriptions` |
| Invoice | `POST .../invoices` | `GET /invoices/{id}` | `PATCH /invoices/{id}/metadata` | `DELETE /invoices/{id}` | `GET /invoices` |
| Recipient | `POST /recipients` | `GET /recipients/{id}` | `PUT /recipients/{id}` | — | `GET /recipients` |
| Payment Link | `POST /checkouts` | `GET /checkouts/{id}` | `PATCH /checkouts/{id}/*` | `PATCH .../cancel` | `GET /checkouts` |
| Webhook | `POST /webhooks` | `GET /webhooks/{id}` | — | — | `GET /webhooks` |
| Transfer | `POST /transfers` | `GET /transfers/{id}` | — | `POST .../cancel` | `GET /transfers` |
| Anticipation | `POST /anticipations` | `GET /anticipations/{id}` | — | `POST .../cancel` | `GET /anticipations` |
