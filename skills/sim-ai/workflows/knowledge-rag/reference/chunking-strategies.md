# Chunking Strategies — Reference

Detailed reference for all 8 chunking strategies in the Sim Studio AI Knowledge/RAG pipeline.

**Source:** `apps/sim/lib/chunkers/`

---

## 1. TextChunker

**Strategy:** Fixed-size text blocks

Splits raw text into chunks of a fixed character size. Simplest chunker — no awareness of document structure.

- **Best for:** Generic text, unstructured content, unknown formats
- **Config:**
  - `chunkSize` — max characters per chunk
  - `chunkOverlap` — overlap characters between chunks
  - `minCharactersPerChunk` — discard chunks below this threshold

---

## 2. TokenChunker

**Strategy:** Split by exact token count

Uses a tokenizer to split text into chunks of exactly N tokens. More precise than character-based splitting because it accounts for actual token usage.

- **Best for:** Precise control over chunk token count, LLM context window alignment
- **Config:**
  - `chunkSize` — max tokens per chunk
  - `chunkOverlap` — overlap tokens between chunks
  - `minCharactersPerChunk` — minimum characters to keep a chunk

---

## 3. RecursiveChunker

**Strategy:** Recursive split by separator hierarchy

Splits text using a prioritized list of separators, recursively subdividing each piece until chunks fit within the size limit. Supports recipes that define different separator hierarchies.

- **Recipes:**
  - `plain` — generic text separators (paragraphs, lines)
  - `markdown` — Markdown-aware separators (headers, code blocks, lists)
  - `code` — code-aware separators (functions, classes, blocks)
- **Best for:** Markdown documents, source code, mixed-format content
- **Config:**
  - `chunkSize` — max tokens per chunk
  - `chunkOverlap` — overlap tokens between chunks
  - `minCharactersPerChunk` — minimum characters to keep a chunk

---

## 4. SentenceChunker

**Strategy:** Split by sentence boundaries

Uses natural language sentence detection to split text at sentence boundaries. Preserves sentence integrity — no mid-sentence cuts.

- **Best for:** Natural language prose, articles, conversational text
- **Config:**
  - `chunkSize` — max tokens per chunk
  - `chunkOverlap` — overlap tokens between chunks
  - `minCharactersPerChunk` — minimum characters to keep a chunk

---

## 5. RegexChunker

**Strategy:** Custom regex pattern splitting

Splits text using a user-provided regular expression pattern. Fully customizable for domain-specific document structures.

- **Best for:** Structured content with known delimiters (e.g., legal clauses, log entries, custom markup)
- **Config:**
  - Regex pattern defined per knowledge base
  - `chunkSize` — max tokens per chunk
  - `chunkOverlap` — overlap tokens between chunks
  - `minCharactersPerChunk` — minimum characters to keep a chunk

---

## 6. DocsChunker

**Strategy:** Split by Markdown headers → sections

Parses Markdown structure and splits at header boundaries (`#`, `##`, `###`, etc.). Each section between headers becomes a chunk.

- **Best for:** Technical documentation, wikis, README files, structured Markdown
- **Config:**
  - `chunkSize` — max tokens per chunk (sections exceeding this are further split)
  - `chunkOverlap` — overlap tokens between chunks
  - `minCharactersPerChunk` — minimum characters to keep a chunk

---

## 7. JsonYamlChunker

**Strategy:** Split by JSON/YAML paths

Parses JSON or YAML structures and creates chunks based on object paths (keys). Each meaningful path segment becomes a separate chunk with its value.

- **Best for:** Configuration files, API responses, data interchange files, YAML manifests
- **Config:**
  - `chunkSize` — max tokens per chunk
  - `chunkOverlap` — overlap tokens between chunks
  - `minCharactersPerChunk` — minimum characters to keep a chunk

---

## 8. StructuredDataChunker

**Strategy:** Split CSV/tables into rows

Parses tabular data (CSV, TSV) and creates one chunk per row (or grouped rows). Headers are preserved or included as context.

- **Best for:** CSV files, spreadsheet data, database exports, tabular datasets
- **Config:**
  - `chunkSize` — max tokens per chunk
  - `chunkOverlap` — overlap tokens between chunks
  - `minCharactersPerChunk` — minimum characters to keep a chunk

---

## Auto Strategy

**`chunkingStrategy: 'auto'`** is the default. The system detects the content type of the uploaded document and selects the best chunker:

- Markdown content → `DocsChunker` or `RecursiveChunker` (markdown recipe)
- Code files → `RecursiveChunker` (code recipe)
- JSON/YAML → `JsonYamlChunker`
- CSV/tabular → `StructuredDataChunker`
- Plain text → `RecursiveChunker` (plain recipe) or `TextChunker`

Users can always override auto-detection by explicitly setting a `chunkingStrategy`.

---

## TypeScript Types

```typescript
type ChunkingStrategy = 'auto' | 'text' | 'regex' | 'recursive' | 'sentence' | 'token'
type RecursiveRecipe = 'plain' | 'markdown' | 'code'

interface ChunkerOptions {
  chunkSize?: number              // in TOKENS
  chunkOverlap?: number           // in TOKENS
  minCharactersPerChunk?: number  // in CHARACTERS
}

interface Chunk {
  text: string
  tokenCount: number
  metadata: {
    startIndex: number
    endIndex: number
  }
}
```

---

## Selection Guide

| Content Type | Recommended Chunker | Reason |
|---|---|---|
| Unknown / mixed | `auto` | System detects best strategy |
| Plain text | `TextChunker` or `RecursiveChunker` (plain) | Simple splitting |
| Markdown docs | `DocsChunker` | Preserves header structure |
| Source code | `RecursiveChunker` (code recipe) | Code-aware boundaries |
| Articles / prose | `SentenceChunker` | Preserves sentence integrity |
| Structured logs / custom format | `RegexChunker` | Custom delimiter support |
| JSON / YAML config | `JsonYamlChunker` | Path-based splitting |
| CSV / spreadsheets | `StructuredDataChunker` | Row-based splitting |
| Precise token control | `TokenChunker` | Exact token counting |
