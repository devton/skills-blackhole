---
name: sim-ai-toolbar
description: Sim Studio AI toolbar architecture — editor visual toolbar with block insertion (click, drag-and-drop, overlay drop), CustomEvent bridge to canvas, search with keyboard navigation, context menus, and 12 global keyboard shortcuts. Extracted from simstudioai/sim v0.6.84.
version: 1.0.0
author: skills-blackhole
license: MIT
metadata:
  hermes:
    tags: [sim-ai, toolbar, editor, canvas, react-flow, visual-editor, block-insertion, drag-and-drop, keyboard-shortcuts, custom-events]
    related_skills: [sim-ai]
---

## sim-ai.workflow.toolbar

### Goal

Provide the complete toolbar architecture for inserting blocks and tools into the Sim AI visual editor canvas, covering the Panel→Tabs→Toolbar component pipeline, three insertion mechanisms (click, drag-and-drop, empty-workflow overlay drop), a CustomEvent bridge for decoupled communication, search with keyboard navigation, and 12 registered global keyboard shortcuts.

### Scope

- **Applies to:** the toolbar subsystem of the Sim AI visual workflow editor — Panel container, Toolbar tab, block/trigger listing, all three insertion mechanisms, the `window.dispatchEvent` CustomEvent bridge between toolbar and canvas, search filtering with keyboard navigation, context menus, and the global commands registry.
- **Covers:**
  - Panel→Tabs→Toolbar component hierarchy and rendering pipeline
  - Three insertion mechanisms: Click to Add, Drag & Drop, Empty Workflow Overlay Drop
  - CustomEvent bridge (`add-block-from-toolbar`, `toolbar-drop-on-empty-workflow-overlay`)
  - Zustand store state management (`usePanelStore`, `useToolbarStore`) with localStorage persistence
  - Search with ArrowDown/Up keyboard navigation cycling through triggers and blocks
  - Context menus (toolbar item context menu, canvas context menu)
  - Global keyboard shortcuts (12 commands in `commands-utils.ts` registry)
  - Static registry cache for block/trigger data (`getBlocksForSidebar`, `getTriggersForSidebar`)
  - Extension patterns for adding new blocks and new shortcuts
- **Does NOT cover:** React Flow canvas internals, individual block configurations, Copilot or Editor tabs, workflow execution engine.

### Triggers

- "Working on toolbar", "fix toolbar issue", "modify toolbar component"
- "Adding block insertion mechanism", "new way to add blocks to canvas"
- "Modifying search or keyboard shortcuts in the editor"
- "Add new block to toolbar", "register new global shortcut"
- "Context menu for toolbar items", "drag preview customization"
- "Panel resize persistence", "toolbar triggers height"

### Inputs

- `blockRegistry`: `blocks/registry.ts` — static map of `BlockConfig` objects keyed by type
- `triggerData`: `getTriggersForSidebar()` — triggers sorted (Start/Schedule/Webhook first, then alphabetical)
- `blockData`: `getBlocksForSidebar()` — blocks first, tools after, Loop+Parallel appended
- `filterBlocks()`: permission-based filtering
- `useSandboxBlockConstraints()`: sandbox-mode constraints
- Zustand stores: `usePanelStore` (`panelWidth`, `activeTab`, `isResizing`), `useToolbarStore` (`toolbarTriggersHeight`, `preSearchHeight`)

### Procedure

#### 1. Understand the Panel→Tabs→Toolbar component hierarchy

The toolbar lives inside a layered component structure:

```
Panel (panel.tsx, ~970 lines)
├── Header (workflow name + actions)
├── Tabs: [Copilot] [Toolbar] [Editor]
├── Toolbar Tab (toolbar.tsx, ~843 lines)
│   ├── Search (filter triggers/blocks)
│   ├── Triggers Section (resizable, 30–800px)
│   ├── Resize Handle (persisted height via localStorage)
│   ├── Blocks Section (collapsible)
│   └── ToolbarItemContextMenu
│       ├── Add to canvas
│       └── View documentation
└── ToolbarItem (memoized, 16x16 icon + label)
```

- All three tabs are **always mounted** — only visibility toggles, preserving state across tab switches.
- Panel width and active tab persist in `usePanelStore` (localStorage).

#### 2. Implement or modify insertion mechanisms

**Mechanism 1 — Click to Add:**
```
ToolbarItem.onClick(type, enableTriggerMode)
→ window.dispatchEvent(CustomEvent('add-block-from-toolbar'))
→ workflow.tsx listener → handleAddBlockFromToolbar()
  → getViewportCenter() + generateId() + getUniqueBlockName()
  → tryCreateAutoConnectEdge() (auto-wiring)
  → addBlock() to Zustand workflow store
```

**Mechanism 2 — Drag & Drop:**
```
ToolbarItem.onDragStart → dataTransfer.setData('application/json', {type, enableTriggerMode})
→ Custom drag preview (icon + name DOM element)
→ ReactFlow canvas onDrop → screenToFlowPosition()
→ handleToolbarDrop() → addBlock()
```

**Mechanism 3 — Empty Workflow Overlay Drop:**
```
CommandList.handleDrop → CustomEvent('toolbar-drop-on-empty-workflow-overlay')
→ workflow.tsx listener → coord conversion → addBlock()
```

Key files: `use-toolbar-item-interactions.ts` (~121 lines), `drag-preview.ts` (~71 lines).

#### 3. Use or extend the CustomEvent bridge

Toolbar and canvas are decoupled via `window.dispatchEvent` to avoid circular imports:
- `'add-block-from-toolbar'` — click insertion event
- `'toolbar-drop-on-empty-workflow-overlay'` — drop on empty state event

When adding a new cross-component communication, add a new CustomEvent name and a corresponding listener in `workflow.tsx`.

#### 4. Implement or modify search with keyboard navigation

- Activated by search icon or `Mod+Alt+F`
- Filters triggers AND blocks simultaneously
- Keyboard navigation: ArrowDown/Up cycles through search → triggers → blocks → search (wrapping)
- Enter/Space activates the focused item
- Search state is local (not persisted)

#### 5. Handle context menus

**Toolbar item context menu** (`toolbar-item-context-menu.tsx`, ~88 lines):
- "Add to canvas" — triggers click insertion
- "View documentation" — opens block docs

**Canvas context menu** (right-click on empty canvas):
- Undo, Redo, Paste, Add Block, Auto-layout, Lock/Unlock, Fit to View, Search & Replace, Logs, Variables, Chat

**Node context menu** (right-click on node):
- BlockMenu — block-specific actions

#### 6. Register or modify global keyboard shortcuts

Registry: `apps/sim/app/workspace/[workspaceId]/utils/commands-utils.ts`
Hook: `useRegisterGlobalCommands(() => createCommands([...]))`

Registered commands (12 total):

- `Run workflow` — Mod+Enter (fixed)
- `Focus toolbar search` — Mod+Alt+F (fixed)
- `Add agent` — Mod+Shift+A (editable)
- `Open search (blocks)` — Mod+K (editable)
- `Search & replace` — Mod+F (editable)
- `Go to logs` — Mod+L (editable)
- `Fit to view` — Mod+Shift+F (fixed)
- `Auto-layout` — Shift+L (fixed)
- Additional commands in registry for canvas operations

**To add a new shortcut:**
1. Add `CommandId` in `commands-utils.ts`
2. Add entry to `COMMAND_DEFINITIONS` with shortcut + `allowInEditable` flag
3. Call `useRegisterGlobalCommands()` in the target component

#### 7. Extend the toolbar with new blocks

1. Create `BlockConfig` in `blocks/blocks/<name>/` with `category: 'blocks'|'tools'`
2. Register in `blocks/registry.ts`: `<type>: BlockConfig`
3. Block appears automatically in toolbar — no toolbar-specific code needed

#### 8. Manage state via Zustand stores

- `usePanelStore`: `panelWidth`, `activeTab`, `isResizing` — persisted to localStorage
- `useToolbarStore`: `toolbarTriggersHeight`, `preSearchHeight` — persisted to localStorage
- CSS variables `--panel-width` and `--toolbar-triggers-height` synced via `layout.tsx` blocking script (pre-hydration)

### Outputs

- Correct toolbar rendering with all blocks/triggers listed and categorized
- Working insertion via click, drag-and-drop, or overlay drop
- CustomEvent bridge events dispatched and handled correctly
- Search filtering with keyboard navigation cycling through results
- Context menus with appropriate actions
- Global keyboard shortcuts registered and functional
- Zustand state persisted across page reloads

### Review gate

- All three insertion mechanisms tested (click adds at viewport center, drag positions at drop point, overlay drop works on empty workflow)
- CustomEvent bridge has no circular imports between panel and canvas components
- Search filters both triggers and blocks, ArrowDown/Up cycles through all sections wrapping back to search
- Context menus render correct options for toolbar items vs canvas vs nodes
- Keyboard shortcuts match the registry and editable/fixed flags are respected
- New blocks added to registry appear in toolbar without toolbar-specific code changes
- Zustand stores persist to localStorage and restore correctly on reload
- No duplicate content between this workflow and the parent `../SKILL.md`

### References

- `../SKILL.md` — parent sim-ai skill entrypoint
- `apps/sim/.../toolbar/toolbar.tsx` (~843 lines) — main toolbar component
- `apps/sim/.../toolbar/hooks/use-toolbar-item-interactions.ts` (~121 lines) — click/drag handlers
- `apps/sim/.../toolbar/hooks/use-toolbar-resize.ts` (~147 lines) — resize handle
- `apps/sim/.../toolbar/components/toolbar-item-context-menu.tsx` (~88 lines) — context menu
- `apps/sim/.../toolbar/components/drag-preview.ts` (~71 lines) — custom drag image
- `apps/sim/.../panel/panel.tsx` (~970 lines) — container with tabs
- `apps/sim/stores/panel/store.ts` (~53 lines) — panel Zustand store
- `apps/sim/stores/panel/toolbar/store.ts` (~49 lines) — toolbar Zustand store
- `apps/sim/blocks/registry.ts` (~538 lines) — block registry
- `apps/sim/blocks/types.ts` (~200 lines) — BlockConfig interface
- `apps/sim/app/workspace/[workspaceId]/utils/commands-utils.ts` — global commands registry
