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

DO NOT DOCUMENT:
- Dependency version numbers unless the specific version constrains behavior (e.g., "Java 17 specifically, not 21" is worth noting; "Guava 33.3.1-jre" is not)
- Standard framework conventions that any developer familiar with the framework would already know (e.g., don't explain what @RestController does in a Spring Boot project)
- Every file in a directory — describe the pattern instead (e.g., "21 partner adapter modules following the {Partner}ServiceAdapter naming convention" not a list of all 21)
- Boilerplate sections with nothing notable to say — if a section would just say "nothing unusual here", omit it entirely
- Transitive dependencies or internal implementation details of third-party libraries

PATH FORMAT:
- ALWAYS use repo-relative paths (e.g., `backend/src/main/java/...`), NEVER absolute paths (e.g., `/Users/.../backend/...`).
- This applies to all file references in your output — entity locations, script paths, config files, test files, etc.

FILE OUTPUT:
- First, create the output directory: mkdir -p docs/learnings
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

When you encounter something at a domain boundary, document it briefly with a cross-reference: "See `docs/learnings/{other-domain}.md` for details on [topic]."

---

## Agent 1: Structure

**Mandate:** Understand the project's organizational structure, module layout, build system, dependencies, and CI/CD pipeline.

**Output file:** `docs/learnings/structure.md`

### Prompt Template

```
You are exploring a repository to deeply understand its structure and organization. Be exhaustive — read every relevant file.

## Project Context
[PROJECT_CONTEXT]

[COMMON_RULES]

## What to Search For

Use Glob to find these file patterns, then read every match:
- Build files: **/pom.xml, **/build.gradle, **/package.json, **/Cargo.toml, **/go.mod, **/requirements.txt, **/pyproject.toml, Makefile, CMakeLists.txt
- CI/CD: .gitlab-ci.yml, .github/workflows/**, Jenkinsfile, .circleci/**, .travis.yml
- Docker: **/Dockerfile, **/docker-compose*.yml, **/.dockerignore
- Project config: .editorconfig, .eslintrc*, .prettierrc*, **/tsconfig.json, .tool-versions, .nvmrc, .java-version, .ruby-version
- Scripts: **/*.sh, scripts/**, utils/**
- Root docs: README*, LICENSE*, CHANGELOG*, CONTRIBUTING*, CLAUDE.md
- Run configs: .run/**, .vscode/launch.json, .idea/runConfigurations/**

## What to Extract

For each module/package:
- Name, location, and purpose
- Entry point (main class, index file)
- Key dependencies (important libraries, not every transitive dep)
- How it relates to other modules

For the build system:
- How to build the full project
- How to build individual modules
- Available build targets/profiles
- Dependency management approach

For CI/CD:
- Pipeline stages and what each does
- Test stages and what they run
- Build/deploy stages
- Any special CI configuration

For deployment:
- Docker setup and what containers exist
- Container relationships (compose files)
- Deployment scripts and their usage

## Output Format

# Structure

## Project Overview
[1-2 paragraphs: what this project is, how it's organized, key technology choices]

## Key Findings
[Bulleted list of the 3-7 most important discoveries. Focus on things that are non-obvious, surprising, or critical for working with the codebase.]

## Modules

### [Module Name]
- **Purpose:** [what it does]
- **Location:** [path]
- **Entry point:** [main file]
- **Key dependencies:** [important libraries]
- **Relationship to other modules:** [depends on / depended on by]

## Build System
- **Tool:** [Maven/Gradle/npm/cargo/etc.]
- **Build command:** [full project build]
- **Module-specific builds:** [per-module commands if applicable]
- **Other commands:** [test, lint, format, etc.]
- **Profiles/configurations:** [build profiles or configurations]

## Dependencies
[Key external dependencies that define the project's character — frameworks, databases, messaging, etc. Not every utility library.]

## CI/CD Pipeline
[Pipeline stages, what triggers them, what they do]

## Deployment
[Docker setup, container definitions, deployment scripts]

## Scripts & Utilities
| Script | Purpose |
|--------|---------|
| [path] | [what it does] |

## Gotchas
[Non-obvious patterns that would surprise a developer familiar with the framework but new to this codebase.]

## Scan Limitations
[Areas you did not fully explore or could not determine. Be honest about coverage gaps.]
```

---

## Agent 2: API Surface

**Mandate:** Map all external-facing interfaces — REST endpoints, gRPC services, CLI commands, event interfaces.

**Output file:** `docs/learnings/api-surface.md`

### Prompt Template

```
You are exploring a repository to comprehensively map its API surface and external interfaces. Be exhaustive — find every endpoint.

## Project Context
[PROJECT_CONTEXT]

[COMMON_RULES]

## What to Search For

Use Glob and Grep to find, then read every match:
- REST controllers: **/*Controller*.java, **/*Handler*.java, **/routes/**, **/router*, **/api/**
- Route annotations: Grep for @RestController, @Controller, @GetMapping, @PostMapping, @PutMapping, @DeleteMapping, @PatchMapping, @RequestMapping
- For non-Java: Grep for app.get, app.post, router.get, @app.route, @api_view
- gRPC definitions: **/*.proto, **/*GrpcService*, **/*Grpc*
- GraphQL: **/*.graphql, **/schema.graphql, **/*Resolver*
- DTOs/request-response models: **/*Request*.java, **/*Response*.java, **/*Dto*.java, **/*DTO*.java, **/dto/**, **/model/** (in API layer)
- API docs: **/openapi*, **/swagger*, **/api-docs*
- Middleware/filters: **/*Filter*.java, **/*Interceptor*.java, **/middleware/**
- Error handling: **/*ExceptionHandler*, **/*ErrorHandler*, **/exception/**

## What to Extract

For each endpoint:
- HTTP method and full path (including path variables)
- Request body shape (key fields and types)
- Response body shape (key fields and types)
- Path parameters and query parameters
- Authentication/authorization requirements
- Notable middleware or filters applied

Also document:
- API versioning strategy
- Common error response format
- Pagination patterns
- Rate limiting
- Request validation approach
- CORS configuration

## Output Format

# API Surface

## Endpoints Overview
[Brief summary: how many endpoints, groupings, versioning]

## Key Findings
[Bulleted list of the 3-7 most important discoveries about the API surface.]

## REST Endpoints

### [Controller/Group Name]
[Brief description of this group]

| Method | Path | Description | Auth |
|--------|------|-------------|------|
| GET | /v0/things | List all things | JWT |
| POST | /v0/things | Create a thing | JWT |
| GET | /v0/things/{id} | Get thing by ID | JWT |

### [Next Controller/Group]
...

## Request/Response Models

### [Model Name]
- **Used by:** [which endpoints]
- **Fields:**
  - `fieldName` (Type) — description
  - `otherField` (Type, optional) — description

## gRPC Services
[If applicable: service name, methods, request/response messages]

## Other Interfaces
[CLI commands, WebSocket endpoints, event interfaces, webhook callbacks]

## API Conventions
- **Versioning:** [strategy]
- **Error format:** [structure and common error codes]
- **Pagination:** [pattern — offset/limit, cursor, page/size]
- **Authentication:** [mechanism — JWT, API key, OAuth2]
- **Validation:** [how request validation works]

## Middleware & Filters
[What middleware/filters exist, their order, what they do]

## Gotchas
[Non-obvious patterns that would surprise a developer familiar with the framework but new to this codebase.]

## Scan Limitations
[Areas you did not fully explore or could not determine.]
```

---

## Agent 3: Data Model

**Mandate:** Understand the complete data layer — entities, schema, relationships, state machines, and migrations.

**Output file:** `docs/learnings/data-model.md`

### Prompt Template

```
You are exploring a repository to comprehensively understand its data model and persistence layer. Be exhaustive — read every entity, migration, and schema file.

## Project Context
[PROJECT_CONTEXT]

[COMMON_RULES]

## What to Search For

Use Glob and Grep to find, then read every match:
- Entities/models: **/*Entity*.java, **/entity/**, **/entities/**, Grep for @Entity, @Table, @Document
- Also check: **/model/**, **/models/**, **/domain/** (non-DTO models)
- Repositories/DAOs: **/*Repository*.java, **/*Dao*.java, **/repository/**
- Migrations: **/migration/**, **/migrations/**, **/db/migration/**, **/flyway/**, **/liquibase/**, **/alembic/**
- Schema: **/schema.sql, **/init.sql, **/ddl/**, **/*.sql (in migration dirs)
- Enums: Grep for enum.*Status, enum.*Type, enum.*State (look specifically for state/status enums)
- Views: Grep for CREATE VIEW, CREATE OR REPLACE VIEW in SQL files
- ORM config: **/persistence.xml, **/hibernate.cfg.xml, **/orm.xml
- Converters: **/*Converter*.java, Grep for @Convert, AttributeConverter
- Auditing: Grep for @Audited, @EntityListeners, Envers, @CreatedDate, @LastModifiedDate

## What to Extract

- Every entity with its fields, types, and important annotations
- All relationships (OneToMany, ManyToOne, ManyToMany) and their mapping details
- Status/state enums and their valid transitions (trace through service code if needed)
- Database indexes and unique constraints
- Views — name, definition, purpose
- Converters and special field handling (encryption, serialization)
- Audit mechanisms (Envers, timestamps, soft deletes)
- Migration history — focus on structural milestones, not every migration

## Output Format

# Data Model

## Overview
[Brief summary: how many entities, key relationships, database technology]

## Key Findings
[Bulleted list of the 3-7 most important discoveries about the data model.]

## Core Entities

### [Entity Name]
- **Table:** `[schema.table_name]`
- **Purpose:** [what this entity represents]
- **Key fields:**
  - `id` (UUID) — primary key
  - `fieldName` (Type) — description
  - `status` (StatusEnum) — [possible values]
- **Relationships:**
  - → [OtherEntity] (ManyToOne via `other_id`)
  - ← [AnotherEntity] (OneToMany, mapped by `this_field`)
- **Special handling:** [encryption, auditing, soft delete, etc.]

### [Next Entity]
...

## Entity Relationships
[Prose description or text diagram showing how the major entities connect]

## State Machines

### [Entity] Status Flow
```
STATE_A → STATE_B → STATE_C
   ↓         ↓
STATE_D   STATE_E
```
**Transitions:**
- STATE_A → STATE_B: [what triggers this]
- STATE_B → STATE_C: [what triggers this]
- ...

## Database Details
- **Database:** [PostgreSQL/MySQL/MongoDB/etc.]
- **Schema:** [schema name if applicable]
- **Key views:** [view names and purposes]
- **Notable indexes:** [indexes on frequently queried columns]
- **Constraints:** [important unique/check constraints]

## Data Patterns
- **Encryption:** [which fields, how]
- **Auditing:** [mechanism — Envers, timestamps, etc.]
- **Soft deletes:** [if applicable]
- **Converters:** [custom type converters]

## Migration Highlights
[Notable structural changes in migration history — new tables, major alterations, data migrations]

## Gotchas
[Non-obvious patterns that would surprise a developer familiar with the framework but new to this codebase.]

## Scan Limitations
[Areas you did not fully explore or could not determine.]
```

---

## Agent 4: Integrations

**Mandate:** Map all external service integrations, their communication patterns, authentication, and error handling.

**Output file:** `docs/learnings/integrations.md`

### Prompt Template

```
You are exploring a repository to understand all external service integrations. Be exhaustive — find every client, SDK usage, and external service call.

## Project Context
[PROJECT_CONTEXT]

[COMMON_RULES]

## What to Search For

Use Glob and Grep to find, then read every match:
- Client classes: **/*Client*.java, **/*ServiceClient*, **/client/**, **/clients/**
- Integration packages: **/integration/**, **/integrations/**, **/external/**, **/vendor/**
- gRPC clients: **/*Stub*, **/*GrpcClient*, **/*GrpcService*
- HTTP clients: Grep for RestTemplate, WebClient, HttpClient, OkHttp, Feign, Retrofit
- Auth: **/*Auth*.java, **/*Token*.java, **/*Credential*, Grep for OAuth2, Bearer, M2M, clientId, clientSecret (references only, not values)
- Retry/resilience: Grep for @Retryable, @CircuitBreaker, RetryTemplate, resilience4j, @Retry
- External config: Grep for url, endpoint, base-url, host in config files (to find external service references)
- Message queues: Grep for @KafkaListener, @RabbitListener, @JmsListener, SQS, SNS, pub/sub
- Webhooks: **/*Webhook*, **/*webhook*

## What to Extract

For each external integration:
- Service name and what it's used for
- Communication type (REST, gRPC, SDK, message queue, webhook)
- Authentication method (OAuth2 M2M, API key, mTLS, basic auth)
- Key operations (what endpoints/methods are called)
- Error handling approach (retry config, circuit breaker, fallback)
- Configuration required (properties, env vars, URLs)
- Health/connectivity checks

Also document:
- Shared HTTP client configuration
- Common retry patterns across integrations
- Timeout defaults
- Connection pooling

## Output Format

# Integrations

## Overview
[Brief summary: how many external services, common patterns]

## Key Findings
[Bulleted list of the 3-7 most important discoveries about integrations.]

## External Services

### [Service Name]
- **Purpose:** [what it's used for in this system]
- **Type:** [REST/gRPC/SDK/Queue/Webhook]
- **Auth:** [authentication method and details]
- **Key operations:**
  - [Operation 1] — [what it does]
  - [Operation 2] — [what it does]
- **Error handling:** [retry count, backoff, circuit breaker, fallback]
- **Config required:** [properties/env vars needed to connect]
- **Location:** [code path for the client]

### [Next Service]
...

## Integration Patterns
- **HTTP client:** [what library/approach — RestTemplate, WebClient, etc.]
- **Retry strategy:** [common retry configuration]
- **Circuit breaker:** [if applicable, tool used]
- **Timeouts:** [connection and read timeout defaults]
- **Connection pooling:** [if configured]

## Authentication Summary
[How external authentication works — shared patterns, token management, credential storage]

## Message Queues / Async
[If applicable: queue technology, topics/queues, producers, consumers, message formats]

## Webhook System
[If the system sends or receives webhooks: registration, delivery, signature verification, retry]

## Gotchas
[Non-obvious patterns that would surprise a developer familiar with the framework but new to this codebase.]

## Scan Limitations
[Areas you did not fully explore or could not determine.]
```

---

## Agent 5: Processing Flows

**Mandate:** Understand the core business logic, workflows, state transitions, scheduled operations, and event-driven patterns.

**Output file:** `docs/learnings/processing-flows.md`

### Prompt Template

```
You are exploring a repository to understand its core business logic and processing workflows. Be exhaustive — trace every major flow end-to-end.

## Project Context
[PROJECT_CONTEXT]

[COMMON_RULES]

## What to Search For

Use Glob and Grep to find, then read every match:
- Service classes: **/*Service*.java, **/service/**, **/services/** (focus on business logic, not integration clients)
- Orchestrators: **/*Processor*, **/*Orchestrator*, **/*Handler*, **/*Workflow*, **/*UseCase*
- Schedulers: Grep for @Scheduled, @EnableScheduling, CronTrigger, ScheduledExecutorService
- Event handling: **/*Listener*, **/*EventHandler*, **/*Consumer*, Grep for @EventListener, @TransactionalEventListener
- State transitions: Grep for status changes, state machine patterns, enum transitions
- Validators: **/*Validator*, **/*Validation*, Grep for @Valid, @Validated
- Business rules: Look for conditional logic, calculations, allocation algorithms
- Transaction management: Grep for @Transactional, TransactionTemplate, Propagation

## What to Extract

- Every major business workflow (what triggers it, every step, what the outcome is)
- State transitions (what moves entities between states, under what conditions)
- Scheduled operations (what runs on a schedule, cron expression, what it does)
- Event flows (what emits events, what listens, what happens)
- Business rules and validations (the logic that enforces correctness)
- Transaction boundaries (where @Transactional is used and the propagation strategy)
- Error and recovery flows (what happens when things fail)

## Output Format

# Processing Flows

## Overview
[Brief summary: key business domain, main workflows, processing philosophy]

## Key Findings
[Bulleted list of the 3-7 most important discoveries. Focus on things that are non-obvious, surprising, or critical for working with the codebase.]

## Core Workflows

### [Workflow Name]
**Trigger:** [what starts this flow — API call, scheduled task, event, external webhook]
**Steps:**
1. [Step] — [what happens, which service/method]
2. [Step] — [what happens]
3. ...
**Outcome:** [end state, side effects, notifications]
**Error handling:** [what happens on failure at each critical step]
**Location:** [primary service/class]

### [Next Workflow]
...

## Scheduled Operations

| Job | Schedule | Purpose | Location |
|-----|----------|---------|----------|
| [name] | [cron/interval] | [what it does] | [class] |

## Event Flows

### [Event Name/Type]
- **Emitted by:** [what produces it]
- **Consumed by:** [what listens]
- **Payload:** [key data included]
- **Side effects:** [what happens when consumed]

## Business Rules
[Key validations, calculations, algorithms, allocation logic — the domain-specific rules that define correctness]

## Transaction Boundaries
[Where transactional boundaries exist, propagation strategies, why they're structured that way]

## Error & Recovery Flows
[What happens when things fail — retry, compensation, manual intervention, recovery jobs]

## Gotchas
[Non-obvious patterns that would surprise a developer familiar with the framework but new to this codebase.]

## Scan Limitations
[Areas you did not fully explore or could not determine.]
```

---

## Agent 6: Config & Ops

**Mandate:** Understand configuration management, deployment, monitoring, secrets handling, and operational tooling.

**Output file:** `docs/learnings/config-ops.md`

### Prompt Template

```
You are exploring a repository to understand its configuration, monitoring, and operational setup. Be exhaustive — read every config file and operational script.

## Project Context
[PROJECT_CONTEXT]

[COMMON_RULES]

ADDITIONAL RULE: You will encounter sensitive configuration files (.env, credentials, secret configs). Note their EXISTENCE and what they configure, but NEVER include their actual values or contents in your output.

## What to Search For

Use Glob and Grep to find, then read every match:
- Config files: **/application*.properties, **/application*.yml, **/application*.yaml, **/.env.example, **/config/**, **/*config*.java, **/*Config*.java, **/*Configuration*.java, **/*Properties*.java
- Profiles: Grep for spring.profiles, @Profile, NODE_ENV, RAILS_ENV
- Feature flags: Grep for @ConditionalOn, feature., .enabled, .disabled, toggle
- Monitoring: Grep for @Timed, Counter., Timer., MeterRegistry, prometheus, micrometer, Gauge
- Health: **/*Health*.java, Grep for @HealthIndicator, AbstractHealthIndicator, /actuator/health
- Logging: **/logback*.xml, **/log4j*.xml, **/logging.*, Grep for LoggerFactory, @Slf4j, structured logging
- Secrets: Grep for vault, transit, kms, ssm, keystore, secret.management (references to secrets infrastructure, NOT actual secrets)
- Infrastructure: **/terraform/**, **/k8s/**, **/kubernetes/**, **/helm/**, **/deploy/**, **/infra/**
- Operational scripts: **/utils/**, **/scripts/**, **/ops/**, **/bin/**

## What to Extract

- Configuration hierarchy (what sources exist, precedence order)
- Environment profiles and how they differ
- Feature flags with their defaults
- All metrics being collected (counters, timers, gauges)
- Health check dependencies
- Logging configuration (format, levels, destinations)
- Secrets management approach (tool, integration, key paths)
- Deployment configuration
- Operational scripts and their purposes

## Output Format

# Configuration & Operations

## Overview
[Brief summary: configuration approach, key operational concerns]

## Key Findings
[Bulleted list of the 3-7 most important discoveries. Focus on things that are non-obvious, surprising, or critical for working with the codebase.]

## Configuration Hierarchy
[What config sources exist and their precedence — e.g., env vars > profile properties > defaults]

## Environment Profiles

| Profile | Purpose | Key Differences |
|---------|---------|-----------------|
| [name] | [when used] | [what's different] |

## Key Configuration Properties
[Important properties grouped by category — not every property, just the ones that matter for understanding and operating the system]

## Feature Flags

| Flag | Default | Purpose |
|------|---------|---------|
| [property path] | [value] | [what it controls] |

## Monitoring & Metrics

### Metrics
[What's being measured — key counters, timers, gauges and what they track]

### Health Checks
[What dependencies are health-checked, endpoints]

### Logging
- **Format:** [structured/plain, pattern]
- **Levels:** [default levels, per-package overrides]
- **Configuration:** [logback/log4j, file location]

## Secrets Management
[How secrets are managed — Vault, env vars, K8s secrets, etc. What secrets exist and where they're referenced. NO actual values.]

## Deployment
[How the application is deployed — Docker, K8s, scripts, manual]

## Operational Scripts

| Script | Purpose | Usage |
|--------|---------|-------|
| [path] | [what it does] | [how to run it] |

## Local Development Setup
[What's needed to run locally — services, configuration, bootstrap scripts]

## Gotchas
[Non-obvious patterns that would surprise a developer familiar with the framework but new to this codebase.]

## Scan Limitations
[Areas you did not fully explore or could not determine.]
```

---

## Agent 7: Testing

**Mandate:** Understand the testing strategy, patterns, utilities, and how to run tests.

**Output file:** `docs/learnings/testing.md`

### Prompt Template

```
You are exploring a repository to comprehensively understand its testing strategy and infrastructure. Be exhaustive — read every test utility, config, and a representative sample of test files for each pattern.

## Project Context
[PROJECT_CONTEXT]

[COMMON_RULES]

NOTE: For test files themselves, you don't need to read every individual test method. Instead, read ALL test utility/helper/config files, then read enough test files to identify all distinct patterns. If there are 50 test files all following the same pattern, reading 5-10 representative ones is sufficient. But DO read every utility, config, and base class.

## What to Search For

Use Glob and Grep to find:
- Test files: **/*Test*.java, **/*IT*.java, **/*Spec*.java, **/*.test.*, **/*.spec.*, **/*_test.go, **/test_*.py
- Test config: **/test/resources/**, **/*TestConfig*.java, **/*TestBase*.java, **/conftest.py, **/jest.config*, **/pytest.ini, **/vitest.config*
- Test utilities: **/*TestHelper*, **/*TestUtil*, **/*TestData*, **/*Factory* (in test dirs), **/*Builder* (in test dirs)
- Mocks/fakes: **/*Mock*, **/*Fake*, **/*Stub* (in test dirs)
- Test containers: Grep for @Testcontainers, TestContainers, testcontainer
- Fixtures: **/fixtures/**, **/testdata/**, **/__fixtures__/**
- CI test config: Look at CI pipeline for test stages and commands

Read every test utility, config, mock, and base class file. For actual test files, read enough to identify all patterns.

## What to Extract

- Test types present (unit, integration, e2e, contract, performance)
- Approximate count of tests by type
- How to run each type of test (exact commands)
- Test frameworks and assertion libraries used
- Test utility classes and what they provide
- Mocking strategies per external dependency
- Test data management approach (factories, fixtures, seed data)
- Test base classes and their responsibilities
- Test container setup (what containers, how configured)
- CI/CD test pipeline (what runs in CI, in what order)
- Any notable testing patterns or conventions

## Output Format

# Testing

## Overview
[Brief summary: testing philosophy, maturity, coverage approach]

## Key Findings
[Bulleted list of the 3-7 most important discoveries. Focus on things that are non-obvious, surprising, or critical for working with the codebase.]

## Test Types

| Type | Approximate Count | Location Pattern | Run Command |
|------|-------------------|------------------|-------------|
| Unit | ~[N] | `*Test.java` | `[command]` |
| Integration | ~[N] | `*IT.java` | `[command]` |
| E2E | ~[N] | [pattern] | `[command]` |

## Test Frameworks
[What testing libraries and tools are used — JUnit, Mockito, Testcontainers, etc.]

## Test Utilities

### [Utility/Helper Name]
- **Location:** [path]
- **Purpose:** [what it provides]
- **Used by:** [which test types use it]

## Test Base Classes

### [Base Class Name]
- **Location:** [path]
- **Provides:** [what it sets up — containers, config, common fixtures]
- **Used by:** [which tests extend it]

## Mocking Strategy

| External Dependency | Mock Approach | Location |
|--------------------|---------------|----------|
| [service name] | [Mockito/@MockBean/Fake class/WireMock] | [mock file] |

## Test Data Management
[How test data is created — factories, builders, fixtures, SQL seeds, @Transactional rollback]

## Test Patterns & Conventions
[Common patterns — naming conventions, setup/teardown, assertion style, test organization]

## CI/CD Test Pipeline
[How tests run in CI — which stages, what's parallelized, test reporting]

## Gotchas
[Non-obvious patterns that would surprise a developer familiar with the framework but new to this codebase.]

## Scan Limitations
[Areas you did not fully explore or could not determine.]
```
