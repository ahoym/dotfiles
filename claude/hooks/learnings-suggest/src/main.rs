// UserPromptSubmit hook: matches the operator's prompt against the federated
// learnings keyword index and injects a <learnings-suggestions> hint block.
// Designed to be fast and silent on miss — never blocks a prompt.

use aho_corasick::{AhoCorasickBuilder, MatchKind};
use serde_json::{json, Value};
use std::collections::{hash_map::DefaultHasher, HashMap, HashSet};
use std::fs::{self, OpenOptions};
use std::hash::{Hash, Hasher};
use std::io::{self, Read, Write};
use std::path::{Path, PathBuf};
use std::time::{SystemTime, UNIX_EPOCH};

const MIN_SCORE: usize = 2;
const STRONG_SCORE: usize = 3;
const MAX_HITS: usize = 3;
const TRIVIAL_LEN: usize = 20;
const FILTER_PREFIXES: &[&str] = &["commands/"];

fn home() -> PathBuf {
    PathBuf::from(std::env::var("HOME").unwrap_or_default())
}
fn claude_root() -> PathBuf {
    home().join(".claude")
}

/// Each entry: (provider_index_base, "relative/path/file.md"). The base is the
/// directory that paths in the index resolve against (parent of localPath).
type IndexEntries = Vec<(String, Vec<(PathBuf, String)>)>;

fn read_payload() -> Option<Value> {
    let mut s = String::new();
    io::stdin().read_to_string(&mut s).ok()?;
    serde_json::from_str(&s).ok()
}

fn expand_tilde(p: &str) -> PathBuf {
    p.strip_prefix("~/")
        .map(|rest| home().join(rest))
        .unwrap_or_else(|| PathBuf::from(p))
}

/// Walk `learnings-providers.json` and return existing index files paired with
/// the base directory their paths are relative to (the provider's parent).
fn collect_index_files() -> Vec<(PathBuf, PathBuf)> {
    let providers_file = claude_root().join("learnings-providers.json");
    let v: Value = match fs::read_to_string(&providers_file)
        .ok()
        .and_then(|s| serde_json::from_str(&s).ok())
    {
        Some(v) => v,
        None => return vec![],
    };

    let mut out = Vec::new();
    if let Some(providers) = v.get("providers").and_then(Value::as_array) {
        for p in providers {
            if let Some(lp) = p.get("localPath").and_then(Value::as_str) {
                let dir = expand_tilde(lp);
                let index = dir.join(".keyword-index.json");
                if index.exists() {
                    let base = dir.parent().unwrap_or(&dir).to_path_buf();
                    out.push((base, index));
                }
            }
        }
    }
    if let Some(pl) = v
        .get("projectLocal")
        .and_then(|p| p.get("path"))
        .and_then(Value::as_str)
    {
        if let Ok(cwd) = std::env::current_dir() {
            let dir = cwd.join(pl);
            let index = dir.join(".keyword-index.json");
            if index.exists() {
                let base = dir.parent().unwrap_or(&dir).to_path_buf();
                out.push((base, index));
            }
        }
    }
    out
}

fn load_merged_index() -> IndexEntries {
    let mut merged: HashMap<String, Vec<(PathBuf, String)>> = HashMap::new();
    for (base, index_file) in collect_index_files() {
        let v: Value = match fs::read_to_string(&index_file)
            .ok()
            .and_then(|s| serde_json::from_str(&s).ok())
        {
            Some(v) => v,
            None => continue,
        };
        let obj = match v.as_object() {
            Some(o) => o,
            None => continue,
        };
        for (kw, paths_val) in obj {
            if kw.starts_with('_') {
                continue;
            }
            if let Some(arr) = paths_val.as_array() {
                let entry = merged.entry(kw.clone()).or_default();
                for p in arr {
                    if let Some(s) = p.as_str() {
                        entry.push((base.clone(), s.to_string()));
                    }
                }
            }
        }
    }
    let mut v: IndexEntries = merged.into_iter().collect();
    // Stable order helps determinism in logs / tests.
    v.sort_by(|a, b| a.0.cmp(&b.0));
    v
}

fn extract_quoted(prompt: &str) -> HashSet<String> {
    let mut out = HashSet::new();
    let bytes = prompt.as_bytes();
    let mut i = 0;
    while i < bytes.len() {
        if bytes[i] == b'"' {
            if let Some(rel) = prompt[i + 1..].find('"') {
                let s = &prompt[i + 1..i + 1 + rel];
                if !s.is_empty() && s.len() < 80 {
                    out.insert(s.to_lowercase());
                }
                i += rel + 2;
                continue;
            }
        }
        i += 1;
    }
    out
}

fn first_line(path: &Path) -> String {
    fs::read_to_string(path)
        .ok()
        .and_then(|s| s.lines().next().map(|l| l.trim().to_string()))
        .unwrap_or_default()
}

fn truncate_chars(s: &str, n: usize) -> String {
    s.chars().take(n).collect()
}

fn display_path(base: &Path, rel: &str) -> String {
    let full = base.join(rel);
    if let Ok(stripped) = full.strip_prefix(home()) {
        format!("~/{}", stripped.display())
    } else {
        full.display().to_string()
    }
}

fn log_event(prompt: &str, session: Option<&str>, hits: &[Hit]) {
    let dir = claude_root().join("claude-artifacts").join("ast");
    if fs::create_dir_all(&dir).is_err() {
        return;
    }
    let path = dir.join("suggest.jsonl");

    let ts = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_secs())
        .unwrap_or(0);
    let mut h = DefaultHasher::new();
    prompt.hash(&mut h);

    let hit_json: Vec<Value> = hits
        .iter()
        .map(|hit| {
            json!({
                "path": display_path(&hit.base, &hit.rel),
                "score": hit.score,
                "tier": if hit.score >= STRONG_SCORE { "strong" } else { "weak" },
                "terms": hit.terms.iter().take(5).collect::<Vec<_>>(),
            })
        })
        .collect();

    let event = json!({
        "ts": ts,
        "prompt_hash": format!("{:016x}", h.finish()),
        "prompt_len": prompt.len(),
        "session": session,
        "hits": hit_json,
    });

    if let Ok(mut f) = OpenOptions::new().create(true).append(true).open(&path) {
        let _ = writeln!(f, "{}", event);
    }
}

struct Hit {
    base: PathBuf,
    rel: String,
    score: usize,
    terms: Vec<String>,
}

fn run() -> Option<()> {
    let payload = read_payload()?;
    let prompt = payload.get("prompt").and_then(Value::as_str).unwrap_or("");
    let session = payload.get("session_id").and_then(Value::as_str);

    if prompt.len() < TRIVIAL_LEN {
        return None;
    }
    if !prompt.chars().any(|c| c.is_ascii_alphabetic()) {
        return None;
    }

    let merged = load_merged_index();
    if merged.is_empty() {
        return None;
    }

    let keywords: Vec<&str> = merged.iter().map(|(k, _)| k.as_str()).collect();
    let ac = AhoCorasickBuilder::new()
        .match_kind(MatchKind::LeftmostLongest)
        .ascii_case_insensitive(true)
        .build(&keywords)
        .ok()?;

    type Key = (PathBuf, String);
    let mut scores: HashMap<Key, (usize, Vec<String>)> = HashMap::new();
    for m in ac.find_iter(prompt) {
        let (kw, paths) = &merged[m.pattern()];
        let weight = kw.split_whitespace().count().max(1);
        for (base, rel) in paths {
            if FILTER_PREFIXES.iter().any(|pre| rel.starts_with(pre)) {
                continue;
            }
            let key = (base.clone(), rel.clone());
            let entry = scores.entry(key).or_insert((0, vec![]));
            entry.0 += weight;
            if !entry.1.iter().any(|t| t == kw) {
                entry.1.push((*kw).to_string());
            }
        }
    }

    let quoted = extract_quoted(prompt);
    let forced: HashSet<Key> = if quoted.is_empty() {
        HashSet::new()
    } else {
        merged
            .iter()
            .filter(|(k, _)| quoted.contains(k.as_str()))
            .flat_map(|(_, paths)| paths.iter().cloned())
            .filter(|(_, rel)| !FILTER_PREFIXES.iter().any(|pre| rel.starts_with(pre)))
            .collect()
    };

    let mut hits: Vec<Hit> = scores
        .into_iter()
        .filter(|(k, (s, _))| *s >= MIN_SCORE || forced.contains(k))
        .map(|((base, rel), (score, terms))| Hit { base, rel, score, terms })
        .collect();
    hits.sort_by(|a, b| b.score.cmp(&a.score).then_with(|| a.rel.cmp(&b.rel)));
    hits.truncate(MAX_HITS);

    log_event(prompt, session, &hits);

    if hits.is_empty() {
        return None;
    }

    let mut lines = vec!["<learnings-suggestions>".to_string()];
    for hit in &hits {
        let tier = if hit.score >= STRONG_SCORE { "strong" } else { "weak" };
        let full = hit.base.join(&hit.rel);
        let desc = truncate_chars(&first_line(&full), 80);
        let term_str = hit
            .terms
            .iter()
            .take(3)
            .cloned()
            .collect::<Vec<_>>()
            .join(", ");
        lines.push(format!(
            "  [{}] {} — {} | {}",
            tier,
            display_path(&hit.base, &hit.rel),
            term_str,
            desc
        ));
    }
    lines.push("</learnings-suggestions>".to_string());

    let out = json!({
        "hookSpecificOutput": {
            "hookEventName": "UserPromptSubmit",
            "additionalContext": lines.join("\n")
        }
    });
    println!("{}", out);
    Some(())
}

fn main() {
    // Any failure path = silent no-op. The hook must never block a prompt.
    let _ = run();
}
