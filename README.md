# workflow

A portable, program-agnostic bug bounty workflow. It merges the best public
methodologies (Jason Haddix's TBHM, NahamSec, STÖK, zseano, Corben Leo,
reconftw, the ProjectDiscovery Discover→Enrich→Detect pipeline, and several
agentic hunting repos) into one disciplined loop with scripts you can run
anywhere.

It is built around a single idea for 2026: **the bottleneck is the triage
queue, not discovery.** Scanners produce thousands of low-value submissions a
minute, and platforms now reward the one validated, high-impact, non-duplicate
report over volume. So every phase here optimizes for *that* report.

## The loop

```
1 SELECT  →  2 LEARN  →  3 RECON  →  4 HUNT  →  5 VERIFY  →  6 REPORT  →  7 TRACK
  pick a      study the    map the     prove it    kill false   write it     log it,
  target      target       surface,    by hand     positives    <600 words   learn the
  worth it    FIRST        hotlist it   (A vs B)    (3x cold)    tight PoC    detection rule
```

Automation does **breadth** (phase 3). You do the **10%** that pays — business
logic and access control (phase 4). Everything else is a gate that keeps junk
out of your reports.

## Quick start

```bash
# 1. scaffold a program
bin/new-program.sh Acme

# 2. fill scope from the LIVE policy page (never from memory)
#    edit programs/Acme/assets.txt  and  programs/Acme/scope.md

# 3. LEARN before you scan — read docs/phases/2-learn.md, study disclosed reports

# 4. recon (passive-first, scope-filtered at every step, writes a HOTLIST)
bin/recon.sh programs/Acme acme.com

# 5. hunt the hotlist by hand (docs/phases/4-hunt.md + the playbooks/)

# 6. before writing anything, verify the finding
bin/verify.sh programs/Acme/findings/my-bug.md

# 7. lint the report before you submit
bin/report-lint.sh programs/Acme/report-draft.md
```

Every script is plain `bash`, needs no root, and skips any recon tool you
don't have installed (it never fakes output). Install the optional tools for
full recon — see `wordlists/README.md` and `docs/phases/3-recon.md`.

## Layout

| Path | What |
| ---- | ---- |
| `docs/WORKFLOW.md` | The full method: the 7 phases + the master validation gate. |
| `docs/phases/` | One file per phase, with the concrete steps. |
| `docs/escalation-ladders.md` | The gadget-chaining model — how low primitives become critical impact. |
| `docs/writeup-study.md` | How to mine public writeups into reusable detection rules. |
| `docs/sources.md` | Every idea traced to its source. |
| `rules/` | Hunting rules, the never-submit list, scope rules. |
| `playbooks/` | Per-class recipes: IDOR, access control, business logic, SSRF, auth, race, XSS, CSRF, CORS, subdomain takeover, file-upload→RCE, SQLi. |
| `templates/` | `finding.md`, `report.md` — the formats the scripts lint. |
| `programs/_template/` | Copy this per program (`bin/new-program.sh`). |
| `bin/` | `scope-gate` · `recon` · `verify` · `report-lint` · `new-program`. |
| `skills/` | Claude Code skills that automate a phase. `js-analyze`: full JS recon (discover → analyze) into an MD report + curl commands. |
| `wordlists/` | Starter wordlists + setup notes. |

## The non-negotiables

- **Scope is a gate on every action, not a one-time check.** One out-of-scope
  request can get you banned. `bin/scope-gate.sh` is deny-first and runs before
  every host you touch; `recon.sh` re-filters every discovered subdomain
  through it.
- **No proof, no report.** A theoretical bug is wasted time. Ask: *can an
  attacker do this right now?*
- **Verify cold, 3 times, before writing.** A separate gate (`verify.sh`) whose
  only job is to destroy false positives before triage does.
- **Manual depth beats tool breadth.** Automation has the highest duplicate
  rate. Your edge is the business logic and access-control testing scanners
  can't do.
- **Honest severity. Reports under 600 words. Never submit from the
  never-submit list.**

See `docs/sources.md` for attribution. Study the originals — this repo is the
synthesis, not a substitute for them.
