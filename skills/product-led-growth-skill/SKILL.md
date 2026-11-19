---
name: product-led-growth
description: Use when designing or optimizing a PLG SaaS strategy.
version: 1.0.0
author: Hermes Agent
tags: [PLG, SaaS, growth, freemium, onboarding, pricing, churn, ARPU]
---

# Product-Led Growth — Skill Orquestrador

> Baseado integralmente no livro **Product-Led Growth: How to Build a Product That Sells Itself** — Wes Bush (Product-Led Institute, 2019)

## O que é PLG

Product-Led Growth é uma **estratégia go-to-market** que usa o produto como principal veículo para adquirir, ativar e reter clientes.
- Produto como #1 canal de aquisição
- Usuário experimenta valor **antes** de comprar
- Cada time (marketing, sales, CS, eng) se orienta pelo produto

Diferença crucial:
- **Sales-led**: leva o comprador de A→B no seu ciclo de vendas
- **Product-led**: leva o comprador de A→B na **vida dele**

---

## Classificação do Pedido (Orquestrador)

| Situação | Referência |
|---|---|
| Decidir entre Free Trial / Freemium / Demo | `references/moat-framework.md` |
| Construir a fundação da estratégia PLG | `references/ucd-framework.md` |
| Definir value metric e precificação | `references/value-metrics.md` + `references/pricing-strategy.md` |
| Melhorar onboarding / conversão free→paid | `references/bowling-alley.md` |
| Processo mensal de otimização | `references/triple-a-sprint.md` |
| Aumentar ARPU | `references/arpu-optimization.md` |
| Reduzir churn | `references/churn-guide.md` |
| Montar sequência de email de onboarding | `references/email-sequences.md` |

---

## Command Routing `/plg <cmd>`

| cmd | Referência |
|---|---|
| `moat` | Escolher modelo PLG (Free Trial / Freemium / Demo) |
| `ucd` | Construir fundação: Entender, Comunicar, Entregar valor |
| `metrics` | Value metrics + precificação |
| `bowling` | Bowling Alley Framework (onboarding + bumpers) |
| `sprint` | Triple A Sprint (Analyze → Ask → Act) |
| `arpu` | Aumentar Average Revenue Per User |
| `churn` | Diagnosticar e matar o churn |
| `emails` | Templates e sequências de email de onboarding |

---

## Os 3 Tsunamis (contexto estratégico)

1. **CAC subindo** — +55% em 5 anos; willingness-to-pay caindo -30%
2. **Buyer auto-educa** — 3 em 4 compradores B2B preferem auto-serviço a sales
3. **Produto = parte essencial do processo de compra** — Netflix, Slack, Dropbox

---

## Frameworks centrais

### MOAT (Capítulos 2–6)
- **M**arket Strategy (Dominant / Disruptive / Differentiated)
- **O**cean Conditions (Red / Blue)
- **A**udience (Top-down / Bottom-up)
- **T**ime-to-Value
→ `references/moat-framework.md`

### UCD — Fundação PLG (Capítulos 7–11)
- **U**nderstand your value (3 outcomes: Functional, Emotional, Social)
- **C**ommunicate your value (pricing page)
- **D**eliver on your value (eliminar value gaps e ability debt)
→ `references/ucd-framework.md`

### Triple A Sprint (Capítulo 12)
1. **Analyze** — 6 macro outputs
2. **Ask** — Onde ir? Qual alavanca? Qual input?
3. **Act** — ICE Score (Impact, Confidence, Ease)
→ `references/triple-a-sprint.md`

### Bowling Alley Framework (Capítulo 13)
- Straight Line + Product Bumpers + Conversational Bumpers
- 9 tipos de email em 3 tracks
→ `references/bowling-alley.md`

### As 3 Alavancas
```
Churn > ARPU > # Customers
```

---

## Hard Rules

- Nunca adotar PLG sem saber **por que as pessoas compram**
- Freemium exige TAM grande; niche pequeno → sales-led
- Blue ocean complexo → sales-led primeiro
- Freemium ≠ free trial indefinido
- Churn é prioridade sobre aquisição. Sempre.

---

## Referências

- `references/moat-framework.md`
- `references/ucd-framework.md`
- `references/value-metrics.md`
- `references/pricing-strategy.md`
- `references/bowling-alley.md`
- `references/triple-a-sprint.md`
- `references/arpu-optimization.md`
- `references/churn-guide.md`
- `references/email-sequences.md`
- `templates/moat-decision-quiz.md`
- `templates/value-metric-scratch-pad.md`
- `templates/straight-line-audit.md`
- `templates/triple-a-sprint-template.md`
