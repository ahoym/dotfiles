Next.js 16 migration patterns: proxy.ts convention, async dynamic route params, Turbopack gotchas, and rate limiter wiring.
- **Keywords:** Next.js 16, proxy.ts, middleware, Turbopack, dynamic route params, async params, rate limiter, token bucket, selectOption, route handler testing, Vitest
- **Related:** react-patterns.md, react-frontend-gotchas.md, testing-patterns.md, typescript-specific.md

---

## Next.js 16: `middleware.ts` → `proxy.ts`

In Next.js 16, `middleware.ts` is deprecated and renamed to `proxy.ts`. Key differences:

- Exported function must be named `proxy()` (not `middleware()`)
- File convention: Next.js auto-detects `proxy.ts` at project root or `src/proxy.ts`
- `config.matcher` pattern works identically
- Proxy runs on **Node.js runtime** (not Edge)
- A codemod is available for migration: `npx @next/codemod@latest middleware-to-proxy`
- Reference: https://nextjs.org/docs/app/api-reference/file-conventions/proxy

```typescript
// proxy.ts (project root)
import { NextRequest, NextResponse } from "next/server";

export function proxy(req: NextRequest) {
  // ... logic
  return NextResponse.next();
}

export const config = {
  matcher: "/api/:path*",
};
```

## Dynamic Route Params Are Async

In Next.js 16, dynamic route params are `Promise<{...}>` — they must be `await`ed. Breaking change from earlier App Router versions where params were synchronous objects. Forgetting `await` causes a runtime error (not always a type error).

Page component:
```typescript
export default async function Page({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
}
```

Route handler:
```ts
export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ address: string }> },
) {
  const { address } = await params;
}
```

## Turbopack Gotchas

### JSX requires `.tsx` extension

Turbopack rejects JSX in `.ts` files with a misleading parse error. Rename to `.tsx`.

### React 19 Context shorthand not supported

`<Context value={}>` shorthand fails under Turbopack with "Expected '>', got 'ident'" — use `<Context.Provider value={}>`.

### Dev server may miss new API routes

New API route files added while the dev server is running may not be detected — results in a Next.js 404 (HTML response instead of JSON). Fix by clearing `.next` and restarting.

## Rate Limiter Wiring Pattern via `proxy.ts`

Pattern for wiring a token-bucket rate limiter through the Next.js 16 proxy:

- **Tiered limits**: Define tiers by operation cost (e.g., STRICT for expensive/destructive ops, MODERATE for mutations, RELAXED for reads)
- **IP extraction**: `x-forwarded-for` → `x-real-ip` → `"unknown"` fallback
- **Bucket key**: `${ip}:${method}:${pathname}` — keeps GET/POST limits independent per route
- **Response**: 429 with `Retry-After` header (seconds until next token available)
- **Scope**: `config.matcher = "/api/:path*"` to only intercept API routes
- **Memory model**: In-memory Map persists across requests within a serverless isolate. Not globally distributed, but a meaningful first layer.

```typescript
function getTier(pathname: string, method: string) {
  if (strictRoutes.has(`${method}:${pathname}`)) return STRICT;
  if (method === "POST") return MODERATE;
  return RELAXED;
}
```

## Testing Route Handlers Directly (No Server Required)

Route handlers are plain async functions — import and call directly in Vitest without spinning up the server. See `testing-patterns.md` § "Route Handler Test Structure" for the full pattern including `vi.hoisted()` mock setup, import ordering, and dynamic route `Promise.resolve()` params.

## Cross-Refs

- `react-patterns.md` — hydration, hooks, component patterns
- `react-frontend-gotchas.md` — condensed Next.js and React tripwires
- `testing-patterns.md` — route handler testing
- `typescript-specific.md` — generic TypeScript patterns (union type extension moved here)
