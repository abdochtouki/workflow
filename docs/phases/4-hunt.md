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
6. Less-saturated: cache poisoning, mobile, CI/CD, mass assignment, file
   upload, GraphQL abuse.

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
