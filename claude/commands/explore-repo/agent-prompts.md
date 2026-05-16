# Exploration Agent Prompts

Prompt templates for each exploration agent. The orchestrating agent injects PROJECT_CONTEXT, COMMIT_HASH, BRANCH_NAME, and DATE before launching each agent.

## Common Rules

Include these rules in EVERY agent prompt:

```
RULES:
- Read EVERY relevant file in your domain. Do not sample or skip files.
- NEVER include contents of sensitive files (.env, credentials, secrets, private keys, API keys) in your output. Note their existence but not their contents.
- If you encounter more than 100 files in your domain, split into logical groups and use the Task tool to spawn sub-agents for each group, then combine their results.
- Structure your output using the headings specified in your Output Format section. Every agent output MUST include these standardized sections in order: Overview, Key Findings, [domain-specific sections], Gotchas, Scan Limitations.
- Be factual. Report what you find, don't speculate about what might exist.
- Include file paths when referencing specific code so the reader can navigate to it.
- ONLY write to your assigned output file. Do not create any other files.
- Stay within your domain boundaries (see Domain Boundaries table below). If you find something interesting outside your domain, mention it briefly but do not deep-dive — the responsible agent will cover it.
- DEDUPLICATE cross-domain findings. When a finding spans multiple domains (e.g., security config, naming conventions), ONE agent should report the full analysis (whichever domain owns it per the boundaries table). All other agents should mention it in one sentence with a cross-reference: "Security configuration permits all endpoints — see `docs/explore-repo/config-ops.md` for full analysis."

CONCISION MANDATE (this is a hard requirement, not a suggestion):
- Target file length: 200–350 lines, including tables. If you blow past 400, you are being too verbose — cut.
- Lead with the table or diagram. Prose is the fallback when structure won't work.
- One-line bullets. No multi-sentence bullets. No paragraphs longer than 2 sentences.
- Strip throat-clearing: no "In this section we will...", "It is worth noting that...", "The system has a...".
- For each entity / endpoint / service / workflow / property: ONE table row, not a paragraph. Push the row's "why" into a single short cell, not a follow-up paragraph.
- Gotchas: each one is ONE numbered bullet, ≤2 sentences. The first sentence is the rule, the second (optional) is the why.
- Use diagrams for: state machines, end-to-end flows, dependency graphs, sequence interactions, branching logic. Use ASCII only — box-drawing characters (┌ ┐ └ ┘ │ ─ ▶ ◀) for components, arrows (→ ⇒) and labels for transitions. No Mermaid, no Graphviz, no rendered formats — output must read correctly in a plain terminal. Keep diagrams ≤25 lines wide and ≤30 lines tall; if you can't fit it, the diagram is doing too much — split or replace with a table.
- Use tables for: anything enumerable (modules, endpoints, entities, properties, services, scheduled jobs, profiles, tests, scripts).

DO NOT DOCUMENT:
- Dependency version numbers unless the specific version constrains behavior (e.g., "Java 17 specifically, not 21" is worth noting; "Guava 33.3.1-jre" is not)
- Standard framework conventions that any developer familiar with the framework would already know (e.g., don't explain what @RestController does in a Spring Boot project)
- Every file in a directory — describe the pattern instead (e.g., "21 partner adapter modules following the {Partner}ServiceAdapter naming convention" not a list of all 21)
- Boilerplate sections with nothing notable to say — if a section would just say "nothing unusual here", omit it entirely
- Transitive dependencies or internal implementation details of third-party libraries
- Field-by-field DTO listings when the type signatures are obvious — name the DTO, list the 2-3 fields that matter (validation, weird semantics, optional vs required), let the rest be implicit
- Prose summaries of what a table just showed — the table IS the answer

FORMAT:
- Default to tables for parallel data (per-item attributes), ASCII diagrams for flows / relationships / state machines.
- Prose only when neither table nor diagram fits; cap section intros at 3 sentences.
- Omit Overview if Key Findings + tables already convey it.
- Key Findings: ≤7 bullets, one line each. Prefer file:line references over restating what a table already shows.
- Gotchas: one-line bullets with file:line refs.
- Do not restate column headers in prose alongside a table.

PATH FORMAT:
- ALWAYS use repo-relative paths (e.g., `backend/src/main/java/...`), NEVER absolute paths (e.g., `/Users/.../backend/...`).
- This applies to all file references in your output — entity locations, script paths, config files, test files, etc.

FILE OUTPUT:
- First, create the output directory: mkdir -p docs/explore-repo
- Write your complete output to `[OUTPUT_FILE]` using the Write tool.
- Start the file with this EXACT metadata header format. Each field MUST be on its own line. Do NOT collapse into a single line:
  ```
  <!-- scan-metadata
  agent: [AGENT_NAME]
  commit: [COMMIT_HASH]
  branch: [BRANCH_NAME]
  date: [DATE]
  -->
  ```
  The header must be the very first content in the file, with no blank lines before it.
  IMPORTANT: Use `<!-- -->` HTML comment delimiters exactly as shown. Do NOT use YAML frontmatter (`---`) or any other format.
- After writing the file, return a 2-3 sentence summary of your key findings. This summary is for the orchestrator — keep it brief. Do NOT return your full findings as the task result.
```

---

## Domain Boundaries

Each agent owns specific aspects of the codebase. Respect these boundaries to avoid duplication across domain files.

| Agent | Owns | Does NOT Own (→ responsible agent) |
|-------|------|------------------------------------|
| Structure | Module layout, build system, CI/CD pipeline stages and jobs, deployment scripts, Docker setup, project scripts | Configuration values (→ Config), test frameworks (→ Testing) |
| API Surface | Endpoints, request/response models, auth schemes, middleware, API conventions | Business logic behind endpoints (→ Flows), external service clients (→ Integrations) |
| Data Model | Entities, schema, relationships, state machines, migrations, converters, repositories | How entities are used in business logic (→ Flows), database configuration (→ Config) |
| Integrations | External service clients, outbound auth patterns, retry strategies, message queues, webhook system | Internal service logic (→ Flows), configuration hierarchy (→ Config) |
| Processing Flows | Business workflows, state transitions, scheduled tasks, validation rules, error recovery, event flows | Data schema details (→ Data Model), HTTP client implementation (→ Integrations), CI/CD pipeline (→ Structure) |
| Config & Ops | Configuration hierarchy, profiles, feature flags, metrics, monitoring, secrets management, deployment config | CI/CD pipeline stages (→ Structure), business logic (→ Flows) |
| Testing | Test types, frameworks, utilities, patterns, CI test pipeline execution, mocking strategies | Application code being tested (→ other domains) |

When you encounter something at a domain boundary, document it briefly with a cross-reference: "See `docs/explore-repo/{other-domain}.md` for details on [topic]."

---

## Agent 1: Structure

**Mandate:** Understand the project's organizational structure, module layout, build system, dependencies, and CI/CD pipeline.

**Output file:** `docs/explore-repo/structure.md`

### Prompt Template

```
You are exploring a repository to deeply understand its structure and organization. Be exhaustive — read every relevant file.

## Project Context
[PROJECT_CONTEXT]

[COMMON_RULES]

## What to Search For

Use Glob to find these file patterns, then read every match:
- Build files: **/pom.xml, **/build.gradle, **/build.gradle.kts, **/package.json, **/Cargo.toml, **/go.mod, **/requirements.txt, **/pyproject.toml, **/Pipfile, **/composer.json, **/*.csproj, **/*.sln, Makefile, CMakeLists.txt
- Monorepo: **/turbo.json, **/nx.json, **/lerna.json, **/pnpm-workspace.yaml, **/Cargo.toml (workspace)
- CI/CD: .gitlab-ci.yml, .github/workflows/**, Jenkinsfile, .circleci/**, .travis.yml, **/bitbucket-pipelines.yml
- Docker: **/Dockerfile, **/docker-compose*.yml, **/.dockerignore
- Project config: .editorconfig, .eslintrc*, .prettierrc*, **/tsconfig.json, .tool-versions, .nvmrc, .java-version, .ruby-version, .python-version, **/rustfmt.toml, **/.golangci.yml
- Scripts: **/*.sh, scripts/**, utils/**, **/Makefile
- Root docs: README*, LICENSE*, CHANGELOG*, CONTRIBUTING*, CLAUDE.md
- Run configs: .run/**, .vscode/launch.json, .idea/runConfigurations/**

## What to Extract

For each module/package: name, location, purpose, entry point, key dependencies, relationship to other modules.

For the build system: how to build (full project + individual modules), available targets/profiles, dependency management approach.

For CI/CD: pipeline stages and what each does, test/build/deploy stages, special CI configuration.

For deployment: Docker setup, container relationships, deployment scripts.

## Output Format

# Structure

## Project Overview
[≤3 sentences: what it is, how it's organized, primary tech. Omit if Key Findings + tables cover it.]

## Key Findings
[≤7 bullets, one line each — non-obvious discoveries only]

## Modules
| Module | Location | Purpose | Entry point | Depends on |
|--------|----------|---------|-------------|------------|

[If module relationships aren't obvious from the `Depends on` column, follow with a small ASCII box-and-arrow diagram showing dependency edges.]

## Build System
| Operation | Command | Notes |
|-----------|---------|-------|
[build full / build module / test / lint / format / per-profile invocations]

[Then 1-3 bullets for non-obvious build behavior — auto-format on `validate`, special profiles, generated sources. Skip if nothing notable.]

## Dependencies
[Only *character-defining* deps that constrain behavior — one-line each: `lib X@version — constrains Y`. Skip utility libs. Omit section if none.]

## CI/CD Pipeline
| Stage | Trigger | Does | Artifacts |
|-------|---------|------|-----------|

[For non-trivial topology, prefix with an ASCII left-to-right pipeline (e.g. `[build] → [test] → [package] → [deploy-dev] → [deploy-staging] → [deploy-prod (manual)]`).]

## Deployment
[ASCII container topology diagram if multi-container/K8s (init container → app, sidecars, etc.); else table: `| Component | Image / script | Purpose |`. Note image-name overrides and ordering constraints.]

## Scripts & Utilities
| Script | Purpose | Status |
|--------|---------|--------|

[Status column: Active / Dormant / Broken — flag dormant scripts so readers don't trust them.]

## Gotchas
[Numbered list, each ≤2 sentences with file:line refs. Rule first, why second.]

## Scan Limitations
[Bullets only — what you couldn't read, what's outside this repo.]
```

---

## Agent 2: API Surface

**Mandate:** Map all external-facing interfaces — REST endpoints, gRPC services, CLI commands, event interfaces.

**Output file:** `docs/explore-repo/api-surface.md`

### Prompt Template

```
You are exploring a repository to comprehensively map its API surface and external interfaces. Be exhaustive — find every endpoint.

## Project Context
[PROJECT_CONTEXT]

[COMMON_RULES]

## What to Search For

Use Glob and Grep to find, then read every match:

**Routes & controllers** — Glob for **/routes/**, **/controllers/**, **/api/**, plus:
  Java/Kotlin: **/*Controller*.java, **/*Controller*.kt; Grep @RestController, @GetMapping, @PostMapping, @PutMapping, @DeleteMapping, @RequestMapping
  Python: **/*views*.py, **/*routes*.py, **/*endpoints*.py, **/urls.py; Grep @app.route, @api_view, APIRouter, path(, re_path(
  TypeScript/JS: **/*.controller.ts, **/*.router.ts, **/routes.ts; Grep app.get, app.post, router.get, @Controller, @Get, @Post
  Go: Grep http.HandleFunc, mux.Handle, gin.GET, echo.GET, chi.Get, fiber.Get
  Rust: Grep #\[get\], #\[post\], Router::new, web::resource, HttpServer::new
  C#: **/*Controller*.cs; Grep \[ApiController\], \[HttpGet\], \[HttpPost\]

**API definitions & docs:** **/*.proto, **/*.graphql, **/schema.graphql, **/*Resolver*, **/openapi*, **/swagger*, **/api-docs*

**Request/response models:**
  Java/Kotlin: **/*Request*.java, **/*Response*.java, **/*Dto*.java, **/dto/**
  Python: **/*schema*.py, **/*serializer*.py; Grep BaseModel, Serializer, @dataclass (in API layer)
  TypeScript/JS: **/*dto*.ts, **/*schema*.ts; Grep z.object, class.*Dto, interface.*Request
  Go/Rust: Request/response structs near route handlers

**Middleware & error handling:**
  Java/Kotlin: **/*Filter*.java, **/*Interceptor*.java; Grep @ExceptionHandler, @ControllerAdvice
  Python: **/middleware.py, **/middleware/**, **/exceptions.py; Grep exception_handler, middleware
  TypeScript/JS: **/middleware/**; Grep app.use, ExceptionFilter, NestMiddleware
  Go: Grep middleware, func.*http.Handler
  Universal: **/middleware/**, **/*ErrorHandler*, **/*ExceptionHandler*

## What to Extract

For each endpoint: HTTP method, full path, request/response shapes, path/query params, auth requirements, notable middleware.

Also: API versioning strategy, common error response format, pagination patterns, rate limiting, validation approach, CORS config.

## Output Format

# API Surface

## Endpoints Overview
[≤3 sentences: count, groupings, versioning strategy, async-vs-sync semantics. Omit if Key Findings + tables cover it.]

## Key Findings
[≤7 bullets, one line each — non-obvious discoveries only]

## REST Endpoints
Group by controller/resource. One table per group:
| Method | Path | Description | Status | Auth | Request | Response |
|--------|------|-------------|--------|------|---------|----------|

[Status column flags non-200 happy paths, e.g. `202 Accepted`. Reference DTOs by name only — full fields go in Models below.]

## Request/Response Models
| Model | Used by | Key fields / validation |
|-------|---------|-------------------------|

[Key fields cell: only the 2-3 fields with non-obvious validation, weird semantics, or required-vs-optional that callers must know. Skip the rest — types are obvious from the name.]

## gRPC / GraphQL / Other Interfaces
[Skip section entirely if none. If outbound only, one line pointing to integrations.md. Otherwise same tabular treatment: `| Service.method | Schema | Notes |`.]

## API Conventions
| Aspect | Convention |
|--------|------------|
[versioning, error envelope, idempotency, pagination, auth mechanism, validation, CORS. Skip rows that aren't notable.]

## Error Contract
| Exception | HTTP | Body shape |
|-----------|------|------------|

[Only include exceptions handled by global advice — internal-only exceptions don't need a row.]

## Middleware & Filters
| Order | Filter / Middleware | Purpose | File:line |
|-------|---------------------|---------|-----------|

[Prefix with an ASCII pipeline `request → [filter1] → [filter2] → controller` if non-linear. Skip section if there are no notable filters.]

## Gotchas
[Numbered list, each ≤2 sentences with file:line refs. Rule first, why second.]

## Scan Limitations
[Bullets only.]
```

---

## Agent 3: Data Model

**Mandate:** Understand the complete data layer — entities, schema, relationships, state machines, and migrations.

**Output file:** `docs/explore-repo/data-model.md`

### Prompt Template

```
You are exploring a repository to comprehensively understand its data model and persistence layer. Be exhaustive — read every entity, migration, and schema file.

## Project Context
[PROJECT_CONTEXT]

[COMMON_RULES]

## What to Search For

Use Glob and Grep to find, then read every match:

**Entities & models:**
  Java/Kotlin: **/*Entity*.java, **/entity/**, **/entities/**; Grep @Entity, @Table, @Document
  Python: **/models.py, **/models/**, **/*model*.py; Grep class.*Model, class.*db.Model, Base =
  TypeScript/JS: **/*entity*.ts, **/*model*.ts, **/schema.prisma; Grep @Entity, model (Prisma), Schema( (Mongoose)
  Go: **/model/**, **/models/**, **/entity/**; Grep gorm.Model, bun.BaseModel
  Rust: Grep #\[derive.*Queryable\], diesel::table!, #\[derive.*FromRow\]
  Universal: **/model/**, **/models/**, **/domain/** (non-DTO models)

**Repositories & data access:**
  Java/Kotlin: **/*Repository*.java, **/*Dao*.java, **/repository/**
  Python: Grep objects.filter, session.query, .select(), Manager
  TypeScript/JS: **/*repository*.ts; Grep getRepository, PrismaClient, mongoose.model
  Go: **/*repository*.go, **/*repo*.go, **/store/**
  Universal: **/repository/**, **/repositories/**, **/store/**

**Migrations & schema:**
  Universal: **/migration/**, **/migrations/**, **/db/migration/**, **/*.sql (in migration dirs)
  Java: **/flyway/**, **/liquibase/**
  Python: **/alembic/**, **/migrations/ (Django)
  TypeScript/JS: **/prisma/migrations/**, **/knex/migrations/**
  Go: **/migrate/**, **/goose/**

**State & type enums:** Grep for enum.*Status, enum.*Type, enum.*State, class.*Status, class.*State

**Additional:**
- Views: Grep for CREATE VIEW, CREATE OR REPLACE VIEW in SQL files
- Converters/serializers: **/*Converter*.java, Grep @Convert, AttributeConverter, custom serializers
- Auditing: Grep for @Audited, @CreatedDate, @LastModifiedDate, auto_now, timestamps, updated_at, created_at

## What to Extract

- Every entity with fields, types, and important annotations/decorators
- All relationships and their mapping details
- Status/state enums and valid transitions (trace through service code if needed)
- Indexes, unique constraints, views
- Converters and special field handling (encryption, serialization)
- Audit mechanisms and migration history highlights

## Output Format

# Data Model

## Overview
[≤3 sentences: entity count, schema name, DB tech, ORM. Omit if Key Findings + ER diagram cover it.]

## Key Findings
[≤7 bullets, one line each — non-obvious discoveries only]

## Core Entities
For each entity, one subsection with:
- One-line purpose
- Fields table: `| Field | Type | Notes |` (notes = annotations, constraints, encryption, soft-delete, @Version, idempotency keys). Skip standard id/created_at/updated_at unless they have non-default semantics.
- Relationships table (if any): `| Relation | Cardinality | Target | Join |`

## Entity Relationships
[ASCII ER diagram if 3+ entities with non-trivial relationships. Boxes for entities, labeled arrows with cardinality (`1───*`, `*───*`). Skip section if Core Entities tables already cover it.]

## State Machines
For each state flow: ASCII state diagram with arrows labeled by transition trigger, then a transition table. Example shape:
```
        ┌─────────┐  processSubmit (adapter=CONFIRMED)
PENDING ─┤         ├──────────▶ CONFIRMED
        │         │  processSubmit (adapter=FAILED)
        │         └──────────▶ FAILED
        │  processSubmit (adapter=PROCESSING)
        └─────────────▶ PROCESSING ───▶ ...
```
Transition table: `| From | To | Trigger | Conditions |`. No prose narration — the diagram IS the documentation.

## Database Details
| Aspect | Value |
|--------|-------|
[engine, schema name, native ENUMs, notable views, partial indexes, unique constraints — one row each, skip rows that don't apply]

## Data Patterns
| Pattern | Where | Mechanism |
|---------|-------|-----------|
[encryption, auditing, soft deletes, converters, optimistic locking, JSON columns, idempotency strategy. Skip patterns not used.]

## Migration Highlights
| Migration | Type | Change |
|-----------|------|--------|

## Gotchas
[Numbered list, each ≤2 sentences with file:line refs. Rule first, why second.]

## Scan Limitations
[Bullets only.]
```

---

## Agent 4: Integrations

**Mandate:** Map all external service integrations, their communication patterns, authentication, and error handling.

**Output file:** `docs/explore-repo/integrations.md`

### Prompt Template

```
You are exploring a repository to understand all external service integrations. Be exhaustive — find every client, SDK usage, and external service call.

## Project Context
[PROJECT_CONTEXT]

[COMMON_RULES]

## What to Search For

Use Glob and Grep to find, then read every match:

**Client classes & integration packages:**
  Universal: **/client/**, **/clients/**, **/integration/**, **/integrations/**, **/external/**, **/vendor/**
  Java/Kotlin: **/*Client*.java, **/*ServiceClient*; Grep RestTemplate, WebClient, OkHttp, Feign, Retrofit
  Python: **/*client*.py; Grep requests.get, requests.post, httpx, aiohttp, urllib
  TypeScript/JS: **/*client*.ts, **/*service*.ts; Grep axios, fetch(, got(, node-fetch
  Go: **/*client*.go; Grep http.NewRequest, http.Client, resty
  Rust: Grep reqwest::Client, hyper::Client

**gRPC clients:** **/*Stub*, **/*GrpcClient*, **/*GrpcService*, **/*_grpc.pb*

**Auth patterns:**
  Universal: **/*Auth*, **/*Token*, **/*Credential*
  Grep for OAuth2, Bearer, M2M, clientId, clientSecret, api_key, API_KEY (references only, not values)

**Retry & resilience:**
  Java/Kotlin: Grep @Retryable, @CircuitBreaker, RetryTemplate, resilience4j
  Python: Grep tenacity, retry, backoff, @retry
  TypeScript/JS: Grep retry, p-retry, cockatiel, polly
  Go: Grep retry, backoff
  Universal: Grep circuit.breaker, circuit_breaker, fallback

**External config:** Grep for url, endpoint, base-url, base_url, host in config files (to find external service references)

**Message queues & async:**
  Java/Kotlin: Grep @KafkaListener, @RabbitListener, @JmsListener
  Python: Grep celery, kombu, pika, boto3.*sqs
  TypeScript/JS: Grep BullModule, amqplib, kafkajs, @nestjs/microservices
  Universal: Grep SQS, SNS, pub/sub, AMQP, NATS

**Webhooks:** **/*Webhook*, **/*webhook*

## What to Extract

For each integration: service name, purpose, communication type (REST/gRPC/SDK/queue/webhook), auth method, key operations, error handling (retry/circuit breaker/fallback), config required.

Also: shared HTTP client config, common retry patterns, timeout defaults, connection pooling.

## Output Format

# Integrations

## Overview
[≤3 sentences: service count, dominant transport (REST/gRPC), auth pattern. Omit if Key Findings + tables cover it.]

## Key Findings
[≤7 bullets, one line each — non-obvious discoveries only]

## External Services
| Service | Type | Auth | Key operations | Config | Code |
|---------|------|------|----------------|--------|------|
(Type: REST / gRPC / SDK / Queue / Webhook. Key operations: 2-4 verbs e.g. submit, pollStatus, fetchBalance. Code: package path.)

## Resilience Matrix
| Service | Retries | Timeout | Circuit Breaker | Idempotency Key |
|---------|---------|---------|-----------------|-----------------|

[Cells: the mechanism in 2-3 words ("`@Retryable` 3x", "`CompletableFuture.get(30s)`", "`requestId` header"). Empty cell = absent.]

## Integration Patterns
| Aspect | Value |
|--------|-------|
[HTTP client library, retry strategy, circuit breaker approach, timeout defaults, connection pooling, bean-name routing, shared executor, SPI seam. Skip patterns not in active use.]

## Authentication Summary
| Pattern | Used by | Token / credential management |
|---------|---------|--------------------------------|
[mechanism, token-provider sharing, credential source (env/Vault), separate-identity splits if any]

## Message Queues / Async
| Tech | Topic / Queue | Producer | Consumer | Message format |
|------|----------------|----------|----------|----------------|

[Skip section if none.]

## Webhook System
| Aspect | Mechanism |
|--------|-----------|
[registration, delivery, signature verification, retry. Skip section if none.]

## Gotchas
[Numbered list, each ≤2 sentences with file:line refs. Rule first, why second.]

## Scan Limitations
[Bullets only.]
```

---

## Agent 5: Processing Flows

**Mandate:** Understand the core business logic, workflows, state transitions, scheduled operations, and event-driven patterns.

**Output file:** `docs/explore-repo/processing-flows.md`

### Prompt Template

```
You are exploring a repository to understand its core business logic and processing workflows. Be exhaustive — trace every major flow end-to-end.

## Project Context
[PROJECT_CONTEXT]

[COMMON_RULES]

## What to Search For

Use Glob and Grep to find, then read every match:

**Service & business logic:**
  Java/Kotlin: **/*Service*.java, **/service/**, **/services/**; Grep @Service (focus on business logic, not integration clients)
  Python: **/*service*.py, **/services/**, **/use_cases/**; Grep class.*Service, class.*UseCase
  TypeScript/JS: **/*service*.ts, **/services/**, **/use-cases/**; Grep @Injectable, class.*Service
  Go: **/*service*.go, **/service/**, **/usecase/**
  Rust: **/service/**, **/services/**; Grep impl.*Service

**Orchestrators & handlers:**
  Universal: **/*Processor*, **/*Orchestrator*, **/*Handler*, **/*Workflow*, **/*UseCase*, **/*Pipeline*

**Schedulers & cron:**
  Java/Kotlin: Grep @Scheduled, @EnableScheduling, CronTrigger
  Python: Grep celery.task, @periodic_task, schedule, APScheduler, crontab
  TypeScript/JS: Grep @Cron, @Interval, cron, node-schedule, BullModule
  Go: Grep cron.New, time.Ticker, gocron
  Universal: Grep crontab, cron, schedule

**Event handling:**
  Java/Kotlin: **/*Listener*, **/*EventHandler*; Grep @EventListener, @TransactionalEventListener
  Python: Grep signal, @receiver, EventHandler, on_event
  TypeScript/JS: Grep @OnEvent, EventEmitter, on(, subscribe(
  Go: Grep chan, Subscribe, Publish
  Universal: **/*Listener*, **/*Consumer*, **/*Subscriber*

**State transitions:** Grep for status changes, state machine patterns, enum transitions

**Validation:**
  Java/Kotlin: **/*Validator*; Grep @Valid, @Validated
  Python: **/*validator*.py; Grep validate, ValidationError, validator
  TypeScript/JS: Grep class-validator, zod, yup, joi
  Go: Grep validate, Validate

**Transaction management:**
  Java/Kotlin: Grep @Transactional, TransactionTemplate, Propagation
  Python: Grep atomic, transaction, session.commit, db.session
  TypeScript/JS: Grep transaction, $transaction, knex.transaction
  Go: Grep tx, Begin, Commit, Rollback

## What to Extract

- Every major business workflow (trigger, steps, outcome)
- State transitions (what moves entities between states, conditions)
- Scheduled operations (schedule, purpose, what it does)
- Event flows (emitters, listeners, side effects)
- Business rules and validations
- Transaction boundaries and propagation strategy
- Error and recovery flows

## Output Format

# Processing Flows

## Overview
[≤3 sentences: business domain, main workflows, processing philosophy (sync/async/inbox/poller). Omit if Key Findings + diagrams cover it.]

## Key Findings
[≤7 bullets, one line each — non-obvious discoveries only]

## Core Workflows
For each workflow:
- ASCII flow or sequence diagram (trigger → steps → outcome; show branches for error paths). Example shape:
  ```
  HTTP                Service               DB              Adapter
    │  POST /movements   │                    │                │
    ├───────────────────▶│                    │                │
    │                    │ 1. write journal   │                │
    │                    ├───────────────────▶│                │
    │                    │ 2. write PENDING   │                │
    │                    ├───────────────────▶│                │
    │  202 Accepted      │                    │                │
    │◀───────────────────┤                    │                │
    │   ┄┄ poller cycle ┄│                    │                │
    │                    │ 3. submit          │                │
    │                    ├──────────────────────────────────▶  │
  ```
- Step table: `| # | Step | Service.method | Notes |`
- One-line "trigger:", "outcome:", "code:" beneath. Skip prose narration — the diagram + table ARE the documentation.

## Scheduled Operations
| Job | Schedule | ShedLock | Purpose | Code |
|-----|----------|----------|---------|------|

## Event Flows
| Event | Emitter | Consumer(s) | Payload | Side effects |
|-------|---------|-------------|---------|--------------|

[Skip section entirely if there's no internal event bus.]

## State Transitions
[Reference data-model.md state machines; document only NEW transitions or NEW triggers introduced by services here. One bullet per trigger: `processSubmit: PENDING → CONFIRMED|FAILED|PROCESSING|SUBMITTED based on adapter response`. Do not duplicate the diagram from data-model.md.]

## Business Rules
| Rule | Where (file:line) | Logic |
|------|-------------------|-------|
[validation rules, idempotency comparison, status gates. Skip one-line input checks.]

## Transaction Boundaries
| Boundary | Propagation | Rationale |
|----------|-------------|-----------|

[Only rows where the choice is non-default (TransactionTemplate vs @Transactional, NEW propagation, per-item txs in batch loops). Standard `@Transactional class` rows aren't notable.]

## Error & Recovery Flows
| Failure mode | Recovery | Trigger | Location |
|--------------|----------|---------|----------|
[retry posture, compensation, manual intervention, recovery jobs]

## Gotchas
[Numbered list, each ≤2 sentences with file:line refs. Rule first, why second.]

## Scan Limitations
[Bullets only.]
```

---

## Agent 6: Config & Ops

**Mandate:** Understand configuration management, deployment, monitoring, secrets handling, and operational tooling.

**Output file:** `docs/explore-repo/config-ops.md`

### Prompt Template

```
You are exploring a repository to understand its configuration, monitoring, and operational setup. Be exhaustive — read every config file and operational script.

## Project Context
[PROJECT_CONTEXT]

[COMMON_RULES]

ADDITIONAL RULE: You will encounter sensitive configuration files (.env, credentials, secret configs). Note their EXISTENCE and what they configure, but NEVER include their actual values or contents in your output.

## What to Search For

Use Glob and Grep to find, then read every match:

**Configuration files:**
  Java/Kotlin: **/application*.properties, **/application*.yml; Grep @Configuration, @ConfigurationProperties, @Value
  Python: **/settings.py, **/config.py, **/pyproject.toml, **/.env.example; Grep DJANGO_SETTINGS, Flask config, pydantic.*Settings
  TypeScript/JS: **/config/**, **/.env.example, **/next.config*, **/nest-cli.json; Grep ConfigModule, process.env, dotenv
  Go: **/config/**, **/*.toml, **/*.yaml (config); Grep viper, envconfig, os.Getenv
  Rust: **/config/**, **/*.toml (config); Grep config::Config, dotenv
  Universal: **/*config*, **/*Config*, **/config/**, **/.env.example

**Profiles & environments:**
  Grep for spring.profiles, @Profile, NODE_ENV, RAILS_ENV, DJANGO_SETTINGS_MODULE, APP_ENV, GO_ENV, RUST_ENV

**Feature flags:** Grep for @ConditionalOn, feature., .enabled, .disabled, toggle, feature_flag, FEATURE_

**Monitoring & metrics:**
  Java/Kotlin: Grep @Timed, Counter., Timer., MeterRegistry, micrometer, Gauge
  Python: Grep prometheus_client, statsd, Counter(, Histogram(, opentelemetry
  TypeScript/JS: Grep prom-client, prometheus, opentelemetry, metrics
  Go: Grep prometheus, metrics, opentelemetry
  Universal: Grep prometheus, grafana, datadog, newrelic, opentelemetry

**Health checks:**
  Java/Kotlin: **/*Health*.java; Grep @HealthIndicator, /actuator/health
  Python: Grep health, healthcheck, readiness, liveness
  TypeScript/JS: Grep HealthCheck, terminus, /health
  Go: Grep /health, /ready, /live

**Logging:**
  Java/Kotlin: **/logback*.xml, **/log4j*.xml; Grep @Slf4j, LoggerFactory
  Python: **/logging.*, Grep logging.config, structlog, loguru
  TypeScript/JS: Grep winston, pino, bunyan, morgan, logger
  Go: Grep log, zap, logrus, zerolog
  Universal: Grep structured.logging, log.level

**Secrets & infrastructure:**
  Grep for vault, transit, kms, ssm, keystore, secret.management (references to secrets infrastructure, NOT actual secrets)
  Glob: **/terraform/**, **/k8s/**, **/kubernetes/**, **/helm/**, **/deploy/**, **/infra/**

**Operational scripts:** **/utils/**, **/scripts/**, **/ops/**, **/bin/**

## What to Extract

- Configuration hierarchy (sources, precedence order)
- Environment profiles and how they differ
- Feature flags with defaults
- Metrics being collected (counters, timers, gauges)
- Health check dependencies
- Logging config (format, levels, destinations)
- Secrets management approach
- Deployment config and operational scripts

## Output Format

# Configuration & Operations

## Overview
[≤3 sentences: config approach, secrets source, key operational stack (metrics + logging + health). Omit if Key Findings + tables cover it.]

## Key Findings
[≤7 bullets, one line each — non-obvious discoveries only]

## Configuration Hierarchy
| Precedence | Source | Notes |
|------------|--------|-------|
(Highest precedence first — runtime overrides, env vars, profile files, defaults. Prefix with an ASCII chain `defaults < application.properties < profile-overlay < env vars < Vault` if it aids skim.)

## Environment Profiles
| Profile | Purpose | Key differences |
|---------|---------|-----------------|

## Key Configuration Properties
| Category | Property | Default | Purpose |
|----------|----------|---------|---------|

[Categories: Database, Adapters, Auth0, Timeouts, etc. Each row ≤1 line. Skip standard framework properties unless they have non-default values.]

## Feature Flags
| Flag | Default | Status | Purpose |
|------|---------|--------|---------|

[Status column: Active / Inactive (no consumer) / Vapor (referenced in config but no `@ConditionalOnProperty` matches). Vapor flags are critical to surface.]

## Monitoring & Metrics
| Metric / probe | Type (counter/timer/gauge/health) | Tags | Source | Purpose | Location |
|----------------|------------------------------------|------|--------|---------|----------|
[Source: aspect/manual/auto. Skip framework-default metrics.]

## Health Checks
[Bullets: each indicator + what it depends on. Skip if only framework defaults are wired.]

## Logging
| Profile | Format | Level | Destination |
|---------|--------|-------|-------------|

[Skip section if there's nothing non-default.]

## Secrets Management
| Secret | Source (vault/env/file) | Used by | Notes |
|--------|--------------------------|---------|-------|
(NO actual values — only names and references. Note what's stored where and what's NOT, e.g. local profile uses env vars.)

## Deployment
[ASCII deployment diagram if multi-container/K8s; else table: `| Component | How deployed | Notes |`. Cross-reference structure.md for pipeline view.]

## Operational Scripts
| Script | Purpose | Usage |
|--------|---------|-------|

[Skip if structure.md already covered scripts; cross-reference instead.]

## Local Development Setup
Prereqs as one-line bullets above; numbered steps (≤7) below with exact commands.

## Gotchas
[Numbered list, each ≤2 sentences with file:line refs. Rule first, why second.]

## Scan Limitations
[Bullets only.]
```

---

## Agent 7: Testing

**Mandate:** Understand the testing strategy, patterns, utilities, and how to run tests.

**Output file:** `docs/explore-repo/testing.md`

### Prompt Template

```
You are exploring a repository to comprehensively understand its testing strategy and infrastructure. Be exhaustive — read every test utility, config, and a representative sample of test files for each pattern.

## Project Context
[PROJECT_CONTEXT]

[COMMON_RULES]

NOTE: For test files themselves, you don't need to read every individual test method. Instead, read ALL test utility/helper/config files, then read enough test files to identify all distinct patterns. If there are 50 test files all following the same pattern, reading 5-10 representative ones is sufficient. But DO read every utility, config, and base class.

## What to Search For

Use Glob and Grep to find:

**Test files:**
  Java/Kotlin: **/*Test*.java, **/*IT*.java, **/*Spec*.java
  Python: **/test_*.py, **/*_test.py, **/tests.py, **/tests/**
  TypeScript/JS: **/*.test.*, **/*.spec.*, **/__tests__/**
  Go: **/*_test.go
  Rust: Grep #\[test\], #\[cfg(test)\]; **/tests/**
  C#: **/*Test*.cs, **/*Tests*.cs

**Test config:**
  Java/Kotlin: **/test/resources/**, **/*TestConfig*.java, **/*TestBase*.java
  Python: **/conftest.py, **/pytest.ini, **/setup.cfg (test section), **/tox.ini
  TypeScript/JS: **/jest.config*, **/vitest.config*, **/.mocharc*, **/playwright.config*
  Go: **/testdata/**, **/*_test_helpers*.go
  Universal: **/*TestConfig*, **/*TestBase*

**Test utilities & factories:**
  Universal: **/*TestHelper*, **/*TestUtil*, **/*TestData*, **/*Factory* (in test dirs), **/*Builder* (in test dirs), **/*fixture*
  Python: **/conftest.py (fixtures), **/factories.py; Grep factory_boy, pytest.fixture
  TypeScript/JS: **/*mock*, **/mocks/**; Grep jest.mock, vi.mock, sinon

**Mocks/fakes:** **/*Mock*, **/*Fake*, **/*Stub* (in test dirs)
**Test containers:** Grep @Testcontainers, TestContainers, testcontainer, docker-compose.*test
**Fixtures:** **/fixtures/**, **/testdata/**, **/__fixtures__/**
**CI test config:** Look at CI pipeline for test stages and commands

Read every test utility, config, mock, and base class file. For actual test files, read enough to identify all patterns.

## What to Extract

- Test types (unit, integration, e2e, contract, performance) with approximate counts
- How to run each test type (exact commands)
- Frameworks and assertion libraries used
- Test utilities and what they provide
- Mocking strategies per external dependency
- Test data management (factories, fixtures, seeds)
- Test base classes and their responsibilities
- Test container setup
- CI/CD test pipeline and conventions

## Output Format

# Testing

## Overview
[≤3 sentences: testing philosophy, maturity, coverage approach. Omit if Key Findings + tables cover it.]

## Key Findings
[≤7 bullets, one line each — non-obvious discoveries only]

## Test Types
| Type | ~Count | Location pattern | Run command |
|------|--------|------------------|-------------|

## Test Frameworks
| Framework | Type (runner / assert / mock) | Used by |
|-----------|-------------------------------|---------|
[one row per framework with one-line "used for X"]

## Test Utilities & Base Classes
| Utility / base | Location | Provides | Used by |
|----------------|----------|----------|---------|
[One row per non-trivial helper. ≤1 line per cell.]

## Mocking Strategy
| External dependency | Mock approach | Location |
|---------------------|---------------|----------|

## Test Data Management
| Approach | Where | Used by |
|----------|-------|---------|
(factories, builders, fixtures, SQL seeds, transactional rollback, etc.)

## Test Patterns & Conventions
| Aspect | Convention |
|--------|------------|
(naming, setup/teardown, assertion style, organization, slice-test usage. Skip rows that are vanilla.)

## CI/CD Test Pipeline
| Stage | Parallelization | Reporting | Notes |
|-------|------------------|-----------|-------|
[Cross-reference structure.md if it already covered the pipeline; only add testing-specific details (parallelization, reporting, flaky-test handling) here.]

## Gotchas
[Numbered list, each ≤2 sentences with file:line refs. Rule first, why second.]

## Scan Limitations
[Bullets only.]
```
