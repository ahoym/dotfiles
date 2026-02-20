# Next.js Learnings

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
