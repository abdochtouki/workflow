---
name: flag-hunter
description: >
  Finisher for the CTF web chain: confirms and extracts the flag once an exploit skill
  reaches read/exec, or sweeps the usual hiding spots when a solve is close but the flag
  isn't in hand. Matches the known flag format, checks common locations, and records the
  solve in app-map.json. USE THIS SKILL after any exploit skill gets code exec / file read,
  when the orchestrator needs to confirm a candidate string is the flag, or when the user
  asks "where's the flag". Trigger on: "find the flag", "confirm the flag", "is this the
  flag", "check flag locations", or as the final phase called by ctf-web-orchestrator.
  Authorized targets only. Reads from and writes the result to app-map.json.
---

# flag-hunter

The small skill that closes the loop. An exploit skill got you read or exec — now turn
that into the confirmed flag, match it to the expected format, and record the solve. Work
only the host in `app-map.json`.

## Input / output

- **Input:** `target`, `flag_format` (e.g. `flag{...}`, `HTB{...}`, `picoCTF{...}`,
  `INTIGRITI{...}`), `flag_location_guess`, and whatever primitive the exploit skill left
  (RCE, file read, a candidate string).
- **Output:** set `solved:true` and `flag` in `app-map.json`; if unconfirmed, record what
  was checked so the orchestrator can route back.

## Step 1 — Know the format

Take `flag_format` from app-map (the orchestrator captured it at intake). If unknown, treat
any `WORD{...}` / `WORD_...` string as a candidate and confirm with the user / platform.
A regex like `[A-Za-z0-9_]+\{[^}]+\}` catches most.

## Step 2 — Check the usual locations

Given a read/exec primitive, sweep in order:
```
cat /flag.txt /flag /flag* 2>/dev/null
cat ~/flag.txt /home/*/flag.txt /root/flag.txt 2>/dev/null
env | grep -iE 'flag|ctf'                 # flag-as-env-var (common in Docker challenges)
ls -la / /app /var/www 2>/dev/null        # then cat the obvious file
cat /app/flag* /var/www/flag* 2>/dev/null
grep -rIE '<FORMAT_REGEX>' / 2>/dev/null | head   # last resort, scoped
```
If the Dockerfile/compose from `source-review` named the location, go straight there. For
DB-backed solves, the flag is usually a row (`SELECT flag FROM ...`) — use the data the
`sqli`/`nosqli` skill already pulled.

## Step 3 — Confirm

Match the candidate against `flag_format`. Reject near-misses (a partial string, a decoy
like `flag{not_the_real_flag}`, a truncated read). CTF flags are sometimes split across two
places — if one half is marked partial, note it and keep looking for the rest.

## Step 4 — Record (and submit)

Write the confirmed flag to `app-map.json` (`solved:true`, `flag`, and a one-line note of
the path that worked). If the challenge has a submission endpoint and the user asked for
auto-submit, submit it; otherwise hand the flag back to the user to submit. Keep a tight
summary of the full chain (recon → bug → exploit → flag) for the writeup.

## Step 5 — If not found

Report what you checked and what primitive you have, and hand back to the orchestrator —
the flag may need more surface (re-run recon / param-discovery) or a different location
guess. Don't fabricate a flag; a confident wrong string wastes a submission.
