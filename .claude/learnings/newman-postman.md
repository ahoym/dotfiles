# Newman / Postman Patterns

## Newman can't skip requests — use conditional assertions

You cannot conditionally skip an HTTP request in Newman. When a resource may already exist (re-runs):

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
