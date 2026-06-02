# Pagar.me API v5 — Complete Endpoint Map

All endpoints use base URL: `https://api.pagar.me/core/v5`
Auth: Basic Auth `base64(secretKey:)`

## Clientes (Customers)

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/customers` | Create customer |
| GET | `/customers/{id}` | Get customer by ID |
| PUT | `/customers/{id}` | Update customer |
| GET | `/customers` | List customers |

**Required fields (create):** `name`, `email`, `document`, `type` (`individual` or `company`)
**PSP also requires:** `phones.mobile_phone` with `country_code`, `area_code`, `number`

## Cartões (Cards)

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/customers/{id}/cards` | Create card for customer |
| GET | `/customers/{id}/cards/{card_id}` | Get card |
| GET | `/customers/{id}/cards` | List customer cards |
| PUT | `/customers/{id}/cards/{card_id}` | Update card |
| DELETE | `/customers/{id}/cards/{card_id}` | Delete card |
| POST | `/customers/{id}/cards/{card_id}/renew` | Renew expired card |
| POST | `/tokens` | Create card token (use client-side) |

## Endereços (Addresses)

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/customers/{id}/addresses` | Create address |
| GET | `/customers/{id}/addresses/{address_id}` | Get address |
| PUT | `/customers/{id}/addresses/{address_id}` | Update address |
| GET | `/customers/{id}/addresses` | List addresses |
| DELETE | `/customers/{id}/addresses/{address_id}` | Delete address |

## BIN

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/bins/{bin}` | Get BIN info (first 6-8 digits of card) |

## Pedidos (Orders)

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/orders` | Create order (single payment method) |
| POST | `/orders/{id}/charges` | Add charge to existing order |
| POST | `/orders` (multimeios) | Create order with multiple payment methods |
| POST | `/orders` (multicompradores) | Create order with multiple buyers |
| GET | `/orders/{id}` | Get order |
| PATCH | `/orders/{id}/closed` | Close order |
| GET | `/orders` | List orders |

### Item do Pedido (Order Items)

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/orders/{id}/items` | Add item to order |
| PUT | `/orders/{id}/items/{item_id}` | Update order item |
| DELETE | `/orders/{id}/items/{item_id}` | Delete order item |
| DELETE | `/orders/{id}/items` | Remove all items |
| GET | `/orders/{id}/items/{item_id}` | Get order item |

## Cobranças (Charges)

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/charges/{id}/capture` | Capture authorized charge |
| GET | `/charges/{id}` | Get charge |
| PATCH | `/charges/{id}/card` | Update charge card |
| PATCH | `/charges/{id}/due-date` | Update charge due date |
| PATCH | `/charges/{id}/payment-method` | Update charge payment method |
| DELETE | `/charges/{id}` | Cancel charge |
| GET | `/charges` | List charges |
| POST | `/charges/{id}/retry` | Retry failed charge manually |
| POST | `/charges/{id}/confirm-payment` | Confirm cash payment |

## Antifraude (Anti-Fraud)

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/orders` (with antifraud) | Create order with anti-fraud analysis |

Fields: `antifraud_enabled: true`, provider config (ClearSale, Konduto)

## Link de Pagamento (Payment Links)

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/checkouts` | Create payment link |
| GET | `/checkouts/{id}` | Get payment link |
| GET | `/checkouts` | List payment links |
| PATCH | `/checkouts/{id}/activate` | Activate draft payment link |
| PATCH | `/checkouts/{id}/cancel` | Cancel payment link |

## Planos (Plans)

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/plans` | Create plan |
| GET | `/plans/{id}` | Get plan |
| PATCH | `/plans/{id}/metadata` | Update plan metadata |
| PUT | `/plans/{id}` | Update plan |
| DELETE | `/plans/{id}` | Delete plan |
| GET | `/plans` | List plans |

### Precificação (Pricing)

Types: `Unidade` (unit), `Pacote` (package), `Volume` (volume tiers), `Faixa` (range tiers)

### Item do Plano (Plan Items)

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/plans/{id}/items` | Add plan item |
| PUT | `/plans/{id}/items/{item_id}` | Update plan item |
| DELETE | `/plans/{id}/items/{item_id}` | Remove plan item |

## Assinaturas (Subscriptions)

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/subscriptions` (avulsa) | Create standalone subscription |
| POST | `/subscriptions` (plano) | Create plan-based subscription |
| GET | `/subscriptions/{id}` | Get subscription |
| GET | `/subscriptions` | List subscriptions |
| DELETE | `/subscriptions/{id}` | Cancel subscription |
| PATCH | `/subscriptions/{id}/card` | Update subscription card |
| PATCH | `/subscriptions/{id}/metadata` | Update subscription metadata |
| PATCH | `/subscriptions/{id}/payment-method` | Update payment method |
| PATCH | `/subscriptions/{id}/start-at` | Update start date |
| PATCH | `/subscriptions/{id}/minimum-price` | Update minimum price |
| POST | `/subscriptions/{id}/manual-billing` | Enable manual billing |
| DELETE | `/subscriptions/{id}/manual-billing` | Disable manual billing |

### Item da Assinatura (Subscription Items)

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/subscriptions/{id}/items` | Add subscription item |
| GET | `/subscriptions/{id}/items` | List subscription items |
| PUT | `/subscriptions/{id}/items/{item_id}` | Update subscription item |
| DELETE | `/subscriptions/{id}/items/{item_id}` | Remove subscription item |

### Uso (Usage Tracking)

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/subscriptions/{id}/items/{item_id}/usages` | Record usage |
| DELETE | `/subscriptions/{id}/items/{item_id}/usages/{usage_id}` | Remove usage |
| GET | `/subscriptions/{id}/items/{item_id}/usages` | List usage |

### Desconto (Discounts)

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/subscriptions/{id}/discounts` | Add discount |
| GET | `/subscriptions/{id}/discounts/{id}` | Get discount |
| GET | `/subscriptions/{id}/discounts` | List discounts |
| DELETE | `/subscriptions/{id}/discounts/{id}` | Remove discount |

### Incremento (Increments)

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/subscriptions/{id}/increments` | Add increment |
| GET | `/subscriptions/{id}/increments/{id}` | Get increment |
| GET | `/subscriptions/{id}/increments` | List increments |
| DELETE | `/subscriptions/{id}/increments/{id}` | Remove increment |

## Faturas (Invoices)

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/subscriptions/{id}/invoices` | Create invoice |
| GET | `/invoices/{id}` | Get invoice |
| GET | `/invoices` | List invoices |
| PATCH | `/invoices/{id}/metadata` | Update invoice metadata |
| DELETE | `/invoices/{id}` | Cancel invoice |

## Ciclos (Cycles)

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/subscriptions/{id}/cycles/{id}/retry` | Retry cycle |
| GET | `/cycles/{id}` | Get cycle |
| GET | `/subscriptions/{id}/cycles` | List cycles |

## Split na Recorrência (Subscription Split)

| Method | Endpoint | Description |
|--------|----------|-------------|
| PATCH | `/subscriptions/{id}/split` | Update split rules for subscription |

## Recebedores (Recipients)

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/recipients` | Create recipient |
| POST | `/recipients/{id}/kyc-link` | Generate KYC proof-of-life link |
| PUT | `/recipients/{id}` | Update recipient |
| GET | `/recipients/{id}` | Get recipient |
| GET | `/recipients` | List recipients |
| PATCH | `/recipients/{id}/code` | Update recipient code |

### Conta Bancária (Bank Account)

| Method | Endpoint | Description |
|--------|----------|-------------|
| PATCH | `/recipients/{id}/bank-account` | Update recipient bank account |

### Saldo (Balance)

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/recipients/{id}/balance` | Get recipient balance |

### Configurações de Transferência

| Method | Endpoint | Description |
|--------|----------|-------------|
| PATCH | `/recipients/{id}/transfer-settings` | Update transfer settings |

### Configurações de Antecipação Automática

| Method | Endpoint | Description |
|--------|----------|-------------|
| PATCH | `/recipients/{id}/anticipation-settings` | Update anticipation settings |

## Marketplace / Split

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/orders` (with split) | Create order with split rules |
| POST | `/charges/{id}/capture` (with split) | Capture with split |
| DELETE | `/charges/{id}` (with split) | Cancel with split |

### Res.264/349 — Seller Interface

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/recipients/{id}/urs` | Get URs for recipient |
| GET | `/contracts/effects` | Get contract effects |
| GET | `/contracts` | Get contracts |
| GET | `/contests` | Get contests |
| POST | `/contracts/{id}/contest` | Contest a contract |

## Webhooks

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/webhooks` | Create webhook subscription |
| GET | `/webhooks/{id}` | Get webhook |
| GET | `/webhooks` | List webhooks |

### Webhook Events (Complete List)

**Customers:** `customer.created`, `customer.updated`
**Cards:** `card.created`, `card.updated`, `card.deleted`, `card.expired`
**Addresses:** `address.created`, `address.updated`, `address.deleted`
**Plans:** `plan.created`, `plan.updated`, `plan.deleted`
**Plan Items:** `plan_item.created`, `plan_item.updated`, `plan_item.deleted`
**Subscriptions:** `subscription.created`, `subscription.canceled`
**Subscription Items:** `subscription_item.created`, `subscription_item.updated`, `subscription_item.deleted`
**Discounts:** `discount.created`, `discount.deleted`
**Increments:** `increment.created`, `increment.deleted`
**Orders:** `order.created`, `order.paid`, `order.payment_failed`, `order.canceled`, `order.closed`, `order.updated`
**Order Items:** `order_item.created`, `order_item.updated`, `order_item.deleted`
**Invoices:** `invoice.created`, `invoice.updated`, `invoice.paid`, `invoice.payment_failed`, `invoice.canceled`
**Charges:** `charge.created`, `charge.updated`, `charge.paid`, `charge.payment_failed`, `charge.refunded`, `charge.pending`, `charge.processing`, `charge.underpaid`, `charge.overpaid`, `charge.partial_canceled`, `charge.chargedback`
**Usage:** `usage.created`, `usage.deleted`
**Recipients:** `recipient.created`, `recipient.updated`

## Financeiro

### Payables (reconciliation)

Marketplace receivables / payables import. Official docs: [Retornando recebíveis](https://docs.pagar.me/reference/retornando-recebiveis).

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/payables` | List payables |
| GET | `/payables/{id}` | Get payable by ID |

**Query params (`GET /payables`):** `recipient_id`, `charge_id`, `status`, `start_date`, `end_date`, `page`, `size`

**Note:** Accepts `charge_id`, not `order_id`. Resolve charge from `GET /orders/{id}` → `charges[0].id`.

**CLI:** see [`cli-tasks.md`](./cli-tasks.md) (`payable list`, `payable get`).

### Recebíveis (Receivables)

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/receivables` | List receivables |

### Operações de Saldo (Balance Operations)

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/balance/operations` | List balance operations |
| GET | `/balance/operations/{id}` | Get specific balance operation |

## Antecipações (Anticipations)

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/anticipations` | Create anticipation |
| GET | `/anticipations/spot-simulation` | Simulate spot anticipation |
| GET | `/anticipations/limits` | Get anticipation limits |
| POST | `/anticipations/{id}/cancel` | Cancel pending anticipation |
| GET | `/anticipations` | List anticipations |

## Liquidações (Settlements)

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/settlements/payments` | List settlement payments |
| GET | `/settlements/payments/recipient/{id}` | List by recipient |
| GET | `/settlements/payments/{id}` | Get specific settlement |

## Transferências (Transfers)

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/transfers` | Create transfer |
| GET | `/transfers` | List transfers |
| GET | `/transfers/{id}` | Get transfer |
| POST | `/transfers/{id}/cancel` | Cancel transfer |
| POST | `/transfers/{id}/receipt` | Get transfer receipt |
