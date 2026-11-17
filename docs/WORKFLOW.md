# The Workflow

This is the full method. The seven phases are the spine; the master gate is
what every finding must pass before it becomes a report. Each phase has its own
file in `docs/phases/` with the concrete steps.

## Operating principle

The 2026 reality: submissions to the big platforms are up massively year over
year, only about a quarter are valid and exploitable, and triage queues are
flooded with scanner spray and low-quality AI output. The thing that gets paid
is a single **validated, high-impact, non-duplicate** report with a PoC that
reproduces. Volume is a liability. This workflow is tuned for that one report.

Two halves, always:
- **Automation does breadth.** Enumeration, probing, fingerprinting, template
  scans, drafts. Run wide, then rank. (Phase 3.)
- **You do the 10%.** Business logic, authorization, the odd behavior a scanner
  can't understand. This is where the money is. (Phase 4.)

## The 7 phases

### 1. Select — pick a target worth hunting
Choose by attack surface and freshness, not prestige or bounty size. Fresh
code, new features, newly-added scope, and multi-role apps (admin / manager /
member, free vs paid) score highest — that is where access-control gaps hide.
The hunters who earn have better recon on less-crowded surface, not better
exploits. → `docs/phases/1-select.md`

### 2. Learn — study the target BEFORE you scan
Read the program's disclosed reports (learn what's been found and how the team
thinks), map the tech stack, and threat-model the money and data flows. This is
your first duplicate defense and the phase most people skip.
→ `docs/phases/2-learn.md`

### 3. Recon — Discover → Enrich → Detect
Passive before active. Breadth before depth. Collect everything, scope-filter
at ingestion, then rank into a HOTLIST by business criticality. `bin/recon.sh`
runs the pipeline and re-filters every discovered host through the scope gate.
A scanner hit is a **lead**, not a bug. → `docs/phases/3-recon.md`

### 4. Hunt — manual, by class, deep not wide
Take the hotlist into manual testing. Pick one or two high-yield classes and go
deep (IDOR/access control + business logic is the best pair). Use two test
accounts and diff (A vs B). Apply the **sibling rule** and the **A→B signal**.
Time-box: no progress in 5 minutes, move on; 3 hours per area, then rotate.
→ `docs/phases/4-hunt.md` and `playbooks/`

### 5. Verify — the independent gate
Before you write anything, run `bin/verify.sh`. Its only job is to destroy false
positives before triage does: reproduced 3× from a clean state, baseline vs
exploit diffed, ≥80% confidence, PoC shows real impact, duplicate checked,
in-scope re-verified, honest severity with CVSS+CWE for High/Critical.
→ `docs/phases/5-verify.md`

### 6. Report — tight, concrete, reproducible
Title formula: `[Bug Class] in [Endpoint] allows [role] to [impact]`. Under 600
words. No theoretical language — state what an attacker *can* do. Always a PoC;
for IDOR show the victim's real data, not a 200. Never submit from the
never-submit list. Lint with `bin/report-lint.sh`. → `docs/phases/6-report.md`

### 7. Track — log it and learn the pattern
Record status through its lifecycle. After every confirmed bug, extract the
root cause into a one-line **detection rule** so you catch the same class
elsewhere (STÖK's "hack, learn, share"). Keep the tracking light — a system
that needs maintenance fails when you're busy. → `docs/phases/7-track.md`

## The master validation gate

No finding becomes a report until it passes all of these. `bin/verify.sh`
enforces the checkboxes; this is the human version.

1. **In scope.** The asset is in the live policy, re-verified today. Deny-first.
2. **Real, now.** An attacker can do this on the live target right now — not in
   theory, not in a lab only.
3. **Reproduced 3× cold.** From a clean state, three times, with baseline and
   exploit request/response pairs saved.
4. **Impact shown.** The PoC demonstrates real impact (victim data, state
   change, money), not just a status code.
5. **Not a duplicate.** Hacktivity, disclosed reports, and public writeups
   checked; your new angle named if a neighbor exists.
6. **Honest severity.** Only what you proved. High/Critical carry a CVSS vector
   and a CWE.
7. **Not on the never-submit list.** (`rules/never-submit.md`.)
8. **Siblings + A→B swept.** Every variant of the pattern checked; 20 minutes
   spent hunting the repeat of this bug before writing it up.

## The rules above every phase

See `rules/hunting-rules.md`. The short version:

- Scope first, deny-first, every action.
- Never hunt theoretical bugs. Kill weak findings in 30 seconds.
- Automation has the highest duplicate rate — manual finds the unique bugs.
- One actor is half a finding. Test accounts A and B, diff everything.
- Sibling rule: check every variant. A→B: the same mistake lives elsewhere.
- Never brute-force credentials/OTPs/tokens. Rate-limit everything; stop on 429.
- Never route around a safety stop — stop and reassess instead of switching
  tools to retry a blocked step.
- No secrets in this repo. Ever.
