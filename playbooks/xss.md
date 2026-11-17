# Cross-Site Scripting (XSS)

The most-documented class in public writeups (~46% of the corpus) — which makes
the basics the most-hunted and most-duplicated. Your edge here is **escalation
and context**, not another reflected alert box. CWE-79.

## Types & where they live

- **Reflected** — input echoed into the response unsanitized (search, error
  pages, parameters reflected in HTML/JS/attribute context).
- **Stored** — input persisted and rendered to others (profiles, comments,
  filenames, support tickets, admin panels that render user data).
- **DOM-based** — client-side sink (`innerHTML`, `document.write`, framework
  template) consuming a source (`location`, `postMessage`, URL fragment).
- **Blind** — stored input rendered somewhere you can't see (admin dashboards,
  logs, internal tools). Detect with an out-of-band callback payload.

## Method

1. Map every input → where it surfaces (HTML body, attribute, JS string, URL,
   JSON rendered to DOM). Context decides the payload.
2. Probe with a harmless marker first (a unique string), find where/how it's
   reflected or stored, then shape a context-appropriate proof.
3. For DOM XSS, trace source → sink in the JS (the recon JS-mining output helps).
4. For blind XSS, plant an OOB-callback payload in fields that reach staff views
   (names, support messages, user-agent, referrer) and wait.
5. Filter/WAF bypass is often the real work — case variation, encoding,
   alternate tags/events, split payloads. Use PayloadsAllTheThings as the
   reference rather than guessing.

## Escalate (don't stop at alert box)

This is where the money is (see `docs/escalation-ladders.md`):
- Reflected/stored XSS → steal session token / CSRF token → **act as the victim**.
- **Self-XSS → stored or ATO**: chain via CSRF or a login/clobbering trick so it
  fires in a victim context. Self-XSS alone is on the never-submit list.
- HTML injection → full XSS when you can break the context.
- XSS in an admin-rendered field → **privilege escalation** to admin.

## False positives

- Reflection inside a context that can't execute (already HTML-encoded, inside a
  non-rendered JSON API with correct content-type).
- A payload that only fires for yourself with no path to a victim (self-XSS) —
  that's a gadget, not a finding, until chained.
- CSP that actually blocks execution (test whether your vector runs).

## Proof

The payload executing in a **victim** context, and the impact shown (stolen
token used to act as them, admin action performed). For stored/blind, the
callback or the rendered execution where another user sees it.

## Detection rule to save

"Any input that later appears in a page → identify its output context and test
execution there; if it's self-only, park it as a gadget for a chain."
