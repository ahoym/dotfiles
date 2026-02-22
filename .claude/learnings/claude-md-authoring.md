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

**Key insight:** The `@` syntax is lightweight — it signals "this context exists and is loadable" without dumping the full content. This keeps root CLAUDE.md as a navigational hub rather than a monolithic knowledge dump.

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
