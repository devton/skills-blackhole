# Sim Studio AI — Architecture Overview

**Version:** v0.6.84  
**Repository:** `github.com/simstudioai/sim`

## Stack Summary

| Layer | Technology |
|-------|-----------|
| Frontend framework | Next.js (App Router) |
| Runtime | Bun |
| Database | PostgreSQL + pgvector extension |
| ORM | Drizzle ORM |
| Realtime | Socket.IO (`apps/realtime`) |
| Pub/Sub | Redis |
| Canvas | ReactFlow (custom nodes, edges, minimap) |
| State management | Zustand stores |
| Styling | Tailwind CSS + shadcn/ui |
| Language | TypeScript (strict) |

## Monorepo Layout

```
sim/
├── apps/
│   ├── sim/                    ← Next.js main application
│   │   ├── app/                ← App Router pages & layouts
│   │   ├── blocks/             ← Block system (registry, types, definitions)
│   │   │   ├── blocks/         ← ~180 block definition directories
│   │   │   ├── serializer/     ← BlockConfig → SerializedBlock
│   │   │   ├── registry.ts     ← Central block registry (538 lines)
│   │   │   └── types.ts        ← BlockConfig, SubBlockConfig interfaces
│   │   ├── executor/           ← Block execution engine
│   │   │   └── handlers/       ← BlockHandler implementations
│   │   ├── tools/              ← ~180 tool implementation directories
│   │   ├── stores/             ← Zustand stores
│   │   │   ├── workflow/       ← Canvas/workflow state
│   │   │   ├── panel/          ← Panel/sidebar state
│   │   │   └── panel/toolbar/  ← Toolbar state
│   │   ├── lib/                ← Shared utilities, helpers, schemas
│   │   └── components/         ← React components (BlockNode, Panel, Toolbar, etc.)
│   └── realtime/               ← Socket.IO server (realtime collaboration)
├── packages/                   ← Shared libraries
└── drizzle/                    ← Drizzle config & migrations
```

## Key Paths

| Path | Purpose |
|------|---------|
| `apps/sim/blocks/` | Block system — registry, types, definitions, serializer |
| `apps/sim/blocks/blocks/` | ~180 block definition directories (one per block type) |
| `apps/sim/blocks/registry.ts` | Central block registry — `Record<string, BlockConfig>` |
| `apps/sim/executor/` | Block execution engine with handler pattern |
| `apps/sim/executor/handlers/` | BlockHandler implementations (Agent, Function, API, Condition, Router, Generic, etc.) |
| `apps/sim/tools/` | ~180 tool implementation directories |
| `apps/sim/stores/` | Zustand stores (workflow, panel, toolbar) |
| `apps/sim/lib/` | Shared utilities, validation schemas, helper functions |
| `apps/sim/components/` | React components — BlockNode, Panel, Toolbar, Canvas overlays |
| `apps/sim/app/` | Next.js App Router — pages, layouts, API routes |
| `apps/realtime/` | Socket.IO server for realtime collaboration |
| `packages/` | Shared libraries across apps |

## Database Schema

PostgreSQL via Drizzle ORM — **26+ tables** including:

- **Workflows:** `workflow`, `workflow_block`, `workflow_edge`, `workflow_variables`
- **Blocks:** `block_snapshot`, `block_state`
- **Execution:** `execution`, `execution_edge`, `execution_loop`
- **Knowledge/RAG:** `knowledge_base`, `knowledge_document`, `knowledge_chunk`, `knowledge_embedding`
- **Integrations:** `integration`, `integration_credential`, `oauth_state`
- **Users & Auth:** `user`, `workspace`, `workspace_member`
- **MCP:** `mcp_server`, `mcp_tool`
- **Realtime:** `collaboration_session`

All vector operations use the **pgvector** extension for similarity search on embeddings.

## Architecture Patterns

1. **Declarative Block Config** — Blocks define WHAT to do (config), executor defines HOW (handler)
2. **Generic Fallback** — `GenericBlockHandler` serves 95%+ of blocks via `tools.config`
3. **Registry Pattern** — Central `Record<string, BlockConfig>` lookup, versioned entries coexist
4. **CustomEvent Bridge** — Toolbar ↔ Canvas communication via `window.dispatchEvent` (avoids circular imports)
5. **Zustand Store Slices** — Domain-specific stores persisted to `localStorage` where appropriate
6. **Tool Abstraction** — Each tool is an independent directory implementing a standard interface
7. **Handler Chain** — `BlockHandler.canHandle(block)` → first matching handler executes, `GenericBlockHandler` as fallback
