# CLAUDE.md Authoring Patterns

Patterns for writing effective CLAUDE.md files that help AI agents navigate codebases.

## Conditional `@` Reference Pattern

**Problem:** Putting all context inline in root CLAUDE.md bloats token usage for every agent invocation, even when the agent only needs context for one subsystem.

**Solution:** Use conditional `@` references in root CLAUDE.md that point to subdirectory CLAUDE.md files. Agents auto-load CLAUDE.md files when they enter directories directly, so the subdirectory files serve double duty:
1. **Top-down discovery** — an agent reading root CLAUDE.md sees the reference and can load it if relevant
2. **Bottom-up auto-loading** — an agent that enters the directory directly gets the context automatically

**Format in root CLAUDE.md:**
```markdown
## Context-Specific Guides

@database/CLAUDE.md - Migration conventions and schema design
@server/orders/CLAUDE.md - Order processing architecture and state machine
@server/billing/CLAUDE.md - Payment and settlement flows
@test/utils/CLAUDE.md - Test infrastructure and shared helpers
```

**Key insight:** `@` references eagerly load the referenced file's content into every conversation. This makes root CLAUDE.md a navigational hub, but each `@` reference has a real token cost. Use this pattern to organize context into focused subdirectory files — the agent pays only for the subset relevant to its task when entering a directory directly, rather than loading everything from a monolithic root file.

## Subdirectory CLAUDE.md Criteria

Not every directory deserves its own CLAUDE.md. The overhead of maintaining another file must be justified by the navigation value it provides.

### When to Create

A subdirectory CLAUDE.md adds value when the directory has:

| Criterion | Example | Why It Helps |
|-----------|---------|--------------|
| **Complex state machines** | Order lifecycle (PENDING → PROCESSING → SUBMITTED → CONFIRMED) | Agents need to understand valid transitions before modifying code |
| **Legacy/new system coexistence** | Old `OrderService` vs new `OrderOrchestrationService` with feature flag | Without context, agents may modify the wrong system |
| **Test infrastructure with constraints** | Shared test context configuration preventing parallel execution | Getting this wrong causes resource exhaustion — non-obvious failure mode |
| **Standalone modules** | Migration runner with its own naming conventions (V###, R__) | Module has its own rules independent of the main app |
| **Integration layers** | Multiple external services with shared client framework | Agents need to know which retry profile to use, auth patterns, etc. |
| **Non-obvious failure modes** | Any directory where an agent entering without context would make common mistakes | Prevention is cheaper than debugging |

### When NOT to Create

- Simple CRUD services with standard patterns
- Directories with only 1-2 files
- Code that follows the same patterns as the rest of the codebase (no surprises)
- Directories already well-documented in the root CLAUDE.md

### What to Include

A good subdirectory CLAUDE.md is **concise and navigational**, not exhaustive:

1. **Architecture diagram** (ASCII) — key components and relationships
2. **State machines or flows** — valid transitions, trigger conditions
3. **Configuration table** — properties that control behavior
4. **Key gotchas** — things that would trip up an agent or developer
5. **Cross-references** — links to deeper documentation in `docs/learnings/`

**Anti-pattern:** Don't duplicate content from detailed documentation files. The CLAUDE.md should be a quick-reference that points to deeper docs, not a copy of them.

## Document Relationships, Not Just Inventory

CLAUDE.md should document how components connect — not just list what files exist. A file inventory tells an agent *what* exists, but relationships tell it *how* things work together.

Key relationship sections to include:

- **App Shell**: Component tree from layout down (e.g., `layout.tsx → Providers → NavBar → page`). Shows providers, wrappers, and navigation structure.
- **State Flow**: How data moves through the system (e.g., context → localStorage → API). Include the auth/session model (or lack thereof).
- **API Conventions**: Request/response patterns, how mutations vs reads differ, shared validation patterns.

These sections let an agent skip straight to the task instead of reading multiple source files to understand the wiring.

## Use Pointers for Fast-Growing Directories

For directories that grow frequently (e.g., UI components), use a pointer instead of an inventory:

**Good** — scales without maintenance:
```markdown
Reusable UI components live in `app/components/`. Before creating a new component, check there first — it likely already exists (modals, loading states, balance formatting, etc.).
```

**Avoid** — becomes stale, bloats context:
```markdown
- `modal-shell.tsx` — Reusable modal wrapper
- `balance-display.tsx` — Formatted balance rendering
- `explorer-link.tsx` — Links to external explorer
...
```

Reserve detailed inventories for stable infrastructure (lib modules, hooks, API routes) that change infrequently. The pointer pattern gives the agent the location and a behavioral nudge ("check here first") without maintenance burden.

## Single Source of Truth: README + CLAUDE.md + Symlink

To maintain one source of truth for both human and agent documentation:

1. **CLAUDE.md** — The real technical reference. Auto-loaded by agents. Contains architecture, API routes, state management, conventions, and gotchas.
2. **README.md** — Lightweight human entry point. Project overview, getting started instructions, and a link to the technical docs. No architecture details (avoids duplication).
3. **TECHNICAL_DETAILS.md** — Symlink to CLAUDE.md. Humans find it from README.md; agents never need it.

```
README.md (humans) ──link──▶ TECHNICAL_DETAILS.md ──symlink──▶ CLAUDE.md (agents)
```

Key insight: CLAUDE.md content is already human-readable — the split is about entry points, not content format. Humans expect README.md; agents get CLAUDE.md auto-loaded. The symlink bridges the two without any content duplication.

## State Conclusions, Not Just Premises

When two or more CLAUDE.md facts must be combined to produce correct behavior, state the actionable conclusion explicitly at the point of use — don't rely on the agent to infer it.

**Example:** "Repo is symlinked to `~/.claude`" + "Glob/Read don't resolve `~`" independently are clear, but neither states the conclusion: "use `.claude/` relative paths for Read/Glob." Adding the conclusion inline prevents repeated inference failures across sessions.

## Signpost Pattern: Non-`@` Lazy-Loaded References

File paths listed in CLAUDE.md **without** the `@` prefix are not eagerly inlined — they're plain text. But proactive agents notice these paths and read them on demand when the topic becomes relevant. This creates a lightweight lazy-loading mechanism.

**Format:**
```markdown
## Lazy-loaded references (read when relevant)

.claude/guidelines/deployment.md - Production deployment checklist
docs/architecture/auth-flow.md - Authentication sequence and token lifecycle
```

**Behavior contrast:**
- `@path` → eagerly inlined, always costs tokens
- `path` (no `@`) → visible as text, read by agent judgment when relevant

**When to use signposts over `@`:** Context that's useful but not universally needed — domain-specific guidelines, deep-dive references, or situational checklists. Reserve `@` for context every session needs.

**Validation method:** Add a unique marker string to the signposted file, start a fresh session, and check whether the agent (a) ignores it, (b) reads it proactively via a Read tool call, or (c) reports the marker without a Read call (indicating eager inlining — a failure). Success = (b).

## Refactor Monolithic CLAUDE.md into Modular Guideline Includes

A monolithic CLAUDE.md (130+ lines) can be refactored into modular files under `.claude/guidelines/` using `@` includes. The root file shrinks to a navigational hub (~8 lines of `@` references). Refactoring into modules creates a natural affordance for content expansion — sections that felt too bulky for a monolithic file grow organically when they have their own file. Expect new content to emerge during the extraction, not just a pure move.

- **Takeaway**: Modularize large CLAUDE.md files into `@`-referenced guideline files; expect content expansion as a bonus.

## Document Conflict Resolution Strategy Alongside Structural Changes

When introducing structural changes that will cause merge conflicts (e.g., switching from inline content to `@` includes), document the conflict resolution strategy in the same PR. Forward-looking documentation prevents confusion when conflicts inevitably arise. Example: "check inline version for NEW additions not yet in modular files, incorporate into the appropriate module, resolve main file to keep `@` includes."

- **Takeaway**: Ship conflict resolution docs with the structural change that causes those conflicts.

## `@` References Resolve Relative to the File, Not the Project Root

`@./guidelines/foo.md` in `~/.claude/CLAUDE.md` resolves to `~/.claude/guidelines/foo.md`. Using `@.claude/guidelines/foo.md` (project-root-relative) may fail to load content even though the path looks correct. Always use `./`-relative paths from the CLAUDE.md file's own directory.

## See also

- `.claude/learnings/claude-authoring-content-types.md` — hub: content type taxonomy, routing table, boundary cases
