// PostToolUse(Read) hook: appends one JSONL event per learnings/guidelines/skill-references Read.
// Cross-referenced offline against suggest.jsonl by analyze.py to compute hit rates.
// Silent on any failure — never blocks a tool call.

use serde_json::{json, Value};
use std::fs::{self, OpenOptions};
use std::io::{self, Read, Write};
use std::path::PathBuf;
use std::time::{SystemTime, UNIX_EPOCH};

fn home() -> PathBuf {
    PathBuf::from(std::env::var("HOME").unwrap_or_default())
}

fn run() -> Option<()> {
    let mut s = String::new();
    io::stdin().read_to_string(&mut s).ok()?;
    let v: Value = serde_json::from_str(&s).ok()?;

    if v.get("tool_name").and_then(Value::as_str)? != "Read" {
        return None;
    }
    let input = v.get("tool_input")?;
    let path = input.get("file_path").and_then(Value::as_str)?;

    // Only log Reads of files that could plausibly be a learnings suggestion.
    let relevant = ["/learnings/", "/guidelines/", "/skill-references/", "/commands/"]
        .iter()
        .any(|m| path.contains(m));
    if !relevant {
        return None;
    }

    let dir = home().join(".claude").join("claude-artifacts").join("ast");
    fs::create_dir_all(&dir).ok()?;
    let log = dir.join("reads.jsonl");

    let ts = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_secs())
        .unwrap_or(0);

    let event = json!({
        "ts": ts,
        "session": v.get("session_id").and_then(Value::as_str),
        "path": path,
        "offset": input.get("offset").and_then(Value::as_u64),
        "limit": input.get("limit").and_then(Value::as_u64),
    });

    let mut f = OpenOptions::new()
        .create(true)
        .append(true)
        .open(&log)
        .ok()?;
    writeln!(f, "{}", event).ok()
}

fn main() {
    let _ = run();
}
