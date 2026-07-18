Multi-agent quality and validation — verification patterns, trust arc, agent-to-agent review, prompt design, and assumption checking.
- **Keywords:** trust arc, agent-to-agent review, verify assumptions, gate announcements, intent files, TaskOutput, subagent verification, front-load context, persona routing, architecture reviewer, defensive coding, adapter code, research PR review, cited-number provenance, findings doc, positive-signal vs finding, orthogonal-aspect merge, dissent over-trigger
- **Related:** none

---

## Diff-Only Line Numbers Drift in Subagents

Subagents that derive line numbers from diff text rather than reading the actual file produce 8-35 line drift on new files. The `@@ -X,Y +X,Y @@` hunk header is reliable for *where* changes start; relative counting from there is error-prone past ~30 lines. Before posting inline review comments, the team-lead must re-read each cited file and correct the line numbers — diff-driven inline comments will land at the wrong location otherwise (or anchor to nothing on stacked PRs, returning `line: null`).

**Two distinct magnitudes — pick the right fix.** (a) *Relative drift* (±8-35 lines): a ±5/±10 window scan for the `anchor_token` around the reported line recovers it. (b) *Artifact-offset* (line_start in the 100s-1000s, often **exceeding the file's length**): the subagent reported its position in the concatenated diff/tool-output file it `Read` — that `cat -n` numbering, not source lines — so the window scan can't recover it (the line doesn't exist). Detect by comparing `line_start` to `wc -l` at head SHA; re-anchor hard via `git show <head_sha>:<file>` + grep the `anchor_token`. Giving subagents the diff as a Read-able file path (cheaper than inlining 74KB ×N) makes (b) the *common* case, not the exception — re-anchoring every posted finding is non-optional regardless of any "use source lines, not artifact offsets" warning in the prompt.

## Persisted Diff Artifacts Can Corrupt Content, Not Just Line Numbers

Large `gh pr diff` outputs (>32KB) saved to tool-output files can have rendering artifacts that change *file content*, not just line offsets — e.g., an `aarch64-linux-gnu` mapping read back as `x86_64-linux-gnu` because adjacent identical lines collapsed visually. Before posting any finding that depends on a specific string comparison, verify against `git show <sha>:<path>` (or grep the worktree). Distinct from line-number drift: that one anchors at the wrong line; this one asserts a bug that isn't there.

## Don't Pre-Annotate Diffs When Delegating to a Subagent Reviewer

When constructing a subagent prompt that includes a diff, send the **clean diff** — don't inline notes like `<-- NOTE: this looks wrong`. The subagent treats the annotation as part of the artifact under review, verifies it against source, and (correctly) flags the annotation itself as inaccurate if the orchestrator's read was wrong. The orchestrator-injected hint also primes anchoring on a single hypothesis. Let the reviewer discover issues from a neutral diff; pass directives separately if you need to focus attention.

## Cross-Check Inline Classification Against Addresser Summary

When re-reviewing an Address pass, the addresser typically posts a top-level summary ("15 implemented, 3 escalated, 2 reacted"). Use it as a sanity-check on per-thread classification — discrepancies signal where the inline analysis may have miscategorized a thread. The summary is one extra read and catches whole classes of misclassification.

## Verify Subagent Research Actually Used Web Sources

When delegating research to subagents (Task tool with `claude-code-guide` or `Explore`), check the **sources** in their output — not just the conclusions. Subagents may read local files and existing learnings instead of performing fresh web searches, then present recycled information as new research. This is especially problematic when the local files contain the very claims you're trying to validate.

**Red flags:** output only cites local file paths, no WebSearch/WebFetch calls in the work, conclusions perfectly match existing assumptions. **Fix:** explicitly instruct subagents to "use WebSearch and WebFetch to find NEW information — do not rely on local files" and review whether they actually did.

## Three-Branch Gate Announcements

Every hard gate (session start, plan mode, implementation start) needs three announcement templates: positive match, already satisfied, and skip/no-match. Missing a branch means the gate fires silently — no observability on whether it executed. During calibration this is especially costly: silent skips look identical to gates that didn't fire at all, making it impossible to diagnose whether the system is working.

## Delegated Operations via Intent Files

When an agent can't execute certain operations (e.g., Bash blocked by security hooks), delegate via structured intent files: agent writes requests to a dedicated file (one per line), outer loop processes them between iterations. Prefer explicit intent files over parsing action logs — separate concerns, simpler parsing, no coupling to log format.

Example: agent can't `git rm` (Bash blocked) → writes `claude/consolidate-output/pending-deletions.txt` with paths to delete → wiggum.sh reads the file between iterations and runs `git rm` for each entry. Safety check: only delete files that are truly empty (prevents accidental deletion from wrong paths).

## Front-Load Structural Context in Subagent Prompts

When delegating classification or evaluation tasks to subagents, include structural context that prevents misclassification — don't assume the subagent will infer it. For example, when evaluating skills, tell the subagent that subdirectory skills (e.g., `explore-repo/brief/`) are already sub-commands of their parent, not independent skills to merge. Without this, subagents flag false positives based on surface-level overlap analysis.

## Inject Ground-Truth Inputs, Not Answers, for Formula/Arithmetic Review

When a review's core question is arithmetic/formula correctness (do these expected values match what the code computes?), compute the ground truth yourself first, then inject the **formula + constants** (the verified *inputs*) into each subagent prompt so they verify against a fixed reference without repo reads. Crucially, inject inputs, not the computed results — and instruct each agent to derive results independently. Handing them the answers (`$5k→1, $15k→2`) manufactures false convergence (agents echo your numbers); handing them the formula + constants and requiring independent derivation keeps multi-persona agreement genuine. Pair with diff-only delegation (subagents work from the diff + injected facts, not the repo), which also sidesteps line-drift from repo reads.

## Inject "Verified-Fixed — Don't Flag" to Suppress Stale-Gotcha False Positives

A proactive persona *learning* may surface a gotcha that the codebase already fixed — and the fix isn't in the diff (it lives in an unchanged file). Diff-only subagents can't see it, so seeding them with the raw gotcha primes N agents to all false-flag a non-bug. Before injecting any learning-derived concern into subagent prompts, verify it against the actual source (`git show <sha>:<file>` or a worktree read); if already handled, inject the *verified result* instead: "orchestrator-verified: `snap_price_to_tick` is tick-precision-aware via `_tick_decimal_places` — do NOT flag a `round(_,4)` off-grid bug." This is the negative-suppression complement to injecting ground-truth inputs: there you supply facts for positive derivation, here you pre-empt a known dead-end.

## Severity-Gap With Same-Direction Fix Is Agreement, Not Dissent

A merge rule that flags "severity differs by 2+ levels → dissent" over-triggers: two reviewers can rate the *same* issue low vs high while agreeing on the fix direction (e.g. both say "guard the cleanup"). That's an **agreement** — merge it, escalate to the higher severity, keep the fuller reasoning, and skip deliberation. Reserve deliberation (SendMessage round-trips) for *contradictory* positions (one says change, one says keep). Spinning up a dissent round-trip for a non-contradictory severity gap is thoroughness theater.

## Positive Signal vs Finding on One Symbol Isn't Dissent When They Target Different Aspects

The merge trigger "one persona's positive signal contradicts another's finding → dissent" over-fires when the two concern *different properties* of the same symbol. On a `build_ts_client(with_lock=False)` seam, three reviewers' positive "the kwarg is wired correctly and the live invariant is test-pinned" does **not** contradict architecture's finding "the *default value* is a forward-compat footgun" — wiring-correctness and default-choice are orthogonal, both true. Merge into one finding annotated with the already-satisfied concern ("wiring/test verified; residual is the default-value tradeoff"), skip deliberation. True dissent needs contradictory claims about the *same* property.

## Verify Assumptions Before Documenting

Test assumptions with a controlled experiment before writing them as facts across multiple files. Run a minimal reproducer that isolates the specific claim. If testing "agents can't use X", test with a known-working variant first before concluding it's a platform issue.

## Verify Shared Reference Conformance in Consuming Files

When multiple files consume a shared reference (e.g., re-review modes consuming `review-comment-classification.md`), the consuming files can restate the reference's logic with subtle errors — especially data model mismatches like using the wrong comment ID as a reaction target. Verify by tracing the actual data flow: what ID does the consuming file use? Does it match the shared reference's specification? API verification (`gh api`) confirms whether the action hit the right target, catching bugs that code review alone misses.

## Cross-Check Subagent Inventory Comparisons

When subagents compare file inventories across two directories, they may report files as "unique to X" that actually exist in both — especially with large file counts (50+). Always cross-check subagent diff results against a canonical source you control (e.g., a glob you ran yourself). The error compounds when the over-reported "unique" files drive downstream decisions (what to copy, what to merge).

## Agent-to-Agent Review Architecture

Reviewer → addresser → operator is a viable review cycle. The addresser investigates deeper than the reviewer (reads full files, not just the diff) and can surface issues the reviewer missed. When the addresser agrees with a suggestion, auto-implement without operator approval; escalate only on disagreement or uncertainty. The operator's role shifts from approving every change to reviewing the PR diff and calibrating agent judgment over time.

Use structured footnotes (`Persona + Role`) to separate comment chains when both agents post as the same GitHub user. Comments without a Role tag are from the operator.

## Iterative Testing for Timing-Dependent Autonomous Features

Autonomous features with timing-dependent side effects (stale poll auto-cancel, timeout-based cleanup, rate-limiting) need iterative testing with an operator watching. The spec gets ~70% right, but edge cases only surface in production: premature cancellation, clock access limitations, permission friction on state persistence. Design the first version, run it live, observe failures, fix, repeat. The loop itself is the test harness.

## Trust-Building Arc as Operator-Agent Collaboration Model

The manager-report trust pattern maps directly to operator-agent autonomy calibration: small scoped tasks with close review → demonstrate good judgment → gradually expand scope → occasional mistakes that are caught and learned from. Learnings, guidelines, and personas are trust artifacts — accumulated evidence of calibration, not just rules for an agent. This frame is useful for evaluating system changes: does this change help build trust (positive signals, outcome tracking) or just constrain behavior (more rules)?

## Verification: Targeted Grep Over Full File Reads

After subagent writes, verify with `wc -l`, `grep -c`, and a 5-line spot-check — not full file reads. Full reads consume ~8k tokens per batch for equivalent confidence to ~400 tokens of grep. Reserve full reads for debugging when grep checks fail.

## TaskOutput Only Works for Background Bash Tasks

`TaskOutput` with `block: false` works for background Bash commands (`run_in_background: true`), not for background Agent tasks. Agent IDs from `run_in_background` agents are tracked via the automatic notification system — you'll be notified when they complete. Don't poll with `TaskOutput`; it returns "No task found" errors.

## Agents Create Unintended Side-Effect Files During Batch Edits

When launching agents to edit specific target files, they sometimes create or modify additional files they weren't asked to touch — writing staging artifacts, enriching adjacent files, or creating root-level duplicates of cluster content. This is especially common when the agent prompt contains content that references other files by name. Always run `git status` after agent completion and revert unexpected changes before committing. The pattern compounds across batches: each organize cycle can produce 2-5 agent-created artifacts that must be cleaned up.

## Adapter/Integration Code Needs Architecture Persona

Domain personas (financial, security, correctness) miss structural concerns in adapter code: constructor design, exception hierarchy consistency, null-safety on SDK returns, forward-compatibility gaps, and cause-chain propagation. Empirically verified: a 3-persona review (correctness + financial + security) found 6 findings; adding architecture-reviewer caught 4 unique structural issues none of the domain personas flagged. Three independent external agents also caught these same structural gaps.

**Routing rule:** Force `architecture-reviewer` when changed files match `**/adapter*/**`, filenames containing `Adapter|Bridge|Gateway|Connector|Client`, or gRPC/proto files. This counts toward the max-3 persona cap; heuristic fills remaining slots.

## Correctness Persona Needs Defensive-Coding Directive at System Boundaries

When reviewing code that calls external services (gRPC stubs, HTTP clients, SDK wrappers), the correctness persona systematically misses boundary validation patterns unless explicitly directed. Empirically: `UUID.fromString(null)` → NPE escape, `e.getCause()` null-safety, empty-string enum mapping, and silent pagination truncation were all caught by external reviewers but missed by our correctness persona.

**Routing rule:** When changed classes call external services AND correctness-reviewer is selected, inject: "Focus on boundary validation (UUID parsing, enum mapping), null guards on SDK returns, exception cause-chain nullability, and silent pagination truncation."

## Multi-Agent Loop Blind Spots: Each Agent's Own Discipline

Paired-agent loops (reviewer/addresser, planner/implementer) catch drift in what each agent says *about the others' work* but not what each agent says *about itself* — its own output format, body shape, or response discipline. The reviewer's body format isn't critiqued by the addresser, and the next-cycle reviewer doesn't critique its previous self; operators catch this drift manually. When format discipline matters, add an out-of-band verifier that reads the converged state and checks each agent's output against its own discipline rules — not just cross-agent semantic correctness.

## Persona-in-Prompt Dramatically Improves Agent Output Quality

Embedding a persona ("You are a senior Spring Boot / Java engineer") + explicit test requirements + a "Quality bar" section in `claude -p` prompts produces dramatically better results than mechanical task descriptions. Observed: first-generation prompts ("create these files, follow existing patterns") → 0 tests, minimal code. Second-generation prompts with persona + quality bar + required test scenarios → 10-16 tests per agent, Javadoc, defensive coding, proper MR descriptions.

Key prompt sections that drive quality:
- **Persona** — sets the bar ("you care about clean architecture, testability")
- **"Read existing code first"** — forces pattern matching before writing
- **"Tests (required)"** — with specific test class names and scenario lists
- **"Quality bar"** — 3-4 bullet points on what good looks like
- **"Full agency"** — "keep what's good, rewrite what's not" unlocks improvement over prior attempts

## Two Confidence Tiers in Agent Output Reports

Agent reports that mix deterministic checks with judgment-based ones should frame them differently. Deterministic checks (structural rules, presence/absence) → assertions with citations ("thread #X has 0 reactions, rule says reaction-only"). Judgment-based checks (intent alignment, scope drift) → questions framed for operator review ("intent doc line 4 says X, diff shows Y, wanted to flag"). Same report, distinct sections, distinct framings — calibrates trust appropriately and prevents the report from overpromising on the judgment half.

## Subagent-Skip on Pure Remediation Commits

For re-review of commits that purely implement prior-cycle recommendations — delta ≤ ~100 lines, all changes in already-flagged files, no new code paths — the team-lead can verify the delta directly without re-launching reviewer subagents. Saves ~3-4× tokens with no quality loss; the team-lead maps each prior finding to a diff line, confirms the implementation matches the recommendation, flags any gaps. Skip only when all three conditions hold; any new code path resets to full subagent review.

## Verify Subagent Claims About Files They Didn't Read

Reviewer subagents inferring file contents they don't have access to (docker-compose, deploy configs, sibling modules) produce false-but-plausible claims. The risk surfaces as **severity inflation**: a finding's severity often hinges on a specific file claim, and a fabricated claim can push HIGH → CRITICAL. **Detection signal:** persona severities span 4+ levels (e.g., financial=CRITICAL, correctness=HIGH, architecture=LOW) — that spread means at least one persona is reasoning from a load-bearing claim the others didn't make. **Fix:** before posting, the team-lead reads the cited file and verifies the specific assertion. Drop the inflated severity to what the verified evidence supports; keep the underlying concern if real.

## Independently Reconstruct a Lone Blocking-Severity Race/Causal Finding

Distinct from severity inflation via fabricated *file* claims (above, detected by cross-persona spread): a **single** reviewer can assert a HIGH/CRITICAL concurrency or causal failure mode that is plausibly-reasoned but cannot actually occur — and there's no spread signal because only one persona flagged it. Subagents reason about runtime they can't execute, so before posting a lone blocking finding that hinges on a *scenario* ("two processes race on X", "A caused B"), the orchestrator must construct the failure path itself and try to falsify it. Example: a "relative `TS_TOKEN_PATH` makes the cross-process lock paths diverge → unserialized race" HIGH collapsed once traced — the token *store* path derives from the same CWD-dependent value, so lock divergence coincides with token-file divergence (no shared resource to race on). **Fix:** downgrade/correct with the counter-scenario shown in the posted finding, not silently — keep any genuine residual (here: a low-severity CWD footgun the PR inherits) but strip the overstated severity.

## Negative-Set Filtering by Subagents Is Permissive

Delegation prompts shaped "find X **not already in** Y" (dedupe against existing learnings, find missing tests, surface uncovered cases) over-include — items that exist in Y leak into the candidate list because matching a negative set is harder than enumerating, and agents prefer false positives to false negatives. Treat output as a candidate pool, not the final list; second-pass dedup against Y by the orchestrator is mandatory before any downstream write. Symptom: a 24-row "novel" table that shrinks to 9 once the orchestrator re-checks against the dedup targets it cited in the original prompt.

## Subagent Bullet Summaries Strip Load-Bearing Specifics

When promoting subagent findings to durable docs (learnings, ADRs, RFCs), bullet-form summaries often drop qualifiers the full source contains — the `is_finite()` companion guard to a `Decimal` coercion, the preflight error-elimination that makes `|| true` correct, the regex-arm ordering that makes ambiguity testable. Grep the source artifacts the agent cited before writing — bullets are an inventory, not a contract.

## Subagent Constraint Relaxation: Replace + Enumerate + Mandate Autonomy

When relaxing a hard-ruled constraint in a subagent prompt template (e.g., template says *"work only from the diff, do not read repo files"*), the relaxation must do three things:

1. **Replace, don't stack.** "You may also Read files for verification" leaves both rules active and the agent fills the ambiguity with permission-experimentation. Phrase as replacement: *"Override: instead of working only from the diff, you may also Read individual files for path verification."*
2. **Enumerate allowed mechanisms.** Vague "you may verify paths" lets the agent reach for whatever tool first surfaces a permission prompt (`ls /Users/...`, `cat`, `find`) and stop to ask the orchestrator. Spell out the shape: *"Use `Read(absolute_path)` for files; `ls <CWD-relative>` for directories. Avoid `ls /Users/...` absolute paths — they prompt."*
3. **Mandate autonomy.** Add explicitly: *"Complete the deliverable autonomously. Log friction as a low-severity finding and continue — do not stop the review to ask the orchestrator meta-questions."* Without this, agents treat permission friction as a blocker and return half-baked output requiring relaunch with corrective guidance.

Symptom of missing any of the three: subagent returns a meta-question ("should I use ls or Read?") instead of the findings JSON, costing a full retry-launch cycle. All three are cheap at prompt-construction time and prevent the most expensive failure mode in review-skill orchestration.

## Translate Cross-Stack Persona Instincts in the Subagent Prompt

Domain reviewer personas carry stack-specific instincts baked into their definition: `financial-reviewer` is framed in Java/BigDecimal/payments-ledger terms ("`float` near money = CRITICAL", "unrecoverable state = double-payment"), `correctness-reviewer` in Spring/`@Version`/JPA terms. Pointed at a different stack (e.g. a Python quant repo where `float`-for-notionals is the house convention and the unrecoverable state is a *margin call*), they misfire — wasting findings flagging the house convention as CRITICAL. Don't rely on the persona to self-adapt: seed each subagent prompt with an explicit instinct-translation block (*"floating point near money → here float is the deliberate convention; focus instead on whether the risk is bounded/recoverable. 'Could this lose money / leave an unrecoverable state?' → a margin call is the unrecoverable state."*). Generalizes the boundary-directive injection (above) from *adding focus* to *re-pointing mismatched instincts*; keeps multi-persona signal high instead of burning a reviewer on inapplicable dogma.

## Naming-Based Coupling Findings Are Often Blessed Conventions

A reviewer subagent flagging a `_leading_underscore` method as "unstable internal-API coupling," a "magic constant," or a "private method reached from a script" is reasoning from naming alone — it can't see that the project documents the symbol as a sanctioned entry point. Before posting such a finding, grep the project's convention docs (`CLAUDE.md`, `tests/CLAUDE.md`, test-infra docs) for the symbol. Example: `BackTester._run_without_report()` looks like fragile private coupling, but `tests/CLAUDE.md` documents it as *the* backtest-e2e/research entry point ("Use `_run_without_report()` to skip file I/O / charts") — so the finding is a false positive and gets dropped. Same class as severity-inflation verification: the orchestrator's repo/doc access falsifies a finding the diff-only subagent couldn't.

## Pre-Verify Behavior-Preserving + Existence Claims, Seed as Do-Not-Flag Facts

Proactive sibling to the reactive falsification above: for a refactor/consolidation review, verify the diff's behavior-preserving claims against the repo *before* launching diff-only subagents, then inject them as a "VERIFIED — do NOT re-flag" block in each prompt. Pre-empts the false positive instead of catching it after collection. Two checks worth the orchestrator's pre-flight:

- **Equivalence/idiom claims the diff can't settle.** Is `trade.direction == 'long'` correct? (grep — `TradeDirection(StrEnum)` ⇒ yes, the enum equals its string value). Does `make_mnq_algo(plz_algo_v2)` reproduce the retired `mnq_algo`, including the `__name__`-derived report-cache key? (read the factory — defaults match ⇒ behavior-preserving swap). Seeding the verified answer stops every persona independently burning a finding on it.
- **Missing-file / dangling-link findings.** "Target not in the changed-files list" is necessary but **not sufficient** — the file may pre-exist on the base branch. `ls` the directory (and `git show FETCH_HEAD:<file>` to confirm absence on the PR branch) before posting a HIGH "link 404s." The same `ls` clears the false alarm when the file exists untouched, and confirms the real dangling link when it doesn't (e.g. a new README row linking a bare `findings.md` that no sibling/base provides).

## Read the Changed Function's Unchanged Counterpart; Inject the Asymmetry

When a diff changes one half of a symmetric pair (writer↔reader, sync↔async, open↔close, encode↔decode, or two documented-companion *classes* implementing the same contract — e.g. sibling risk overlays whose `load_state` must agree on fail-loud-vs-tolerant), the highest-yield finding is often that the *unchanged* half didn't get the matching change — and diff-only subagents structurally cannot see it. The orchestrator's pre-flight: for each changed function, `grep` its call sites and read its unchanged counterpart, then inject the asymmetry as system context. Worked example: a PR added a legacy-file write-fallback to `write_algo_plz_limits_by_key`, but its paired reader `read_algo_plz_limits_by_key` (untouched, not in the diff) had no legacy fallback → writes land where the reader can't see them. Both personas independently anchored their top HIGH finding on that injected fact; neither could have found it from the diff. Positive complement to "Inject 'Verified-Fixed — Don't Flag'": there you read an unchanged file to *suppress* a false positive, here you read one to *surface* a real bug the diff hides.

## Subagent Repo Reads During Local Review See the Base Branch, Not the PR Head

A local team-review runs with the working tree on the *base* branch (`main`), so any subagent that reads a repo file — plain `Read`, `ls`, or grep, especially in a deliberation round where the "work from the diff only" constraint wasn't repeated — sees **pre-PR code** and can return a confident-but-wrong verdict citing functions/line numbers the PR added or moved. Seen: a `correctness-reviewer` "MAINTAIN MEDIUM" rebuttal claiming "the futures path doesn't reconcile against the broker at all," citing the pre-PR `_sync_holdings_from_broker` at line numbers absent from the PR head — it had read `main`, while the other reviewer cited the PR's actual added code.

**Fix:** when two reviewers' deliberation verdicts rest on *contradictory factual claims* about the code (not just different severities), resolve against the PR head yourself (`git show origin/<HEAD_BRANCH>:<file>`) — don't average or surface as `⚖️ DISSENT`; a "hold" built on a base-branch read is not a genuine dissent, adopt the side the primary source supports. And give any verification-capable subagent the head ref plus an explicit "the working tree is the base branch; verify via `git show origin/<branch>:<file>` or the provided diff only." Distinct from "Verify Subagent Claims About Files They Didn't Read" (that's *inferring* unread files; this is *reading the wrong ref*).

## Don't Seed Review Subagents With a Precomputed Line Map — Only `anchor_token` Matters

The orchestrator re-derives every inline comment's line from the finding's `anchor_token` against the head-SHA file anyway (see the line-drift entries above), so a subagent's `line_start` is throwaway. Handing subagents a hand-computed "source line map" to improve it is wasted prompt budget *and* a new error source — an eyeballed map is as likely to be miscounted as the subagent's own counting (seen: a map asserting `L74` for a trip test actually at `L93`, while a different subagent independently guessed `L90`; the orchestrator's `anchor_token` pass corrected all of them regardless). Tell subagents to return a precise `anchor_token` (the unique identifier on the target line) and not to sweat line numbers; the orchestrator owns anchor→line mapping post-collection. Corollary of "send the clean diff, pass directives separately" — even a *separate, well-meant* line map is one the reviewer doesn't need.

## Reviewing a Research/Findings PR: Scripts Are Code, Cited Numbers Need Provenance

A docs/research PR that adds reproducer scripts + a findings writeup is **not** a pure-docs PR — the scripts are code and the conclusions are only as sound as the computation under them. Route it as code+domain, not lens-only: a code-correctness reviewer (the scripts — look-ahead, NaN/warmup, metric math, reproducibility, cost realism), a domain-soundness reviewer (are the conclusions framed honestly — for a risk study, "did it raise CAGR or only cut maxDD?"; margin survival; no-free-lunch), and `architecture-reviewer` for the cross-cutting doc/script maintainability (Tier-1 duplication across N sibling scripts; the same rationale + verbatim numbers restated across index/README/findings = drift).

**Highest-yield orchestrator check: verify each cited headline number was generated at the config the doc recommends/ships.** A research doc can quote a table at one parameter, *recommend* a second in its own sweep, and a downstream plan can *ship* a third — grep the generating script's factory default to confirm which value produced the cited cell. Worked: a §16 DCA table cited `139/46/3.00` and the "deployable pick" prose described `reclaim_after=21`, but the same section's reclaim sweep concluded ~24, the trip sweep ran at 24, and the live-wiring plan shipped 24; `git show <sha>:tqqq_breaker.py` → `def flat(..., after=21)` confirmed the headline numbers were computed at the value the doc itself rejects. Confirming the finding (not just falsifying it) means reading the provenance — the default several hops from where the number is quoted. (Project rule: "a conclusion is only as sound as the computation under it.")

**A cited "reproduces the baseline exactly on window W" invariant only proves fidelity for the code paths W exercises.** When a re-implementation claims to mirror a production function "except for documented deltas" and cites a bit-identical reproduction as proof, fetch the production original (it's *not* in the diff) + the semantics of every helper it calls, inject as the reference the re-impl must match, then check whether the changed decision path is *reachable* in W before trusting the invariant. Worked: a research algo re-implemented production's QQQ dip-gate as a *compounded* return where production *sums* per-bar % returns (an undocumented third divergence; the docstring falsely claimed a match), yet the doc's "bit-identical on TEST (CAGR 140.134%, 139 trades)" invariant couldn't see it — both TEST-window flip days were bearish-market, so the bullish-branch dip-gate was never reached there, and the only bullish flip day sat in TRAIN. "Reproduces on window W" is proof only for the paths W's data triggers, never general fidelity; identify the diff's changed branches and confirm W actually hits them. Sibling to the headline-number-provenance check above — both scrutinize the doc's own cited evidence rather than taking it as given.

**Duplicated input constants (cost/spec/param) that *disagree* across sibling runner copies are a provenance bug, not a DRY nit — they silently fork the committed result tables.** Each result file embeds whichever copy its runner imported, so e.g. a round-trip commission keyed `2.5` in `run_baseline.py` (imported by ~13 runners) vs `5.0` in the purpose-built `_common.py` (imported by one) means the effort's conclusions rest on mutually-inconsistent costs. Grep *every* definition of a cost/spec/param constant across the effort, confirm they agree, and elevate a disagreement to the severity of a wrong cited number — not a style finding the author can defer. Distinct from boilerplate duplication (maintainability) and doc-text drift (`:191`): here the duplicated *input* forked, so the *outputs* disagree.

## Reviewing a Pure-Docs PR That Describes the Code: Verify Claims Against Source, Repo-Reads ON

Sibling to the research-PR case above (`:189`), for the case it excludes: a **pure-docs PR** (glossary, architecture map, onboarding README — no scripts) that *describes the codebase* is a **factual-accuracy audit** — every finding is "this prose contradicts the source." The highest-value move **inverts the default diff-only / inject-facts rule** (`:47`, `:170`, `:185`): explicitly grant subagents repo-read access and tell them to verify each claim against the named source — instrument/symbol defs, file paths, env-var sets, mapping tables, that a cited CI script exists, and that every internal link/anchor resolves. State the override in the prompt; the reviewer template's "do not read repo files" constraint is wrong for this shape.

**Discriminator vs inject-facts:** inject-facts (orchestrator verifies a *few* computed/structural facts, subagents stay diff-only) fits a handful of facts. A glossary carries *dozens* of heterogeneous claims scattered 1:1 across source — injecting them all is infeasible, so delegate verification to repo-reading subagents. Line numbers stay reliable: subagents reading the checked-out PR branch get source-accurate lines, and the orchestrator's `anchor_token` pass is still the safety net.

**Persona pairing:** a domain-expert persona (verifies factual/domain claims — e.g. `python-quant-dev` for trading instruments) + `architecture-reviewer` (described mental model matches real module boundaries; cross-doc duplication = drift; link/index integrity). Drop the code-defect personas (`correctness`, `financial`) — their idempotency/race/null lenses have no surface in prose. The high-yield findings are factual: a symbol the system doesn't actually trade (`ES/MES` listed as traded but absent from `CONTRACT_SPECS`), an overstated guarantee ("idempotent per day" when the code relies on a single-writer invariant), a mapping table duplicated across two docs + the code dict it derives from.

## Idle-Timed-Out Review Subagents: Re-Launch Fresh With a Brevity/Early-Write Directive

A reviewer subagent that stalls on long extended-thinking returns "Stream idle timeout — partial response received" with no findings file written, and resume-via-SendMessage may be unavailable (not wired in every harness/session — `ToolSearch("select:SendMessage")` can miss). Recovery: re-launch a fresh subagent with the same context but an explicit brevity contract — "write the output file within your first 1-2 actions, keep each finding 2-4 sentences, don't overthink." Seen: two reviewers timed out at ~5 min with 0 findings; re-launched with that directive, both finished in ~1 min with full findings. The early-write directive both bounds the thinking that causes the timeout and guarantees a partial-progress artifact if it recurs.

## A Workflow's Un-Verified Findings Are Hypotheses, Not Conclusions

When a multi-phase audit/review workflow adversarially verifies only a *subset* of its findings ("16 of 80 confirmed"), the verified subset is trustworthy but the **un-verified remainder are hypotheses** — re-verify each against the real code before acting. They collapse at a high rate: a synthesis-level "X is duplicated / X is a bug" claim that no agent read the code to confirm is frequently wrong (one session deferred 3 of 3 acted-on items, *all* from the un-verified set; every adversarially-verified item held). Spend the next session's skepticism on the un-verified items specifically — and when a workflow's verify phase is scoped to a subset, the un-verified findings are exactly where to gate (a short re-verify pass) before any implementation.

## Fan-Out Migration of Side-Effectful Code: Static-Verify Only, Never Execute

Parallelizing a mechanical migration across independent files is safe — *until* the files have dangerous side effects (scripts that place live orders, hit a broker/network, mutate prod state). Instruct the agents to verify **statically only** (`ruff check` + `python -m py_compile`) and **never run** the target — one over-eager "let me confirm it works" can fire a live order. Review every returned diff yourself; the agents' self-reports are necessary, not sufficient. The import-cleanup half is well-guarded even on untested code: `ruff` `F401` flags an import that should've been dropped, `F821` flags one dropped but still used — so a "replace construction + remove dead imports" sweep is statically catchable.

## Scale Injected Persona/Learning Context to PR Size

A review skill that says "load every resolved proactive-load file into the persona content" over-injects on a small/focused PR — multi-KB of mostly domain-irrelevant cross-refs (Java/resilience files on a Python refactor) × N reviewers. Distill the handful of directly-relevant learning entries into one compact block (~10–15 lines), reuse it across personas, and let each reviewer apply its own lens first. The full proactive set earns its cost on a broad, cross-cutting PR — not a 3-file mechanical refactor.

## Verify a Mapping/Dispatch Refactor by the Full Cartesian Table, Not Spot-Checks

For a behavior-preserving refactor of a dispatch table or lookup map (`getattr` string-table → typed enum + `match`, signal→symbol map, status→handler), instruct the reviewer to enumerate the *full* input space as a table — every dimension crossed (e.g. open/close × long/short × market/limit = 8 cells) — and trace each cell old→new to the identical target, plus any sign/arg-order/log-string carried alongside. Green tests + "looks equivalent" miss a single transposed cell; the cartesian trace proves parity by construction. Have the subagent return the verdict explicitly ("8-cell parity PASSED") so the orchestrator can gate on it.

## A Skeptic Agent on a *Clean* Implementation Audits Test Coverage, Not Just Bugs

Run a single adversarial review agent (prompted to *refute*, not praise) even when you're confident a well-grounded solo implementation is correct. The bug-hunt often comes back empty — but it surfaces real test-coverage gaps the author can't see: e.g. "every unit test passes a single-element `closes` list, so a `[-1]`-vs-`[0]` index regression is only caught by the one e2e." The agent pays for itself on the coverage audit even when it finds zero bugs; fold its gaps back in as added tests before shipping.

## Resolve All Inline-Comment Anchors in One Call Against the Head-SHA File

The orchestrator owns anchor→line mapping (see line-drift entries above), and a local team-review runs on the base branch — so don't `Read` the working tree (it returns pre-PR lines). When the PR branch isn't checked out: `git fetch origin <branch>` once, then resolve *every* finding's anchor in a single call — `git show FETCH_HEAD:<file> | grep -nE 'anchor1|anchor2|anchor3'` — rather than N per-anchor reads. This also exposes diff-artifact offsets instantly: a reported line past the file's EOF (e.g. `300` in a 215-line file) can't match and gets re-anchored from the grep.

## A Subagent Executes a Flawed Premise Faithfully — Verify Agent-Introduced Facts Against Source

An obedient subagent won't question a wrong instruction — hand it "keep date X as the vintage" and every output inherits the error with no flag. Review agent-*introduced* factual changes (dates, constants, labels) against the source-of-truth, not just for internal consistency: consistency only proves the agents agreed with your premise. Worked example: a *recompute* date (re-prove / regen) is not a *data vintage* (last input-data change) — instructing several agents to stamp the compute date propagated it into N files before a source-check caught it.

## A "Same Pattern As <Sibling>" Finding Can Name a File That Lacks the Pattern

When a reviewer subagent generalizes a real finding to a sibling ("same unguarded `np.corrcoef` as `file_A` — also in `file_B`"), the cited `file_B` may not contain the pattern at all. A third hallucination class, distinct from line-drift (wrong line, right file) and content-corruption (wrong string, right file): here the *file* is wrong. Before posting any cross-file-generalized / "same as X" finding, independently grep the cited file for the anchor (`git show <head_sha>:<file> | grep -n <token>`) and drop it if absent — the subagent reasoned by analogy from a true sibling, so its single-file finding can be sound while the generalization is phantom.
