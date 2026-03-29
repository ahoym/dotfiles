# Public Release Review

## Pre-Publish Sanitization Checklist

Before making skills, commands, or documentation public, review all files for unintentional domain-specific leaks. These often hide in examples rather than instructions.

### What to check

- **Service/module names** in example paths (e.g., `my-internal-service/src/...` should be `backend/src/...`)
- **Domain-specific business terms** in parenthetical examples (e.g., specific workflow names should be generic like "order lifecycle, approval flow")
- **Internal URLs, hostnames, or API endpoints** in examples or comments
- **Team/org names** or internal project identifiers
- **Business logic references** that reveal what the original codebase does

### Where leaks hide

- Inline examples in instructions (e.g., `e.g., ...` parentheticals)
- Path format examples in agent prompts
- Sample output blocks
- ASCII diagrams with labeled components
- Comments explaining "why" with domain context

### Fix approach

Replace with generic equivalents that preserve the teaching value without revealing the source domain.
