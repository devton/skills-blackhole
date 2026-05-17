---
name: sim-ai-block-system
description: Declarative BlockConfig architecture for Sim Studio AI — defines WHAT each block does via config, resolved by executor handlers through a central registry of 20+ block types and 180+ tool integrations.
version: 1.0.0
author: skills-blackhole
license: MIT
metadata:
  hermes:
    tags: [sim-ai, blocks, registry, tools, executor, visual-editor, blockconfig]
    related_skills:
      - sim-ai
      - sim-ai-subblock-system
      - sim-ai-toolbar
      - sim-ai-block-node-canvas
---

## sim-ai.workflow.block-system

### Goal

Implement and maintain the declarative BlockConfig system where each block defines **WHAT** to do (configuration) while the executor resolves **HOW** to do it (handlers + tools), covering the registry, serializer, executor handlers, and tool mapping layer.

### Scope

- **Applies to:**
  - `BlockConfig` interface and all required/optional fields
  - Central block registry (`blocks/registry.ts`) and its public API
  - 20+ core block types (`blocks` category)
  - 10+ trigger block types (`triggers` category)
  - 180+ tool integration blocks (`tools` category)
  - `GenericBlockHandler` and specialized executor handlers
  - Provider pattern: `tools.config.tool()` / `tools.config.params()`
  - Block serializer (`blocks/serializer/`)
  - Block versioning (`file_v2`, `file_v3`, `file_v4`, etc.)
  - Adding new blocks or modifying existing block configs
  - Tool registry and tool implementation directories (`tools/`)
- **Does NOT cover:**
  - SubBlock types and UI rendering (see `workflows/subblock-system`)
  - Canvas rendering and ReactFlow integration (see `workflows/canvas-editor`)
  - Toolbar and panel UI (see `workflows/toolbar`)
  - Block node visual rendering (see `workflows/block-node-canvas`)

### Triggers

- "Define a new block" / "Add a new block type"
- "Register a block in the registry"
- "Modify block config" / "Change block fields"
- "Add a tool integration" / "Create a new tool block"
- "Fix block execution" / "Debug handler routing"
- "Update tools registry" / "Map tool to block"
- Working on `blocks/registry.ts`
- Working on `blocks/blocks/<block-name>/`
- Working on `tools/<tool-name>/`
- Working on `executor/handlers/`
- Files matching `blocks/types.ts`, `blocks/serializer/`

### Inputs

- `blockType` — unique string identifier for the block (e.g. `'agent'`, `'slack'`)
- `category` — `'blocks'` | `'tools'` | `'triggers'`
- `subBlocks` — array of `SubBlockConfig[]` defining the configuration UI
- `tools` — `{ access: string[]; config?: { tool, params } }` mapping to executor
- `inputs` / `outputs` — schemas for block data flow
- `integrationType` — optional classification (AI, CRM, Databases, etc.)

### Invariants

- **Declarative principle:** Blocks define configuration only; execution logic lives in handlers and tools. Never embed execution code in a block config.
- **Registry is the source of truth:** All blocks must be registered in `blocks/registry.ts`. No inline block definitions.
- **GenericBlockHandler fallback:** 95%+ of tool blocks are served by `GenericBlockHandler` via `tools.config`. Only add a specialized handler when the generic path is insufficient.
- **Version coexistence:** Versioned blocks (e.g. `file_v2`, `file_v3`, `file_v4`) must all remain in the registry for backward compatibility with existing workflows.
- **Type normalization:** Registry lookups normalize `-` to `_` (e.g. `get-block` → `get_block`).
- **Provider pattern:** `tools.config.tool(params)` returns a tool ID (may be dynamic based on `operation`); `tools.config.params(params)` transforms inputs before passing to the tool.

### Procedure

#### 1. Understand the execution flow

```
BlockConfig (declarative)
    ↓ Serializer (blocks/serializer/)
SerializedBlock { id, config: { tool, params }, inputs, outputs }
    ↓ BlockExecutor
BlockHandler.canHandle(block)? → handler.execute(ctx, block, inputs)
    ↓ GenericBlockHandler (fallback)
tools.config.tool(params) → tool ID → executeTool(toolId, inputs)
```

Every block flows through: **config → serialize → handler → tool**.

#### 2. Use the registry API

The central registry (`blocks/registry.ts`, ~538 lines) is a `Record<string, BlockConfig>` with direct string lookup:

- `getBlock(type)` — lookup by type string (normalizes `-` → `_`)
- `getLatestBlock(baseType)` — resolves to the newest version (e.g. `file` → `file_v4`)
- `getBlockByToolName(toolName)` — reverse lookup from tool name to block
- `getBlocksByCategory(category)` — filter by `'blocks'` | `'tools'` | `'triggers'`
- `getAllBlockTypes()` — all registry keys
- `isValidBlockType(type)` — type guard

#### 3. Define a new block config

Follow this pattern when creating a new block:

```typescript
// 1. blocks/blocks/<block_name>.ts
export const MyBlock: BlockConfig<MyResponse> = {
  type: 'my_block',
  name: 'My Block',
  description: 'Does something useful',
  category: 'tools',
  integrationType: IntegrationType.DeveloperTools,
  bgColor: '#FF5733',
  icon: MyIcon,
  subBlocks: [
    { id: 'operation', type: 'dropdown', options: [{ label: 'Create', id: 'create' }] },
    { id: 'credential', type: 'oauth-input', serviceId: 'my-service', mode: 'basic' },
  ],
  tools: {
    access: ['my_tool_create'],
    config: {
      tool: (params) => `my_tool_${params.operation}`,
      params: (params) => ({ ...params }),
    },
  },
  inputs: { operation: { type: 'string' }, credential: { type: 'string' } },
  outputs: { result: { type: 'string' } },
}
```

**Required fields:** `type`, `name`, `description`, `category`, `bgColor`, `icon`, `subBlocks`, `tools`, `inputs`, `outputs`

**Important optional fields:**
- `integrationType` — AI, CRM, Databases, etc.
- `tags` — filtering labels
- `docsLink` — documentation URL
- `authMode` — OAuth | ApiKey | BotToken
- `triggerAllowed` — can this block be a trigger
- `singleInstance` — one instance per workflow
- `hideFromToolbar` — hidden (legacy/infra)
- `triggers` — `{ enabled: boolean; available: string[] }`

#### 4. Register the block

```typescript
// blocks/registry.ts
import { MyBlock } from '@/blocks/blocks/my_block'
registry.my_block = MyBlock
```

#### 5. Implement the tool

Create the tool implementation in `tools/my_tool/`. The `GenericBlockHandler` resolves `tools.config` automatically — no custom handler needed for most tool blocks.

#### 6. Handle executor routing

The executor uses a handler chain. Each handler implements `canHandle(block)` and `execute(ctx, block, inputs)`:

- **TriggerBlockHandler** — Triggers: starts a workflow
- **AgentBlockHandler** — Agent: LLM + tools + memory loop
- **FunctionBlockHandler** — Function: JS/Python sandbox
- **ApiBlockHandler** — API: HTTP requests
- **ConditionBlockHandler** — Condition: boolean branching
- **RouterBlockHandler** — Router: intelligent routing
- **ResponseBlockHandler** — Response: API response
- **HumanInTheLoopBlockHandler** — HITL: approval pause
- **GenericBlockHandler** — All tool blocks: fallback that resolves `tools.config.tool` → `executeTool()`

The `tools.config` bridge:
- `tool(params)` → returns the tool ID (can be dynamic via `operation`)
- `params(params)` → transforms inputs before passing to the tool

#### 7. Version a block

When evolving a block, create a versioned entry:

- Name: `file_v2`, `file_v3`, `file_v4`, etc.
- Use `createVersionedToolSelector()` to map operations → tool IDs with `_v2` suffix
- `getLatestBlock('file')` returns the newest version
- Keep all versions in registry for backward compatibility

### Outputs

- Block config file in `blocks/blocks/<name>.ts`
- Registry entry in `blocks/registry.ts`
- Tool implementation in `tools/<tool_name>/`
- (Optional) Custom executor handler in `executor/handlers/`

### Review gate

- [ ] Block follows the declarative principle: config only, no execution logic
- [ ] All required `BlockConfig` fields are present (`type`, `name`, `description`, `category`, `bgColor`, `icon`, `subBlocks`, `tools`, `inputs`, `outputs`)
- [ ] Block is registered in `blocks/registry.ts`
- [ ] `tools.config.tool()` and `tools.config.params()` are correctly mapped
- [ ] `GenericBlockHandler` is used unless a specialized handler is justified
- [ ] Versioned blocks preserve backward compatibility
- [ ] Registry API functions handle the new block correctly
- [ ] No modifications to out-of-scope areas (SubBlock UI, canvas, toolbar)

### References

- Parent skill: [../SKILL.md](../../SKILL.md)
- Block types map: [reference/block-types-map.md](reference/block-types-map.md)
- SubBlock system: [../subblock-system/SKILL.md](../subblock-system/SKILL.md)
- Architecture overview: [../../reference/architecture-overview.md](../../reference/architecture-overview.md)
