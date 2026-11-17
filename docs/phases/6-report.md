# Phase 6 — Report

Triage queues are flooded. A tight, concrete, reproducible report is how you
get paid fast and build the researcher reputation that earns private invites.
The bar beneath all the AI-spam noise is unchanged: **clear steps to reproduce
+ demonstrated impact.**

Start from `templates/report.md`. Lint with `bin/report-lint.sh`.

## The rules

- **Title formula:** `[Bug Class] in [Endpoint] allows [role] to [impact]`.
  e.g. "IDOR in /api/invoices allows any user to read other tenants' billing
  data".
- **Under 600 words.** The report is the repro and the impact, not an essay.
- **No theoretical language.** Never "could", "may", "potentially". State what
  an attacker *can* do: "An attacker can X by Y."
- **Always a PoC.** Exact request/response. For IDOR, show the **victim's real
  data**, not a 200 OK.
- **Demonstrate impact, and elevate it with proof.** Triage scores on
  demonstrated real-world impact; if you can prove a bigger impact, show it —
  researchers are rewarded for it. But never overclaim beyond the proof.
- **Honest severity** with a justified CVSS vector and a CWE for High/Critical.
- **Never submit from the never-submit list** (`rules/never-submit.md`) unless
  it's a proven link in a chain — then title by the chain's impact.

## Structure (from `templates/report.md`)

1. **Title** — the formula.
2. **Summary** — 2–3 sentences: what, who, what they gain.
3. **Severity** — rating, CVSS, CWE, asset, version.
4. **Steps to reproduce** — prerequisites (accounts A/B), numbered steps,
   expected vs actual.
5. **Proof of concept** — the request/response that proves it.
6. **Impact** — concrete, proven.
7. **Remediation** — a concrete fix (speeds triage and resolution).
8. **References** — prior art / CWE.

## One report per root cause

Group same-root-cause endpoints into one report. Don't split a systemic bug
into ten (and don't stockpile bugs to build a mega-chain — file clean impactful
findings as you confirm them).

## Before you submit

```bash
bin/report-lint.sh programs/<name>/report-draft.md
```

Fix the blockers, consider the warnings, then submit through the program's
route. Record the report ID and date back in the finding file and
`scope.md`.

**Done when:** the report is submitted and its ID + status are recorded.
