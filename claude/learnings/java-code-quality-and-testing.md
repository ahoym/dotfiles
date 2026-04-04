### `Objects.equals` for null-safe equality; avoid `.equals()` on literals

SonarQube flags patterns like `Integer.valueOf(1).equals(result)` — a backwards equals call that also boxes unnecessarily. Use `Objects.equals(a, b)` whenever either side could be null. It handles null safely on both sides without boxing overhead.
