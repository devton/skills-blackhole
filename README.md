# skills-blackhole

Repository of agentic workflow skills generated from the [agentic-workflow-blueprint](https://github.com/devton/agentic-workflow-blueprint).

Each skill is a scoped, agent-oriented documentation contract for a specific technology or flow. Agents load only what they need — less tokens, more precision.

## Structure

```
skills-blackhole/
  blueprint/                   ← agentic-workflow-blueprint (template + reference)
  skills/
    <technology>/              ← one folder per skill
      SKILL.md                 ← contract: Goal, Scope, Triggers, Procedure, Outputs, Review gate
      reference/               ← progressive disclosure (optional)
      workflows/               ← chained workflows (optional)
  README.md
```

## How it works

1. **Blueprint** defines the contract format and scaffolding procedure.
2. Pick a technology/flow → generate a skill following the blueprint.
3. Each skill is self-contained: inputs, outputs, invariants, procedure, review gate.
4. Agents classify the task → load the right skill → execute deterministically.

## Adding a new skill

```bash
# From this repo root, trigger the blueprint:
# Provide: projectSlug, techStack, workflowsWanted, constraints
# The agent scaffolds skills/<slug>/ with contracts and wires everything.
```

## Available skills

<!-- Add entries as skills are created -->

## License

MIT
