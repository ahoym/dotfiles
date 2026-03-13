# Process Conventions

Patterns for how engineering work is organized, scoped, and tracked.

### pyproject.toml as stable anchor across package manager migrations

`pyproject.toml` is the stable artifact across Python package manager changes (requirements.txt -> Poetry -> uv). Lock files and tooling-specific configs are the disposable parts. When migrating package managers, `pyproject.toml` persists while everything else gets replaced.

- **Takeaway**: Build migration plans around pyproject.toml as the anchor file.

### Dockerfile updates alongside package manager changes

Package manager migrations require coordinated Dockerfile updates. The build layer that installs dependencies changes when the tool changes. This is a checklist item for any tooling migration.

- **Takeaway**: Package manager change = Dockerfile change. Always.

### Migration scripts committed alongside the migration

Commit a dedicated migration script (e.g., `scripts/migrate-poetry-to-uv.sh`) alongside the migration PR. Captures the exact steps used, serves as documentation and a reproducible recipe for similar migrations.

- **Takeaway**: Non-trivial tooling migrations deserve a committed migration script.

### Defer large cross-cutting refactors to tracked issues

When code review surfaces a systemic improvement (e.g., float-to-Decimal conversion), file an issue rather than scope-creeping the current PR. The PR stays focused; the improvement gets tracked.

- **Takeaway**: Systemic improvements surfaced during review = new issue, not PR scope expansion.

### Plan-first PRs as exploration pattern

PRs that include a plan document alongside implementation code serve as design artifacts. Even when the PR is ultimately closed, the planning work feeds into the decision — the analysis itself is the value.

- **Takeaway**: Exploration PRs that get closed still produce value through their analysis.

### Closing PRs cleanly with cherry-pick intent

Rather than silently abandoning a PR, explicitly note that unique content will be cherry-picked into a follow-up. Makes the closed PR a discoverable record of what was tried and what content is still pending.

- **Takeaway**: Close PRs with documented intent — what's abandoned vs. what's being carried forward.
