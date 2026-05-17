---
name: sim-ai-mcp-integration
description: Model Context Protocol integration for Sim Studio AI — MCP server discovery and connections, tool discovery and execution with dynamic args, OAuth auto-discovery, SSE/Streamable HTTP proxy pattern, and workspace versus workflow server scoping via mcpService singleton.
version: 1.0.0
author: skills-blackhole
license: MIT
metadata:
  hermes:
    tags: [sim-ai, mcp, model-context-protocol, agent-tools, oauth, proxy, tool-discovery]
    related_skills:
      - sim-ai
      - sim-ai-block-system
      - sim-ai-subblock-system
---

## sim-ai.workflow.mcp-integration

### Goal

Implement and maintain the Model Context Protocol (MCP) integration layer that connects Sim Studio AI to external MCP servers for dynamic tool discovery, execution, and OAuth-authenticated proxy routing across workspace-level and workflow-level server scopes.

### Scope

- **Applies to:**
  - API routes under `/api/mcp/` (discovery, execution, server CRUD, proxy, copilot)
  - Workspace MCP servers — registered at workspace level, available to any workflow
  - Workflow MCP servers — scoped per-workflow, configured via the `mcp` block
  - `mcpService` singleton (`apps/sim/lib/mcp/service.ts`) — server connections, tool caching, execution with timeout, error categorization
  - MCP block SubBlocks: `mcp-server-selector`, `mcp-tool-selector`, `mcp-dynamic-args`
  - OAuth auto-discovery via `.well-known/oauth-authorization-server` and `.well-known/oauth-protected-resource`
  - Domain whitelist (`allowed-mcp-domains`) for security validation
  - Hybrid auth (`checkHybridAuth()`) — session OR API key for MCP endpoints
  - DB schema: `workflowMcpServer` table and workspace server configuration
- **Does NOT cover:**
  - Block config definitions (see `workflows/block-system`)
  - SubBlock type rendering (see `workflows/subblock-system`)
  - Canvas rendering and ReactFlow integration (see `workflows/canvas-editor`)
  - Knowledge/RAG pipelines (see `workflows/knowledge-rag`)

### Triggers

- "Integrate an MCP server" / "Add MCP support"
- "Discover MCP tools" / "List tools from MCP server"
- "Execute MCP tool" / "Call MCP tool"
- "Configure OAuth for MCP" / "MCP OAuth flow"
- "Add workspace server" / "Add workflow MCP server"
- "MCP proxy" / "SSE proxy for MCP"
- "MCP block" / "mcp-server-selector" / "mcp-tool-selector"
- Working on `apps/sim/lib/mcp/`
- Working on `apps/sim/app/api/mcp/`
- Files matching `mcp`, `workflowMcpServer`, `allowed-mcp-domains`

### Inputs

- **Server config** — URL, transport type (SSE / Streamable HTTP), auth credentials
- **Server scope** — `'workspace'` (global) or `'workflow'` (per-workflow)
- **Tool call** — `{ serverId, toolName, arguments }` from MCP block execution
- **OAuth metadata** — `.well-known` endpoints for auto-discovery
- **Domain whitelist** — admin-configured allowed domains for outbound connections

### Invariants

- **Proxy pattern:** All MCP communication routes through the API layer as proxy — the frontend never connects directly to external MCP servers.
- **Dual scope:** Workspace servers are shared globally; workflow servers are isolated per-workflow. Both are resolved the same way at execution time.
- **Dynamic schema:** MCP tool arguments derive from the server's `inputSchema` — no hardcoded argument definitions.
- **Tool discovery cache:** Discovered tools are cached and require manual refresh (`/api/mcp/servers/[id]/refresh`).
- **OAuth auto-discovery:** OAuth requirements are detected via `.well-known` URLs, never assumed or hardcoded.
- **Hybrid auth required:** All `/api/mcp/` routes enforce `checkHybridAuth()` (session OR API key) plus workspace permission checks via `assertPermissionsAllowed()`.
- **Error categorization:** `categorizeError()` classifies MCP errors for UX-friendly display.

### Procedure

#### 1. Understand the MCP architecture

```
MCP Block (canvas)
  ↓ Configures: server URL + auth + tool selection
  ↓
API Routes (proxy layer)
  /api/mcp/discover          → List available servers
  /api/mcp/serve/[serverId]  → SSE/Streamable HTTP proxy
  /api/mcp/tools/discover    → List tools from a server
  /api/mcp/tools/execute     → Execute a specific tool
  /api/mcp/tools/stored      → Cached tools
  /api/mcp/servers           → CRUD workspace servers
  /api/mcp/workflow-servers  → CRUD workflow servers
  /api/mcp/copilot           → Copilot MCP endpoint
  ↓
mcpService singleton
  ↓ Connects to external MCP server (SSE / Streamable HTTP)
  ↓ Returns McpToolResult
```

#### 2. Manage MCP servers

**Workspace servers** (global, shared across workflows):
- `GET /api/mcp/discover` — list all workspace servers
- `POST /api/mcp/servers` — create workspace server
- `PATCH /api/mcp/servers/[id]` — update server config
- `DELETE /api/mcp/servers/[id]` — remove server
- `POST /api/mcp/servers/[id]/refresh` — refresh cached tools

**Workflow servers** (per-workflow, stored in `workflowMcpServer` table):
- `GET /api/mcp/workflow-servers` — list workflow servers
- `POST /api/mcp/workflow-servers` — create workflow server
- `PATCH /api/mcp/workflow-servers/[id]` — update
- `DELETE /api/mcp/workflow-servers/[id]` — remove
- `GET /api/mcp/workflow-servers/[id]/tools` — list tools
- `GET /api/mcp/workflow-servers/[id]/tools/[toolId]` — tool detail
- `PATCH /api/mcp/workflow-servers/[id]/tools/[toolId]` — update tool

#### 3. Execute MCP tools

```
MCP Block → GenericBlockHandler
  ↓ tools.config.tool(params) → resolve MCP tool ID
  ↓ mcpService.executeTool(serverId, toolName, args)
  ↓ HTTP/SSE call to external MCP server
  ↓ McpToolResult → block output
```

Core types:
```typescript
interface McpTool {
  name: string
  description: string
  inputSchema: Record<string, SchemaProperty>
}

interface McpToolCall {
  name: string
  arguments: Record<string, unknown>
}

interface McpToolResult {
  content: Array<{ type: string; text: string }>
  isError?: boolean
}
```

- `mcpService` manages server connections (SSE / Streamable HTTP)
- Tool execution includes timeout handling
- Errors are categorized via `categorizeError()` for UX display

#### 4. Handle OAuth flow

1. MCP server may require OAuth — detected via `.well-known/oauth-authorization-server`
2. Protected resource metadata via `.well-known/oauth-protected-resource`
3. Token management stored in server config
4. Copilot endpoint: `/api/mcp/copilot` with OAuth discovery at `.well-known/oauth-authorization-server/api/mcp/copilot`

#### 5. Enforce security

- **Hybrid auth:** `checkHybridAuth()` validates session OR `X-API-Key` header
- **Permissions:** `assertPermissionsAllowed()` checks workspace membership before tool execution
- **Domain whitelist:** `allowed-mcp-domains` setting validates outbound URLs before connecting
- **Workflow-level read permission** required for search operations

#### 6. Implement MCP block SubBlocks

The `mcp` block on the canvas uses three SubBlocks:
- `mcp-server-selector` — select server (workspace or workflow scope)
- `mcp-tool-selector` — select tool from the chosen server
- `mcp-dynamic-args` — render dynamic argument form from the tool's `inputSchema`

### Outputs

- API route files under `apps/sim/app/api/mcp/`
- MCP service updates in `apps/sim/lib/mcp/service.ts`
- MCP block config and SubBlock definitions
- DB schema changes for `workflowMcpServer` table
- OAuth configuration and domain whitelist settings

### Review gate

- [ ] All MCP routes enforce `checkHybridAuth()` and workspace permission checks
- [ ] Workspace and workflow server scoping is correctly separated
- [ ] Tool discovery uses caching with manual refresh capability
- [ ] OAuth auto-discovery follows `.well-known` conventions
- [ ] Domain whitelist is validated before outbound connections
- [ ] `mcpService` handles SSE and Streamable HTTP transports
- [ ] Error categorization provides UX-friendly messages
- [ ] MCP block SubBlocks render dynamic args from `inputSchema`
- [ ] No modifications to out-of-scope areas (block config, SubBlock types, canvas, RAG)

### References

- Parent skill: [../../SKILL.md](../../SKILL.md)
- Block system: [../block-system/SKILL.md](../block-system/SKILL.md)
- SubBlock system: [../subblock-system/SKILL.md](../subblock-system/SKILL.md)
