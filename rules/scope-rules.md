# Scope rules

Scope is the one rule that can get you banned. Treat it as a gate in front of
every live action, not a one-time check.

## The scope file

Each program has `programs/<name>/assets.txt`, one rule per line:

```
example.com              # exact host, in scope
*.example.com            # any subdomain of example.com, in scope
!admin.example.com       # explicit OUT of scope (deny-first)
!*.internal.example.com  # whole subtree out of scope
# comment line, ignored
```

Keep it in sync with the **live** policy page. Scope changes; the policy page
is the only source of truth. Never test from memory.

## How the gate decides (`bin/scope-gate.sh`)

1. **Deny-first.** If the host matches any `!` rule, it is OUT — full stop. A
   later broad `*.example.com` can never override an explicit `!` deny.
2. **Then allow.** The host must match a positive rule (exact or `*.` wildcard)
   to be in scope.
3. **Concrete candidates only.** The host you test must be concrete — no `*`,
   `?`, `[`, `]`, no URL scheme, no whitespace.
4. **No scope file = deny.** Missing or empty `assets.txt` denies everything.
5. **Case-insensitive** on the host.

```bash
bin/scope-gate.sh programs/Acme api.acme.com   # exit 0 if in scope, 1 if not
```

## Rules

- **A plain domain does NOT cover its subdomains.** `example.com` matches only
  `example.com`. To include subdomains, add `*.example.com`. This is
  deliberate — scope is exactly what the file says.
- **Out-of-scope assets are treated as nonexistent.** Don't test them, don't
  report findings on them, don't even enumerate into them.
- **`recon.sh` re-filters every discovered host** through this gate before
  probing. Enumeration finds out-of-scope subdomains constantly; the gate is
  what stops you from scanning them.
- **Re-verify on filing day.** Scope and versions change. Confirm the asset is
  still in scope before you submit.
- **If scope is unclear, clarify before testing** — never test first and ask
  later.
