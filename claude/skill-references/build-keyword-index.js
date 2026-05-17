#!/usr/bin/env node
// Rebuild claude/learnings/.keyword-index.json via mechanical extraction.

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const SCRIPT_DIR = path.dirname(fs.realpathSync(__filename));
const REPO_ROOT = path.resolve(SCRIPT_DIR, '..', '..');
const CLAUDE_DIR = path.join(REPO_ROOT, 'claude');
const ROOTS = ['learnings', 'guidelines', 'commands', 'skill-references'];
const EXCLUDE_DIR_PREFIXES = [
  'worktrees/',
  'consolidate-output/',
  'ralph/',
  'personal-memory/',
  'plans/',
  'agents/',
  '.git/',
];

// Boilerplate / structural headings to skip (lowercased, normalized).
const SKIP_HEADINGS = new Set([
  'cross-refs',
  'recommended actions',
  'apply actions',
  'calibration',
  'sizes',
  'proactive cross-refs',
  'sub-clusters',
  'context',
  'usage',
  'overview',
  'instructions',
  'output format',
  'format',
  'key findings',
  'prerequisites',
  'important notes',
  'reference files',
  'what to search for',
  'what to extract',
  'scan limitations',
  'project context',
  'your job',
  'your mindset',
  'severity calibration',
  'review methodology',
  'what you look for',
]);

// --- file enumeration --------------------------------------------------------

function walk(dir, out) {
  const entries = fs.readdirSync(dir, { withFileTypes: true });
  for (const e of entries) {
    const full = path.join(dir, e.name);
    const rel = path.relative(CLAUDE_DIR, full);
    if (EXCLUDE_DIR_PREFIXES.some(p => rel.startsWith(p))) continue;
    if (e.isDirectory()) {
      walk(full, out);
    } else if (e.isFile() && full.endsWith('.md')) {
      const base = path.basename(full);
      if (base === 'CLAUDE.md' || base === 'INDEX.md') continue;
      out.push(rel);
    }
  }
}

const allFiles = [];
for (const r of ROOTS) {
  const root = path.join(CLAUDE_DIR, r);
  if (fs.existsSync(root)) walk(root, allFiles);
}
allFiles.sort();

// --- extraction --------------------------------------------------------------

function normalizeTerm(s) {
  let t = s.toLowerCase();
  // Strip backticks
  t = t.replace(/`/g, '');
  // Strip leading/trailing punctuation/whitespace, keep internal hyphens/dots/slashes
  t = t.replace(/^[\s\-—:.,;!?"'()*]+/, '').replace(/[\s\-—:.,;!?"'()*]+$/, '');
  // Collapse whitespace
  t = t.replace(/\s+/g, ' ').trim();
  return t;
}

function extractKeywordsFromLine(line) {
  // Match: ^- **Keywords:** ... OR ^**Keywords:** ...
  const m = line.match(/^(?:-\s*)?\*\*Keywords:\*\*\s*(.+)$/);
  if (!m) return null;
  const rest = m[1];
  const parts = rest.split(',').map(s => normalizeTerm(s)).filter(Boolean);
  return parts;
}

function extractHeadingTerm(line) {
  const m = line.match(/^#{2,3}\s+(.+?)\s*$/);
  if (!m) return null;
  const raw = m[1];
  const stripped = raw.replace(/\s*#+\s*$/, '');
  const term = normalizeTerm(stripped);
  if (!term) return null;
  if (SKIP_HEADINGS.has(term)) return null;
  // Skip templatic markers
  if (term.startsWith('<iso')) return null;
  if (term.startsWith('extends:')) return null;
  return term;
}

function extractTermsForFile(absPath) {
  const content = fs.readFileSync(absPath, 'utf8');
  const lines = content.split('\n');
  const terms = new Set();
  for (const ln of lines) {
    const kws = extractKeywordsFromLine(ln);
    if (kws) {
      kws.forEach(k => terms.add(k));
      continue;
    }
    const h = extractHeadingTerm(ln);
    if (h) terms.add(h);
  }
  return terms;
}

// --- build index -------------------------------------------------------------

const termToFiles = new Map();
const fileSources = {};
const filesWithNoTerms = [];

for (const rel of allFiles) {
  const abs = path.join(CLAUDE_DIR, rel);
  const terms = extractTermsForFile(abs);
  fileSources[rel] = 'mechanical';
  if (terms.size === 0) {
    filesWithNoTerms.push(rel);
    continue;
  }
  for (const t of terms) {
    if (!termToFiles.has(t)) termToFiles.set(t, new Set());
    termToFiles.get(t).add(rel);
  }
}

const sortedTerms = [...termToFiles.keys()].sort();

const headSha = execSync('git rev-parse --short HEAD', { cwd: REPO_ROOT }).toString().trim();
const rebuiltAt = new Date().toISOString().slice(0, 10);

const out = {
  _meta: {
    last_rebuild_commit: headSha,
    rebuilt_at: rebuiltAt,
    file_sources: fileSources,
    stats: {
      files: allFiles.length,
      terms: sortedTerms.length,
    },
  },
};
for (const t of sortedTerms) {
  out[t] = [...termToFiles.get(t)].sort();
}

const outputPath = path.join(REPO_ROOT, 'tmp', 'claude-artifacts', 'keyword-index', 'keyword-index.json');
fs.writeFileSync(outputPath, JSON.stringify(out, null, 2));

// --- validation --------------------------------------------------------------

const broken = [];
for (const t of sortedTerms) {
  for (const p of out[t]) {
    if (!fs.existsSync(path.join(CLAUDE_DIR, p))) broken.push({ term: t, path: p });
  }
}

const fileRefCount = new Map();
for (const t of sortedTerms) {
  for (const p of out[t]) {
    fileRefCount.set(p, (fileRefCount.get(p) || 0) + 1);
  }
}
const top10 = [...fileRefCount.entries()].sort((a, b) => b[1] - a[1]).slice(0, 10);

const report = {
  output: outputPath,
  files_indexed: allFiles.length,
  total_terms: sortedTerms.length,
  zero_term_files: filesWithNoTerms,
  broken_paths: broken,
  top10,
  head: headSha,
};
console.log(JSON.stringify(report, null, 2));
