# Phase 5 — Verify (the independent gate)

Before you write a single line of report, verify. This is a separate step with
one job: **destroy false positives before triage does.** Treat it as if a
different, skeptical person is checking your work — because that's what keeps
you out of the spam pile.

Run it: `bin/verify.sh programs/<name>/findings/<finding>.md`

## The gate (all must pass)

1. **Confirmed exploitable right now** on the live target. Not theoretical, not
   lab-only.
2. **Reproduced 3× from a clean state.** Fresh session/accounts each time. If it
   only works once, it isn't confirmed.
3. **Baseline vs exploit diffed.** Save both request/response pairs in
   `evidence/`. The diff *is* the proof.
4. **≥80% confidence.** If you're not 80% sure it's real and impactful, it's a
   lead, not a finding.
5. **PoC shows real impact.** Victim data, a state change, money moved — not a
   200 OK. For IDOR, the response must contain the victim's actual data.
6. **Duplicate checked.** Hacktivity + disclosed + public writeups. If a
   neighbor exists, name your new angle explicitly.
7. **In scope, re-verified today.** `bin/scope-gate.sh` on the asset.
8. **Honest severity, calibrated.** Only what you proved. High/Critical carry a
   CVSS:3.x vector and a CWE. If a live check contradicts an earlier read,
   correct the severity now.

## Why 3× cold

A bug that reproduces once might be a cache artifact, a race you got lucky on,
or residual state from your own session. Three clean reproductions rule that
out. This is the hydra verifier's bar, and it's the difference between a report
triage confirms in minutes and one they close as "cannot reproduce."

## If it fails

It goes back to phase 4, or it's dropped. **Nothing is filed on a failed
gate.** A dropped lead is cheap; a non-reproducing report costs you reputation
and costs the triager time.

**Done when:** `bin/verify.sh` exits clean (0 blockers) on the finding file.
