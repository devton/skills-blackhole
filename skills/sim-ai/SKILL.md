---
name: sim-ai
description: Operational reference for building and contributing to Sim Studio AI — an open-source agent workflow platform with a visual canvas editor. Classifies tasks and routes to the correct sub-skill.
version: 1.0.0
author: skills-blackhole
license: MIT
metadata:
  hermes:
    tags: [sim-ai, agents, workflows, visual-editor, canvas, reactflow, blocks, tools, mcp, rag]
    related_skills:
      - sim-ai-block-system
      - sim-ai-toolbar
      - sim-ai-subblock-system
      - sim-ai-block-node-canvas
      - sim-ai-canvas-editor
      - sim-ai-knowledge-rag
      - sim-ai-mcp-integration
---

# Sim Studio AI — Orchestrator

## Goal

Complete operational reference for building and contributing to **Sim Studio AI** — an open-source agent workflow platform with a visual canvas editor (ReactFlow). This skill classifies incoming tasks and routes to the appropriate sub-skill for deterministic execution.

## Scope

- **Applies to:** any development task on the Sim Studio AI codebase (`github.com/simstudioai/sim`, v0.6.84)
- **Covers:**
  - Block system — config, registry, tools, executor handlers
  - Toolbar — panel, search, drag-and-drop insertion, context menus
  - SubBlock system — types, conditions, canonical params, wand
  - Block node canvas — visual rendering, handles, dimensions, selection ring
  - Canvas editor — ReactFlow store, subflows, layout, zoom, minimap
  - Knowledge/RAG — embeddings, chunking, vector search (pgvector)
  - MCP integration — servers, tools, dynamic args
- **Does NOT cover:** billing, authentication system, deployment operations, infrastructure provisioning

## Project Constraints

- **Stack:** Next.js + Bun runtime + PostgreSQL (pgvector extension)
- **Realtime:** Socket.IO server (`apps/realtime`) + Redis for pub/sub
- **Monorepo:** `apps/sim` (Next.js app) · `apps/realtime` (Socket.IO) · `packages/` (shared libs)
- **Canvas:** ReactFlow (custom nodes, edges, minimap, controls)
- **State:** Zustand stores (workflow, panel, toolbar, etc.)
- **ORM:** Drizzle ORM with PostgreSQL — 26+ tables
- **Styling:** Tailwind CSS + shadcn/ui components
- **Version:** v0.6.84

## Orchestrator — Task Classification

When a task arrives, classify it by matching keywords/intent to the correct workflow:

| Intent / Keywords | Workflow | Sub-skill |
|---|---|---|
| Block config, BlockConfig, registry, tool definition, API contract, `blocks/blocks/`, `blocks/registry.ts` | Block System | `workflows/block-system` |
| Toolbar, panel, sidebar, menu insertion, drag-and-drop, search, context menu, `toolbar.tsx`, `panel.tsx` | Toolbar | `workflows/toolbar` |
| SubBlock, SubBlockConfig, SubBlockType, condition, canonicalParamId, wand, `subBlocks: [...]` | SubBlock System | `workflows/subblock-system` |
| Block node, canvas node, handles, dimensions, selection ring, `BlockNode`, `CustomNode` | Block Node Canvas | `workflows/block-node-canvas` |
| Canvas editor, ReactFlow store, subflows, layout, zoom, minimap, `workflow.tsx`, `useWorkflowStore` | Canvas Editor | `workflows/canvas-editor` |
| Knowledge, RAG, embeddings, chunking, vector search, pgvector, documents | Knowledge / RAG | `workflows/knowledge-rag` |
| MCP, Model Context Protocol, servers, MCP tools, `mcp-server-selector`, `mcp-tool-selector` | MCP Integration | `workflows/mcp-integration` |

**Routing procedure:**
1. Read the task description.
2. Match the primary domain using the table above (first match wins; if ambiguous, ask for clarification).
3. Load the corresponding sub-skill.
4. If the task spans multiple domains, load each relevant sub-skill and sequence the work.

## Workflows

- **[Block System](workflows/block-system)** — BlockConfig declarative architecture, registry API, tool mapping, executor handlers, versioning. Covers `blocks/`, `tools/`, `executor/`.
- **[Toolbar](workflows/toolbar)** — Editor visual toolbar, block insertion (click/drag/drop), search, context menus, panel tabs, keyboard shortcuts. Covers `toolbar/`, `panel/`.
- **[SubBlock System](workflows/subblock-system)** — SubBlockConfig types, conditional visibility, canonical params, wand (AI assistant), mode (basic/advanced). Covers `subBlocks` array definitions.
- **[Block Node Canvas](workflows/block-node-canvas)** — Visual block node in ReactFlow canvas, handles (input/output), dimensions, selection ring, icon rendering. Covers `BlockNode` components.
- **[Canvas Editor](workflows/canvas-editor)** — ReactFlow integration, Zustand workflow store, subflows, auto-layout, zoom, minimap, edge rendering. Covers `workflow.tsx`, `stores/`.
- **[Knowledge / RAG](workflows/knowledge-rag)** — Knowledge bases, document upload, chunking strategies, embedding generation, vector search via pgvector. Covers `knowledge/`, embeddings pipeline.
- **[MCP Integration](workflows/mcp-integration)** — Model Context Protocol server connections, tool discovery, dynamic args, selector UI components. Covers MCP server/tool management.

## References

- Architecture overview: `reference/architecture-overview.md`

## Review Gate

Before finalizing any task routed through this skill:

- [ ] Task was classified to the correct sub-skill
- [ ] Changes respect project constraints (stack, monorepo layout, ORM patterns)
- [ ] No modifications to out-of-scope areas (billing, auth, deployment)
- [ ] Sub-skill review gate passed
- [ ] All links and references resolve correctly
