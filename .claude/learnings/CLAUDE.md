# Learnings Index

Read this file when starting domain-relevant work. Load the files that match your task, then follow their cross-references.

If `~/.claude/learnings-private/CLAUDE.md` exists, read it too — it contains private project-specific learnings.
If `docs/learnings/CLAUDE.md` exists in the current project, read it for repo-local learnings.

---

## Claude Authoring

- `claude-authoring-claude-md.md` — Patterns for writing effective CLAUDE.md files that help agents navigate codebases
- `claude-authoring-content-types.md` — Routing guide: decide whether content belongs in skills, guidelines, learnings, or personas
- `claude-authoring-guidelines.md` — Patterns for writing, merging, and maintaining guidelines
- `claude-authoring-learnings.md` — Patterns for authoring and curating learnings files (genericize, structure, dedup)
- `claude-authoring-personas.md` — Patterns for writing domain personas (judgment layer, not recipe catalog)
- `claude-authoring-skills.md` — Core skill design patterns (structure, allowed-tools, operator/agent distinction)
- `claude-authoring-polling-review-skills.md` — Patterns specific to polling and review skill design

## Claude Code & Agent Infrastructure

- `claude-code.md` — Claude Code tool gotchas: Task tool worktree limitations, permission edge cases
- `claude-code-hooks.md` — PreToolUse hook authoring and hook configuration patterns
- `skill-platform-portability.md` — Official features, cross-platform compatibility, plugins, agent definitions
- `multi-agent-patterns.md` — Multi-agent orchestration: background agents, output verification, intermediate files
- `parallel-plans.md` — Parallel plan execution: DAG shape, speedup bounds, dependency ordering
- `ralph-loop.md` — Ralph loop: resuming completed loops, loop state management
- `explore-repo.md` — explore-repo skill patterns: parallel multi-agent exploration for unfamiliar repos
- `cross-repo-sync.md` — Cross-repo sync patterns and path-mismatch gotchas

## XRPL

- `xrpl-patterns.md` — XRPL patterns: getOrderbook vs raw book_offers, xrpl.js v4 specifics
- `xrpl-gotchas.md` — Condensed XRPL integration tripwires (companion to xrpl-patterns.md)
- `xrpl-amm.md` — XRPL AMM: constant-product formulas with fee, LP token mechanics
- `xrpl-cross-currency-payments.md` — Cross-currency payments: delivered_amount, path finding, slippage
- `xrpl-dex-data.md` — XRPL DEX external APIs: OnTheDEX token data, market data sources
- `xrpl-permissioned-domains.md` — XRPL permissioned domains and credentials (feature status, setup)

## Java / Spring Boot

- `spring-boot.md` — Spring Boot patterns and best practices (Mockito 5+, BOM, testing)
- `spring-boot-gotchas.md` — Spring Boot tripwires: common one-liner mistakes (companion to spring-boot.md)
- `java-observability.md` — Java observability: Micrometer counters, Grafana dashboard patterns
- `java-observability-gotchas.md` — Micrometer/metrics tripwires (companion to java-observability.md)
- `java-infosec-gotchas.md` — Java security tripwires: check before any code review or implementation
- `quarkus-kotlin.md` — Quarkus + Kotlin: enum hot-reload, dev mode gotchas, build quirks

## Frontend / React

- `react-patterns.md` — React patterns: React 19 hooks rules, state management, render behavior
- `react-frontend-gotchas.md` — React 19, Next.js/Turbopack, and Playwright tripwires (companion to react-patterns.md)
- `nextjs.md` — Next.js learnings: middleware rename, routing, app router patterns
- `ui-patterns.md` — UI patterns: CSS tooltips, Tailwind group-hover, component layout
- `accessibility-patterns.md` — Common accessibility gaps in React/Next.js components and their fixes
- `typescript-specific.md` — TypeScript patterns: union types, Record keys, type narrowing
- `typescript-ci-gotchas.md` — pnpm/Node CI: lockfile handling, action setup, browser caching, linting config

## AWS / Infrastructure

- `aws-patterns.md` — AWS patterns: EventBridge scheduler, IAM, Lambda gotchas
- `aws-messaging.md` — AWS messaging: SQS/SNS/EventBridge queue selection and configuration
- `vercel-deployment.md` — Vercel deployment: cron job limits, environment variables, edge config

## CI/CD

- `ci-cd.md` — CI/CD patterns: Docker build/push stage sharing, pipeline structure
- `ci-cd-gotchas.md` — GitHub Actions and GitLab CI tripwires (companion to ci-cd.md and gitlab-ci-cd.md)
- `gitlab-ci-cd.md` — GitLab CI/CD patterns: diagnosing failures with glab, pipeline structure
- `gitlab-cli.md` — GitLab CLI (glab): flag differences from gh CLI (--all, --raw diff, --jq workaround)

## Database

- `postgresql-query-patterns.md` — PostgreSQL: window functions, CTEs, query optimization patterns
- `local-dev-seeding.md` — Local dev seeding: hybrid API + SQL architecture for repeatable test data

## Financial

- `financial-applications.md` — Financial application patterns: monetary calculation safety, error handling
- `bignumber-financial-arithmetic.md` — BigNumber.js for JS financial arithmetic: prevents float precision errors in prices and totals
- `order-book-pricing.md` — Order book pricing: mid-price approaches, slippage calculation, spread

## General Engineering

- `api-design.md` — API design: consistent response shapes, versioning, error contracts
- `code-quality-instincts.md` — Fundamental code quality practices that apply across all languages and frameworks
- `refactoring-patterns.md` — Refactoring guidelines: survey before acting, scope discipline
- `testing-patterns.md` — Testing patterns: Vitest + React Testing Library, test structure, mocking
- `playwright-patterns.md` — Playwright E2E testing: patterns, gotchas, best practices
- `newman-postman.md` — Newman/Postman: skipRequest synchronous constraint, collection patterns
- `git-patterns.md` — Git patterns: commit-message-based identification, rebase, branch management
- `bash-patterns.md` — Bash patterns: shell env default ordering, quoting gotchas
- `python-specific.md` — Python patterns: Pydantic v2 optional fields, serialization
- `resilience-patterns.md` — Resilience patterns: idempotent processing, reprocessing loop prevention
- `reactive-data-patterns.md` — Reactive data patterns for real-time UIs: background refresh, resource validation
- `web-session-sync.md` — Web session sync: when sync is needed vs not, implementation patterns
- `process-conventions.md` — Engineering process conventions: scoping, tracking, work organization
