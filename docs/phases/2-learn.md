# Phase 2 — Learn (before you scan)

The phase most hunters skip, and the best duplicate defense you have. Spend
real time here before touching the target with a tool.

## Read the program's disclosed reports

- Go through Hacktivity / disclosed reports for this program.
- Learn **what's already been found** (so you don't re-file it) and, more
  importantly, **how the security team thinks** — which classes they pay well,
  which they downrate, what they've hardened.
- Note the endpoints and patterns that produced bugs; the sibling of a fixed
  bug is often still open.
- Run each report through the 10-question template in `docs/writeup-study.md`
  and keep the one-line detection rule. Reading reports without extracting
  rules is just reading.

## Study the class, not just the program

Before you hunt a class on this target, read 10–20 public writeups of that
class back to back — patterns only jump out in bulk. Aim where the crowd isn't:
public writeups are ~46% XSS and heavy on RCE/CSRF/SQLi, while **IDOR, access
control, and business logic are under-documented — meaning less crowded and
fewer duplicates.** Full breakdown and the study loop: `docs/writeup-study.md`.

## Map the tech stack

- Frameworks, languages, cloud provider, auth provider (OAuth/OIDC/SAML), API
  style (REST / GraphQL), mobile apps.
- Known CVEs for that stack and version → candidate leads for phase 3/4.
- Where the JavaScript lives (SPA? which bundler?) — you'll mine it in recon.

## Threat-model the money and data flows

Draw the flows that matter to the business:
- Who can pay / move money / change a plan? (business logic gold)
- Where does one user's data become reachable by an ID? (IDOR gold)
- Where does the server fetch a URL you control? (SSRF)
- Where do roles/permissions get decided, and can the client influence them?

Rank the flows. These become your hunting priorities, ahead of whatever recon
spits out.

## Duplicate Radar

Before you commit a direction, check that it isn't already disclosed. A lead
that's a near-certain duplicate scores low no matter how fresh — park it.

**Done when:** you can describe, in a paragraph in `programs/<name>/notes.md`,
what the target does, how it's built, what's already been found, and your top
3 flows to attack.
