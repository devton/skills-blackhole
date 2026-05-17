# skills-blackhole

Repository of agentic workflow skills. Each skill is a scoped, agent-oriented documentation contract for a specific technology or flow — agents load only what they need.

Built on the [agentic-workflow-blueprint](https://github.com/devton/agentic-workflow-blueprint) contract format.

## Structure

```
skills-blackhole/
  blueprint/                   ← agentic-workflow-blueprint (template + reference)
  skills/
    <technology>/
      SKILL.md                 ← entry point: goal, scope, auth, routing, pitfalls
      reference/               ← progressive disclosure: endpoint maps, routing matrices
      workflows/               ← chained workflows (optional)
  README.md
```

## How it works

1. **Blueprint** defines the contract format (Goal → Scope → Triggers → Procedure → Outputs → Review gate).
2. Pick a technology/flow → generate a skill following the blueprint.
3. Each skill is self-contained: the agent classifies the task → loads the right skill → executes deterministically.

## Available Skills

- **Pagar.me v5** (`skills/pagarme/v5/`) — Brazilian payment gateway (Stone). Full API v5 reference: auth, credit card, Pix, boleto, subscriptions, marketplace split, webhooks, recipients, anti-fraud. ~100 endpoints mapped.
- **Sim Studio AI** (`skills/sim-ai/`) — Open-source agent workflow platform with visual canvas editor (ReactFlow). Orchestrator skill routing to 7 sub-skill workflows: block system, toolbar, subblock system, block node canvas, canvas editor, knowledge/RAG, MCP integration. v0.6.84.

## Adding a new skill

Use the blueprint as template:

1. Read `blueprint/SKILL.md` for the scaffolding procedure.
2. Create `skills/<tech>/SKILL.md` following the contract format.
3. Add `reference/` files for progressive disclosure (endpoint maps, routing matrices).
4. Update the **Available Skills** list above.
5. Commit.

## License

MIT
