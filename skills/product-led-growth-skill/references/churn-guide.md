# Churn Guide — Diagnosticar e Matar o Churn Beast

> Capítulo 15 | Product-Led Growth — Wes Bush

## Por Que Churn é Crítico

- +5% retention = +25–95% de lucros
- -5% churn = **+73% de receita** vs empresa com +5% churn
- "Churn é o assassino silencioso" — Patrick Campbell

---

## Os 3 Tipos de Churn

### 1. Customer Churn (retroativo)
```
Customer Churn = (Churned Customers / Total Customers) × 100
```
Medianas: Enterprise 1–3%/ano | SMB 5–10%/mês
**Regra:** compare com seu próprio histórico, não benchmarks de mercado.

### 2. Revenue Churn (retroativo)
```
Revenue Churn = (Churned MRR / Total MRR) × 100
```
- 1% customer churn + perda do maior cliente = 40% revenue churn
- **Negativo churn** = expansion revenue supera churn = holy grail

### 3. Activity Churn (preditivo)
- Clientes que ainda não cancelaram mas já pararam de usar
- Des Traynor (Intercom): diário → semanal → mensal → "por que ainda pago?" → cancel
- Permite agir **antes** do cancelamento

---

## Calculando Activity Churn (5 passos de Derek Skaletsky / Sherlock)

**Step 1: Defina Engagement**
Liste ações que definem engajamento. Ex: B2B tool = projetos criados, tarefas completadas, membros adicionados.

**Step 2: Rastreie os Eventos**
Se ainda não rastreia: faça isso antes de qualquer outra coisa.

**Step 3: Pese Cada Evento**
Convidar usuário > logar. Criar projeto > completar tarefa.
Tabela: Evento | Peso | Freq (7 dias) | Score = Peso × Freq

**Step 4: Normalize os Scores (0–100)**
"Score 458" não significa nada. "Score 91" qualquer pessoa entende.
Use Winsorizing + função exponencial.

**Step 5: Torne Acionável**
1. Rank users → descubra power users, risk users, priorize CS
2. Score accounts → saúde do negócio, priorize upsell e churn risk
3. Overall product score → seu trabalho de produto está movendo engajamento?
4. Compare cohorts → free vs paid, novas vs antigas contas
5. Correlacione com outras métricas → engajamento vs LTV

---

## 10 Táticas para Matar o Churn

1. **Meça e nomeie um dono** — "Se é responsabilidade de todos, não é de ninguém"
2. **Comece clientes no pé direito** — onboarding robusto pós-conversão
3. **Elimine Ability Debt** — produto difícil de usar = churn certo
4. **Usage Review Emails** — lembre o cliente do valor que está recebendo
5. **Reafirme valor no invoicing** — cobrança = gatilho de cancelamento (veja Zapier)
6. **Churn-prevention campaigns** — remarketing para low activity score
7. **Processo de cancelamento robusto** — survey + ações automáticas por razão
8. **Tackle delinquent churn** — 20–40% do churn vem de cartões falhos (ProfitWell)
9. **Invista em Customer Success** — proativo (não reativo como support)
10. **Corrija o pricing** — per-user sem network effects inibe adoção → churn

---

## Processo de Cancelamento

Uma pergunta: *Por que você cancelou sua conta?*

| Resposta | Ação |
|---|---|
| Ainda avaliando | Extensão de trial |
| Não é fit | Nurture funnel |
| Muito complexo | Call com CS |
| Muito caro | Desconto pontual |
| Fui para concorrente | Top-of-funnel nurturing |

---

## Churn Negativo — O Santo Graal

Expansion revenue supera MRR perdido por churn.
Net Revenue Retention (NRR) > 100% = negócio cresce mesmo sem novos clientes.

---

## Referências
- Activity churn + onboarding: `bowling-alley.md`
- Usage review emails: `email-sequences.md`
- ARPU: `arpu-optimization.md`
- Sprint mensal: `triple-a-sprint.md`
