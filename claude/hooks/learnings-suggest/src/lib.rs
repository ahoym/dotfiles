// Shared utilities for the learnings-suggest binaries.
//
// `learnings-suggest` (UserPromptSubmit) and `learnings-index-build`
// (offline indexer) both resolve providers from `learnings-providers.json` and
// expand tilde paths. They differ on one axis: `projectLocal` learnings live in
// the CWD and only exist at hook-runtime — the offline indexer can't pre-bake
// them. `providers(include_project_local)` makes that split explicit.

use serde_json::Value;
use std::fs;
use std::path::PathBuf;

pub const SCHEMA_VERSION: u64 = 1;

pub fn home() -> PathBuf {
    PathBuf::from(std::env::var("HOME").unwrap_or_default())
}

pub fn claude_root() -> PathBuf {
    home().join(".claude")
}

pub fn expand_tilde(p: &str) -> PathBuf {
    p.strip_prefix("~/")
        .map(|rest| home().join(rest))
        .unwrap_or_else(|| PathBuf::from(p))
}

#[derive(Clone)]
pub struct Provider {
    pub name: String,
    pub base: PathBuf, // The learnings directory itself
    pub root: PathBuf, // The base's parent — indexes encode paths relative to this
}

/// Read `~/.claude/learnings-providers.json` and resolve providers.
/// `include_project_local`: when true, also append `projectLocal` resolved from CWD.
/// The runtime hook passes true; the offline indexer passes false (projectLocal
/// cannot be globally pre-indexed).
pub fn providers(include_project_local: bool) -> Vec<Provider> {
    let pf = claude_root().join("learnings-providers.json");
    let v: Value = match fs::read_to_string(&pf)
        .ok()
        .and_then(|s| serde_json::from_str(&s).ok())
    {
        Some(v) => v,
        None => return vec![],
    };
    let mut out = Vec::new();
    if let Some(arr) = v.get("providers").and_then(Value::as_array) {
        for p in arr {
            let name = p.get("name").and_then(Value::as_str).unwrap_or("").to_string();
            if let Some(lp) = p.get("localPath").and_then(Value::as_str) {
                let base = expand_tilde(lp);
                if base.exists() {
                    let root = base.parent().unwrap_or(&base).to_path_buf();
                    out.push(Provider { name, base, root });
                }
            }
        }
    }
    if include_project_local {
        if let Some(pl) = v
            .get("projectLocal")
            .and_then(|p| p.get("path"))
            .and_then(Value::as_str)
        {
            if let Ok(cwd) = std::env::current_dir() {
                let base = cwd.join(pl);
                if base.exists() {
                    let root = base.parent().unwrap_or(&base).to_path_buf();
                    out.push(Provider {
                        name: "projectLocal".to_string(),
                        base,
                        root,
                    });
                }
            }
        }
    }
    out
}
