# CORS misconfiguration

A permissive cross-origin policy lets an attacker's page read authenticated
responses from the target — turning "I can read your data from my site" into
token theft and account takeover. CWE-942.

## Trigger

An endpoint that returns sensitive data to authenticated users and sets
`Access-Control-Allow-Origin` dynamically, especially with
`Access-Control-Allow-Credentials: true`.

## Method

1. Find authenticated JSON/data endpoints (API, account, settings, tokens).
2. Replay the request with an `Origin:` header you control and inspect the
   response's `Access-Control-Allow-Origin`:
   - **Reflects your origin** + `Allow-Credentials: true` → exploitable.
   - **`null`** accepted + credentials → exploitable (sandboxed iframe origin).
   - **Weak regex**: `target.com.evil.com`, `eviltarget.com`, trailing-dot, or
     a sibling subdomain accepted → exploitable depending on the match.
3. Prove it: a page on your origin makes a credentialed `fetch` and reads the
   response body (the victim's data).

## Escalate

- Read the victim's profile/API response → extract **session token / API key /
  CSRF token** → **account takeover** (see `docs/escalation-ladders.md`).
- CORS on an out-of-scope host that returns in-scope data → report the in-scope
  impact.
- Chain: CORS read of a CSRF token → CSRF on a protected action.

## False positives

- `Allow-Origin: *` **without** `Allow-Credentials` on a non-sensitive, public
  endpoint — browsers block credentialed reads, so no real impact.
- The reflected origin is on a strict allowlist you can't satisfy.
- Response contains nothing sensitive.

## Proof

Your attacker page (different origin) reading the victim's authenticated
response — show the retrieved sensitive fields, not just the headers.

## Detection rule to save

"Any credentialed data endpoint → replay with a foreign `Origin`; if it's
reflected (or `null`) with `Allow-Credentials: true`, prove a cross-origin read
of sensitive data."
