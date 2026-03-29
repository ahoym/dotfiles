TypeScript patterns for union types, Record keys, and type-level constraints.
- **Keywords:** union type, Record key, codebase search, type extension, PascalCase
- **Related:** ~/.claude/learnings/code-quality-instincts.md

---

## Extending a Union Type Used in Record Keys

When adding a new member to a union type used as a `Record` key (e.g., adding `"mainnet"` to `"testnet" | "devnet"`), every `Record<ThatUnion, ...>` in the codebase must be updated. TypeScript will catch missing keys — but the errors may be in unexpected files (e.g., configuration maps, URL registries, not just the primary type definition).

Search for `Record<YourUnionType` across the codebase when extending the union.

## Cross-Refs

- `~/.claude/learnings/code-quality-instincts.md` — general code quality patterns
