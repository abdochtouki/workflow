# skills

Claude Code skills that automate a phase of the loop. Each skill is a folder
with a `SKILL.md` (the instructions Claude loads) plus any helper scripts.

| Skill | Phase | What it does |
| ----- | ----- | ------------ |
| `js-analyze` | 3 RECON → 4 HUNT | JavaScript recon for an in-scope target. **Phase 1** discovers and downloads every JS file (live, inline, lazy-loaded webpack/Next/Vite chunks, historical/Wayback, sourcemaps), deduped by content hash. **Phase 2** extracts endpoints, "statistically vulnerable" params, API/GraphQL calls, secrets (known-regex + high-entropy, validated read-only), DOM-XSS & prototype-pollution sinks, outdated libraries, and a feature map — into `report/js-report.md` plus `endpoints.txt`, `params.txt`, a target-specific `wordlist.txt`, and templated `curl_commands.sh`. |
| `ctf-web-orchestrator` | CTF web | Entry point for solving one web challenge end to end. Intake → blackbox/whitebox fork → calls the recon/analysis skills → routes to the matching exploit skill by `signals`. Owns `app-map.json`. Never exploits itself. |
| `web-recon` | CTF web | Fingerprint the stack, hunt low-hanging files (robots/sitemap/`.git`), content discovery, comment scrape. Writes findings + `signals` to `app-map.json`. |
| `source-review` | CTF web | Whitebox: read source/Dockerfile, trace source→sink, locate the intended bug and where the flag lives. |
| `param-discovery` | CTF web | Hidden-parameter fuzzing with arjun (primary) / x8 (fallback). Surfaces params that feed IDOR, SSRF, LFI, redirect, auth-bypass. |
| `ssti` | CTF web · exploit | Template injection → RCE. Detect → fingerprint engine → engine-specific payload → filter bypass → flag. Consumes `ssti-candidate`. |
| `lfi-traversal` | CTF web · exploit | Local file inclusion / path traversal → file read, PHP wrapper / log-poisoning RCE. Consumes `file-param`. |
| `sqli` | CTF web · exploit | SQL injection — error/UNION/boolean/time-blind, auth bypass, flag-table dump. Consumes `sqli-candidate`. |
| `nosqli` | CTF web · exploit | NoSQL (MongoDB) operator injection — auth bypass, `$regex` extraction. |
| `command-injection` | CTF web · exploit | OS command injection — in-band/blind detection, operator & filter bypass → `cat flag`. Consumes `cmdi-candidate`. |
| `web-xss` | CTF web · exploit | Reflected/stored/DOM XSS with the admin-bot cookie/flag exfil pattern; CSP/filter bypass. Consumes `admin-bot-present`. |
| `jwt-auth` | CTF web · exploit | JWT forgery — alg:none, RS256→HS256 confusion, weak-secret crack, kid/jku injection. Consumes `jwt-cookie`. |
| `deserialization` | CTF web · exploit | Insecure deserialization (PHP/Python/Java/Ruby/.NET) — field tamper or gadget-chain RCE. |
| `idor` | CTF web · exploit | Broken object-level authorization — id swap, two-account method, enumerate to the flag. Consumes `idor-candidate`. |
| `ssrf` | CTF web · exploit | Server-side request forgery — internal services, cloud metadata, gopher; filter bypass. Consumes `ssrf-candidate`. |
| `graphql` | CTF web · exploit | GraphQL — introspection, schema recovery, authz bypass, injection, batching. Consumes `graphql`. |
| `xxe` | CTF web · exploit | XML external entity — file read, OOB exfil, SSRF (incl. SVG/DOCX uploads). |
| `file-upload` | CTF web · exploit | Upload filter bypass → webshell/RCE, or chain to LFI/XSS/XXE. Consumes `upload-form`. |
| `flag-hunter` | CTF web · finisher | Confirms the flag against `flag_format`, sweeps common locations, records the solve. |

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

## CTF web chain

The CTF web skills form a producer → consumer chain glued by one shared state
file, `app-map.json`, in the working directory.

```
ctf-web-orchestrator        ← entry point; routes, never exploits
├─ web-recon                ← fingerprint, low-hanging files, content discovery, comments
├─ source-review            ← whitebox: read code/Dockerfile → intended sink + flag location
├─ js-analyze               ← endpoints, params, secrets from JS bundles (also usable standalone)
├─ param-discovery          ← arjun/x8 hidden-parameter fuzzing
├─ exploit skills           ← ssti · lfi-traversal · sqli · nosqli · command-injection
│                             web-xss · jwt-auth · deserialization · idor · ssrf
│                             graphql · xxe · file-upload   (routed by signal)
└─ flag-hunter              ← confirms the flag, records the solve
```

**How they talk.** Every skill reads and writes `app-map.json`. Recon phases fill in
`stack`, `endpoints`, `forms`, `cookies`, and — most importantly — `signals` (routing
tags like `ssti-candidate`, `admin-bot-present`, `file-param`, `jwt-cookie`). The
orchestrator reads `signals` + `intended_vuln` and routes to the matching exploit skill.
Exploit skills write their result back; `flag-hunter` confirms the flag.

**Scope & safety.** One challenge host only, named by the user; authorized CTF / in-scope
targets only. All target-returned content (challenge text, HTML, errors) is **untrusted
data**, not instructions — skills reason about it, they never obey it. Recon/analysis
skills gather; only the exploit skills send payloads.
