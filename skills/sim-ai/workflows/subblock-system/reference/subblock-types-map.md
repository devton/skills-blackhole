# SubBlockType → Component Mapping

Full mapping of all 40+ SubBlockTypes to their React components, grouped by category. Rendering is handled by the central `switch(config.type)` in `sub-block.tsx` (~lines 658–1196).

## Texto (Text Input)

- **`short-input`** → `ShortInput` — Single-line input. Supports `password`, `readOnly`, and `wandConfig` integration.
- **`long-input`** → `LongInput` — Multi-line textarea with configurable `rows`. Supports `wandConfig`.
- **`code`** → `Code` — Code editor for JS/JSON/Python. Collapsible. Supports `wandConfig`.
- **`text`** → `Text` — Static display-only text. Content rendered via `value` function.

## Seleção (Selection)

- **`dropdown`** → `Dropdown` — Select from static `options` or async `fetchOptions`. Supports `multiSelect`.
- **`combobox`** → `ComboBox` — Editable dropdown with expression support (`{{variable}}`).
- **`switch`** → `Switch` — Inline boolean toggle.
- **`slider`** → `SliderInput` — Numeric slider with `min`, `max`, `step`, `integer` constraints.
- **`checkbox-list`** → `CheckboxList` — Checkbox list with optional `descriptions` per item.
- **`grouped-checkbox-list`** → `GroupedCheckboxList` — Grouped checkboxes with `group` labels and `maxHeight`.

## Estruturado (Structured)

- **`table`** → `Table` — Key-value table editor with configurable `columns`.
- **`condition-input`** → `ConditionInput` — Condition builder in default mode. Used for If/Else blocks.
- **`router-input`** → `ConditionInput` — Condition builder in `mode='router'`. Used for Router blocks.
- **`eval-input`** → `EvalInput` — Evaluation expression builder.
- **`filter-builder`** → `FilterBuilder` — Filter rule builder for data filtering operations.
- **`sort-builder`** → `SortBuilder` — Sort rule builder for ordering operations.
- **`input-format`** → `InputFormat` — Starter block input configuration editor.
- **`response-format`** → `ResponseFormat` — Response format configuration editor.
- **`input-mapping`** → `InputMapping` — Input mapping editor for block data flow.
- **`variables-input`** → `VariablesInput` — Variables editor for environment/key-value pairs.

## OAuth / Selectors

- **`oauth-input`** → `CredentialSelector` — OAuth/API key credential selector. Never blocked by `dependsOn`.
- **`channel-selector`** → `SelectorInput` — Channel picker with `SLACK_OVERRIDES` support.
- **`user-selector`** → `SelectorInput` — User picker with `SLACK_OVERRIDES` support.
- **`file-selector`** → `SelectorInput` — Dynamic file picker.
- **`sheet-selector`** → `SelectorInput` — Dynamic spreadsheet picker.
- **`folder-selector`** → `SelectorInput` — Folder picker with `FOLDER_OVERRIDES` (e.g. Gmail INBOX).
- **`project-selector`** → `SelectorInput` — Dynamic project picker.
- **`document-selector`** → `SelectorInput` — Dynamic document picker.
- **`knowledge-base-selector`** → `KnowledgeBaseSelector` — Knowledge base picker with external link.
- **`table-selector`** → `TableSelector` — Database table picker with external link.
- **`workflow-selector`** → `WorkflowSelectorInput` — Workflow picker for referencing other workflows.

## Especializados (Specialized)

- **`tool-input`** → `ToolInput` — Schema-driven tool parameter editor.
- **`skill-input`** → `SkillInput` — Skill selector for agent blocks.
- **`messages-input`** → `MessagesInput` — Messages array editor with `wandConfig` support.
- **`file-upload`** → `FileUpload` — File upload with `acceptedTypes`, `multiple`, `maxSize` constraints.
- **`schedule-info`** → `ScheduleInfo` — Read-only schedule display.
- **`time-input`** → `TimeInput` — Time picker component.
- **`modal`** → `MODAL_REGISTRY[modalId]` — Dynamic modal loader (e.g. `slack-setup-wizard`).
- **`webhook-config`** → *(rendered as URL input)* — Webhook configuration display.
- **`document-tag-entry`** → `DocumentTagEntry` — Tag entry for document categorization.
- **`knowledge-tag-filters`** → `KnowledgeTagFilters` — Tag filter builder for knowledge queries.
- **`mcp-server-selector`** → `McpServerSelector` — MCP (Model Context Protocol) server picker.
- **`mcp-tool-selector`** → `McpToolSelector` — MCP tool picker from selected server.
- **`mcp-dynamic-args`** → `McpDynamicArgs` — Dynamic arguments rendered from MCP tool `inputSchema`.
