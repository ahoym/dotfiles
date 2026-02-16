# Browser Security Learnings

## localStorage Encryption Tradeoffs for Wallet Apps

### What localStorage encryption protects against
- Malicious browser extensions reading storage
- Shoulder surfing via DevTools → Application → localStorage
- XSS exfiltration (attacker gets ciphertext, not usable seed)
- Forensic extraction from browser profiles/backups

### What it does NOT protect against
- Active XSS while wallet is unlocked (seed lives in JS heap)
- Keyloggers capturing the encryption password
- Memory dumps of the running process
- Supply chain attacks on the app itself

### Key UX tradeoff
Encrypting localStorage requires a password prompt on every app load (for seed-type wallets). Wallet adapter integrations (Crossmark, GemWallet, Xaman) sidestep this entirely since seeds never touch the app.

### Export encryption has better ROI than localStorage encryption
- Exported JSON files leave the browser's security boundary (saved to disk, synced to cloud, emailed, backed up)
- localStorage is at least origin-scoped and ephemeral (clear browser data = gone)
- Export encryption can be opt-in (no UX friction for users who skip it)
- Implementation uses Web Crypto API (AES-GCM + PBKDF2) — zero new npm dependencies

### Decision framework
If the app supports wallet adapter integrations as the secure path, encrypting localStorage adds UX friction for marginal security gain. Focus encryption efforts on exported files (higher-risk artifact) and push users toward wallet adapters for mainnet use.
