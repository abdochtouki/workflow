---
name: web-recon
description: >
  Reconnaissance and enumeration for a single CTF web challenge (or an authorized,
  in-scope pentest target). Fingerprints the stack, hunts low-hanging files, reviews
  client-side source, and runs content discovery — then writes everything to a shared
  app-map.json for the router and exploit skills to consume. USE THIS SKILL whenever
  the user wants to recon, enumerate, map, or "look at" a web target before attacking.
  Trigger on: "recon this box", "enumerate the web challenge", "map this app",
  "what's running on [url]", "find hidden files/endpoints", "fingerprint the stack",
  "walk the application", or as the first phase called by ctf-web-orchestrator.
  This skill GATHERS; it does not exploit. It never touches a target outside the
  challenge/scope the user named.
---

# web-recon

You are the recon phase of a CTF web workflow. Your job is to build the clearest
possible picture of one target before any exploitation, and hand that picture to the
next skills as a structured file. You work only against the single host/challenge the
user named. You do not DoS, you do not touch out-of-scope hosts, and you do not exploit
anything here — you produce the map that tells the router which bug class to try.

## Output contract (do this no matter what)

Everything you learn goes into `./app-map.json` in the working directory. Create it on
first finding and append as you go. Exploit skills read ONLY this file, so be complete
and honest — write "unknown" rather than guessing. Schema:

```json
{
  "target": "http://host:port/",
  "flag_format": "flag{...}",
  "mode": "blackbox | whitebox",
  "stack": { "server": "", "lang": "", "framework": "", "db": "", "notes": [] },
  "cookies": [{ "name": "", "flags": "", "looks_like": "" }],
  "interesting_files": [],
  "endpoints": [{ "path": "", "method": "", "params": [], "notes": "" }],
  "forms": [{ "action": "", "method": "", "inputs": [] }],
  "auth": { "mechanism": "", "roles": [], "notes": "" },
  "features": [],
  "flag_location_guess": [],
  "signals": []
}
```

`signals` is the most important field for the router — short tags like `ssti-candidate`,
`admin-bot-present`, `file-param`, `jwt-cookie`, `graphql`, `upload-form`. Add one
whenever a finding points at a bug class (see the router's table).

## Step 0 — Intake

Record `target` and `flag_format` from the user. If source code, a Dockerfile, or a
docker-compose was provided, set `mode: whitebox` and note that `source-review` will
own the code read — but STILL do the live steps below (the running app often differs
from the repo). Otherwise `mode: blackbox`.

## Step 1 — First contact

Pull the raw truth before any tooling opinion:

```bash
curl -sSi "$T"                      # status, headers, cookies, redirects
curl -sS "$T" -o index.html         # save the body for source review
curl -sSi "$T/THIS_DOES_NOT_EXIST"  # 404 fingerprint — framework/server leaks here
```

Note the `Server`, `X-Powered-By`, `Set-Cookie`, and any custom headers. A verbose or
styled 404/500 page often names the framework (Werkzeug/Flask, Rails, Express, Laravel).

## Step 2 — Fingerprint the stack

- **Backend language** — swap the index extension: try `index.php`, `index.html`,
  `index.jsp`, `index.aspx`, `index.cgi`. The one that resolves tells you the language.
  No extension resolving → likely an action-dispatcher framework (Flask/Django/Rails/Express).
- **Cookies as tells** — `PHPSESSID`→PHP, `JSESSIONID`→Java, `connect.sid`→Express,
  `session=` signed cookie→Flask (→ `signals: flask-signed-cookie`), `laravel_session`→Laravel.
- **Tooling** (if installed; gentle, single-host):
  ```bash
  whatweb -a 3 "$T"
  # wappalyzer / webanalyze as a second opinion
  ```
- Write `server`, `lang`, `framework`, and guessed `db` into `stack`. If a signed/serialized
  cookie appears, add `signals: deserialization-candidate`.

## Step 3 — Low-hanging files

Check these directly (cheap, high-value in CTF):

```
/robots.txt   /sitemap.xml   /.well-known/security.txt
/.git/        /.svn/   /.hg/         ← source leak → signals: git-exposure
/.env  /.env.bak  /config.php.bak    ← secrets / backups
/package.json  /composer.json  /Dockerfile  /docker-compose.yml
/admin  /login  /dashboard  /api  /graphql   ← graphql present → signals: graphql
```

If `/.git/` is exposed, that's often the intended path — note it loudly and let
`source-review` dump it. Record every hit in `interesting_files`.

## Step 4 — Client-side source review

Read the saved `index.html` and every linked asset. CTF authors hide hints here:

- HTML comments, page footers, `<meta>` tags, `TODO`/`FIXME`/`debug` notes.
- CSS: `background:url(...)` pointing at stray files; revealing class/id names
  (a `.adm1n` class hints at an `/adm1n` route).
- Inline JS and `<script src>` → hand every JS file to the **js-analyze** skill; fold its
  endpoints/params/secrets back into `app-map.json`.
- Note every `<form>` (action, method, inputs) and any `?param=` you see → `forms` / `endpoints`.

## Step 5 — Content discovery

Manual-first, then fuzz. Keep threads/rate modest — it's a shared challenge box, not a
stress test. Match extensions to the stack from Step 2.

```bash
# Fast recursive sweep (Rust, auto-recurses)
feroxbuster -u "$T" -w /usr/share/seclists/Discovery/Web-Content/raft-medium-directories.txt \
  -x "$EXT" -t 40 --no-recursion -o ferox.txt     # add recursion once the layout is clear

# ffuf equivalent, with calibration to kill soft-404 noise
ffuf -u "$T/FUZZ" -w /usr/share/seclists/Discovery/Web-Content/raft-medium-words.txt \
  -e ".$EXT" -ac -mc 200,204,301,302,307,401,403,405 -o ffuf.json
```

`$EXT` by stack: PHP→`php,phtml,bak,old,txt`; Java→`jsp,do,action`; Node→`js,json`;
generic→`txt,bak,old,~,swp,zip,tar.gz`. Always try **backup/temp extensions** on files
you already found (`index.php` → try `index.php.bak`, `index.php~`, `.index.php.swp`) —
classic CTF source-leak. Add confirmed paths to `endpoints`.

## Step 6 — Directory listing & crawl

- Probe asset dirs for open listing: `/js/`, `/css/`, `/images/`, `/uploads/`, `/backup/`.
- If a crawler is available, map linked structure:
  ```bash
  katana -u "$T" -jc -o katana.txt        # includes JS-parsed endpoints
  ```
- Fold anything new into `endpoints`.

## Step 7 — Map auth & features

Summarize how the app works: authentication mechanism (form login, JWT, basic, SSO),
any visible roles, and the notable features (search, file upload → `signals: upload-form`,
URL-fetch/webhook → `signals: ssrf-candidate`, template-rendered reflection →
`signals: ssti-candidate`, numeric `id=` in URLs → `signals: idor-candidate`, an
"admin bot visits your link" note → `signals: admin-bot-present`). Fill `auth` and `features`.

## Step 8 — Flag-location guess & handoff

Fill `flag_location_guess` from what you've seen (`/flag.txt`, env var, a DB table, a
comment pointing somewhere, `/flag` route). Write the final `app-map.json`, then tell the
orchestrator recon is complete and summarize the top 2–3 `signals` so the router can act.

## CTF etiquette

- One challenge host only. No subdomain/ASN sweeps — CTF web is almost always a single box.
- Low request rates; stop if the box wobbles. Heavy scanners (nikto, aggressive dirbusters)
  are discouraged in CTF — prefer targeted manual checks and a modest ffuf/ferox pass.
- Recon is iterative: when an exploit skill gets stuck, come back and discover more.
