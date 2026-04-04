Security patterns: certificate validation, trust stores, and SSL context configuration.
- **Keywords:** SSL, TLS, certificate, trust store, SSLContext, KeyStore, cert pinning, test security
- **Related:** ~/.claude/learnings/docker-security.md

---

### Replace trust-all-certs with cert-pinned SSLContext in tests

Even in test code, `TrustAllCerts` / no-op `TrustManager` implementations mask certificate rotation and validation issues that would surface in production. Load the actual test certificate into a `KeyStore`, build a proper `SSLContext` from it, and use that in test HTTP clients. This catches cert expiry, chain issues, and hostname mismatches during the test cycle rather than after deployment.
