---
name: sim-ai-canvas-editor
description: ReactFlow canvas with Zustand workflow store, subflow containers (Loop 4 types + Parallel), auto-layout engine, and serializer — the visual editing layer that manages workflow state for Sim Studio AI.
version: 1.0.0
author: skills-blackhole
license: MIT
metadata:
  hermes:
    tags: [sim-ai, canvas, react-flow, editor, subflow, zustand, auto-layout, serializer, sentinel-blocks]
    related_skills:
      - sim-ai
      - sim-ai-block-system
      - sim-ai-subblock-system
      - sim-ai-block-node-canvas
      - sim-ai-toolbar
---

## sim-ai.workflow.canvas-editor

### Goal

Implement and maintain the ReactFlow-based canvas editor that manages workflow state through a centralized Zustand store (`useWorkflowStore`), supporting subflow containers (Loop/Parallel), auto-layout positioning, and block-to-execution serialization.

### Scope

- **Applies to:**
  - `useWorkflowStore` (Zustand) — main workflow state: blocks, edges, loops, parallels
  - `useSubBlockStore` — decoupled sub-block value store (performance optimization)
  - `useWorkflowRegistry` — workflow CRUD and metadata
  - `useExecutionStore` — execution state (running blocks, logs, outputs)
  - `usePanelStore` / `usePanelEditorStore` — panel tab, width, editor state
  - Subflow containers:
    - Loop — 4 types: `for` (fixed count), `forEach` (collection iteration), `while` (boolean condition), `doWhile` (execute-then-check)
    - Parallel — 2 types: `count` (N branches), `collection` (batch by size)
  - Auto-layout engine (`lib/workflows/autolayout/`) — top-down positioning, change-set animation
  - Serializer (`serializer/index.ts`) — `BlockState[]` + `Edge[]` → `SerializedWorkflow`
  - Sentinel blocks — invisible executor markers (`__loop_start__` / `__loop_end__`, `__parallel_start__` / `__parallel_end__`)
  - Panel editor (`panel/components/editor/`) — dynamic SubBlock rendering per selected block
  - SubflowNode component — custom ReactFlow node for Loop/Parallel containers
- **Does NOT cover:**
  - Block config definitions and registry (see `workflows/block-system`)
  - SubBlock types, conditions, and rendering logic (see `workflows/subblock-system`)
  - Block node visual rendering, handles, dimensions (see `workflows/block-node-canvas`)
  - Toolbar and search panel (see `workflows/toolbar`)

### Triggers

- "Fix canvas behavior" / "Canvas not updating" / "ReactFlow rendering issue"
- "Modify workflow store" / "Add store action" / "Change Zustand state"
- "Add subflow support" / "Loop container" / "Parallel container"
- "Auto-layout" / "Arrange blocks" / "Fix layout"
- "Serialize workflow" / "SerializedBlock" / "Pre-execution validation"
- "Sentinel blocks" / "Loop start/end markers"
- Working on `stores/workflows/`
- Working on `lib/workflows/autolayout/`
- Working on `serializer/`
- Working on `executor/utils/subflow-utils.ts`
- Working on `subflows/subflow-node.tsx`
- Files matching `workflow/store.ts`, `autolayout/core.ts`, `serializer/index.ts`

### Inputs

- `blocks` — `Record<string, BlockState>` (ID → block position, type, data, layout)
- `edges` — ReactFlow `Edge[]` (connections between blocks)
- `loops` — `Record<string, Loop>` (loop ID → type, count, collection config)
- `parallels` — `Record<string, Parallel>` (parallel ID → type, count, batch size)
- `BlockState` shape: `{ id, type, name, position, data (parentId, extent, enabled, width, height), layout, subBlocks }`
- Subflow parent-child via `data.parentId` and ReactFlow `extent: 'parent'`

### Invariants

- **Single source of truth:** All canvas state flows through `useWorkflowStore`. No local React state for blocks/edges.
- **Batch operations only:** Use `batchAddBlocks`, `batchRemoveBlocks`, `batchUpdatePositions` for atomic multi-block changes. Never mutate state directly.
- **Separated SubBlock store:** Sub-block values live in `useSubBlockStore` (decoupled from canvas state for performance). Always read sub-block values from the sub-block store, not from `BlockState`.
- **Subflow = ReactFlow parent:** Blocks inside a subflow container set `data.parentId = containerBlockId` and `extent: 'parent'`. Children cannot escape the container.
- **Sentinel blocks are invisible:** `__loop_start__<id>` / `__loop_end__<id>` and `__parallel_start__<id>` / `__parallel_end__<id>` exist only for the executor. They never appear on the canvas.
- **Auto-layout produces change-sets:** The layout engine returns position diffs (not absolute positions) to enable smooth animations. Never set positions directly from layout output.
- **Serializer validates before execution:** `WorkflowValidationError` must block execution if any block lacks a tool, has invalid params, or has missing connections.

### Procedure

#### 1. Store architecture

The canvas state is managed by a family of Zustand stores, each with a single responsibility:

- **`useWorkflowStore`** (`stores/workflows/workflow/store.ts`, ~500 lines) — Primary canvas state:
  - State: `currentWorkflowId`, `blocks`, `edges`, `loops`, `parallels`, `lastSaved`
  - Batch actions: `batchAddBlocks`, `batchRemoveBlocks`, `batchUpdatePositions`, `batchUpdateBlocksWithParent`, `batchAddEdges`, `batchRemoveEdges`, `batchToggleEnabled`
  - Single-block actions: `duplicateBlock(id)` (clone with offset + unique name), `updateBlockName`, `setBlockEnabled`, `setBlockHandles`, `setBlockAdvancedMode`, `setBlockTriggerMode`
  - Loop actions: `updateLoopCount`, `updateLoopType`, `updateLoopCollection`, `generateLoopBlocks()`
  - Parallel actions: `updateParallelCount`, `updateParallelBatchSize`, `updateParallelType`, `generateParallelBlocks()`

- **`useSubBlockStore`** (`stores/workflows/subblock/store.ts`) — Decoupled field-value store for performance.

- **`useWorkflowRegistry`** (`stores/workflows/registry/store.ts`) — Workflow list CRUD and metadata (not canvas state).

- **`useExecutionStore`** (`stores/workflows/execution/store.ts`) — Execution tracking: running blocks, logs, outputs.

- **`usePanelStore`** / **`usePanelEditorStore`** — Panel sidebar: active tab, width, editor state.

#### 2. Subflow system

Subflow containers are custom ReactFlow nodes that visually group child blocks:

- **Loop** (`type: 'loop'`) — blue container (`#2FB3FF`), `RepeatIcon` icon
- **Parallel** (`type: 'parallel'`) — yellow container (`#FEE12B`), `SplitIcon` icon

**Hierarchy:**
- Child blocks set `data.parentId = containerBlockId`
- ReactFlow `extent: 'parent'` constrains children within the container
- `batchUpdateBlocksWithParent()` moves blocks in/out of subflows

**Loop types:**
| Type | Behavior |
|------|----------|
| `for` | Fixed counter (loopCount) |
| `forEach` | Iterates over a collection |
| `while` | Boolean condition check before each iteration |
| `doWhile` | Executes at least once, then checks condition |

**Parallel types:**
| Type | Behavior |
|------|----------|
| `count` | N parallel branches |
| `collection` | Divides collection into batches (batchSize) |

**SubflowNode component** (`subflow-node.tsx`) renders:
- Header with icon + name + child-count badge
- Input handle (top) + output handle (bottom)
- Internal start/end handles (loop-start-source, loop-end-source)
- ActionBar (delete, duplicate, etc.)

#### 3. Auto-layout algorithm

**Path:** `lib/workflows/autolayout/`

| File | Function |
|------|----------|
| `core.ts` | Main algorithm — top-down position calculation |
| `change-set.ts` | Position diff for smooth animation |
| `constants.ts` | Spacing, offsets, layout options |
| `containers.ts` | Subflow container layout (resize on child add/remove) |
| `utils.ts` | Block metrics, snap-to-grid, position normalization |

**Algorithm steps:**
1. Prepare block metrics (measured width/height)
2. Build dependency graph from edges (parent → child)
3. Calculate positions top-down with vertical spacing
4. Subflow containers: compute child bounds + padding
5. Resolve overlaps through iteration
6. Return change-set for animated transition

**Trigger:** Canvas context menu → "Auto-layout" (`Shift+L`), via `use-auto-layout.ts` hook.

#### 4. Serializer

**Path:** `serializer/index.ts` (~300 lines)

Converts `BlockState[]` + `Edge[]` → `SerializedWorkflow` for execution:

```
BlockState + SubBlockValues
  ↓ For each block:
  │  1. getBlock(type) → BlockConfig
  │  2. Filter subBlocks by visibility/condition
  │  3. Resolve canonical params (basic/advanced mode)
  │  4. buildSubBlockValues() → params
  │  5. Resolve tools.config.tool(params) → tool ID
  │  6. Resolve tools.config.params(params) → transformed params
  ↓
SerializedBlock { id, name, type, config: { tool, params }, inputs, outputs }
  ↓
SerializedWorkflow { blocks: SerializedBlock[], edges }
```

`WorkflowValidationError` — pre-execution validation (block without tool, invalid params, missing connections).

#### 5. Sentinel blocks

Loop and Parallel containers use invisible sentinel blocks in the executor:

- `__loop_start__<id>` / `__loop_end__<id>`
- `__parallel_start__<id>` / `__parallel_end__<id>`

`subflow-utils.ts` provides helpers to build and identify sentinel IDs. Sentinels are never rendered on the canvas — they exist only in the serialized workflow for the executor.

### Outputs

- Updated workflow store state (blocks, edges, loops, parallels)
- Subflow container nodes with correct parent-child hierarchy
- Auto-layout change-set with new positions
- `SerializedWorkflow` ready for execution
- Sentinel block IDs for executor routing

### Review gate

- [ ] All canvas state changes go through `useWorkflowStore` batch actions (no direct mutation)
- [ ] Sub-block values are read from `useSubBlockStore`, not from `BlockState`
- [ ] Subflow children correctly set `data.parentId` and `extent: 'parent'`
- [ ] Loop type supports all 4 variants (`for`, `forEach`, `while`, `doWhile`) with correct config
- [ ] Parallel type supports `count` and `collection` with batch sizing
- [ ] Auto-layout returns a change-set (position diff), not absolute positions
- [ ] Serializer validates all blocks and raises `WorkflowValidationError` for invalid state
- [ ] Sentinel block IDs follow the `__<type>_<start|end>__<id>` convention
- [ ] No modifications to out-of-scope areas (block configs, SubBlock types, block node rendering, toolbar)

### References

- Parent skill: [../../SKILL.md](../../SKILL.md)
- Block system: [../block-system/SKILL.md](../block-system/SKILL.md)
- SubBlock system: [../subblock-system/SKILL.md](../subblock-system/SKILL.md)
- Block node canvas: [../block-node-canvas/SKILL.md](../block-node-canvas/SKILL.md)
- Architecture overview: [../../reference/architecture-overview.md](../../reference/architecture-overview.md)
