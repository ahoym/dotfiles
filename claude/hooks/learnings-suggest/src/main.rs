// UserPromptSubmit hook: matches the operator's prompt against the federated
// learnings corpus and injects a <learnings-suggestions> hint block.
//
// Match sources (both consulted, section-level preferred on overlap):
//   1. ~/.claude/claude-artifacts/ast/sections.json (iteration 2a — section-level,
//      built by `learnings-index-build`)
//   2. <provider>/.keyword-index.json (iteration 1 — file-level, hand-curated by
//      `/learnings:curate`)
//
// Falls back to file-level only when sections.json is missing or schema-mismatched.
// Hook must never block a prompt: any failure → silent no-op.

use aho_corasick::{AhoCorasickBuilder, MatchKind};
use serde_json::{json, Value};
use std::collections::{hash_map::DefaultHasher, BTreeMap, HashMap, HashSet};
use std::fs::{self, OpenOptions};
use std::hash::{Hash, Hasher};
use std::io::{self, Read, Write};
use std::path::{Path, PathBuf};
use std::time::{SystemTime, UNIX_EPOCH};

const SCHEMA_VERSION: u64 = 1;
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

fn expand_tilde(p: &str) -> PathBuf {
    p.strip_prefix("~/")
        .map(|rest| home().join(rest))
        .unwrap_or_else(|| PathBuf::from(p))
}

// ---------- Provider resolution (shared by both indexes) ----------

#[derive(Clone)]
struct Provider {
    name: String,
    base: PathBuf, // The learnings directory itself
    root: PathBuf, // The base's parent — indexes encode paths relative to this
}

fn providers() -> Vec<Provider> {
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
    // projectLocal: resolved relative to CWD, indexed at runtime only
    if let Some(pl) = v.get("projectLocal").and_then(|p| p.get("path")).and_then(Value::as_str) {
        if let Ok(cwd) = std::env::current_dir() {
            let base = cwd.join(pl);
            if base.exists() {
                let root = base.parent().unwrap_or(&base).to_path_buf();
                out.push(Provider { name: "projectLocal".to_string(), base, root });
            }
        }
    }
    out
}

// ---------- Unified hit shape ----------

#[derive(Clone)]
struct Hit {
    provider: String,
    rel: String,                       // e.g. "learnings/python-specific.md"
    section: Option<SectionRef>,       // None = file-level
    score: usize,
    terms: Vec<String>,
}

#[derive(Clone)]
struct SectionRef {
    anchor: String,
    header: String,
    lines: (usize, usize),
}

fn passes_filter(rel: &str) -> bool {
    !FILTER_PREFIXES.iter().any(|pre| rel.starts_with(pre))
}

// ---------- Index loaders ----------

struct SectionsIndex {
    by_keyword: BTreeMap<String, Vec<usize>>,
    sections: Vec<SectionEntry>,
    // mtime of sections.json itself, for staleness checks
    mtime: SystemTime,
}

struct SectionEntry {
    provider: String,
    rel: String,
    anchor: String,
    header: String,
    lines: (usize, usize),
}

fn load_sections_index() -> Option<SectionsIndex> {
    let path = claude_root()
        .join("claude-artifacts")
        .join("ast")
        .join("sections.json");
    let meta = fs::metadata(&path).ok()?;
    let mtime = meta.modified().ok()?;
    let v: Value = serde_json::from_str(&fs::read_to_string(&path).ok()?).ok()?;
    let schema = v.get("_meta").and_then(|m| m.get("schema")).and_then(Value::as_u64);
    if schema != Some(SCHEMA_VERSION) {
        return None;
    }
    let by_kw_obj = v.get("by_keyword").and_then(Value::as_object)?;
    let mut by_keyword = BTreeMap::new();
    for (k, arr) in by_kw_obj {
        if let Some(a) = arr.as_array() {
            by_keyword.insert(
                k.clone(),
                a.iter().filter_map(|x| x.as_u64().map(|n| n as usize)).collect(),
            );
        }
    }
    let sec_arr = v.get("sections").and_then(Value::as_array)?;
    let mut sections = Vec::with_capacity(sec_arr.len());
    for s in sec_arr {
        let lines = s.get("lines").and_then(Value::as_array);
        let l0 = lines.and_then(|a| a.first()).and_then(Value::as_u64).unwrap_or(0) as usize;
        let l1 = lines.and_then(|a| a.get(1)).and_then(Value::as_u64).unwrap_or(0) as usize;
        sections.push(SectionEntry {
            provider: s.get("provider").and_then(Value::as_str).unwrap_or("").to_string(),
            rel: s.get("rel").and_then(Value::as_str).unwrap_or("").to_string(),
            anchor: s.get("anchor").and_then(Value::as_str).unwrap_or("").to_string(),
            header: s.get("header").and_then(Value::as_str).unwrap_or("").to_string(),
            lines: (l0, l1),
        });
    }
    Some(SectionsIndex { by_keyword, sections, mtime })
}

/// File-level keyword index entries: keyword → list of (provider_root, rel_path).
type FileIndexEntries = Vec<(String, Vec<(PathBuf, String)>)>;

fn load_file_index(provs: &[Provider]) -> FileIndexEntries {
    let mut merged: HashMap<String, Vec<(PathBuf, String)>> = HashMap::new();
    for prov in provs {
        let index_file = prov.base.join(".keyword-index.json");
        if !index_file.exists() {
            continue;
        }
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
                        entry.push((prov.root.clone(), s.to_string()));
                    }
                }
            }
        }
    }
    let mut v: FileIndexEntries = merged.into_iter().collect();
    v.sort_by(|a, b| a.0.cmp(&b.0));
    v
}

// ---------- Prompt helpers ----------

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

fn display_path(root: &Path, rel: &str) -> String {
    let full = root.join(rel);
    if let Ok(stripped) = full.strip_prefix(home()) {
        format!("~/{}", stripped.display())
    } else {
        full.display().to_string()
    }
}

// ---------- Telemetry ----------

fn log_event(prompt: &str, session: Option<&str>, hits: &[(Hit, PathBuf)]) {
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
        .map(|(hit, root)| {
            let mut o = json!({
                "path": display_path(root, &hit.rel),
                "score": hit.score,
                "tier": if hit.score >= STRONG_SCORE { "strong" } else { "weak" },
                "terms": hit.terms.iter().take(5).collect::<Vec<_>>(),
            });
            if let Some(sec) = &hit.section {
                o["anchor"] = json!(sec.anchor);
                o["lines"] = json!([sec.lines.0, sec.lines.1]);
            }
            o
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

// ---------- Main flow ----------

fn read_payload() -> Option<Value> {
    let mut s = String::new();
    io::stdin().read_to_string(&mut s).ok()?;
    serde_json::from_str(&s).ok()
}

fn build_matcher(keys: &[&str]) -> Option<aho_corasick::AhoCorasick> {
    AhoCorasickBuilder::new()
        .match_kind(MatchKind::LeftmostLongest)
        .ascii_case_insensitive(true)
        .build(keys)
        .ok()
}

fn run() -> Option<()> {
    let payload = read_payload()?;
    let prompt = payload.get("prompt").and_then(Value::as_str).unwrap_or("");
    let session = payload.get("session_id").and_then(Value::as_str);

    if prompt.len() < TRIVIAL_LEN || !prompt.chars().any(|c| c.is_ascii_alphabetic()) {
        return None;
    }

    let provs = providers();
    if provs.is_empty() {
        return None;
    }

    // --- Section-level matching (preferred) ---
    let sections = load_sections_index();
    let mut section_hits: HashMap<(String, usize), (usize, Vec<String>)> = HashMap::new();
    let section_keys: Vec<String> = sections
        .as_ref()
        .map(|idx| idx.by_keyword.keys().cloned().collect())
        .unwrap_or_default();
    if let Some(idx) = &sections {
        if let Some(ac) = build_matcher(&section_keys.iter().map(String::as_str).collect::<Vec<_>>()) {
            for m in ac.find_iter(prompt) {
                let kw = &section_keys[m.pattern()];
                let weight = kw.split_whitespace().count().max(1);
                if let Some(sec_ids) = idx.by_keyword.get(kw) {
                    for &sid in sec_ids {
                        let sec = match idx.sections.get(sid) {
                            Some(s) => s,
                            None => continue,
                        };
                        if !passes_filter(&sec.rel) {
                            continue;
                        }
                        let entry = section_hits.entry((sec.provider.clone(), sid)).or_insert((0, vec![]));
                        entry.0 += weight;
                        if !entry.1.iter().any(|t| t == kw) {
                            entry.1.push(kw.clone());
                        }
                    }
                }
            }
        }
    }

    // --- File-level matching (always; supplements sections, plus serves dense files) ---
    let file_idx = load_file_index(&provs);
    let file_keys: Vec<&str> = file_idx.iter().map(|(k, _)| k.as_str()).collect();
    let mut file_hits: HashMap<(String, String), (usize, Vec<String>, PathBuf)> = HashMap::new();
    if let Some(ac) = build_matcher(&file_keys) {
        for m in ac.find_iter(prompt) {
            let (kw, paths) = &file_idx[m.pattern()];
            let weight = kw.split_whitespace().count().max(1);
            for (root, rel) in paths {
                if !passes_filter(rel) {
                    continue;
                }
                // Synthesize a provider-name proxy from the root.
                let pname = root
                    .file_name()
                    .and_then(|s| s.to_str())
                    .unwrap_or("")
                    .to_string();
                let entry = file_hits
                    .entry((pname, rel.clone()))
                    .or_insert((0, vec![], root.clone()));
                entry.0 += weight;
                if !entry.1.iter().any(|t| t == kw) {
                    entry.1.push(kw.clone());
                }
            }
        }
    }

    // Materialize section hits as Hit + staleness downgrade
    let mut hits: Vec<(Hit, PathBuf)> = Vec::new();
    let mut covered_paths: HashSet<(String, String)> = HashSet::new();
    if let Some(idx) = &sections {
        for ((provider, sid), (score, terms)) in section_hits {
            let sec = match idx.sections.get(sid) {
                Some(s) => s,
                None => continue,
            };
            // Resolve provider root
            let prov_root = match provs.iter().find(|p| p.name == provider) {
                Some(p) => p.root.clone(),
                None => continue,
            };
            // Staleness check: if the file is newer than sections.json, drop :start-end
            let full = prov_root.join(&sec.rel);
            let section_ref = match fs::metadata(&full).and_then(|m| m.modified()).ok() {
                Some(mt) if mt > idx.mtime => None, // downgrade to file-level
                _ => Some(SectionRef {
                    anchor: sec.anchor.clone(),
                    header: sec.header.clone(),
                    lines: sec.lines,
                }),
            };
            hits.push((
                Hit {
                    provider: provider.clone(),
                    rel: sec.rel.clone(),
                    section: section_ref,
                    score,
                    terms,
                },
                prov_root,
            ));
            covered_paths.insert((provider, sec.rel.clone()));
        }
    }

    // Add file-level hits where the path isn't already covered by a section hit
    for ((pname, rel), (score, terms, root)) in file_hits {
        // Map root to provider name by checking provs (the file_idx root is the provider's root path)
        let provider_name = provs
            .iter()
            .find(|p| p.root == root)
            .map(|p| p.name.clone())
            .unwrap_or_else(|| pname.clone());
        if covered_paths.contains(&(provider_name.clone(), rel.clone())) {
            continue;
        }
        hits.push((
            Hit {
                provider: provider_name,
                rel,
                section: None,
                score,
                terms,
            },
            root,
        ));
    }

    // Quoted-term bypass: keywords in quotes force inclusion below MIN_SCORE
    let quoted = extract_quoted(prompt);
    let forced: HashSet<(String, String)> = if quoted.is_empty() {
        HashSet::new()
    } else {
        let mut out: HashSet<(String, String)> = HashSet::new();
        if let Some(idx) = &sections {
            for (kw, sec_ids) in &idx.by_keyword {
                if quoted.contains(kw) {
                    for &sid in sec_ids {
                        if let Some(sec) = idx.sections.get(sid) {
                            if passes_filter(&sec.rel) {
                                out.insert((sec.provider.clone(), sec.rel.clone()));
                            }
                        }
                    }
                }
            }
        }
        for (kw, paths) in &file_idx {
            if quoted.contains(kw) {
                for (root, rel) in paths {
                    if !passes_filter(rel) {
                        continue;
                    }
                    let provider_name = provs
                        .iter()
                        .find(|p| p.root == *root)
                        .map(|p| p.name.clone())
                        .unwrap_or_default();
                    out.insert((provider_name, rel.clone()));
                }
            }
        }
        out
    };

    hits.retain(|(h, _)| {
        h.score >= MIN_SCORE || forced.contains(&(h.provider.clone(), h.rel.clone()))
    });
    hits.sort_by(|(a, _), (b, _)| b.score.cmp(&a.score).then_with(|| a.rel.cmp(&b.rel)));
    hits.truncate(MAX_HITS);

    log_event(prompt, session, &hits);
    if hits.is_empty() {
        return None;
    }

    let mut lines = vec!["<learnings-suggestions>".to_string()];
    for (hit, root) in &hits {
        let tier = if hit.score >= STRONG_SCORE { "strong" } else { "weak" };
        let term_str = hit
            .terms
            .iter()
            .take(3)
            .cloned()
            .collect::<Vec<_>>()
            .join(", ");
        let (path_str, desc) = match &hit.section {
            Some(sec) => {
                let p = display_path(root, &hit.rel);
                (
                    format!("{}:{}-{}", p, sec.lines.0, sec.lines.1),
                    sec.header.clone(),
                )
            }
            None => {
                let full = root.join(&hit.rel);
                let desc = truncate_chars(&first_line(&full), 80);
                (display_path(root, &hit.rel), desc)
            }
        };
        lines.push(format!("  [{}] {} — {} | {}", tier, path_str, term_str, desc));
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
    let _ = run();
}
