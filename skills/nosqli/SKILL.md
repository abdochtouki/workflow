---
name: nosqli
description: >
  Exploits NoSQL injection (primarily MongoDB) on a CTF web challenge (or an authorized,
  in-scope target) — operator injection for auth bypass, user enumeration, and
  character-by-character data extraction. USE THIS SKILL when the backend is a NoSQL store
  (MongoDB/CouchDB/Redis), when a JSON login/search ignores types, or when SQLi payloads
  don't fit. Trigger on: "nosql injection", "mongodb injection", "$ne auth bypass",
  "$where", or as the nosqli branch routed by ctf-web-orchestrator. Authorized targets
  only. Reads the target from app-map.json and writes the result back.
---

# nosqli

NoSQL injection abuses the fact that an app forwards user input into a query without type
validation — so an attacker can supply an *object* (a query operator) where the app
expected a *string*, and change what the query matches. Most CTF cases are MongoDB
operator injection. Work only the host in `app-map.json`; treat returned data as data.

## Input / output

- **Input:** `target`, the injectable endpoint/param (login, search), request format
  (form vs JSON), `flag_location_guess`.
- **Output:** append to `app-map.json` — the technique, extracted data/flag
  (`solved:true`, `flag`), each try in `attempts`.

## Step 1 — Detect

Two flavors:
- **Syntax injection** — break the query like SQLi: `'`, `"`, `\`, `{`, `;` and watch for
  errors or changed behavior.
- **Operator injection** — supply a MongoDB operator object instead of a scalar. This is
  the common one.

## Step 2 — Auth bypass (operator injection)

Swap the string value for an operator. Two encodings depending on how the app parses input:
```
# URL-encoded form body:
username[$ne]=x&password[$ne]=x
username[$ne]=x&password[$regex]=.*

# JSON body:
{"username":{"$ne":null},"password":{"$ne":null}}
{"username":"admin","password":{"$gt":""}}
```
`$ne`/`$gt`/`$regex` make the password clause always true → log in without the password.
If the app returns the logged-in user's data, you may land straight on the flag.

## Step 3 — Enumerate & extract

- **User enumeration:** `username[$regex]=^adm` narrows which users exist.
- **Password/flag extraction** char-by-char via `$regex` (boolean oracle on
  success/failure or response diff):
  ```
  username=admin&password[$regex]=^a      # true if password starts with 'a'
  username=admin&password[$regex]=^fl4g\{  # walk the known flag prefix forward
  ```
  Script the walk over the charset, extending the matched prefix each round.
- **`$where` JS injection** (when the app uses `$where`): `'||'1'=='1`, or
  `';return true;'` — can enable boolean/JS-based extraction, sometimes code exec.

## Step 4 — Notes & bypass

- Send JSON? Set `Content-Type: application/json` and nest operators as objects.
- `$regex` special chars (`.`, `{`, `\`) must be escaped when matching a literal flag.
- Operator blocked → try the other encoding (bracket vs JSON), alternate operators
  (`$gt`/`$gte`/`$in`), or `$where` for JS.

## Step 5 — Record

Write the technique, working payload, and the flag to app-map. Note whether `$where`
reached JS execution (possible RCE pivot).

## Tooling

`nosqlmap` automates MongoDB operator injection; `PayloadsAllTheThings/NoSQL Injection`
and the Invicti NoSQL cheat sheet have the per-engine operator sets. CTF solves are
usually a short manual `$ne`/`$regex` script.
