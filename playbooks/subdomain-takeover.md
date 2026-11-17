# Subdomain takeover

High-certainty, recon-detectable, and often underrated on impact. A subdomain
points (dangling DNS) at a third-party service that's been deprovisioned; you
claim that service and now control content on a trusted subdomain. CWE-350.

## Trigger

A `CNAME` (or NS/A) record pointing to an external service that returns a
"not found / no such app / domain not configured" state — meaning the record is
live but the backing resource is gone and re-registrable.

## Commonly vulnerable backends (from the writeup corpus)

AWS S3 buckets, Shopify, Heroku, GitHub Pages, Hubspot, Pantheon, Wufoo,
Fastly, Zendesk, Readme, Surge, Netlify, Tumblr, and other "custom domain" SaaS.
Each has a known fingerprint page when unclaimed.

## Method

1. From recon, resolve every in-scope subdomain and capture CNAME targets
   (`dnsx -cname`). The `recon.sh` enrich stage flags dangling records.
2. For each dangling CNAME, fetch the host and match the service's
   "unclaimed/404" fingerprint.
3. Confirm the service lets you register that exact hostname (this is the
   takeover). **Claim it minimally** — enough to prove control (a benign marker
   page), never malicious content.

## Escalate (impact decides the bounty)

A bare takeover of a parked subdomain is low. Raise it (see
`docs/escalation-ladders.md`):
- **Session/cookie theft** if the parent domain scopes cookies to `*.domain`.
- **OAuth / redirect allowlist abuse** if the subdomain is a trusted redirect
  target.
- **Phishing / content spoofing** on a trusted domain (state it, don't execute
  against real users).
- Reading auth'd requests the app sends to that host.

## False positives

- The service returns 404 but won't actually let you register the name (not
  takeoverable).
- The subdomain is in use and the 404 is app-level, not service-level.
- Out-of-scope host — check scope first (`scope-gate.sh`).

## Proof

Your controlled marker served from the in-scope subdomain, plus the DNS record
showing the dangling pointer, plus the impact (cookie scope, redirect trust) if
you claimed one.

## Detection rule to save

"Every in-scope subdomain → resolve CNAME; any pointing at a SaaS with an
unclaimed fingerprint → takeover candidate; score it by the parent domain's
trust (cookies, OAuth)."
