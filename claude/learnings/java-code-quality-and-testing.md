Java code quality: null-safe equality with Objects.equals, SonarQube patterns.
- **Keywords:** Objects.equals, null-safe, SonarQube, boxing, Integer, equality
- **Related:** ~/.claude/learnings/java-code-quality.md

---

### `Objects.equals` for null-safe equality; avoid `.equals()` on literals

SonarQube flags patterns like `Integer.valueOf(1).equals(result)` — a backwards equals call that also boxes unnecessarily. Use `Objects.equals(a, b)` whenever either side could be null. It handles null safely on both sides without boxing overhead.
