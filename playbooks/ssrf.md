# SSRF (Server-Side Request Forgery)

Part of Broken Access Control in OWASP 2025 — the server makes a request on the
attacker's behalf to a resource it shouldn't. CWE-918. High impact when it
reaches cloud metadata or internal services.

## Trigger

Any feature where the server fetches a URL you influence: webhooks, URL
previews/unfurls, image/file import by URL, PDF/HTML renderers, "import from
URL", integrations, avatar-by-URL, SSO metadata URLs, document converters.

**Most common entry points in the writeup corpus:** image resizers/processors,
PDF generators, webhooks, `ffmpeg`/media processing, and "upload/import from
URL". Media and document processors are the highest-signal place to start.
Techniques that recur: DNS rebinding, `gopher://` to reach non-HTTP services,
and open-redirect-assisted filter bypass (see `docs/escalation-ladders.md`).

## The exact test

1. Point the parameter at a collaborator you control (self-hosted
   `interactsh` / Burp Collaborator). A DNS or HTTP callback = server-side
   fetch confirmed.
2. Escalate toward impact:
   - Cloud metadata: `http://169.254.169.254/latest/meta-data/` (AWS),
     `http://metadata.google.internal/` (GCP) — read creds/tokens.
   - Internal services: `http://localhost:<port>/`, `http://127.0.0.1/`,
     internal hostnames from recon.
   - Scheme abuse: `file://`, `gopher://`, `dict://` where the fetcher allows.
3. Bypass filters (common): decimal/octal/hex IP, `[::]`, `127.0.0.1.nip.io`,
   redirect from an attacker URL to the internal target, DNS rebinding.

## Blind vs full-read

- **Blind SSRF** (callback only, no response body) is still reportable — prove
  the server fetched your URL. Impact depends on what you can reach.
- **Full-read SSRF** (response reflected back) is far higher impact — show the
  internal/metadata content retrieved.

## Safety

Do **not** hammer internal ranges or pull large internal data. Prove reach and
one piece of impact, then stop. Never DoS.

## False positives

- A client-side fetch (the browser made the request, not the server).
- A fetch that only resolves public URLs and blocks everything internal
  (filter working).

## Proof

The collaborator callback from the target's infrastructure, plus the retrieved
internal/metadata content for full-read. For blind, the server-side origin of
the callback.

## Detection rule to save

"Any 'fetch a URL' feature → collaborator test first, then metadata/internal,
then filter bypasses."
