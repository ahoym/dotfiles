# XRPL Permissioned Domains & Credentials

Permissioned domains (XLS-80), credentials (XLS-70), and proposed permissioned DEX (XLS-81) on the XRP Ledger.
**Keywords:** XLS-70, XLS-80, XLS-81, CredentialCreate, CredentialAccept, PermissionedDomainSet, AcceptedCredentials, DomainID, tfHybrid, AuthorizeCredential
**Related:** xrpl-patterns.md, xrpl-gotchas.md, xrpl-dex-data.md

---

## Status

- **Credentials (XLS-70)** — Activated on mainnet
- **Permissioned Domains (XLS-80)** — Activated on mainnet February 4, 2026
- **Permissioned DEX (XLS-81)** — Proposed, not yet activated. Depends on XLS-80.

## Three Independent Roles

The permissioned domain system involves three roles that are completely independent:

1. **Currency Issuer** — Issues tokens (Payment). No relationship to domains or credentials.
2. **Credential Issuer** — Attests identity (CredentialCreate/Delete). Referenced by domain's AcceptedCredentials.
3. **Domain Owner** — Creates trading environments (PermissionedDomainSet/Delete). References credential issuers.

**"Issuer" is overloaded**: In `AcceptedCredentials[].Issuer`, "Issuer" means the credential issuer, NOT the currency issuer.

## What Each Layer Controls

- **WHAT gets traded** — Controlled by Currency Issuers + Trust Lines. Domains have NO say.
- **WHO can trade** — Controlled by Domains + Credentials. Only accounts with valid credentials can participate.
- **WHERE matching happens** — Controlled by DomainID on OfferCreate. Each domain has its own isolated order book.

## Credentials (XLS-70)

On-chain attestations (e.g., KYC verification) stored as ledger objects.

### Lifecycle

1. **Create** — Issuer submits `CredentialCreate` → exists but NOT yet valid
2. **Accept** — Subject submits `CredentialAccept` → `lsfAccepted` flag set, credential becomes valid; reserve transfers to subject
3. **Delete** — Either party can delete. Anyone can delete expired credentials.

### Key Fields

- `Subject` — Account the credential is about
- `CredentialType` — Hex-encoded type identifier (max 64 bytes, variable-length hex)
- `Expiration` — Optional, seconds since Ripple Epoch
- `URI` — Optional link to off-chain data (max 256 bytes)

A credential is valid only when `lsfAccepted` is true AND not expired.

## Permissioned Domains (XLS-80)

### AcceptedCredentials

Array of 1-10 entries, each with `Issuer` (credential issuer) and `CredentialType` (hex). **OR logic**: an account needs only ONE matching credential to be a member.

### Membership

Automatic — if you hold an accepted credential, you're in. No explicit "join" needed. Domain owner does NOT need a credential themselves.

### PermissionedDomainSet

Creates or modifies a domain. Omit `DomainID` to create; include to modify. `AcceptedCredentials` must have 1-10 entries.

## Permissioned DEX (XLS-81) — Proposed

Extends the DEX with credential-gated order books. Each domain gets its own separate order book — strictly separated from open DEX and other domains.

### Matching Rules

| Scenario | Allowed? |
|---|---|
| Same-domain offers | Yes |
| Different-domain offers | No |
| Permissioned + open offers | No |

### xrpl.js Support

- `OfferCreate.DomainID` — optional field for permissioned offers
- `OfferCreateFlags.tfHybrid` — offer in both domain + open book
- `BookOffersRequest.domain` — optional filter for domain-specific books
- `AuthorizeCredential` — nested type for AcceptedCredentials entries

Sources: [XLS-80](https://xls.xrpl.org/xls/XLS-0080-permissioned-domains.html), [XLS-81d](https://github.com/XRPLF/XRPL-Standards/discussions/229), [Credentials concept](https://xrpl.org/docs/concepts/decentralized-storage/credentials)

## Cross-Refs

- `xrpl-patterns.md` — DomainID typing gaps, book_offers domain param, funded offer fields
- `xrpl-gotchas.md` — DomainID availability (account_objects vs account_offers)
- `xrpl-dex-data.md` — native DEX protocol reference, OfferCreate flags, order book mechanics
