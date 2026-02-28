# Validation

## "Validate" means run it

When asked to validate that scripts/workflows work, **execute them** — don't just lint. Static analysis (`bash -n`, file existence checks, cross-reference verification) catches structural issues but misses runtime bugs: wrong env values, ordering problems, integration failures.

**Default escalation**: syntax check → dry-run (if available) → actual execution. Only stop at static analysis if execution is explicitly impossible or the user says so.

## Verify documentation against source code

When creating docs that mirror code-defined data (enums, config, topology), run the source code to validate claims programmatically. Counting items, listing values, or computing derived facts via `poetry run python3 -c "..."` catches misclassifications that manual review misses.
