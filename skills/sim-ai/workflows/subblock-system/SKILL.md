---
name: sim-ai-subblock-system
description: >
  Declarative SubBlock configuration system for Sim Studio AI — maps 40+ SubBlockTypes to React
  components, manages 3-layer conditions (condition/required/reactiveCondition), canonical params
  (basic/advanced toggle), wandConfig (AI assistant with streaming), fetchOptions (async dropdowns),
  and dependsOn cascade gating. Deep architecture from simstudioai/sim v0.6.84.
version: 1.0.0
author: skills-blackhole
license: MIT
metadata:
  hermes:
    tags: [sim-ai, subblocks, editor, forms, declarative-ui, canonical-params, wand, conditions, depends-on]
    related_skills:
      - sim-ai
      - sim-ai-block-system
      - sim-ai-toolbar
      - sim-ai-block-node-canvas
      - sim-ai-canvas-editor
---

## sim-ai.workflow.subblock-system

### Goal

Implement and maintain the declarative SubBlock configuration system where each block's `subBlocks: SubBlockConfig[]` array is rendered dynamically into a complete configuration UI with visibility, dependency, AI generation, and basic/advanced mode support — all driven purely by config, zero imperative rendering code.

### Scope

- **Applies to:**
  - 40+ `SubBlockType` → React component mapping (rendering switch in `sub-block.tsx`)
  - 3-layer condition system: `condition` (visibility), `required` (obligation), `reactiveCondition` (credential-type gating)
  - Canonical params — `canonicalParamId` + `mode: 'basic' | 'advanced'` swap pairs
  - `wandConfig` — AI assistant integration with streaming on ShortInput, LongInput, Code, MessagesInput
  - `fetchOptions` / `fetchOptionById` — async dropdown population and hydration
  - `dependsOn` — cascade dependency gating (AND/OR) via `useDependsOnGate`
  - `reactiveCondition` — OAuth vs API key credential visibility via `useReactiveConditions`
  - Core hooks: `useSubBlockValue`, `useSubBlockInput`, `useCanonicalSubBlockValue`, `useSelectorSetup`, `useEditorSubblockLayout`
  - Visibility utilities in `lib/workflows/subblocks/visibility.ts`
  - Feature flag gating (`isSubBlockFeatureEnabled`) and hiding (`hideWhenHosted`, `hideWhenEnvSet`)
- **Does NOT cover:**
  - Block config definition and registry (see `workflows/block-system`)
  - Canvas rendering and ReactFlow integration (see `workflows/canvas-editor`)
  - Toolbar and panel UI (see `workflows/toolbar`)
  - Block node visual rendering (see `workflows/block-node-canvas`)

### Triggers

- "Add a subblock field" / "Add a SubBlockConfig to a block"
- "Create a new SubBlockType" / "Register a new subblock component"
- "Modify subblock conditions" / "Change when a field is visible"
- "Add canonical params" / "Basic/advanced toggle for a field"
- "Configure wand" / "Add AI generation to a field"
- "Set up fetchOptions" / "Dynamic dropdown population"
- "Add dependsOn" / "Cascade dependency between fields"
- "Fix reactive condition" / "OAuth vs API key field visibility"
- Working on `sub-block.tsx`, `sub-block/` directory, `visibility.ts`
- Working on any `SubBlockConfig` array or `SubBlockType` definition
- Files matching `use-sub-block-value.ts`, `use-canonical-sub-block-value.ts`, `use-depends-on-gate.ts`

### Inputs

- `SubBlockConfig` — declarative config object per field (id, type, label, condition, etc.)
- `SubBlockType` — string discriminator (`'short-input'`, `'dropdown'`, `'oauth-input'`, etc.)
- `condition` — visibility rule: `{ field, value, not?, and? }` or `(values) => Condition`
- `required` — obligation rule: same format as `condition`, adds `*` to label
- `reactiveCondition` — `{ watchFields, requiredType }` for credential-type gating
- `canonicalParamId` — groups basic/advanced subblocks sharing one logical parameter
- `mode` — `'basic'` | `'advanced'` within a canonical pair
- `wandConfig` — `{ enabled, prompt, generationType?, placeholder?, maintainHistory? }`
- `fetchOptions` — `(blockId) => Promise<{label, id}[]>` for async dropdown population
- `dependsOn` — `string[]` or `{ all?: string[]; any?: string[] }` for cascade gating

### Invariants

- **Declarative rendering principle:** All UI is derived from the `SubBlockConfig[]` array. Never write imperative rendering code for subblock fields.
- **Rendering switch is the single source of truth:** All SubBlockType → component mapping lives in the `switch(config.type)` block in `sub-block.tsx`. New types must be added there.
- **Condition evaluation is centralized:** All condition logic flows through `evaluateSubBlockCondition` in `visibility.ts`. Never inline condition checks.
- **Canonical swap is transparent:** When basic/advanced modes share a `canonicalParamId`, only one is visible at a time. The toggle swaps them without data loss.
- **Wand streaming persists only on completion:** AI generation streams visually but only commits the value when streaming ends. Partial streams are never persisted.
- **dependsOn blocks except oauth-input:** When a dependency is unsatisfied, the field is disabled/blocked — but `oauth-input` is never blocked by dependsOn.
- **Feature flag gating applies everywhere:** `isSubBlockFeatureEnabled` can hide any subblock by env/plan. Check flags before adding new types.

### Procedure

#### 1. SubBlockType rendering switch

When a new `SubBlockType` is needed, add a case to the central switch in `sub-block.tsx` (~lines 658-1196):

```
switch(config.type)
  'short-input'     → ShortInput     (password, readOnly, wand)
  'long-input'      → LongInput      (textarea with rows, wand)
  'code'            → Code           (JS/JSON/Python, collapsible, wand)
  'dropdown'        → Dropdown       (static options or fetchOptions)
  'combobox'        → ComboBox       (editable, expression support)
  'switch'          → Switch         (toggle boolean)
  ... (40+ total — see reference/subblock-types-map.md)
```

Each case receives the full `SubBlockConfig` and passes relevant props to the component.

#### 2. Conditions evaluation (3 layers)

**Layer A — `condition` (visibility):**
```
condition: { field: 'operation', value: 'create_booking' }    // simple match
condition: { field: 'operation', value: ['create', 'update'] } // array includes
condition: { field: 'authMethod', value: 'oauth', not: true }  // negation
condition: { field: 'op', value: 'send', and: { field: 'has', value: true } } // AND compound
condition: (values) => ({ field: 'model', value: values?.model ?? '__none__' }) // dynamic fn
```

Evaluation via `evaluateSubBlockCondition(values, condition)` in `visibility.ts`:
- Array `value` → `fieldValue ∈ value` (includes)
- `not: true` → negate result
- `and` → both must be true
- Function → call with values first, then evaluate result

**Layer B — `required` (obligation):**
Same format as `condition`. When matched, adds `*` asterisk to the field label. Does NOT hide the field.

**Layer C — `reactiveCondition` (credential-type gating):**
```typescript
reactiveCondition: {
  watchFields: ['credential'],    // fields to observe
  requiredType: 'oauth'           // or 'service_account'
}
```

Flow:
1. `useReactiveConditions()` observes `watchFields` changes
2. Resolves credential ID via canonical index
3. `useWorkspaceCredential(credentialId)` → fetch from API
4. Compares `credential.type === requiredType`
5. If mismatch → field is hidden

#### 3. Canonical flow (basic/advanced)

```typescript
// Basic: dropdown with tables
{ id: 'tableId', type: 'table-selector', canonicalParamId: 'tableId', mode: 'basic' }

// Advanced: manual input of ID
{ id: 'manualTableId', type: 'short-input', canonicalParamId: 'tableId', mode: 'advanced' }
```

Resolution pipeline:
1. `buildCanonicalIndex(subBlocks)` → `Map<canonicalId, CanonicalGroup { canonicalId, basicId?, advancedIds[] }>`
2. `resolveCanonicalMode(group, values)` → `'basic'` or `'advanced'`
3. `isSubBlockVisibleForMode(subBlock, mode, group)` → show only active mode's subblock
4. Label toggle: `←→` button swaps between basic/advanced
5. `useCanonicalSubBlockValue(blockId, id)` → resolves value by active mode
6. `resolveDependencyValue()` honors canonical swaps when resolving dependsOn values

#### 4. Wand streaming (AI assistant)

```typescript
wandConfig: {
  enabled: true,
  prompt: 'Generate a SQL query based on the table schema...',
  generationType: GenerationType.TEXT,
  placeholder: 'Generate with AI...',
  maintainHistory: true
}
```

Flow:
1. Component label shows "Generate" button (when `wandConfig.enabled`)
2. Click → inline input appears with `placeholder`
3. User submits search query → `onWandTrigger(searchQuery)`
4. Streaming begins → `isWandStreaming = true` → displays "Generating..."
5. Stream completes → value persisted to subblock state

Available on: `ShortInput`, `LongInput`, `Code`, `MessagesInput`

#### 5. dependsOn cascade gating

```typescript
dependsOn: ['credential', 'spreadsheetId']                    // all must have values
dependsOn: { all: ['credential'], any: ['sheetId', 'range'] } // all + any mix
```

Evaluation via `useDependsOnGate`:
1. `parseDependsOn(config.dependsOn)` → `{ allFields, anyFields }`
2. Resolve values via `resolveDependencyValue()` (honors canonical swaps)
3. `allSatisfied` = every allFields has a non-empty value
4. `anySatisfied` = at least one anyFields has a value
5. If not satisfied → field is disabled/blocked
6. **Exception:** `oauth-input` is never blocked by dependsOn

#### 6. fetchOptions (dynamic dropdowns)

```typescript
fetchOptions: (blockId: string) => Promise<Array<{ label: string; id: string }>>
fetchOptionById: (blockId: string, optionId: string) => Promise<{ label: string; id: string } | null>
```

- `fetchOptions` → populates dropdown asynchronously (e.g. list sheets from Google Sheets)
- `fetchOptionById` → hydration: resolves a saved value to a label before the full dropdown loads
- Used by `Dropdown`, `ComboBox`, and all `*-selector` types

#### 7. Feature flags and hiding

- `isSubBlockFeatureEnabled(subBlock)` — checks env/plan feature flags
- `hideWhenHosted: true` — hides field in hosted deployment
- `hideWhenEnvSet: 'VARIABLE_NAME'` — hides field when env variable is set

### Outputs

- SubBlockConfig entries in the block's `subBlocks` array
- (If new type) Component case in `sub-block.tsx` switch
- (If new condition pattern) Test cases for `evaluateSubBlockCondition`
- (If canonical pair) Two SubBlockConfig entries sharing `canonicalParamId`
- (If wand) `wandConfig` object on the SubBlockConfig
- (If dynamic options) `fetchOptions` / `fetchOptionById` functions

### Review gate

- [ ] SubBlock follows the declarative principle: config-driven, no imperative rendering
- [ ] `SubBlockType` exists in the rendering switch in `sub-block.tsx` (or a new case was added)
- [ ] `condition` / `required` / `reactiveCondition` use the correct format and are evaluated via `visibility.ts`
- [ ] Canonical pairs share the same `canonicalParamId` and have distinct `mode` values
- [ ] `wandConfig` includes all required fields (`enabled`, `prompt`) and is only used on supported types
- [ ] `fetchOptions` returns the correct `{ label, id }` shape; `fetchOptionById` handles null for missing options
- [ ] `dependsOn` correctly uses string array or `{ all, any }` format; `oauth-input` is not blocked
- [ ] Feature flags checked: no hidden subblocks unintentionally visible
- [ ] No modifications to out-of-scope areas (block registry, canvas, toolbar)

### References

- Parent skill: [../../SKILL.md](../../SKILL.md)
- SubBlock types map: [reference/subblock-types-map.md](reference/subblock-types-map.md)
- Block system: [../block-system/SKILL.md](../block-system/SKILL.md)
- Architecture overview: [../../reference/architecture-overview.md](../../reference/architecture-overview.md)
