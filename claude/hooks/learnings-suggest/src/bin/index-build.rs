// Walks the federated learnings corpus, parses each .md with pulldown-cmark,
// and emits ~/.claude/claude-artifacts/ast/sections.json — an inverted index
// keyed by keyword → section ids, plus a section table with line ranges.
//
// Run from /learnings:curate or manually after content edits.

use learnings_suggest::{artifacts_dir, providers, Provider, SCHEMA_VERSION};
use pulldown_cmark::{Event, HeadingLevel, Parser, Tag, TagEnd};
use serde_json::{json, Value};
use std::collections::{BTreeMap, HashMap, HashSet};
use std::fs;
use std::path::{Path, PathBuf};
use std::time::{SystemTime, UNIX_EPOCH};

const MIN_SECTION_LINES: usize = 8;
const MAX_KEYWORDS_PER_SECTION: usize = 12;

// IDF integer-scale: at match time, keyword score = word_count * kw_weight.
// kw_weight = round(ln((N+1)/(df+1)) * IDF_SCALE), clamped to [IDF_FLOOR, IDF_CEIL].
// Common terms (df near N) → ~IDF_FLOOR; rare terms → ~IDF_CEIL. Scale chosen
// empirically for ~700-section corpora: bigger numbers compress most terms at
// the ceiling, smaller numbers compress everything near 1. 1.5 spreads typical
// harness keywords (df ~20-50) into the 4-5 range while keeping rare terms at 8.
const IDF_FLOOR: usize = 1;
const IDF_CEIL: usize = 8;
const IDF_SCALE: f64 = 1.5;

// Markers for cluster-level audience tagging. A CLAUDE.md anywhere in the
// learnings tree may declare `**Audience:** <name>` (or legacy `Audience:`);
// all sections under that file's directory inherit the tag. At match time,
// sections with an audience tag are downweighted when the prompt doesn't
// mention the audience name — a soft filter, not a hard exclusion.
const AUDIENCE_MARKER: &str = "**Audience:**";
const AUDIENCE_MARKER_LEGACY: &str = "Audience:";
const AUDIENCE_HEADER_SEARCH_LIMIT: usize = 30;

// Repo-wide convention: line 2 of every learnings file is
// `- **Keywords:** kw1, kw2, ...`. `Keywords:` (no asterisks) is a legacy
// form retained for files that predate the bolded marker.
const KEYWORDS_MARKER: &str = "**Keywords:**";
const KEYWORDS_MARKER_LEGACY: &str = "Keywords:";

// Upper bound for how many leading lines to scan for the keywords marker.
// Not the header size — a search budget so we stop before walking the body
// if a file's header is malformed.
const KEYWORDS_HEADER_SEARCH_LIMIT: usize = 5;

const STOPWORDS: &[&str] = &[
    "a", "an", "the", "is", "are", "was", "were", "be", "been", "being",
    "to", "of", "in", "on", "at", "by", "for", "with", "from", "as", "into",
    "and", "or", "but", "if", "not", "no", "yes", "than", "then", "so",
    "this", "that", "these", "those", "it", "its", "they", "them", "their",
    "we", "you", "your", "our", "us", "i", "me", "my",
    "do", "does", "did", "doing", "done",
    "have", "has", "had", "having",
    "can", "could", "should", "would", "will", "may", "might", "must",
    "what", "when", "where", "why", "how", "which", "who",
    "one", "two", "three", "each", "every", "all", "some", "any", "none",
    "more", "most", "less", "very", "much", "many", "just", "only",
    "also", "still", "always", "never", "often", "usually",
    "use", "used", "using", "uses", "make", "makes", "made", "making",
    "see", "now", "get", "got", "set", "run", "ran", "via", "such",
    "e.g", "i.e",
];

fn walk_md(dir: &Path, out: &mut Vec<PathBuf>) {
    let entries = match fs::read_dir(dir) {
        Ok(e) => e,
        Err(_) => return,
    };
    for entry in entries.flatten() {
        let path = entry.path();
        let name = entry.file_name();
        let s = name.to_string_lossy();
        // Skip dotfiles (incl. .keyword-index.json) and underscore-prefixed (staging)
        if s.starts_with('.') || s.starts_with('_') {
            continue;
        }
        if path.is_dir() {
            walk_md(&path, out);
        } else if path.extension().and_then(|s| s.to_str()) == Some("md") {
            out.push(path);
        }
    }
}

fn line_starts(text: &str) -> Vec<usize> {
    let mut starts = vec![0usize];
    for (i, b) in text.bytes().enumerate() {
        if b == b'\n' {
            starts.push(i + 1);
        }
    }
    starts
}

fn line_for_byte(starts: &[usize], byte: usize) -> usize {
    // 1-indexed line numbers (matches Read's offset convention)
    match starts.binary_search(&byte) {
        Ok(i) => i + 1,
        Err(i) => i,
    }
}

fn slugify(s: &str) -> String {
    let mut out = String::with_capacity(s.len());
    let mut last_dash = true;
    for c in s.chars() {
        let lower = c.to_ascii_lowercase();
        if lower.is_ascii_alphanumeric() {
            out.push(lower);
            last_dash = false;
        } else if !last_dash {
            out.push('-');
            last_dash = true;
        }
    }
    out.trim_matches('-').to_string()
}

fn extract_keywords(body: &str) -> Vec<String> {
    let stop: HashSet<&str> = STOPWORDS.iter().copied().collect();
    let mut counts: HashMap<String, usize> = HashMap::new();
    for raw in body.split(|c: char| !c.is_ascii_alphanumeric() && c != '_' && c != '-') {
        if raw.len() < 3 || raw.len() > 40 {
            continue;
        }
        let w = raw.to_ascii_lowercase();
        if stop.contains(w.as_str()) {
            continue;
        }
        // Pure-numeric tokens add nothing
        if w.chars().all(|c| c.is_ascii_digit()) {
            continue;
        }
        *counts.entry(w).or_insert(0) += 1;
    }
    let mut pairs: Vec<(String, usize)> = counts.into_iter().collect();
    pairs.sort_by(|a, b| b.1.cmp(&a.1).then_with(|| a.0.cmp(&b.0)));
    pairs.into_iter()
        .take(MAX_KEYWORDS_PER_SECTION)
        .map(|(w, _)| w)
        .collect()
}

#[derive(Clone)]
struct Section {
    provider: String,
    rel: String,
    anchor: String,
    header: String,
    lines: (usize, usize),
    level: u8,
    keywords: Vec<String>,
    audience: Option<String>,
}

fn extract_audience(file_text: &str) -> Option<String> {
    file_text
        .lines()
        .take(AUDIENCE_HEADER_SEARCH_LIMIT)
        .find_map(|line| {
            let l = line.trim_start_matches(|c: char| c == '-' || c == '*' || c.is_whitespace());
            l.strip_prefix(AUDIENCE_MARKER)
                .or_else(|| l.strip_prefix(AUDIENCE_MARKER_LEGACY))
        })
        .map(|s| s.trim().to_ascii_lowercase())
        .filter(|s| !s.is_empty() && s.len() < 40)
}

fn walk_for_filename(dir: &Path, target: &str, out: &mut Vec<PathBuf>) {
    let entries = match fs::read_dir(dir) {
        Ok(e) => e,
        Err(_) => return,
    };
    for entry in entries.flatten() {
        let path = entry.path();
        let name = entry.file_name();
        let s = name.to_string_lossy();
        if s.starts_with('.') || s.starts_with('_') {
            continue;
        }
        if path.is_dir() {
            walk_for_filename(&path, target, out);
        } else if s == target {
            out.push(path);
        }
    }
}

/// Build the audience-by-directory-prefix map by scanning every CLAUDE.md under
/// each provider's tree for an `**Audience:**` marker. Returned vector is sorted
/// longest-prefix-first so the deepest matching ancestor wins.
fn build_audience_map(provs: &[Provider]) -> Vec<(String, String, String)> {
    // (provider_name, rel_dir_prefix, audience_name)
    let mut out: Vec<(String, String, String)> = Vec::new();
    for prov in provs {
        let mut claude_mds = Vec::new();
        walk_for_filename(&prov.base, "CLAUDE.md", &mut claude_mds);
        for cmd in claude_mds {
            let text = match fs::read_to_string(&cmd) {
                Ok(t) => t,
                Err(_) => continue,
            };
            let aud = match extract_audience(&text) {
                Some(a) => a,
                None => continue,
            };
            let rel_dir = match cmd.parent().and_then(|p| p.strip_prefix(&prov.root).ok()) {
                Some(p) => p.to_string_lossy().to_string(),
                None => continue,
            };
            out.push((prov.name.clone(), rel_dir, aud));
        }
    }
    // Longest prefix wins (so /director/CLAUDE.md beats /multi-agent/CLAUDE.md
    // for a section under multi-agent/director/).
    out.sort_by(|a, b| b.1.len().cmp(&a.1.len()));
    out
}

fn lookup_audience(
    audiences: &[(String, String, String)],
    provider: &str,
    rel: &str,
) -> Option<String> {
    audiences
        .iter()
        .find(|(p, prefix, _)| p == provider && rel.starts_with(prefix.as_str()))
        .map(|(_, _, aud)| aud.clone())
}

fn extract_explicit_keywords(file_text: &str) -> Vec<String> {
    file_text
        .lines()
        .take(KEYWORDS_HEADER_SEARCH_LIMIT)
        .find_map(|line| {
            let l = line.trim_start_matches(|c: char| c == '-' || c.is_whitespace());
            l.strip_prefix(KEYWORDS_MARKER)
                .or_else(|| l.strip_prefix(KEYWORDS_MARKER_LEGACY))
        })
        .map(|kws| {
            kws.split(',')
                .map(|s| s.trim().to_ascii_lowercase())
                .filter(|s| !s.is_empty())
                .collect()
        })
        .unwrap_or_default()
}

fn parse_file(provider: &str, rel: String, file_text: &str) -> Vec<Section> {
    let starts = line_starts(file_text);
    let total_lines = starts.len();
    let explicit = extract_explicit_keywords(file_text);

    let parser = Parser::new(file_text).into_offset_iter();

    // Section accumulation state
    let mut sections = Vec::new();
    let mut current_header_text = String::new();
    let mut capturing_header = false;
    let mut pending: Option<(u8, usize, String)> = None;  // (level, start_byte, header_text)
    // Per-section anchor counters to disambiguate duplicates within a file
    let mut anchor_seen: HashMap<String, usize> = HashMap::new();
    // Body text accumulator for the current section
    let mut body_buf = String::new();

    let push_section =
        |sections: &mut Vec<Section>,
         anchor_seen: &mut HashMap<String, usize>,
         level: u8,
         start_byte: usize,
         end_byte: usize,
         header: String,
         body: &str| {
            let start_line = line_for_byte(&starts, start_byte);
            let end_line = line_for_byte(&starts, end_byte.saturating_sub(1)).max(start_line);
            if end_line.saturating_sub(start_line) + 1 < MIN_SECTION_LINES {
                return;
            }
            let base_anchor = slugify(&header);
            if base_anchor.is_empty() {
                return;
            }
            let n = anchor_seen.entry(base_anchor.clone()).or_insert(0);
            *n += 1;
            let anchor = if *n == 1 {
                base_anchor
            } else {
                format!("{}-{}", base_anchor, n)
            };
            let mut keywords = extract_keywords(body);
            // Mix in explicit file-level keywords as supplementary hits (cap respected)
            for k in &explicit {
                if !keywords.iter().any(|w| w == k) && keywords.len() < MAX_KEYWORDS_PER_SECTION {
                    keywords.push(k.clone());
                }
            }
            sections.push(Section {
                provider: provider.to_string(),
                rel: rel.clone(),
                anchor,
                header,
                lines: (start_line, end_line),
                level,
                keywords,
                audience: None,
            });
        };

    for (event, range) in parser {
        match event {
            Event::Start(Tag::Heading { level, .. }) => {
                let lvl = match level {
                    HeadingLevel::H2 => 2,
                    HeadingLevel::H3 => 3,
                    _ => 0,
                };
                if lvl != 0 {
                    // Close the previous section, if any.
                    if let Some((p_lvl, p_start, p_header)) = pending.take() {
                        push_section(
                            &mut sections,
                            &mut anchor_seen,
                            p_lvl,
                            p_start,
                            range.start,
                            p_header,
                            &body_buf,
                        );
                    }
                    body_buf.clear();
                    current_header_text.clear();
                    capturing_header = true;
                    pending = Some((lvl as u8, range.start, String::new()));
                }
            }
            Event::End(TagEnd::Heading(level)) => {
                let lvl = match level {
                    HeadingLevel::H2 => 2,
                    HeadingLevel::H3 => 3,
                    _ => 0,
                };
                if lvl != 0 && capturing_header {
                    capturing_header = false;
                    if let Some((ref _l, ref _s, ref mut h)) = pending {
                        *h = current_header_text.trim().to_string();
                    }
                }
            }
            Event::Text(t) | Event::Code(t) => {
                if capturing_header {
                    current_header_text.push_str(&t);
                } else if pending.is_some() {
                    body_buf.push_str(&t);
                    body_buf.push(' ');
                }
            }
            _ => {}
        }
    }
    // Close the trailing section.
    if let Some((lvl, start, header)) = pending {
        let total_bytes = file_text.len();
        push_section(
            &mut sections,
            &mut anchor_seen,
            lvl,
            start,
            total_bytes,
            header,
            &body_buf,
        );
        let _ = total_lines;
    }
    sections
}

fn anchor_commit(provs: &[Provider]) -> Option<String> {
    // Best-effort: use HEAD of the repo containing the personal learnings dir.
    let p = provs.iter().find(|p| p.name == "personal")?;
    let real = fs::canonicalize(&p.base).ok()?;
    // Walk up to find .git
    let mut dir = real.as_path();
    while let Some(parent) = dir.parent() {
        if parent.join(".git").exists() {
            let out = std::process::Command::new("git")
                .args(["-C", parent.to_str()?, "rev-parse", "--short", "HEAD"])
                .output()
                .ok()?;
            if out.status.success() {
                return Some(String::from_utf8_lossy(&out.stdout).trim().to_string());
            }
        }
        dir = parent;
    }
    None
}

fn main() {
    // projectLocal is omitted: it's CWD-dependent and only meaningful at hook runtime.
    let provs = providers(false);
    if provs.is_empty() {
        eprintln!("learnings-index-build: no providers found at ~/.claude/learnings-providers.json");
        std::process::exit(1);
    }

    let audience_map = build_audience_map(&provs);

    let mut all_sections: Vec<Section> = Vec::new();
    let mut file_count = 0usize;

    for prov in &provs {
        let mut md_files = Vec::new();
        walk_md(&prov.base, &mut md_files);
        for path in md_files {
            file_count += 1;
            let rel_path = match path.strip_prefix(&prov.root) {
                Ok(p) => p.to_string_lossy().to_string(),
                Err(_) => continue,
            };
            let text = match fs::read_to_string(&path) {
                Ok(t) => t,
                Err(_) => continue,
            };
            let mut sections = parse_file(&prov.name, rel_path.clone(), &text);
            // Inherit audience from any ancestor CLAUDE.md.
            if let Some(aud) = lookup_audience(&audience_map, &prov.name, &rel_path) {
                for s in &mut sections {
                    s.audience = Some(aud.clone());
                }
            }
            all_sections.extend(sections);
        }
    }

    // Inverted index: keyword → list of section indices into `sections[]`
    let mut by_keyword: BTreeMap<String, Vec<usize>> = BTreeMap::new();
    for (i, sec) in all_sections.iter().enumerate() {
        for kw in &sec.keywords {
            by_keyword.entry(kw.clone()).or_default().push(i);
        }
    }

    // IDF-derived integer weight per keyword. df = number of sections containing
    // the keyword; n = total sections. Common keywords (high df) end up at
    // IDF_FLOOR; rare ones at IDF_CEIL. Clamping the ceiling stops a single
    // very-rare term from outscoring an aggregate of moderately-rare terms.
    let n = all_sections.len() as f64;
    let kw_weights: BTreeMap<String, usize> = by_keyword
        .iter()
        .map(|(kw, sec_ids)| {
            let df = sec_ids.len() as f64;
            let idf = ((n + 1.0) / (df + 1.0)).ln();
            let scaled = (idf * IDF_SCALE).round() as i64;
            let w = scaled.clamp(IDF_FLOOR as i64, IDF_CEIL as i64) as usize;
            (kw.clone(), w)
        })
        .collect();

    let sections_json: Vec<Value> = all_sections
        .iter()
        .map(|s| {
            let mut o = json!({
                "provider": s.provider,
                "rel": s.rel,
                "anchor": s.anchor,
                "header": s.header,
                "lines": [s.lines.0, s.lines.1],
                "level": s.level,
                "keywords": s.keywords,
            });
            if let Some(aud) = &s.audience {
                o["audience"] = json!(aud);
            }
            o
        })
        .collect();

    let by_keyword_json: BTreeMap<String, Vec<usize>> = by_keyword;

    let ts = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_secs())
        .unwrap_or(0);

    let audience_summary: BTreeMap<String, usize> = {
        let mut counts: BTreeMap<String, usize> = BTreeMap::new();
        for s in &all_sections {
            if let Some(a) = &s.audience {
                *counts.entry(a.clone()).or_insert(0) += 1;
            }
        }
        counts
    };

    let out = json!({
        "_meta": {
            "schema": SCHEMA_VERSION,
            "built_at": ts,
            "anchor_commit": anchor_commit(&provs),
            "source_files": file_count,
            "total_sections": all_sections.len(),
            "min_section_lines": MIN_SECTION_LINES,
            "audience_counts": audience_summary,
        },
        "by_keyword": by_keyword_json,
        "kw_weights": kw_weights,
        "sections": sections_json,
    });

    let dir = artifacts_dir();
    if let Err(e) = fs::create_dir_all(&dir) {
        eprintln!("learnings-index-build: cannot create {}: {}", dir.display(), e);
        std::process::exit(1);
    }
    let out_path = dir.join("sections.json");
    // Atomic write: tmp + rename
    let tmp_path = dir.join("sections.json.tmp");
    if let Err(e) = fs::write(&tmp_path, serde_json::to_string(&out).unwrap()) {
        eprintln!("learnings-index-build: cannot write {}: {}", tmp_path.display(), e);
        std::process::exit(1);
    }
    if let Err(e) = fs::rename(&tmp_path, &out_path) {
        eprintln!("learnings-index-build: cannot rename to {}: {}", out_path.display(), e);
        std::process::exit(1);
    }

    eprintln!(
        "learnings-index-build: {} sections from {} files → {}",
        all_sections.len(),
        file_count,
        out_path.display()
    );
}
