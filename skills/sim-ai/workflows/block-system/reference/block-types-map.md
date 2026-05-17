# Block Types Map

Complete mapping of every block type in the Sim Studio AI registry, organized by category with key configuration details.

Source: `blocks/registry.ts` (~538 lines) in `github.com/simstudioai/sim` v0.6.84.

## Category: `blocks` (Core Workflow — 24 types)

Core workflow building blocks that define agent logic, flow control, and data operations.

- **`agent`** — LLM agent with tools + memory loop. Handler: `AgentBlockHandler`. Supports `tool-input`, `messages-input`, `skill-input` subblocks.
- **`api`** — HTTP request block. Handler: `ApiBlockHandler`. Config: method, URL, headers, body via `tools.config`.
- **`condition`** — Boolean branching. Handler: `ConditionBlockHandler`. Uses `condition-input` subblock for rule evaluation.
- **`credential`** — Credential management block. Handles OAuth/API key credential storage.
- **`evaluator`** — Evaluation block. Uses `eval-input` for expression-based evaluation.
- **`function`** — JS/Python sandbox execution. Handler: `FunctionBlockHandler`. Uses `code` subblock with language selection.
- **`guardrails`** — Input/output guardrail enforcement. Validates data against defined rules.
- **`human_in_the_loop`** — Approval pause block. Handler: `HumanInTheLoopBlockHandler`. Pauses workflow pending human review.
- **`knowledge`** — Knowledge base integration. Connects to RAG/embedding pipelines.
- **`logs`** — Logging and audit block. Captures workflow execution data.
- **`memory`** — Agent memory management. Store/retrieve conversational context.
- **`mothership`** — Internal orchestration block. `hideFromToolbar: true` (infrastructure use).
- **`note`** — Canvas annotation block. Display-only, no execution.
- **`response`** — API response block. Handler: `ResponseBlockHandler`. Defines output format for API endpoints.
- **`router`** — Intelligent routing. Handler: `RouterBlockHandler`. Uses `router-input` for route rules. Legacy version.
- **`router_v2`** — Router v2. Improved routing logic with enhanced condition builder.
- **`starter`** — Workflow entry point. Uses `input-format` for initial parameter schema.
- **`table`** — Data table operations. Uses `table-selector` for dynamic table references.
- **`variables`** — Variable management. Uses `variables-input` for key-value pairs.
- **`wait`** — Delay/sleep block. Pauses workflow execution for a specified duration.
- **`webhook_request`** — Outbound webhook. Sends HTTP requests to external endpoints.
- **`workflow`** — Sub-workflow invocation. Uses `workflow-selector` to reference other workflows.
- **`workflow_input`** — Workflow input parameter definition. Defines the schema for workflow inputs.

## Category: `triggers` (10 types)

Blocks that initiate workflow execution based on external events.

- **`start_trigger`** — Manual start. `TriggerBlockHandler`. Primary workflow trigger.
- **`schedule`** — Cron-based scheduling. Uses `schedule-info` subblock for cron expression display.
- **`generic_webhook`** — Webhook endpoint trigger. Creates a public webhook URL. Uses `webhook-config`.
- **`chat_trigger`** — Chat interface trigger. Starts workflow from chat interaction.
- **`manual_trigger`** — Manual execution trigger. Requires explicit user action.
- **`api_trigger`** — API call trigger. Starts workflow via API request.
- **`input_trigger`** — Input-based trigger. Starts workflow when input data is provided.
- **`rss`** — RSS feed monitor. Polls RSS/Atom feeds for new entries.
- **`imap`** — IMAP email monitor. Watches email inboxes for new messages. Uses `folder-selector`.
- **`circleback`** — Circleback integration trigger. Connects to Circleback meeting service.

## Category: `tools` (180+ integration types)

External service integrations. All served by `GenericBlockHandler` unless noted. Each uses `tools.config` with dynamic `tool(params)` resolution based on `operation` dropdown.

### AI / ML

- **`openai`** — OpenAI API (GPT models, embeddings). IntegrationType: AI.
- **`perplexity`** — Perplexity AI search API.
- **`huggingface`** — HuggingFace models and inference.
- **`elevenlabs`** — ElevenLabs text-to-speech.
- **`vision`** — Vision/image analysis.
- **`stt`** — Speech-to-text transcription.
- **`tts`** — Text-to-speech synthesis.
- **`browser_use`** — Browser automation (AI-driven).
- **`stagehand`** — Stagehand browser automation.
- **`dspy`** — DSPy framework integration.

### Databases

- **`postgresql`** — PostgreSQL database operations.
- **`mysql`** — MySQL database operations.
- **`mongodb`** — MongoDB document database.
- **`redis`** — Redis cache/store operations.
- **`supabase`** — Supabase (PostgreSQL + auth + storage).
- **`neo4j`** — Neo4j graph database.
- **`pinecone`** — Pinecone vector database.
- **`qdrant`** — Qdrant vector database.
- **`databricks`** — Databricks data platform.
- **`bigquery`** — Google BigQuery analytics.

### CRM

- **`hubspot`** — HubSpot CRM operations.
- **`salesforce`** — Salesforce CRM operations.
- **`pipedrive`** — Pipedrive CRM operations.
- **`attio`** — Attio CRM operations.

### Communication

- **`slack`** — Slack messaging. Uses `channel-selector`, `user-selector`. Supports OAuth.
- **`discord`** — Discord messaging and server management.
- **`telegram`** — Telegram bot messaging.
- **`whatsapp`** — WhatsApp Business API messaging.
- **`teams`** — Microsoft Teams messaging.
- **`zoom`** — Zoom meeting management.
- **`twilio`** — Twilio SMS/voice/video.

### Email

- **`gmail`** — Gmail operations. Uses `folder-selector` with GMAIL_INBOX overrides.
- **`outlook`** — Outlook/Microsoft 365 email.
- **`resend`** — Resend transactional email API.
- **`sendgrid`** — SendGrid email delivery.
- **`mailchimp`** — Mailchimp email marketing.

### Developer Tools

- **`github`** — GitHub repositories, issues, PRs.
- **`gitlab`** — GitLab projects and CI/CD.
- **`vercel`** — Vercel deployments.
- **`cloudflare`** — Cloudflare DNS/CDN/Workers.
- **`sentry`** — Sentry error tracking.
- **`launchdarkly`** — LaunchDarkly feature flags.

### Documents / Productivity

- **`google_docs`** — Google Docs read/write.
- **`google_sheets`** — Google Sheets operations. Uses `sheet-selector`.
- **`notion`** — Notion pages and databases.
- **`confluence`** — Confluence wiki pages.
- **`sharepoint`** — SharePoint document management.
- **`asana`** — Asana project management.
- **`jira`** — Jira issues and boards.
- **`linear`** — Linear issue tracking.
- **`monday`** — Monday.com project boards.
- **`trello`** — Trello boards and cards.
- **`google_calendar`** — Google Calendar events.

### Search / Scraping

- **`google_search`** — Google Search API.
- **`tavily`** — Tavily AI search.
- **`serper`** — Serper Google search API.
- **`exa`** — Exa AI search.
- **`firecrawl`** — Firecrawl web scraping.

### File Storage

- **`google_drive`** — Google Drive file operations. Uses `file-selector`.
- **`onedrive`** — OneDrive file operations.
- **`dropbox`** — Dropbox file operations.
- **`s3`** — Amazon S3 storage.
- **`sftp`** — SFTP file transfer. Versioned: `sftp` may have `_v2`, `_v3` variants.

### Security / Auth

- **`okta`** — Okta identity management.
- **`clerk`** — Clerk authentication.
- **`infisical`** — Infisical secrets management.
- **`crowdstrike`** — CrowdStrike security.

### Versioned Blocks

Some blocks have multiple versions coexisting in the registry:

- **`file`** → `file_v2`, `file_v3`, `file_v4` — File operations across versions
- **`sftp`** — May have versioned variants

Use `getLatestBlock('file')` to resolve to the newest version (`file_v4`). Use `createVersionedToolSelector()` for version-aware tool mapping.

## Key Configuration Reference

### BlockConfig Required Fields

| Field | Type | Purpose |
|-------|------|---------|
| `type` | `string` | Unique identifier (e.g. `'agent'`, `'slack'`) |
| `name` | `string` | Display name in the editor |
| `description` | `string` | Short description |
| `category` | `'blocks' \| 'tools' \| 'triggers'` | Classification |
| `bgColor` | `string` | Node color on canvas |
| `icon` | `BlockIcon` | SVG React component |
| `subBlocks` | `SubBlockConfig[]` | Configuration UI fields |
| `tools` | `{ access, config }` | Executor tool mapping |
| `inputs` | `Record<string, ParamConfig>` | Input schema |
| `outputs` | `Record<string, OutputFieldDefinition>` | Output schema |

### tools.config Bridge

```typescript
tools: {
  access: ['tool_create', 'tool_update'],  // available tool IDs
  config: {
    tool: (params) => `tool_${params.operation}`,   // dynamic tool resolution
    params: (params) => ({ ...params }),              // input transformation
  },
}
```

### Handler Routing

```
Block → BlockHandler.canHandle(block)?
  → YES: handler.execute(ctx, block, inputs)
  → NO:  try next handler
  → GenericBlockHandler (always matches tools category)
       → tools.config.tool(params) → executeTool(toolId, inputs)
```
