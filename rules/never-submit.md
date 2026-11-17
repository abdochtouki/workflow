# Never-submit list

Classes that are rejected on sight when reported alone, with no demonstrated
impact. `bin/report-lint.sh` flags these. They are only worth filing when they
are a proven link in a chain with real impact.

Merged primarily from federicopinan/ai-bug-bounty-hunter reporting rules, plus
common program policy.

## Rejected alone (file only as part of a proven chain)

- **Self-XSS** — requires the victim to attack themselves. No impact alone.
- **Missing security headers** (CSP, X-Frame-Options, HSTS) — no impact without
  a demonstrated attack that the missing header enables.
- **GraphQL introspection enabled** — information, not a vulnerability by
  itself. Use it to *find* an IDOR/auth bug, then report that.
- **Open redirect alone** — low/no impact unless chained (OAuth token theft,
  SSRF filter bypass).
- **Clickjacking on pages with no sensitive state-changing action.**
- **Verbose errors / stack traces** with no exploitable secret.
- **Rate-limiting absence** on non-sensitive endpoints, with no account/OTP/
  money impact proven.
- **CSRF on non-sensitive actions**, or where tokens/SameSite already protect.
- **Descriptive-only reports from a scanner** — e.g. `nuclei -severity critical`
  output submitted verbatim. Never do this.
- **Best-practice / hardening suggestions** with no attacker action.

## The test

Before submitting anything on this list, answer: *what can an attacker actually
do, right now, and what's the proof?* If the answer is "nothing yet, but it
could help with…", it is a note in your own files, not a report.

## But don't discard them — they're gadgets

Everything on this list is a **gadget**: worthless filed alone, valuable as a
rung in a chain. The hunters who earn take these exact primitives and escalate
them (open redirect → OAuth token theft → ATO; self-XSS → stored → ATO;
missing-CSRF → email change → ATO). So the rule is three-way, not two-way:
**don't file it alone, don't throw it away — save it and climb.** See
`docs/escalation-ladders.md`.

## When they DO count

Chained, with proof:
- Open redirect **+** OAuth → account takeover.
- Missing CSP **+** an injection → working XSS with session impact.
- Introspection **+** an exposed mutation → IDOR on another tenant's data.

Report the *chain and its impact*, titled by the end result, not the weak link.
