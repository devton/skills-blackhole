---
name: sim-ai-knowledge-rag
description: Knowledge/RAG pipeline for Sim Studio AI — document upload, parsing/OCR, 8 chunking strategies, embeddings (OpenAI/Gemini), pgvector vector search (3 modes), Cohere reranker, and a 17-slot typed tag system. Extracted from simstudioai/sim v0.6.84.
version: 1.0.0
author: skills-blackhole
license: MIT
metadata:
  hermes:
    tags: [sim-ai, rag, knowledge, embeddings, pgvector, chunking, reranker, vector-search]
    related_skills:
      - sim-ai
      - sim-ai-block-system
---

## sim-ai.workflow.knowledge-rag

### Goal

Implement and maintain the Knowledge/RAG pipeline — from document upload through parsing, chunking, embedding, pgvector storage, vector search, Cohere reranking, and typed tag filtering — that powers semantic retrieval for Sim Studio AI agents.

### Scope

- **Applies to:**
  - Document upload pipeline: file/URL/connector → MIME detection → parsing/OCR → text extraction
  - 8 chunking strategies (`apps/sim/lib/chunkers/`): text, token, recursive, sentence, regex, docs, json-yaml, structured-data (+ auto-detect)
  - Embedding generation (`apps/sim/lib/knowledge/embeddings.ts`): OpenAI, Azure OpenAI, Gemini providers; batch processing with retry
  - Embedding model registry (`apps/sim/lib/knowledge/embedding-models.ts`): `text-embedding-3-small`, `text-embedding-3-large`, `gemini-embedding-001`
  - pgvector storage: `document_chunk` table with vector column, cosine distance
  - 3 search modes: vector-only, tag-only, tag+vector hybrid
  - Cohere reranker (`apps/sim/lib/knowledge/reranker.ts`): `rerank-v4.0-pro`, `rerank-v4.0-fast`, `rerank-v3.5`
  - 17-slot typed tag system (`apps/sim/lib/knowledge/tags/`): 7 text, 5 number, 2 date, 3 boolean
  - Connectors (`apps/sim/app/api/knowledge/[id]/connectors/`): external source sync
  - API routes (`/api/knowledge/...`): CRUD for knowledge bases, documents, chunks, connectors, tag definitions
- **Does NOT cover:**
  - Block system configuration (see `workflows/block-system`)
  - Canvas rendering and ReactFlow integration (see `workflows/canvas-editor`)
  - Toolbar and panel UI (see `workflows/toolbar`)

### Triggers

- "Add a knowledge base" / "Create a knowledge base"
- "Upload documents" / "Parse a file" / "Extract text from PDF"
- "Chunk a document" / "Split text into chunks" / "Change chunking strategy"
- "Generate embeddings" / "Use a different embedding model"
- "Vector search" / "Semantic search" / "Query knowledge base"
- "Rerank results" / "Improve search precision"
- "Add tags to documents" / "Filter by tags"
- "Set up a connector" / "Sync external documents"
- Working on `lib/chunkers/`
- Working on `lib/knowledge/`
- Working on `app/api/knowledge/`
- Files matching `embeddings.ts`, `reranker.ts`, `chunkers/index.ts`

### Inputs

- `knowledgeBaseId` — unique identifier for the knowledge base
- `documents` — uploaded files, URLs, or connector-synced sources
- `chunkingStrategy` — `'auto' | 'text' | 'regex' | 'recursive' | 'sentence' | 'token'` (plus `docs`, `json-yaml`, `structured-data` via auto)
- `ChunkerOptions` — `{ chunkSize, chunkOverlap, minCharactersPerChunk }`
- `embeddingModel` — model ID from registry (default: `text-embedding-3-small`)
- `SearchParams` — `{ knowledgeBaseIds, topK, structuredFilters, queryVector, distanceThreshold }`
- `RerankerConfig` — model selection (default: `rerank-v4.0-fast`)

### Invariants

- **Auto-chunking fallback:** When `chunkingStrategy = 'auto'`, the system detects content type and selects the best chunker. Users can always override.
- **Batch embedding with retry:** Embeddings are batched by token limit (`MAX_TOKENS_PER_REQUEST = 8000`), executed concurrently (`MAX_CONCURRENT_BATCHES = 50`), with exponential backoff retry.
- **BYOK everywhere:** Workspace-level API keys for OpenAI, Gemini, and Cohere override global defaults.
- **Typed tag slots (17 fixed):** Performance-optimized schema — 7 text (`tag1`–`tag7`), 5 number (`number1`–`number5`), 2 date (`date1`–`date2`), 3 boolean (`boolean1`–`boolean3`) — instead of flexible JSON.
- **Rerank is optional:** Vector search works without reranking. Reranking adds a Cohere relevance-scoring layer to improve precision.
- **Structured filters pre-search:** Tag values are typed columns enabling SQL-level filtering before vector search, not post-hoc filtering.

### Procedure

#### 1. Upload pipeline

```
Upload (file / URL / connector)
  → MIME-type detection
  → Parsing & OCR (text extraction)
  → Raw text ready for chunking
```

Documents enter via upload, URL import, or connector sync. MIME detection routes to the appropriate parser. OCR extracts text from images/PDFs.

#### 2. Chunking strategies (8 strategies)

Select a chunking strategy per knowledge base. The system supports 8 strategies via `apps/sim/lib/chunkers/`:

- **TextChunker** — Fixed-size text blocks, generic use
- **TokenChunker** — Split by exact token count, precise sizing
- **RecursiveChunker** — Recursive split by separator hierarchy; recipes: `plain`, `markdown`, `code`
- **SentenceChunker** — Split by sentence boundaries, natural language
- **RegexChunker** — Custom regex pattern splitting, structured content
- **DocsChunker** — Split by Markdown headers → sections, documentation
- **JsonYamlChunker** — Split by JSON/YAML paths, config/data files
- **StructuredDataChunker** — Split CSV/tables into rows, tabular data

**`auto` strategy** detects content type and selects the best chunker automatically.

**Chunker options:**
```typescript
interface ChunkerOptions {
  chunkSize?: number              // in TOKENS
  chunkOverlap?: number           // in TOKENS
  minCharactersPerChunk?: number  // in CHARACTERS
}
```

**Chunk output:**
```typescript
interface Chunk {
  text: string
  tokenCount: number
  metadata: { startIndex: number; endIndex: number }
}
```

→ See detailed reference: [reference/chunking-strategies.md](reference/chunking-strategies.md)

#### 3. Embedding models and generation

```typescript
SUPPORTED_EMBEDDING_MODELS = {
  'text-embedding-3-small': { provider: 'openai',  dimensions: 1536 },
  'text-embedding-3-large': { provider: 'openai',  dimensions: 3072 },
  'gemini-embedding-001':   { provider: 'gemini',  tokenizer: 'google' },
}
```

- **Default:** `text-embedding-3-small` (1536 dimensions)
- **Providers:** OpenAI (`/v1/embeddings`), Azure OpenAI (BYOK workspace key), Gemini (`batchEmbedContents`, max 100/request)
- **Config:** `MAX_TOKENS_PER_REQUEST = 8000`, `MAX_CONCURRENT_BATCHES = 50`, `EMBEDDING_REQUEST_TIMEOUT_MS = 60_000`

#### 4. pgvector search (3 modes)

```
Query text → generateSearchEmbedding() → vector
  → pgvector cosine distance search via SQL
  → 3 modes: vector-only | tag-only | tag+vector
  → Reranking (optional, Cohere)
  → Top-K filtered results
```

**Search result schema:**
```typescript
interface SearchResult {
  id: string
  content: string
  documentId: string
  chunkIndex: number
  tag1-7: string | null         // 7 text tag slots
  number1-5: number | null      // 5 number tag slots
  date1-2: Date | null          // 2 date tag slots
  boolean1-3: boolean | null    // 3 boolean tag slots
  distance: number
  knowledgeBaseId: string
}
```

**Search parameters:**
```typescript
interface SearchParams {
  knowledgeBaseIds: string[]
  topK: number
  structuredFilters?: StructuredFilter[]
  queryVector?: string
  distanceThreshold?: number
}
```

#### 5. Reranker (Cohere)

```typescript
RerankerModelId = 'rerank-v4.0-pro' | 'rerank-v4.0-fast' | 'rerank-v3.5'
DEFAULT = 'rerank-v4.0-fast'
```

- **Provider:** Cohere (`/v1/rerank`)
- **Max 100 docs** per rerank call (1 search unit)
- **Flow:** Vector search top-K candidates → Cohere rerank → relevance score filtering → return final top-K
- **BYOK:** Workspace-level Cohere API key supported

#### 6. Tag system (17 slots)

Tags are **definitions** (name + type) created per knowledge base, with **values** assigned per document/chunk.

- 7 text slots (`tag1`–`tag7`)
- 5 number slots (`number1`–`number5`)
- 2 date slots (`date1`–`date2`)
- 3 boolean slots (`boolean1`–`boolean3`)

Tag operations:
- Tag definitions: CRUD via `/api/knowledge/[id]/tag-definitions`
- Tag filtering: `StructuredFilter[]` in search queries
- Tag auto-extraction: AI-powered extraction at upload time

#### 7. Connectors

External source connectors (`/api/knowledge/[id]/connectors/`):
- CRUD per knowledge base
- Manual or scheduled sync
- Automatic document discovery and upload

#### 8. API routes

- `GET/POST /api/knowledge` — List/Create knowledge bases
- `GET/PATCH/DELETE /api/knowledge/[id]` — CRUD knowledge base
- `GET/POST /api/knowledge/[id]/documents` — List/Upload documents
- `POST /api/knowledge/[id]/documents/upsert` — Upsert document
- `GET/DELETE /api/knowledge/[id]/documents/[documentId]` — Document detail
- `GET /api/knowledge/[id]/documents/[documentId]/chunks` — List chunks
- `PATCH /api/knowledge/[id]/documents/[documentId]/chunks/[chunkId]` — Edit chunk
- `POST /api/knowledge/[id]/search` — Vector search
- `GET/POST /api/knowledge/[id]/connectors` — CRUD connectors
- `POST /api/knowledge/[id]/connectors/[connectorId]/sync` — Trigger sync
- `GET/POST /api/knowledge/[id]/tag-definitions` — CRUD tag definitions

### Outputs

- Knowledge base with configured chunking strategy and embedding model
- Ingested documents parsed, chunked, embedded, and stored in pgvector
- Search results with optional reranking and tag filtering
- Tag definitions and auto-extracted tag values

### Key files

- `lib/chunkers/index.ts` — Chunker registry (8 strategies)
- `lib/knowledge/embeddings.ts` — Embedding generation (batch, retry)
- `lib/knowledge/embedding-models.ts` — Model registry (OpenAI/Gemini)
- `lib/knowledge/reranker.ts` — Cohere reranker client
- `lib/knowledge/reranker-models.ts` — Reranker model registry
- `lib/knowledge/tags/` — Tag system (definitions, values)
- `app/api/knowledge/search/route.ts` — Search endpoint
- `app/api/knowledge/search/utils.ts` — Search logic (vector/tag/hybrid)

### Review gate

- [ ] Chunking strategy is appropriate for the content type (or `auto` is used)
- [ ] Embedding model is registered in `embedding-models.ts` and dimensions match pgvector column
- [ ] Batch embedding respects `MAX_TOKENS_PER_REQUEST` and concurrency limits
- [ ] Search mode (vector-only / tag-only / tag+vector) is correct for the use case
- [ ] Reranker model ID is valid (`rerank-v4.0-pro` | `rerank-v4.0-fast` | `rerank-v3.5`)
- [ ] Tag definitions use correct slot types (text/number/date/boolean)
- [ ] Structured filters map to valid tag slots before vector search
- [ ] BYOK workspace keys are used when configured
- [ ] No modifications to out-of-scope areas (blocks, canvas, toolbar)
- [ ] API route signatures match the documented endpoints

### References

- Parent skill: [../../SKILL.md](../../SKILL.md)
- Chunking strategies: [reference/chunking-strategies.md](reference/chunking-strategies.md)
- Architecture overview: [../../reference/architecture-overview.md](../../reference/architecture-overview.md)
