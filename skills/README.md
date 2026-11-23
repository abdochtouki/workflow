# skills

Claude Code skills that automate a phase of the loop. Each skill is a folder
with a `SKILL.md` (the instructions Claude loads) plus any helper scripts.

| Skill | Phase | What it does |
| ----- | ----- | ------------ |
| `js-analyze` | 3 RECON → 4 HUNT | JavaScript recon for an in-scope target. **Phase 1** discovers and downloads every JS file (live, inline, lazy-loaded webpack/Next/Vite chunks, historical/Wayback, sourcemaps), deduped by content hash. **Phase 2** extracts endpoints, "statistically vulnerable" params, API/GraphQL calls, secrets (known-regex + high-entropy, validated read-only), DOM-XSS & prototype-pollution sinks, outdated libraries, and a feature map — into `report/js-report.md` plus `endpoints.txt`, `params.txt`, a target-specific `wordlist.txt`, and templated `curl_commands.sh`. |

## Using one

In Claude Code, invoke by name (`js-analyze`) or let it trigger from its
description. It respects the repo's non-negotiables: **scope is a gate on every
request**, no CAPTCHA bypass, and leaked keys are validated with read-only
identity calls only — never used to read data or pivot. Output goes under a
program's `recon/` (gitignored), so live hunting data is never committed.

### js-analyze helper

`skills/js-analyze/jsluice2curl.py` — turns `jsluice urls` JSONL into deduped
curl commands with `FUZZ` placeholders, plus `endpoints.txt` and `params.txt`:

```bash
find raw pretty -name '*.js' | jsluice urls -R https://target.com > urls.jsonl
python3 -I skills/js-analyze/jsluice2curl.py urls.jsonl https://target.com report/
```
