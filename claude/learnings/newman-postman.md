# Newman / Postman Patterns

Newman/Postman runtime gotchas: skipRequest sync-only behavior, conditional assertions for idempotent seeding, export-environment manifests, and collection rebase conflicts.
**Keywords:** Newman, Postman, skipRequest, pm.execution, pm.sendRequest, export-environment, idempotent seeding, JSON merge, collection rebase, env-var
**Related:** local-dev-seeding.md

---

## `pm.execution.skipRequest()` — synchronous only

`pm.execution.skipRequest()` works in pre-request scripts but **only synchronously**. Inside async `pm.sendRequest()` callbacks it fires too late — Newman already sent the main request.

**Works (synchronous env var check):**
```javascript
var existing = pm.environment.get('RESOURCE_ID');
if (existing) {
    console.log('Already set: ' + existing + ' (skipping)');
    pm.execution.skipRequest();
}
```

**Doesn't work (async race condition):**
```javascript
pm.sendRequest({ url: '...', method: 'GET' }, function(err, res) {
    pm.execution.skipRequest(); // Too late — main request already sent
});
```

**Best pattern for idempotent seeding:** Pre-query IDs in the calling shell script (via API) and pass as `--env-var` to Newman. Then use synchronous `pm.environment.get()` checks in pre-request scripts.

## Newman can't skip requests — use conditional assertions

When `skipRequest()` isn't viable (async checks needed), use conditional assertions instead. When a resource may already exist (re-runs):

1. **Pre-request script**: detect existing state via env var, generate non-conflicting data (e.g., orphan tenant name) so the unavoidable request doesn't break state
2. **Test script**: check if the resource was pre-set, conditionally pass assertions and preserve the original ID instead of overwriting from the response

```javascript
// Pre-request: avoid conflicts on re-run
var existingId = pm.environment.get('RESOURCE_ID');
if (existingId) {
    pm.environment.set('TENANT', 'orphan-' + uuid.v4().substring(0,8));
} else {
    pm.environment.set('TENANT', derivedTenantName);
}

// Test: preserve pre-set ID
if (pm.environment.get('RESOURCE_ID')) {
    tests['Reused existing'] = true;
} else {
    tests['Created'] = responseCode.code === 201;
    pm.environment.set('RESOURCE_ID', JSON.parse(responseBody).id);
}
```

## Newman `--export-environment` as a Manifest Bridge

Use `--export-environment` to capture all IDs created during a Newman seeding run. The exported JSON becomes a manifest for downstream tooling (SQL seeding, validation scripts, CI).

```bash
newman run collection.json \
  --folder "Seed Data" \
  --export-environment .local-seeded.json

# Extract IDs for downstream use (e.g., envsubst into SQL templates)
while IFS='=' read -r key value; do
  export "$key=$value"
done < <(jq -r '.values[] | select(.value != "") | "\(.key)=\(.value)"' .local-seeded.json)
```

Each Postman test script chains IDs via `pm.environment.set("ENTITY_ID", data.id)` so subsequent requests and the final export both see them.

## Postman Collection Rebase Conflicts from Indentation Changes

When a branch re-exports a Postman collection with different indentation (2-space → tabs or vice versa), git treats the entire file as changed. Every subsequent commit touching the collection will produce a whole-file conflict during rebase.

**Root cause:** Postman's export format isn't stable — different Postman versions or export methods produce different whitespace. Git's line-based diff can't match any lines between the two indentation styles.

**Solution:** Use programmatic JSON merge (see `git-patterns.md` → "Programmatic JSON Merge for Rebase Conflicts"). Normalize both versions through `json.loads()`, diff semantically, and reconstruct the merged output.

## Cross-Refs

- `local-dev-seeding.md` — hybrid API + SQL seeding architecture using Newman as the API seeding layer
