# General Code Review Patterns

### Mutable domain entities should be classes, not records

Records/data classes are for immutable value objects. Domain entities with changing state (status transitions, accumulated collections) should be regular classes to avoid confusion about mutability semantics.

### Test naming convention: method_when_should

Test method names should encode what's being tested, the condition, and the expected behavior: `getTransfer_whenIdNotFound_shouldReturn404`. This makes test failures self-documenting.

### Always include negative test cases

Happy-path-only tests are incomplete. MRs should include not-found, invalid input, and edge case scenarios. Reviewers will flag this.

### No System.out.println in production code -- use structured logging

`System.out.println` and `System.err.println` should never appear in production code. Use SLF4J with structured logging (e.g., `StructuredArguments.v()` with logstash-logback-encoder). This was the most frequently flagged issue in MR !10 (4 separate comments).

### Avoid duplicate logging across layers

Don't log the same request/response data in both client and service layers. Log at one layer (typically the client) and keep the orchestration layer clean. More broadly, logging the same condition at the same level in caller and callee creates noise -- log at the point closest to the decision/action.

- **Takeaway**: Log at the point closest to the decision. Duplicate logging across the call stack is a code smell.

### Handle InterruptedException properly -- restore the interrupt flag

When catching `InterruptedException`, call `Thread.currentThread().interrupt()` before logging/rethrowing. Bare `throw new RuntimeException(e)` loses the interrupt flag and makes debugging harder.

### Prefer enums over strings for fields with known value sets

When entity fields represent a fixed set of values (network type, asset type, status), use enums. Makes the domain model self-documenting and prevents invalid values at compile time.

### REST endpoint paths should be specific and self-describing

Generic paths like `/address` are ambiguous. Use `/wallet-address` to make the resource type obvious. Reviewers will flag vague naming.

### Method names must match the parameters they use

If a method says it operates on a transfer ID, it should receive one. Inconsistency between method name/signature and actual parameters signals a copy-paste error or incomplete refactor.

### Don't commit hardcoded test data in production code paths

Placeholder values (hardcoded IDs, sample UUIDs) in production code are merge hazards. Either parameterize them or remove and add a TODO with a ticket reference.

### Optional<Optional<T>> is a code smell

Nested Optionals add no information -- the inner Optional already handles absence. If you find yourself wrapping Optional in Optional, the API design needs rethinking.

### Properties files treat double quotes as literal characters

In Spring `.properties` files, values like `cors.allowed-origins="https://..."` include the quotes as part of the value string. This causes silent configuration failures (e.g., CORS origin matching fails because the stored origin includes quote characters). GitLab Duo caught this in review.

- **Takeaway**: Never quote values in `.properties` files. Use `key=value` without surrounding quotes.

### Secrets in properties files are a recurring review issue

Hardcoded tokens/secrets committed to `application.properties` appeared in 6 out of 21 MRs on one project. Even with reviewer awareness, this keeps recurring because local development naturally leads to pasting real values. Use `${ENV_VAR}` syntax in committed files and `application-local.properties` (gitignored) for actual values. In MR !16, the resolution was to exclude clientId/clientSecret from application-{env}.properties entirely since they get injected by the deploy repo.

- **Takeaway**: Pre-commit hooks or CI checks for literal tokens in properties files would catch this automatically.

### Spring Security CORS requires explicit configurationSource wiring

`cors(Customizer.withDefaults())` relies on Spring auto-detecting a `CorsConfigurationSource` bean. Custom security configurations can disrupt this auto-detection, causing silent CORS failures (403s with no clear error message). Use explicit wiring: `.cors(c -> c.configurationSource(corsConfigSource))`.

- **Takeaway**: Prefer explicit configuration over convention-based auto-detection for security-critical settings.

### Integration clients should throw on error, not return empty

Returning `Optional.empty()` or null from integration client methods when errors occur silently swallows failures. The caller loses the ability to distinguish "not found" from "service error." Throw exceptions and let the caller decide on handling strategy.

- **Takeaway**: Integration client error handling: throw on error, return Optional only for legitimate "not found" cases.

### Automated reviewers can create a false sense of review coverage

When AI-powered review tools (GitLab Duo, etc.) are configured as reviewers, human reviewers may defer entirely rather than providing independent review. In multiple cases, 4 human reviewers were listed but only the AI tool provided substantive comments. However, automated and human reviewers are complementary: AI catches mechanical issues (null checks, config indexing, property formatting, constraint/message mismatches), while humans catch architectural and security concerns (PII logging, MR scope, credential management). Domain invariants can justify dismissing AI-suggested defensive checks when the data path is well-understood (e.g., guaranteed non-null values at a specific processing stage).

- **Takeaway**: Monitor whether automated review tools are supplementing or replacing human review. Both provide different, complementary value. Evaluate AI suggestions against design intent -- they catch real bugs (wrong generic types, unsafe casts, constraint/message drift, null-safety in financial arithmetic) but also flag intentional omissions where domain invariants guarantee safety. Duo comments tend toward defensive/obvious findings; the highest-impact issues (e.g., endpoint placed on the wrong controller) are consistently surfaced by human reviewers. AI reviewers correctly identify cross-cutting blast radius from localized changes (e.g., removing `@UuidGenerator` affects all creation sites) but can miss application context (e.g., flagging removal as "critical" when application code manually assigns UUIDs). GitLabDuo is particularly effective at catching null-safety gaps in financial code paths with concrete code reference evidence.

### Avoid unnecessary wrapper methods -- call dependencies directly

One-line delegation methods (e.g., `getAuthToken()` that just calls `tokenProvider.getToken()`) add indirection without value. Call the dependency directly unless the wrapper adds caching, error handling, logging, or other real logic. This extends to service layers: when a service just delegates to another without adding validation, transformation, or abstraction, remove the indirection entirely.

- **Takeaway**: Inline trivial delegation methods and unnecessary service indirection layers. Wrappers earn their existence by adding behavior.

### Scope MRs tightly -- one concern per merge request

Breaking changes to existing APIs bundled with new features make review, rollback, and changelog tracking harder. Ship them separately even if they're logically related. Large exploratory MRs (47+ files) get closed and split. Cross-cutting refactors (49 files) with zero pre-alignment face high closure risk -- zero reviewers, zero discussion, closed. MR dependency chains (MR !31 -> !35) compound the problem -- if one MR in the chain is abandoned, all downstream work is blocked.

- **Takeaway**: Breaking API changes should never share an MR with new feature work. Pre-align with the team before broad refactors. Avoid dependency chains between MRs. Defer related-but-out-of-scope work to follow-up tickets rather than expanding scope. Small, focused MRs (4 files, single purpose) get same-day turnaround. Narrowly scoped bugfixes (e.g., routing/path fixes) and well-scoped renames with clear problem statements sail through review with minimal friction.

### Java switch expressions throw NPE on null enum values

`switch` on a null enum reference throws NullPointerException before matching any case -- the `default` branch does NOT catch null. Guard with explicit null checks before the switch.

- **Takeaway**: Always null-check before enum switch expressions. This is a Java language behavior, not a framework issue.

### Switch default cases should throw, not return null

When switch expressions return null from the default case on unknown values, callers that don't expect null get NPEs downstream. Throw IllegalArgumentException for unknown values instead of returning null -- exceptions fail fast, null propagates silently.

- **Takeaway**: Default cases in switch expressions should throw IllegalArgumentException, not return null. This is distinct from the null-input NPE problem.

### Use correct enum types in test data -- copy-paste risk

Tests may compile with the wrong enum type if both enums are structurally compatible. Semantic incorrectness won't cause a test failure until the code path that validates the type is exercised. Common source: copy-pasting test setup between similar test methods. Also manifests as wrong Javadoc ("Create" instead of "Update"), wrong assertion values (404 instead of 400), and semantically wrong test values (TXID with passport-format data).

- **Takeaway**: Review test data for semantic correctness, not just compilation success. Copy-paste bugs span enums, docs, assertions, and test data values.

### Ship integration client separately from orchestration wiring

For large external integrations, ship the client (HTTP/gRPC wrapper, DTOs, auth) as a standalone MR before the orchestration that wires it into the processing flow. Reduces review complexity and isolates failure domains.

- **Takeaway**: Integration client + wiring = two MRs. Review and test the client independently first.

### Never log authentication tokens or PII

Auth tokens logged at INFO level are a security vulnerability. PII (names, birthdates) in logs creates compliance risk. Use DEBUG for success confirmations (without the sensitive value) or omit sensitive data from logs entirely.

- **Takeaway**: Treat log statements containing secrets or PII as security bugs. Downgrade level AND remove the value.

### Rename parameters to reflect intent, not implementation

When a parameter name describes implementation (e.g., `clientId` for what's actually an idempotency key), rename it to match its semantic role (`requestId`). Misleading parameter names cause bugs when callers assume the name describes the expected value.

- **Takeaway**: Parameter names should describe what the value represents, not where it came from or how it's used internally.

### Pass idempotency keys as arguments rather than generating inside clients

Generating `UUID.randomUUID()` inside a client method prevents the orchestration layer from reusing the same key across correlated operations. Idempotency keys should be caller-controlled for proper correlation.

- **Takeaway**: Generate idempotency keys at the orchestration layer. Client methods should accept them as parameters.

### Log correlation/request IDs in integration client operations

When operations have idempotency or correlation IDs, include them in all log statements for that operation. Without this, debugging integration issues requires correlating logs by timestamp alone.

- **Takeaway**: Always include request/correlation IDs in log statements for integration client calls.

### Commented-out code in migrations needs explanatory comments

Migrations are immutable after deployment. Commented-out SQL (e.g., GRANT statements) needs context about why it's commented out and whether it should be re-enabled, because the migration file itself cannot be edited later.

- **Takeaway**: Treat commented-out migration SQL as documentation. Add context for future readers.

### READMEs for infrastructure modules should lead with prerequisites

Users need to know what to install (Docker, specific tools, env vars) before they can follow setup steps. Burying prerequisites after development instructions leads to failed setups and backtracking.

- **Takeaway**: Structure infrastructure docs: prerequisites first, then setup, then usage.

### Avoid unnecessary Optional wrapping when null check suffices

`Optional.ofNullable().map().orElse()` adds ceremony without value when the logic is a simple null-to-default transformation. A direct null check with ternary is cleaner and more readable.

- **Takeaway**: Reserve Optional for method return types signaling absence. For inline null checks, use ternary or if-statement.

### Validation failure tests should verify service layer never called

For 400-level validation failures, assert that the service layer was never invoked: `verify(service, never()).method(any(), any())`. This confirms the validation short-circuits before reaching business logic and isn't just returning 400 after partially processing.

- **Takeaway**: Validation test = status code assertion + verify service never called.

### Unnecessary null checks on guaranteed non-null collection returns

`if (list != null && !list.isEmpty())` is unnecessary when the method contract guarantees a non-null return (e.g., `new ArrayList<>()`). Per Java convention, methods returning collections should never return null.

- **Takeaway**: Know your API contracts. Collection-returning methods should never return null; don't null-check them.

### Discarded builder.build() call -- Lombok builder pitfall

`.build()` called mid-chain with the result discarded. The compiler won't catch it since `build()` returns a value that can legally be ignored. Common with Lombok builders during multi-field setup.

- **Takeaway**: Watch for orphaned `.build()` calls in Lombok builder chains. The result must be assigned or returned.

### Junction tables should include updated_at for future flexibility

Even if not currently needed, adding `updated_at` to junction/association tables costs nothing and avoids a future migration when the relationship needs to track modification times.

- **Takeaway**: Default to including `updated_at` on junction tables. Zero cost now, avoids migration later.

### Defer work that isn't needed yet

Don't add schema columns for features that haven't been designed yet. It's cheaper to add a column later than to migrate away from the wrong one. This principle extends beyond schema: question whether any new API surface, endpoint, or abstraction is technically needed. If the data is already available through an existing response, adding a dedicated endpoint is unnecessary complexity.

- **Takeaway**: "Do we technically need this?" is a powerful review question. Applies to schema columns, API endpoints, and any speculative work.

### Large renames should be staged: internals first, then deployment-visible

Prioritize internal renames to unblock dependent MRs, deferring deployment-visible changes (Docker image paths, pipeline configs). Reduces blast radius per MR and unblocks dependent work sooner.

- **Takeaway**: Stage renames: internal code first, deployment artifacts second.

### Remove self-evident Javadoc and comments on self-documenting methods

findByCustomerId is self-documenting. Comments that restate the method signature add noise. Reserve Javadoc for non-obvious behavior, side effects, or domain context. More broadly, if the method name is self-documenting, skip the comment entirely -- comments explain *why*, not *what*.

- **Takeaway**: Don't add Javadoc or comments to methods where the name fully describes the behavior.

### Nullable column constraints caught in entity review

Missing `nullable=false` on JPA annotations that should mirror DB NOT NULL constraints. The entity layer should be consistent with migration-defined constraints. Extends to DTO validation: `@Size(max=N)` on DTOs should match the corresponding `VARCHAR(N)` column constraint in the DB to avoid confusing errors where DTO validation passes but the DB insert fails (or vice versa).

- **Takeaway**: Cross-reference JPA nullable annotations and DTO validation constraints against migration column constraints during entity review.

### Optional.get() without isPresent is a bug waiting to happen

.get() on Optional without handling the absent case should always be .orElseThrow() with a meaningful exception. Bare .get() throws NoSuchElementException with no context.

- **Takeaway**: Always use .orElseThrow() instead of .get() on Optional.

### Guard against null before string operations on map values

When accessing map values (e.g., `request.getData().get("type")`), the result can be null. Calling `.toUpperCase()` or similar string methods directly on the result throws NPE. Always null/empty-check map-retrieved values before string operations, especially when feeding into switch statements.

- **Takeaway**: Treat Map.get() results as nullable. Add null/empty guards before string operations.

### Validate FieldError type before casting in exception handlers

When processing `MethodArgumentNotValidException`, casting all errors to `FieldError` is unsafe. Global validation errors (non-field) cause `ClassCastException`. Use `instanceof` pattern matching to safely handle mixed error types.

- **Takeaway**: Use instanceof checks when processing validation errors -- not all errors are FieldErrors.

### Extract validation into dedicated validator classes

Validation logic extracted from orchestration services into standalone validator classes (e.g., `RawCustodyTransactionValidator`) keeps processors focused on orchestration while validation rules become independently testable.

- **Takeaway**: Separate validation from orchestration. Validator classes are easier to test and modify independently.

### Remove unused repository methods proactively

Dead code in repositories is particularly costly because it implies supported query patterns that don't actually exist. Proactively delete unused query methods during refactors rather than leaving them for "future use." This extends to test code: when removing production methods, also remove corresponding test helpers, mocks, and test utilities that exercised them.

- **Takeaway**: Unused repository methods mislead about supported access patterns. Delete them during the same MR that removes their callers. Audit test files for orphaned helpers too.

### Self-documenting MR descriptions that direct reviewer attention

For larger MRs, explicitly state which files contain the important business logic changes. Example: "Most changes are trivial; the main logic to review is in X.java and the getStartDate method." Guides reviewers to spend time where it matters.

- **Takeaway**: In MR descriptions for non-trivial changes, tell reviewers where to focus.

### Author self-annotation as review substitute

When no reviewers are assigned, authors proactively annotating their own code with comments explaining design decisions creates a written record of intent. Not a substitute for review, but better than no documentation of reasoning.

- **Takeaway**: Self-review annotations are a fallback when reviewers aren't available, not a replacement.

### Migration conflict resolution should be documented in MR description

For migration conflict MRs (renumbering after concurrent merges), state the original version and the new version in the description. Makes it easy for reviewers to verify correctness without digging through diffs.

- **Takeaway**: Migration conflict MR descriptions: state old version, new version, and why the renumber was needed.

### Bundle schema alterations with data inserts in one migration

When seed data doesn't fit existing column constraints, alter the schema and insert the data in a single migration rather than splitting across two. Keeps the migration atomic -- no window where the schema is changed but data isn't inserted (or vice versa).

- **Takeaway**: Schema change + data that depends on it = one migration file.

### Validate data completeness before adding NOT NULL constraints

When a migration backfills data then adds NOT NULL, ensure the UPDATE covers ALL rows. If it only fills a subset, the subsequent ALTER COLUMN SET NOT NULL fails for rows still containing NULL. Test migrations against realistic data volumes, not just dev seed data. For tables with existing data, use a two-step migration (add nullable, backfill, constrain). For empty tables, a single step is acceptable but document the assumption.

- **Takeaway**: Before SET NOT NULL, verify the backfill UPDATE has no WHERE clause gaps. Two-step migration for populated tables; single step for empty tables with documented assumption. Ship nullable first, backfill in follow-up, add NOT NULL constraint -- don't block on backfill.

### Flyway migration files must end with a trailing newline

Missing trailing newlines in SQL migration files cause version control diff noise and compatibility issues with some database tools. Consistently enforced in review.

- **Takeaway**: Always end migration SQL files with a trailing newline.

### Prefer FK references over plain string columns for relational data

When adding a column that stores a value from another table, use a foreign key constraint. Storing a string without FK creates data consistency risk -- nothing prevents orphaned references or typos. Reviewer flagged this and it was validated with insert/update SQL tests. When changing a FK to reference a different table, add a data validation step (e.g., `DO $$ ... END $$` block checking orphaned rows) before `ALTER TABLE ... ADD CONSTRAINT`.

- **Takeaway**: If a column references another table's data, add a FK constraint. Validate with SQL tests. FK target changes need pre-validation of data integrity.

### Validate migration constraints with actual SQL tests, not just review

When a reviewer questions whether a constraint is properly enforced, demonstrate it with concrete SQL tests -- happy path, unhappy path, and edge cases. Providing both screenshots and reproducible SQL scripts is the gold standard for migration constraint verification.

- **Takeaway**: Prove constraint correctness with executable SQL, not just code review assertions.

### Verify environment state assumptions before claiming "no data exists"

When justifying migration decisions based on data state (e.g., skipping a backfill because "no data exists"), be specific about which table and which environment. A reviewer pushed back noting dev1 did have data in related tables when the author claimed otherwise.

- **Takeaway**: Check all environments before making data-state claims that affect migration strategy.

### Validation error messages must stay in sync with constraint annotations

When updating validation constraints (e.g., changing @Size(max = 10) to @Size(max = 50)), always update the corresponding error message string. GitLab Duo caught a @Size(max = 50) paired with a message still saying "10 characters or less."

- **Takeaway**: Treat constraint annotation + error message as an atomic pair. Change one, change both.

### Pagination loop termination must guard against null tokens

Pagination termination logic using `!next.equals(pageToken)` can cause infinite loop when pageToken starts as null and API returns null for nextPageToken on first page. Safer pattern: `hasNext = next != null && !next.isBlank()`.

- **Takeaway**: Always null-guard pagination tokens. Equality checks on potentially-null values cause infinite loops.

### Add discoverability comments when introducing global/cross-cutting behavior

When a global handler silently catches what domain-specific handlers previously handled, add comments in the domain handlers pointing to the global one. Future developers may not know a global handler exists and will waste time debugging why their local handler isn't firing.

- **Takeaway**: Cross-cutting behavior needs breadcrumbs. Comment at the point of displacement, not just the point of implementation.

### Preparatory refactoring deserves its own MR

"Make the change easy, then make the easy change." Separating refactoring (e.g., consolidating exception handling) from feature work keeps both MRs focused and reviewable. The refactoring MR establishes the new structure; the feature MR builds on it cleanly.

- **Takeaway**: Prep refactoring + feature = two MRs. Reviewers can verify the refactoring is behavior-preserving before reviewing the feature.

### Boolean column indexes justified by data skew

Low-cardinality boolean columns normally don't benefit from indexes. However, when data distribution is heavily skewed (e.g., 99% FALSE, 1% TRUE) and there's a view or query filtering on the minority value, the index is justified because it drastically narrows the scan.

- **Takeaway**: Boolean indexes are valid when data skew makes the minority value rare and queries filter on it.

### Debugging artifacts in production code

Self-directed markers like `-- HEY THERE!!` are debugging artifacts that should never reach review. Use conventional `TODO:` or `FIXME:` format instead -- they're greppable, professional, and most IDEs/CI tools can flag them.

- **Takeaway**: All in-code markers should use standard TODO/FIXME format. Ad-hoc markers signal incomplete cleanup.

### Eliminate redundant columns in views

When a view joins tables and both sides have a column with identical values (e.g., wallet_network always equals transaction_network), include only one. Redundant columns in views add confusion about which is authoritative and waste query bandwidth.

- **Takeaway**: Design views around their filtering purpose, not the breadth of joined data. Drop columns that duplicate information.

### Update tests when API contract changes

When switching from request-param-sourced to JWT-sourced identity (or any API contract change), tests must stop passing the old parameter. Stale test parameters mask the actual API contract and give false confidence that the old interface still works.

- **Takeaway**: API contract change = test contract change. Stale test params are false documentation of the API surface.

### Avoid `Impl` suffix for class names

The `Impl` suffix is conventionally reserved for interface implementations and is considered an anti-pattern — it signals an unnecessary abstraction layer. Name classes by what they do, not by their relationship to an interface (e.g., `FundingApi` instead of `FundingApiImpl`).

- **Source**: continuous-settlement MR !2
- **Frequency**: convention
- **Takeaway**: Name classes by responsibility, not by structural role. `Impl` suffix is a naming smell.

### Composite primary keys don't auto-index individual columns in PostgreSQL

PostgreSQL's B-tree index on a composite PK `(a, b)` supports lookups by `a` (leading column) but NOT by `b` alone. A separate index on `b` is justified for direct lookups. An index on `a` alone is redundant. AI reviewers frequently misunderstand this.

- **Takeaway**: Composite PK indexes only support leading-column lookups. Add separate indexes for non-leading column queries.

### Column naming should match the referenced entity, not legacy naming

When FK targets change, evaluate whether the column name still communicates intent. If `asset` column now references `currencies`, consider renaming to `currency`. Misleading column names create confusion about the actual relationship.

- **Takeaway**: Column names should reflect the current referenced entity. Rename when FK targets change.

### Null safety in BigDecimal stream reductions and arithmetic

Nullable fields will throw NPE in `reduce(BigDecimal.ZERO, BigDecimal::add)`. Add `.filter(Objects::nonNull)` or use `Optional.ofNullable().orElse(BigDecimal.ZERO)` before reducing. This extends to individual arithmetic operations: methods like `getFeeAmount()` can return null, so guard with `BigDecimal.ZERO` before subtraction or other operations.

- **Takeaway**: Always null-guard before BigDecimal operations -- both stream reductions and individual arithmetic. Nullable fields + reduce/subtract = NPE.

### Add comments explaining domain-specific constants like terminal status sets

Domain-specific constants that encode business rules (e.g., sets of terminal statuses, cutoff values) should have inline documentation explaining what the constant means and why those specific values are included.

- **Takeaway**: Business rule constants need comments explaining the "why" behind the value set.

### Remove duplicated constants when moving logic between services

When extracting logic into a new service, remove the constant from the original to avoid maintenance drift. Two copies of the same constant will diverge silently.

- **Takeaway**: Constants must have a single source of truth. Remove from the original when extracting to a new service.

### Log level demotion requires justifying where the signal is preserved

When downgrading log levels (e.g., WARN to DEBUG), always identify the alternative location where the information is still logged at an appropriate level. Without this justification, important signals can disappear from production logs.

- **Takeaway**: Demoting a log level? State where the signal is still preserved at the appropriate level.

### Entity ID strategy must match usage site -- audit both when changing either

When modifying `@Id` generation annotations, grep for all entity creation sites to verify which strategy is actually in use. Mismatches between ID generation annotation and actual usage are silent bugs.

- **Takeaway**: Changing ID generation strategy? Audit all creation sites. Changing creation sites? Verify the annotation matches.

### Hardcoded timezone offsets are brittle -- use ZoneId

Use `ZoneId.of("Asia/Singapore")` instead of `ZoneOffset.of("+08:00")` for business logic tied to a location. ZoneId handles DST changes and political timezone adjustments; fixed offsets don't.

- **Takeaway**: Location-based time logic should use ZoneId, not ZoneOffset. Offsets are for protocols, not business rules.

### Reviewer-initiated regression analysis on data model changes

When changes affect data model relationships (e.g., custody account structures, entity hierarchies), reviewers should independently trace the full data flow to verify no regressions. In MR !102, a reviewer traced the complete flow unprompted to verify correctness.

- **Takeaway**: Data model relationship changes warrant full flow tracing by reviewers, not just code-level review.

### E2E evidence in MR comments for infrastructure changes

Custody, wallet, and infrastructure changes should include screenshots and DB query results posted in MR comments before merge. This provides concrete proof the change works in a real environment, not just in tests.

- **Takeaway**: Infrastructure changes need E2E evidence (screenshots + DB queries) in MR comments before approval.

### API response completeness against published docs

Reviewers should cross-reference response DTOs against published API documentation. Missing fields in responses are a recurring gap that's easy to miss when reviewing code in isolation.

- **Takeaway**: Cross-reference response DTOs against API docs during review. Missing fields are a common silent gap.

### Domain isolation: keep conversion logic in the owning domain's service

When Service A needs data from Domain B, expose a method on Service B rather than reaching into B's repositories directly. This preserves domain boundaries and keeps conversion/transformation logic with the domain that understands it.

- **Takeaway**: Cross-domain data access should go through the owning domain's service, not directly through its repositories.

### Reuse existing converters before building parallel paths

Before building new DTO construction logic, check if existing view/converter infrastructure already covers the data shape. Extend existing converters rather than duplicating transformation logic in a parallel path.

- **Takeaway**: Check existing infrastructure before building new conversion paths. Extend over duplicate.

### Reviewers picking up adjacent work from review threads

When a reviewer identifies work they can do to unblock or improve the MR, they create a parallel MR. This is a healthy collaboration pattern that accelerates delivery without expanding the original MR's scope.

- **Takeaway**: Reviewers creating parallel MRs from review discoveries is a positive collaboration signal.

### Generic error messages for uniqueness constraint violations

Avoid leaking which specific field caused a uniqueness violation in error responses. Generic messages like "duplicate entry" reduce enumeration attack surface compared to "email already exists."

- **Takeaway**: Uniqueness violation error messages should not reveal which field conflicted. Reduces enumeration risk.

### Sensitive data audit checklist for shared dotfiles/config repos

Beyond secrets and tokens, audit for: internal project/repo names, MR/PR numbers that identify specific work, absolute paths with usernames, internal tool names, team names, and org-specific identifiers. These leak context about employer and work even without credentials.

- **Takeaway**: Scrub provenance markers (project names, MR refs) from learnings before publishing. `settings.local.json` is gitignored — focus effort on tracked files.

### Prefer exceptions over Optional returns for fatal errors

When an error is fatal and the caller can't meaningfully continue, raise an exception instead of returning `Optional`/`None`. Eliminates defensive null checks downstream and makes the return type non-optional.

- **Takeaway**: Fatal errors → exceptions. Reserve Optional/None for legitimate absence.

### Review summaries must accurately reflect changes

Superficial LGTMs with inaccurate summaries of what the PR actually implements are worse than no summary. Review summaries should describe the actual changes, not a paraphrase of the title.

- **Takeaway**: Verify your review summary matches the actual diff, not just the PR title.

### Two-step review: question placement, then request extraction

When reviewing code placement, first ask "does this need to be here?" with a concrete test (e.g., "does the added code use enough of ClassX to justify living there?"). Get analysis back, then decide whether to request extraction. Avoids premature refactoring requests.

- **Takeaway**: Question rationale before requesting architectural changes.

### Name features for what they actually do

If the implementation is a single train/test split (holdout validation), don't call it "walk-forward analysis." Aspirational naming creates confusion and technical debt. Name things for current behavior, not future intent.

- **Takeaway**: Feature names should describe current implementation, not aspirational scope.

### Remove cross-cutting concerns to separate PRs

When a tangential change (e.g., CLAUDE.md update) appears in a feature PR, split it out. Keep PRs scoped to their stated purpose.

- **Takeaway**: Tangential changes get their own PR, even if they're small.
