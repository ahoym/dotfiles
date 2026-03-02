# Troubleshooting Guidelines

## Root-cause before config workarounds

When `tsc`/typecheck fails on missing module imports, check whether the dependency is actually installed (`ls node_modules/<pkg>`) before restructuring `tsconfig.json` excludes or paths. Stale `node_modules` (out of sync with lockfile) is a more common root cause than misconfigured TypeScript includes. Run the package manager's install command first — config changes that hide the importing files mask the real problem.
