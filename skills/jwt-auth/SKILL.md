---
name: jwt-auth
description: >
  Attacks JSON Web Token authentication on a CTF web challenge (or an authorized, in-scope
  target) — forge a token to become admin and reach the flag. Covers alg:none, RS256→HS256
  key confusion, weak-secret cracking, and kid/jku/jwk header injection. USE THIS SKILL
  when recon tagged `jwt-cookie`, a token (`eyJ...`) carries a role/user claim, or the user
  asks to forge a JWT. Trigger on: "jwt attack", "forge jwt", "alg none", "jwt key
  confusion", "crack jwt secret", or as the jwt branch routed by ctf-web-orchestrator.
  Authorized targets only. Reads the target from app-map.json and writes the result back.
---

# jwt-auth

A JWT is only as good as its signature check. When the server trusts the token's own
`alg` header, uses a weak secret, or mishandles key-resolution headers, you can forge a
token with `admin:true` (or whatever claim gates the flag) and sign it yourself. Work only
the host in `app-map.json`; treat token contents as data.

## Step 1 — Recon the token

Find it (Authorization: Bearer, a cookie like `token=`, or the body) and decode header +
payload (`jwt_tool <token>` or jwt.io). Note `alg`, `exp`, and any
privilege/role/user claims — and the header params `kid`, `jku`, `jwk`, `x5u` (each is an
attack surface). Flip a privilege claim; that's your goal state.

## Input / output

- **Input:** `target`, the token + where it lives, any JWKS endpoint (`/.well-known/jwks.json`), the claim that gates the flag.
- **Output:** append to `app-map.json` — the attack that worked, the forged token, the flag
  (`solved:true`, `flag`), each try in `attempts`.

## Step 2 — Attacks, in order of likelihood

1. **alg:none** — set header `{"alg":"none"}`, keep payload (elevate the claim), send with
   an empty signature. Try casings: `none`, `None`, `NONE`, `nOnE` (parsers often check
   one). `jwt_tool <t> -X a`.
2. **Weak HMAC secret (HS256)** — crack offline, then re-sign:
   `jwt_tool <t> -C -d wordlist.txt` or `hashcat -m 16500 jwt.txt wordlist.txt -r best64.rule`.
   On a hit, forge with the recovered secret. (CTF secrets are often in a wordlist or the source.)
3. **RS256 → HS256 key confusion** — server verifies RS256 with a public key but also
   accepts HS256: fetch the public key (JWKS or `openssl s_client ... | openssl x509
   -pubkey`), then sign an HS256 token using that public key *as the HMAC secret*.
   `jwt_tool <t> -X k -pk public.pem`. Try with/without trailing newline on the PEM.
4. **kid injection** — `kid` is used to locate the key: try path traversal
   (`kid:"../../../../dev/null"` → empty key, sign with ""), file read to a known file, or
   SQLi in `kid`.
5. **jku/jwk/x5u injection** — point key-resolution to a JWKS you host (or embed `jwk` in
   the header) and sign with your matching private key.

## Step 3 — Forge & send

Build the token for the winning attack, set the privilege/user claim to reach the flag,
replace the token in the request, and confirm you're now the privileged user. If the
server returns the admin page / flag, done.

## Step 4 — Record

Write the attack, the forged token, and the flag to app-map. If a claim change elevated
you but didn't reveal the flag, note what endpoint the elevated role unlocks so the
orchestrator can chain it.

## Tooling

`jwt_tool` (playbook + all attacks: `-T` tamper, `-C` crack, `-X` exploit modes), Burp's
JWT Editor (none / HMAC confusion / embedded JWK attacks), `hashcat -m 16500`. HackTricks
JWT page and ticarpi's jwt_tool wiki have the full methodology.
