---
name: param-discovery
description: >
  Finds hidden/undocumented HTTP parameters on a CTF web challenge (or an authorized,
  in-scope target) that the app accepts but never links or shows. Hidden params expand
  the attack surface and are a common CTF path — they feed IDOR, SSRF, LFI, open-redirect
  and authorization-bypass bugs. USE THIS SKILL when endpoints are known but their
  parameters are thin or unknown, or when a solve is stuck and you need more surface.
  Trigger on: "find hidden parameters", "param discovery", "fuzz parameters for [url]",
  "what params does this endpoint take", or as a phase called by ctf-web-orchestrator
  after recon. It discovers params; it does not exploit them. Writes results to app-map.json.
---

# param-discovery

Apps accept parameters they never advertise — debug flags, admin toggles, object refs,
URL fetchers. Finding them often unlocks the challenge. This skill brute-forces parameter
names against known endpoints and records the ones the app actually reacts to. It finds;
the exploit skills abuse.

## Input / output

- **Input:** the `endpoints` list in `./app-map.json` (from web-recon / js-analyze /
  source-review). If there are none yet, run against the base URL and any obvious paths.
- **Output:** for each endpoint, add discovered params to its `params` array in app-map,
  and add a routing `signal` when a found param smells like a bug class (see step 4).

## Tooling

`arjun` is the primary (Python; richer JSON output and response-diffing). `x8` is the
fallback (Rust; faster on huge wordlists and flexible for body/header params). Pick arjun
by default; reach for x8 on large wordlists or when fuzzing JSON-body/header params.

```bash
# install hint (if missing): pipx install arjun   |   cargo install x8
```

## Step 1 — Discover on each endpoint

**arjun** (GET, then POST where a form/JSON endpoint exists):
```bash
arjun -u "http://TARGET/ENDPOINT" -oJ arjun.json            # GET
arjun -u "http://TARGET/ENDPOINT" -m POST -oJ arjun_post.json
arjun -u "http://TARGET/ENDPOINT" --headers "Cookie: SESSION=..."   # authed endpoints
```
Feed a whole list at once with `-i urls.txt` (one endpoint per line, built from app-map).

**x8** fallback / large wordlist / body & header params:
```bash
x8 -u "http://TARGET/ENDPOINT" -w params.txt -o x8.txt
x8 -u "http://TARGET/ENDPOINT" -w params.txt --as-body -t json   # JSON body params
x8 -u "http://TARGET/ENDPOINT" -w params.txt -H "Cookie: SESSION=..."
x8 -u "http://TARGET/ENDPOINT" --headers -H "X-FUZZ: test"       # hidden header params
```

## Step 2 — Keep it CTF-polite

Single challenge host, modest threads and a small delay — you're confirming parameters,
not stress-testing the box. Always carry the session cookie from app-map so you fuzz the
authenticated surface, not just the login wall. If the app rate-limits, slow down rather
than hammering.

## Step 3 — Verify, don't trust the first hit

Parameter fuzzers flag anything that changes the response. Re-request each candidate once
to drop flukes (caching, rate-limit pages). Keep a param only if it reliably changes
status, length, or content. Note HOW it reacted — reflected in the page, changed a
redirect, altered a DB result — because that reaction is the lead.

## Step 4 — Tag what you found

Write confirmed params into app-map, and add a `signal` when the name/behavior points at
a bug class so the router knows where to send it:

| Hidden param looks like | Signal to add |
|---|---|
| `url=`, `next=`, `redirect=`, `callback=`, `dest=` | `ssrf-candidate` / open-redirect |
| `file=`, `path=`, `page=`, `template=`, `include=` | `file-param` (LFI/traversal, maybe SSTI) |
| `id=`, `user=`, `uid=`, `account=`, `doc=` | `idor-candidate` |
| `debug=`, `admin=`, `test=`, `is_admin=`, `role=` | auth/logic bypass |
| reflected param (value echoed in response) | `xss-candidate` / `ssti-candidate` |

## Step 5 — Hand off

Summarize the high-value params for the orchestrator (which endpoint, which param, how it
reacted) and let it route to the matching exploit skill. Hidden params are frequently the
whole solve — surface them clearly.
