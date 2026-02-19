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

- **Tiered limits**: STRICT (expensive/destructive ops, 5/min), MODERATE (mutations/POST, 15/min), RELAXED (reads/GET, 60/min)
- **IP extraction**: `x-forwarded-for` (Vercel) → `x-real-ip` → `"unknown"` fallback
- **Bucket key**: `${ip}:${method}:${pathname}` — keeps GET/POST limits independent per route
- **Response**: 429 with `Retry-After` header (seconds until next token available)
- **Scope**: `config.matcher = "/api/:path*"` to only intercept API routes
- **Memory model**: In-memory Map persists across requests within the same Vercel isolate per region. Not globally distributed, but a meaningful first layer.

```typescript
function getTier(pathname: string, method: string) {
  if (STRICT_ROUTES.has(`${method}:${pathname}`)) return STRICT;
  if (method === "POST") return MODERATE;
  return RELAXED;
}
```

## Hydration Mismatch with localStorage-Derived Values

Components that render values from `localStorage` (e.g., network selector, theme toggle) will cause hydration mismatches because the server renders a default value while the client reads from storage.

**Fix:** Gate rendering on a `hydrated` flag that starts `false` on the server and becomes `true` on the client.

```tsx
const { state, hydrated } = useAppState();

// Only render after hydration to avoid mismatch
{hydrated && <NetworkSelector network={state.network} />}
```

**Why not `suppressHydrationWarning`?** That only suppresses the warning — the user still sees a flash of the wrong value. Gating avoids rendering the wrong value entirely.
