---
name: sim-ai-block-node-canvas
description: ReactFlow block-to-node rendering pipeline for Sim Studio AI — transforms declarative BlockConfig into visual WorkflowBlock nodes with handles, dimensions, ring overlay, ActionBar, edge rendering, and permission gating. Deep architecture from simstudioai/sim v0.6.84.
version: 1.0.0
author: skills-blackhole
license: MIT
metadata:
  hermes:
    tags: [sim-ai, reactflow, canvas, nodes, handles, edges, visual-editor, workflow-block]
    related_skills:
      - sim-ai
      - sim-ai-block-system
      - sim-ai-subblock-system
      - sim-ai-canvas-editor
---

## sim-ai.workflow.block-node-canvas

### Goal

Transform each declarative BlockConfig into a visual `WorkflowBlock` node on the ReactFlow canvas — rendering the card anatomy (header, content rows, handles), dimension system, ring overlay, ActionBar, and edge connections with deterministic positioning and permission-aware gating.

### Scope

- **Applies to:**
  - `WorkflowBlock` node component and visual anatomy
  - Node type registration (`workflowBlock`, `noteBlock`, `subflowNode`)
  - Handle system — static (target, source, error) and dynamic (condition, router)
  - Handle position constants and direction toggling (horizontal ↔ vertical)
  - Dimension calculation — deterministic via constants (no ResizeObserver)
  - Ring overlay — 8-priority visual state chain
  - ActionBar — 7 floating buttons with permission gating
  - Edge rendering — `WorkflowEdge` with 7-level color priority
  - Permission and sandbox gating (`canEdit`, `canAdmin`, `isSandbox`, `isEmbedded`, `isOfflineMode`)
  - Files: `workflow-block.tsx`, `action-bar.tsx`, `block-dimensions.ts`, `deterministic-dimensions.ts`, `use-block-dimensions.ts`, `block-ring-utils.ts`, `use-block-state.ts`, `workflow-constants.ts`, `workflow-edge.tsx`, `dynamic-handle-topology.ts`
- **Does NOT cover:**
  - BlockConfig declaration and registry (see `workflows/block-system`)
  - SubBlock types and UI rendering (see `workflows/subblock-system`)
  - ReactFlow store, subflows, layout, zoom, minimap (see `workflows/canvas-editor`)
  - Toolbar and panel UI (see `workflows/toolbar`)

### Triggers

- "Modify block visual appearance" / "Change node card style"
- "Add or change handles" / "Fix handle position" / "Handle direction toggle"
- "Change block dimensions" / "Fix node height calculation"
- "Edge rendering" / "Change edge color" / "Edge path style"
- "Ring overlay" / "Selection ring" / "Diff highlight on node"
- "ActionBar buttons" / "Add block action"
- "Permission gating on canvas" / "Sandbox mode rendering"
- Working on `workflow-block.tsx`, `action-bar.tsx`, `block-dimensions.ts`
- Working on `workflow-edge.tsx`, `workflow-constants.ts`
- Working on `block-ring-utils.ts`, `dynamic-handle-topology.ts`

### Inputs

- `BlockConfig` — declarative config defining block type, name, icon, bgColor, subBlocks
- `blockState` — runtime state: isActive, isPending, selected, dragging, enabled, locked
- `subBlockValues` — current values for visible sub-block rows
- `conditionRows` / `routerRows` — dynamic handle source data
- `canEdit` / `canAdmin` — permission flags
- `isSandbox` / `isEmbedded` / `isOfflineMode` — environment flags
- `diffState` — diff overlay data (new, edited, deleted)

### Invariants

- **Deterministic dimensions:** Block height is calculated by formula (no ResizeObserver) — eliminates layout thrash. `height = max(HEADER_HEIGHT + WORKFLOW_CONTENT_PADDING + rowsCount × WORKFLOW_ROW_HEIGHT, MIN_HEIGHT)`.
- **Memo-optimized rendering:** `React.memo` with `shouldSkipBlockRender` compares id, type, name, isActive, isPending, config, subBlockValues, blockState, selected, dragging — **excludes xPos/yPos** to avoid re-render during drag.
- **Ring priority chain:** Single overlay element with dynamically applied class based on highest-priority state. Only one ring state renders at a time.
- **Dynamic handle topology:** Condition/Router blocks generate handles dynamically with signature tracking (`getDynamicHandleTopologySignature`) to detect changes and update node internals.
- **Permission-first UX:** `canEdit`/`canAdmin`/`isSandbox`/`isEmbedded` control what renders — ActionBar visibility, lock button, click-to-edit, API calls.

### Procedure

#### 1. Node type registration

Register custom node and edge types with ReactFlow:

```typescript
// workflow-constants.ts
const nodeTypes = {
  workflowBlock: WorkflowBlock,    // workflow blocks
  noteBlock: NoteBlock,            // sticky notes
  subflowNode: SubflowNodeComponent // loop/parallel containers
}
const edgeTypes = {
  default: WorkflowEdge,
  workflowEdge: WorkflowEdge
}
```

#### 2. WorkflowBlock visual anatomy

Each block renders as a fixed 250px card:

```
<div class="group relative">                           // wrapper for ActionBar hover
  <div ref={contentRef}                                // main body
    class="w-[250px] cursor-grab rounded-lg border
           bg-[var(--surface-2)]">

    [Pending badge "Next Step"]                        // amber, above card
    <ActionBar />                                      // hover-revealed
    <Handle type="target" />                           // input (left/top)

    <Header>                                           // 40px
      <Icon 24x24 bgColor={config.bgColor}>
      <Name text>
      <Badges: undeployed | disabled | locked | webhook | schedule>
    </Header>

    <Content>                                          // flex-col gap-2 p-2
      [SubBlockRows | ConditionRows | RouterRows]
      <SubBlockRow title="error" />                    // always at end
    </Content>

    <Handle type="source" />                           // output (right/bottom)
    <Handle type="source" id="error" />                // error output (right)

    [Ring overlay]                                     // absolute inset-0 z-40
  </div>
</div>
```

#### 3. Handle system

**5 handle types:**

| Handle | Position | Connectivity | When |
|--------|----------|--------------|------|
| Target (input) | Left/Top | `start=false, end=true` | Non-triggers, non-starter |
| Source (output) | Right/Bottom | `start=true, end=false` | Non-condition/router/response |
| Error | Right (bottom:17px) | `start=true, end=false` | All except response |
| Dynamic Condition | Right, Y offset | `start=true` | Condition blocks |
| Dynamic Router | Right, Y offset | `start=true` | Router_v2 blocks |

**Position constants:**

| Constant | Value | Use |
|----------|-------|-----|
| `DEFAULT_Y_OFFSET` | 20px | Target/Source handles |
| `ERROR_BOTTOM_OFFSET` | 17px | Error handle |
| `CONDITION_START_Y` | 60px | Start of condition/router handles |
| `CONDITION_ROW_HEIGHT` | 29px | Height per condition/router row |
| `SUBFLOW_START_Y_OFFSET` | 80px | Subflow start handle |

**Dynamic handles:**
- Condition: one handle per condition (if, else if, else). ID: `condition-{cond.id}`. Y: `CONDITION_START_Y + index × CONDITION_ROW_HEIGHT`
- Router: one handle per route. ID: `router-{route.id}`. Y: `CONDITION_START_Y + (index+1) × CONDITION_ROW_HEIGHT`
- Topology tracking via `getDynamicHandleTopologySignature` → `"condition:id1|id2"` or `"router:id1|id2"`

**Handle styling:** base `!z-[0] !cursor-crosshair !border-none !transition-[colors] !duration-150`, normal `!bg-[var(--workflow-edge)]`, error `!bg-[var(--text-error)]`, size 7px × 20px offset 8px, hover expands to 10px offset 11px rounded.

**Direction toggle:** ActionBar switches horizontal (Left/Right) ↔ vertical (Top/Bottom). Stored per block.

#### 4. Dimension calculation (deterministic)

**Constants:** `FIXED_WIDTH=250px`, `HEADER_HEIGHT=40px`, `MIN_HEIGHT=100px`, `WORKFLOW_CONTENT_PADDING=16px`, `WORKFLOW_ROW_HEIGHT=29px`.

```typescript
calculateWorkflowBlockDimensions({
  blockType, visibleSubBlockCount, conditionRowCount, routerRowCount
})
// rowsCount = visibleSubBlockCount | conditionRowCount | 1 + routerRowCount
// contentHeight = WORKFLOW_CONTENT_PADDING + rowsCount * WORKFLOW_ROW_HEIGHT
// height = max(HEADER_HEIGHT + contentHeight, MIN_HEIGHT)
// width = FIXED_WIDTH
```

Hook `useBlockDimensions` → updates store + calls `updateNodeInternals(blockId)`.

#### 5. Ring overlay (8 states)

Single `<div className="pointer-events-none absolute inset-0 z-40 rounded-lg" className={ringStyles} />` with priority chain:

| # | State | Color | Style |
|---|-------|-------|-------|
| 1 | Executing | `--border-success` green | 3.5px + pulse animation |
| 2 | Selected / Editor open | `--brand-secondary` blue | 1.75px |
| 3 | Pending (Next Step) | `--warning` amber | 1.75px |
| 4 | Deleted | `--text-error` red | 1.75px |
| 5 | Diff: new | `--brand-accent` accent | 1.75px |
| 6 | Diff: edited | `--warning` amber | 1.75px |
| 7 | Run: success | `--border-success` green | 1.75px |
| 8 | Run: error | `--text-error` red | 1.75px |

#### 6. ActionBar (7 buttons)

Position: `-top-[46px] absolute right-0`, shown on `group-hover:opacity-100`. Each button 23×23px.

| Button | Icon | When | Action |
|--------|------|------|--------|
| Run | `PlayOutline` | Not note, not subflow | `runFromBlock()` |
| Enable/Disable | `Circle`/`CircleOff` | Not note | Toggle enabled |
| Lock/Unlock | `Lock`/`Unlock` | `canAdmin` only | Toggle locked |
| Duplicate | `Copy` | Not starter/response | `collaborativeBatchAddBlocks` |
| Handle Direction | `ArrowLeftRight`/`ArrowUpDown` | Not note/subflow | Horizontal↔Vertical |
| Remove from Subflow | `LogOut` | Inside loop/parallel | Remove from container |
| Delete | `Trash2` | Always | `collaborativeBatchRemoveBlocks` |

Gating: `canEdit` controls ActionBar rendering. `canAdmin` for lock. Offline mode shows "Connection lost".

#### 7. Edge rendering (7 color priorities)

Path: `getSmoothStepPath` with `borderRadius: 8`, offset 30 (horizontal) or 20 (vertical).

| # | Condition | Color | Width | Extra |
|---|-----------|-------|-------|-------|
| 1 | Diff: deleted | `--text-error` red | 3 | dashed (10,5), opacity 0.7 |
| 2 | Diff: new | `--brand-accent` | 3 | — |
| 3 | Run: success (preview) | `--brand-accent` | 2.5 | — |
| 4 | Run: success (canvas) | `--border-success` | 2.5 | — |
| 5 | Run: error | `--text-error` | 2.5 | — |
| 6 | Error edge (untaken) | `--text-error` | 2 | — |
| 7 | Default | `--workflow-edge` | 2 | — |

Selection: opacity 0.5, width 2.5, X button at midpoint via `EdgeLabelRenderer`. Diff ID: `${source}-${sourceHandle}-${target}-${targetHandle}`.

#### 8. Permission and sandbox gating

| Context | Effect |
|---------|--------|
| `canEdit=true` | ActionBar rendered |
| `canEdit=false` | ActionBar hidden |
| `canAdmin=true` | Lock/Unlock visible |
| `isWorkflowLocked` | Everything disabled |
| `isSandbox=true` | workspaceId/workflowId empty, no API calls |
| `isEmbedded=true` | No ActionBar, no click-to-edit |
| `isOfflineMode` | "Connection lost" message |

### Outputs

- Modified node component files in `components/workflow-block/`
- Modified edge component in `components/workflow-edge/`
- Updated dimension constants or calculation logic
- Updated ring overlay styling
- Updated ActionBar buttons or gating logic
- Updated handle position constants or dynamic handle logic

### Review gate

- [ ] Block visual changes respect the 250px fixed width and deterministic height formula
- [ ] Handles follow the position constants (`DEFAULT_Y_OFFSET`, `CONDITION_START_Y`, etc.)
- [ ] Dynamic handles (condition/router) include topology signature tracking
- [ ] Ring overlay follows the 8-state priority chain (highest wins)
- [ ] ActionBar buttons respect permission gating (`canEdit`, `canAdmin`)
- [ ] Edge rendering follows the 7-level color priority system
- [ ] Sandbox mode suppresses API calls and uses empty IDs
- [ ] Memo optimization excludes xPos/yPos to prevent drag re-renders
- [ ] No modifications to out-of-scope areas (BlockConfig, SubBlock types, canvas store, toolbar)

### References

- Parent skill: [../../SKILL.md](../../SKILL.md)
- Block system: [../block-system/SKILL.md](../block-system/SKILL.md)
- SubBlock system: [../subblock-system/SKILL.md](../subblock-system/SKILL.md)
- Canvas editor: [../canvas-editor/SKILL.md](../canvas-editor/SKILL.md)
- Architecture overview: [../../reference/architecture-overview.md](../../reference/architecture-overview.md)
