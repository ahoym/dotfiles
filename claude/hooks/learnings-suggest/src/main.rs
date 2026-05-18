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
use learnings_suggest::{artifacts_dir, claude_root, home, providers, Provider, SCHEMA_VERSION};
use serde_json::{json, Value};
use std::collections::{hash_map::DefaultHasher, BTreeMap, HashMap, HashSet};
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

// Neutral fallback when a sections.json was built by an older index-build that
// didn't emit `kw_weights` (additive-optional schema). Keeps scoring numerically
// equivalent to the pre-IDF behavior so old indexes don't change tier meanings.
const KW_WEIGHT_NEUTRAL: usize = 1;

// Audience downweight: when a section carries an audience tag (e.g. "director")
// and the prompt doesn't mention that audience, its score is multiplied by
// AUDIENCE_KEEP/100. Soft filter — high enough to preserve genuinely-strong
// matches, low enough to push category-mismatched suggestions out of top-3.
//
// PROVISIONAL — this whole audience system (the `**Audience:**` CLAUDE.md
// convention, the SectionEntry field, the downweight math) is on probation.
// It introduces a second metadata concept on top of `**Keywords:**`. If telemetry
// shows IDF + curated keywords would have done the job, rip out audience and
// simplify back to a single metadata axis. See README §Scoring.
const AUDIENCE_KEEP: usize = 30;

// Opt-in markers that let a skill prompt declare which slice of itself carries
// the user-intent signal. When both delimiters are present and well-formed, only
// the enclosed text is scored; falls through to the full prompt otherwise.
const CONTEXT_OPEN: &str = "<learnings-context>";
const CONTEXT_CLOSE: &str = "</learnings-context>";

// ---------- Unified hit shape ----------

#[derive(Clone)]
struct Hit {
    provider: String,
    rel: String,                       // e.g. "learnings/python-specific.md"
    section: Option<SectionRef>,       // None = file-level
    score: usize,
    terms: Vec<String>,
    audience: Option<String>,          // Set only for section hits with cluster audience tag.
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
    // Per-keyword IDF-derived weight. Empty when sections.json was built by an
    // index-build version without IDF support — match_sections then falls back
    // to KW_WEIGHT_NEUTRAL so the score math stays continuous.
    kw_weights: HashMap<String, usize>,
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
    audience: Option<String>,
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
    // Optional: per-keyword IDF weights. Missing on indexes built before IDF support.
    let kw_weights: HashMap<String, usize> = v
        .get("kw_weights")
        .and_then(Value::as_object)
        .map(|obj| {
            obj.iter()
                .filter_map(|(k, val)| val.as_u64().map(|n| (k.clone(), n as usize)))
                .collect()
        })
        .unwrap_or_default();

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
            audience: s.get("audience").and_then(Value::as_str).map(|x| x.to_string()),
        });
    }
    Some(SectionsIndex { by_keyword, kw_weights, sections, mtime })
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

/// Extract the user-intent scoring slice. Skill prompts can wrap their
/// signal-bearing portion in `<learnings-context>...</learnings-context>` to opt
/// out of having the procedural template body weighted against them. When the
/// markers are absent or malformed, the whole prompt is used (status quo).
fn extract_scoring_text(prompt: &str) -> &str {
    if let Some(open_idx) = prompt.find(CONTEXT_OPEN) {
        let body_start = open_idx + CONTEXT_OPEN.len();
        if let Some(rel_close) = prompt[body_start..].find(CONTEXT_CLOSE) {
            return &prompt[body_start..body_start + rel_close];
        }
    }
    prompt
}

// Only matches ASCII "..". macOS smart-quote autocorrect (U+201C/U+201D) is not captured —
// the bypass would silently miss those quoted terms.
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

/// Render a per-provider hit path: tilde-collapses under `$HOME`, otherwise
/// absolute. Provider-agnostic — works for any provider location, not just
/// `~/.claude/learnings/`.
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
    let dir = artifacts_dir();
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
            if let Some(aud) = &hit.audience {
                o["audience"] = json!(aud);
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
    // Single-syscall write so concurrent workers can't interleave fragments — see
    // read-log.rs for the rationale. suggest.jsonl is lower-volume than reads.jsonl
    // (one record per UserPromptSubmit vs. one per Read), but the race is identical.
    if let Ok(line) = serde_json::to_vec(&event) {
        if let Ok(mut f) = OpenOptions::new().create(true).append(true).open(&path) {
            let mut buf = line;
            buf.push(b'\n');
            let _ = f.write_all(&buf);
        }
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

type SectionHits = HashMap<(String, usize), (usize, Vec<String>)>;
type FileHits = HashMap<(String, String), (usize, Vec<String>, PathBuf)>;

fn match_sections(prompt: &str, idx: &SectionsIndex) -> SectionHits {
    let keys: Vec<String> = idx.by_keyword.keys().cloned().collect();
    let mut out: SectionHits = HashMap::new();
    let ac = match build_matcher(&keys.iter().map(String::as_str).collect::<Vec<_>>()) {
        Some(ac) => ac,
        None => return out,
    };
    for m in ac.find_iter(prompt) {
        let kw = &keys[m.pattern()];
        // IDF-weighted contribution. Multi-word phrases still get their length
        // bonus on top of IDF — a 2-word rare phrase outweighs two separate rare
        // 1-word hits because the phrase is a tighter contextual signal.
        let idf_weight = idx
            .kw_weights
            .get(kw)
            .copied()
            .unwrap_or(KW_WEIGHT_NEUTRAL);
        let weight = kw.split_whitespace().count().max(1) * idf_weight;
        let sec_ids = match idx.by_keyword.get(kw) {
            Some(ids) => ids,
            None => continue,
        };
        for &sid in sec_ids {
            let sec = match idx.sections.get(sid) {
                Some(s) => s,
                None => continue,
            };
            if !passes_filter(&sec.rel) {
                continue;
            }
            let entry = out.entry((sec.provider.clone(), sid)).or_insert((0, vec![]));
            entry.0 += weight;
            if !entry.1.iter().any(|t| t == kw) {
                entry.1.push(kw.clone());
            }
        }
    }
    out
}

fn match_files(prompt: &str, file_idx: &FileIndexEntries) -> FileHits {
    let keys: Vec<&str> = file_idx.iter().map(|(k, _)| k.as_str()).collect();
    let mut out: FileHits = HashMap::new();
    let ac = match build_matcher(&keys) {
        Some(ac) => ac,
        None => return out,
    };
    for m in ac.find_iter(prompt) {
        let (kw, paths) = &file_idx[m.pattern()];
        let weight = kw.split_whitespace().count().max(1);
        for (root, rel) in paths {
            if !passes_filter(rel) {
                continue;
            }
            // provider-name proxy: file index entries don't carry provider names directly.
            let pname = root
                .file_name()
                .and_then(|s| s.to_str())
                .unwrap_or("")
                .to_string();
            let entry = out
                .entry((pname, rel.clone()))
                .or_insert((0, vec![], root.clone()));
            entry.0 += weight;
            if !entry.1.iter().any(|t| t == kw) {
                entry.1.push(kw.clone());
            }
        }
    }
    out
}

/// Combine section hits (preferred) with file hits (fallback), applying the
/// section-index staleness downgrade and de-duping by (provider, rel). Audience
/// downweight is applied here too: if a section carries an audience tag (set in
/// the cluster's CLAUDE.md) and the scoring text doesn't mention the audience,
/// the score is reduced to AUDIENCE_KEEP%. Soft filter — strong matches still
/// surface, marginal ones get pushed out of the top-3 cap.
fn merge_and_dedup(
    section_hits: SectionHits,
    file_hits: FileHits,
    sections: Option<&SectionsIndex>,
    provs: &[Provider],
    scoring_text_lower: &str,
) -> Vec<(Hit, PathBuf)> {
    let mut hits: Vec<(Hit, PathBuf)> = Vec::new();
    let mut covered: HashSet<(String, String)> = HashSet::new();
    if let Some(idx) = sections {
        for ((provider, sid), (raw_score, terms)) in section_hits {
            let sec = match idx.sections.get(sid) {
                Some(s) => s,
                None => continue,
            };
            let prov_root = match provs.iter().find(|p| p.name == provider) {
                Some(p) => p.root.clone(),
                None => continue,
            };
            // Staleness: if the source file is newer than sections.json, drop :start-end.
            let full = prov_root.join(&sec.rel);
            let section_ref = match fs::metadata(&full).and_then(|m| m.modified()).ok() {
                Some(mt) if mt > idx.mtime => None,
                _ => Some(SectionRef {
                    anchor: sec.anchor.clone(),
                    header: sec.header.clone(),
                    lines: sec.lines,
                }),
            };
            // Audience downweight: tag present + audience name absent from
            // prompt → keep AUDIENCE_KEEP% of the score. Audience name present →
            // no penalty; the section's domain matches what the prompt is about.
            let score = match &sec.audience {
                Some(aud) if !scoring_text_lower.contains(aud.as_str()) => {
                    (raw_score * AUDIENCE_KEEP) / 100
                }
                _ => raw_score,
            };
            hits.push((
                Hit {
                    provider: provider.clone(),
                    rel: sec.rel.clone(),
                    section: section_ref,
                    score,
                    terms,
                    audience: sec.audience.clone(),
                },
                prov_root,
            ));
            covered.insert((provider, sec.rel.clone()));
        }
    }
    for ((pname, rel), (score, terms, root)) in file_hits {
        // Reverse-lookup the provider by root path. If two providers ever
        // shared a parent dir this would collide — falls back to basename.
        // Not expected in practice.
        let provider_name = provs
            .iter()
            .find(|p| p.root == root)
            .map(|p| p.name.clone())
            .unwrap_or_else(|| pname.clone());
        if covered.contains(&(provider_name.clone(), rel.clone())) {
            continue;
        }
        hits.push((
            Hit {
                provider: provider_name,
                rel,
                section: None,
                score,
                terms,
                audience: None,
            },
            root,
        ));
    }
    hits
}

fn compute_forced(
    prompt: &str,
    sections: Option<&SectionsIndex>,
    file_idx: &FileIndexEntries,
    provs: &[Provider],
) -> HashSet<(String, String)> {
    let quoted = extract_quoted(prompt);
    if quoted.is_empty() {
        return HashSet::new();
    }
    let mut out: HashSet<(String, String)> = HashSet::new();
    if let Some(idx) = sections {
        for (kw, sec_ids) in &idx.by_keyword {
            if !quoted.contains(kw) {
                continue;
            }
            for &sid in sec_ids {
                if let Some(sec) = idx.sections.get(sid) {
                    if passes_filter(&sec.rel) {
                        out.insert((sec.provider.clone(), sec.rel.clone()));
                    }
                }
            }
        }
    }
    for (kw, paths) in file_idx {
        if !quoted.contains(kw) {
            continue;
        }
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
    out
}

fn format_block(hits: &[(Hit, PathBuf)]) -> String {
    let mut lines = vec!["<learnings-suggestions>".to_string()];
    for (hit, root) in hits {
        let tier = if hit.score >= STRONG_SCORE { "strong" } else { "weak" };
        let term_str = hit.terms.iter().take(3).cloned().collect::<Vec<_>>().join(", ");
        let (path_str, desc) = match &hit.section {
            Some(sec) => (
                format!("{}:{}-{}", display_path(root, &hit.rel), sec.lines.0, sec.lines.1),
                sec.header.clone(),
            ),
            None => {
                let full = root.join(&hit.rel);
                (display_path(root, &hit.rel), truncate_chars(&first_line(&full), 80))
            }
        };
        lines.push(format!("  [{}] {} — {} | {}", tier, path_str, term_str, desc));
    }
    lines.push("</learnings-suggestions>".to_string());
    lines.join("\n")
}

fn run() -> Option<()> {
    let payload = read_payload()?;
    let prompt = payload.get("prompt").and_then(Value::as_str).unwrap_or("");
    let session = payload.get("session_id").and_then(Value::as_str);

    if prompt.len() < TRIVIAL_LEN || !prompt.chars().any(|c| c.is_ascii_alphabetic()) {
        return None;
    }
    let provs = providers(true);
    if provs.is_empty() {
        return None;
    }

    // Scoring slice: user-intent only when the prompt opted in via the
    // <learnings-context> markers; otherwise the full prompt. Quoted-term
    // forcing still consults the *full* prompt — operators expect "foo" to bind
    // regardless of where it appears.
    let scoring_text = extract_scoring_text(prompt);
    let scoring_text_lower = scoring_text.to_lowercase();

    let sections = load_sections_index();
    let section_hits = match sections.as_ref() {
        Some(idx) => match_sections(scoring_text, idx),
        None => HashMap::new(),
    };

    let file_idx = load_file_index(&provs);
    let file_hits = match_files(scoring_text, &file_idx);

    let mut hits = merge_and_dedup(
        section_hits,
        file_hits,
        sections.as_ref(),
        &provs,
        &scoring_text_lower,
    );
    let forced = compute_forced(prompt, sections.as_ref(), &file_idx, &provs);

    hits.retain(|(h, _)| {
        h.score >= MIN_SCORE || forced.contains(&(h.provider.clone(), h.rel.clone()))
    });
    hits.sort_by(|(a, _), (b, _)| b.score.cmp(&a.score).then_with(|| a.rel.cmp(&b.rel)));
    hits.truncate(MAX_HITS);

    log_event(prompt, session, &hits);
    if hits.is_empty() {
        return None;
    }

    let out = json!({
        "hookSpecificOutput": {
            "hookEventName": "UserPromptSubmit",
            "additionalContext": format_block(&hits),
        }
    });
    println!("{}", out);
    Some(())
}

fn main() {
    let _ = run();
}
