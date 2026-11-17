# Phase 4 — Hunt (manual, by class, deep)

This is the 10% automation can't do, and where the money is. Take the HOTLIST
and your top flows from phase 2 into manual testing.

## How to work

- **Two accounts, always.** A and B, both yours. Run the same action as each
  and diff the responses. A difference in what each can see or do is the
  finding. One actor is half a finding.
- **Baseline first.** Capture the normal request/response before you change
  anything. You compare against this later (and it's your verify evidence).
- **One variable at a time.** Change one ID, one parameter, one role. Know
  exactly what caused a different response.
- **Pick one or two classes and go deep.** Don't spread across twelve. IDOR /
  access control + business logic is the best-paying, least-automatable pair.
- **One class across the whole app, not one page across all classes.** Sweep
  the entire application for a single class at a time — jumping between classes
  randomly misses the patterns that reveal systemic issues.
- **Collect gadgets; don't settle for Informative.** A low-impact primitive
  (open redirect, self-XSS, HTML injection, CORS, missing-CSRF, an SSRF entry
  point) is not a report and not trash — it's a rung. Note it and climb. See
  `docs/escalation-ladders.md`.

## The two multipliers

- **Sibling rule.** Found `/api/user/{id}/invoices`? Test `/orders`, `/files`,
  `/settings`; test `{id}±1`, a third tenant's id, the first id; test the old
  API version (`/api/v1/`) and the mobile API. Most handlers share a bug.
- **A→B signal.** The moment bug A is confirmed, **stop and spend 20 minutes**
  looking for the same mistake elsewhere before you write A up. The same
  developer pattern repeats across the codebase.

## Priority classes (highest yield in 2026)

1. **Broken Access Control / IDOR / BOLA** — the single most consistently
   rewarded class. → `playbooks/idor-bola.md`, `playbooks/access-control.md`
2. **Business logic** — hard to automate, human creativity wins, rising
   bounties. → `playbooks/business-logic.md`
3. **SSRF** (now part of Broken Access Control in OWASP 2025) →
   `playbooks/ssrf.md`
4. **Auth / session / OAuth / SAML** → `playbooks/auth-session.md`
5. **Race conditions / TOCTOU** — scanners can't find these →
   `playbooks/race-conditions.md`
6. **File upload / path traversal → RCE** — the most common bottom rung of RCE
   chains → `playbooks/file-upload-rce.md`
7. **XSS** — most-documented, most-crowded; win on escalation →
   `playbooks/xss.md`
8. **CSRF / CORS** — mostly gadgets; chain them to impact →
   `playbooks/csrf.md`, `playbooks/cors.md`
9. **Subdomain takeover** — recon-detectable, high-certainty →
   `playbooks/subdomain-takeover.md`
10. **SQLi** — rarer but high-value where it survives → `playbooks/sqli.md`
11. Less-saturated: cache poisoning, mobile, CI/CD, mass assignment, GraphQL
    abuse, HTTP request smuggling.

**Whatever class you pick, read `docs/escalation-ladders.md` first** — the bug
that pays is the chain to impact, not the primitive.

## Discipline

- **Time-box.** No progress in 5 minutes on a probe → move on. ~3 hours per
  area → rotate. Prevents rabbit-holing.
- **A scanner hit is a lead.** Reproduce it by hand and prove impact, or drop
  it.
- **Log as you go.** Every lead → `programs/<name>/notes.md` with its status.
  Every confirmed finding → a file from `templates/finding.md`.
- **Don't pull more data than the PoC needs.** Never exfiltrate real user data,
  never DoS, never social-engineer.

**Done when:** each priority flow is tested, and every anomaly is either a
written-up lead with a manual re-check or closed.
