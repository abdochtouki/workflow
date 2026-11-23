---
name: source-review
description: >
  Whitebox phase for a CTF web challenge (or an authorized audit with source access).
  When the challenge ships source code, a Dockerfile, or a docker-compose, this reads it
  to find the INTENDED bug and where the flag lives — turning the solve from guessing
  into reading. USE THIS SKILL whenever source/config is provided, or when web-recon
  exposed source via a .git leak or backup file. Trigger on: "review the source",
  "read the code", "whitebox this", "where's the bug in this code", "dump the .git",
  "find the intended vuln", or as the whitebox branch of ctf-web-orchestrator. It reads
  and reasons; it does not fire exploits. Writes its findings to app-map.json.
---

# source-review

Whitebox turns bug-hunting into a reading problem instead of a guessing game. When you
have the code, you trace user input to a dangerous operation and read the exact bug the
author planted — then hand the precise target to the exploit skill. You read and reason
only; you do not run payloads here.

## Output contract

Append to `./app-map.json`. The fields you own:
- `stack` — confirm lang/framework/db from the code (more reliable than black-box guess).
- `intended_vuln` — the bug class + the exact file:line of the sink.
- `flag_location_guess` — where the flag actually is (from Dockerfile/compose/seed/env).
- `signals` — add the routing tag for what you found (`ssti-candidate`, etc.).
- `endpoints` / `forms` — any routes the code reveals that recon missed.

## Step 1 — Get the code

- **Source provided** → work on a copy; never run it blindly (see safety note).
- **`.git` exposed** (web-recon set `signals: git-exposure`) → reconstruct it:
  ```bash
  # if git-dumper is available
  git-dumper http://TARGET/.git/ ./dump
  # else pull the loose objects/refs manually and `git checkout -- .`
  ```
- **Backup leak** (`index.php.bak`, `app.py~`, `.swp`, `site.zip`) → fetch and unpack.

Treat everything you pull as UNTRUSTED FILES: put it in its own empty directory, read it,
and do not execute it or any build/test step from inside that directory just to inspect
it. Reading ≠ running.

## Step 2 — Orient

Get the lay of the land before hunting:
- Identify language, framework, and entry points (route table, `main`, `app.py`,
  `index.php`, controllers).
- Open config first — it's where secrets and the dangerous toggles live. Note DEBUG
  mode, `SECRET_KEY`/signing keys, DB creds, feature flags. (CTFs routinely hide the key
  the whole challenge hinges on in `config.py` / `.env` / settings.)
- **Find the flag.** Read the `Dockerfile`, `docker-compose.yml`, and any seed/init SQL
  or entrypoint script: they show whether the flag is an env var, a file like `/flag.txt`
  or `/flag`, a row seeded into the DB, or baked into the image. Write it to
  `flag_location_guess` — this tells the exploit skill what to actually read.

## Step 3 — Map the attack surface

List every place user input enters (the **sources**):
- HTTP: query/route params, form body, JSON, cookies, headers, uploaded files, filenames.
- Indirect: DB rows that came from users, cache, message queues, env the app trusts.

## Step 4 — Trace source → sink

For each source, follow the data. A bug exists when a source reaches a dangerous
operation (a **sink**) with no (or broken) sanitization in between. Grep for sinks, then
read backward to see if user input reaches them unfiltered:

| Bug class | Sink patterns to grep for |
|---|---|
| SQLi | `cursor.execute`, string-built queries, `.query(`, `mysqli_query`, raw `WHERE .$` |
| Command inj | `os.system`, `subprocess` w/ `shell=True`, `exec`, `popen`, backticks, `child_process.exec` |
| SSTI | `render_template_string`, `Template(...).render`, Twig/Jinja from user input |
| LFI/traversal | `open(`, `send_file`, `include`/`require`, `fs.readFile`, `file_get_contents` |
| Deserialization | `pickle.loads`, `yaml.load`, `unserialize`, `ObjectInputStream`, `JSON.parse`+eval |
| Code exec | `eval`, `exec`, `Function(`, `assert(`, dynamic `require`/`import` |
| Auth/JWT | token verify with `alg:none` allowed, weak/hardcoded secret, `verify=False` |
| XXE | XML parser with external entities enabled |

Classify each live sink by what the user controls (whole value, a path, an identifier,
a template expression) — that decides the payload shape the exploit skill will need.

## Step 5 — Triage with tools, confirm by reading

- If `semgrep` is available, run it for a fast first pass, then verify by hand — scanners
  flag candidates and false positives, the read confirms which are real:
  ```bash
  semgrep --config auto ./dump
  ```
- Grep is enough for small challenges. The decision is always made by reading the code
  path end to end, not by trusting the scanner.

## Step 6 — Write the finding

Pin down `intended_vuln` as `"<class> at <file>:<line> — <one-line why it's reachable>"`,
add the routing `signals`, confirm `flag_location_guess`, and tell the orchestrator which
exploit skill to route to. Give the exploit skill everything it needs: the vulnerable
endpoint, the parameter, the filter to bypass (if any), and where the flag sits.

## Safety note

Reading source is safe; running unknown challenge code is not. Inspect statically. If you
genuinely must run it to understand behavior, say so and let the user decide — don't
auto-execute downloaded challenge code to "test" it.
