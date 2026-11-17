# Hunting rules

The rules that sit above every phase. Merged from federicopinan's hunting
rules, shuvonsec's gate rules, Haddix's TBHM, STÖK, Corben Leo, and zseano.
Attribution in `docs/sources.md`.

1. **Read the full scope first.** One out-of-scope request can get you banned.
   Scope is deny-first and checked before every live action, not once.
2. **Never hunt theoretical bugs.** Ask: can an attacker do this *right now*?
   If no, stop. "Could lead to" is not a finding.
3. **Kill weak findings fast.** A 30-second check saves hours of reporting.
   Run the finding through the master gate early, not after you've written it.
4. **Pick one or two classes and go deep.** IDOR / access control + business
   logic is the highest-yield, least-automatable pair. Depth beats breadth.
5. **Focus on one program and learn it deeply** (zseano). Rotating programs
   every hour produces shallow duplicates.
6. **Automation has the highest duplicate rate.** Use it for breadth only.
   Manual testing finds the unique bugs that pay.
7. **One actor is half a finding.** Use two of your own test accounts (A and
   B) and diff every action. A difference in authorization is the finding.
8. **Sibling rule.** When you find a pattern like `/api/user/{id}/...`, test
   every sibling — other IDs, other roles, other verbs, old API versions,
   the mobile API.
9. **A→B signal.** When bug A is confirmed, the same mistake almost always
   exists elsewhere. Spend 20 minutes hunting B *before* writing up A.
10. **Time-box.** No progress after 5 minutes on a probe, move on (shuvonsec's
    5-minute rule). Max ~3 hours per area, then rotate (Corben Leo).
11. **Collect everything, judge by findings not output.** A recon run is good
    if it surfaces a lead, not if it collected gigabytes.
12. **Never brute-force** credentials, tokens, OTPs, or passwords. Ever.
13. **Rate-limit everything. Stop on 429** or a spike of 5xx. Never look like a
    denial-of-service.
14. **Honest severity.** Claim only the impact you proved. When a live check
    contradicts a code reading, correct the severity in the same pass.
15. **Never route around a safety stop.** A scope doubt, a blocked PoC, a
    safety flag — stop and reassess. Don't switch tools to retry a blocked
    step.
16. **Turn every bug into a detection rule** (STÖK). After each confirmed
    finding, write the one-line pattern that would catch the class elsewhere.
17. **Densest surfaces for 2025–2026:** mobile, CI/CD, and SAML/SSO. Point the
    sibling rule there.
18. **No secrets in this repo.** No tokens, cookies, passwords, or API keys in
    any file. Strip PII from evidence before saving.
