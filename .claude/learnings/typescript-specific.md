# TypeScript-Specific Patterns

## Extending a Union Type Used in Record Keys

When adding a new member to a union type used as a `Record` key (e.g., adding `"mainnet"` to `"testnet" | "devnet"`), every `Record<ThatUnion, ...>` in the codebase must be updated. TypeScript will catch missing keys — but the errors may be in unexpected files (e.g., configuration maps, URL registries, not just the primary type definition).

Search for `Record<YourUnionType` across the codebase when extending the union.

## See also

- `~/.claude/learnings/nextjs.md` — Next.js patterns (original context for union type pattern)
- `~/.claude/learnings/react-frontend-gotchas.md` — condensed frontend tripwires
- `~/.claude/learnings/code-quality-instincts.md` — general code quality patterns
