# Finding: <short name>

| Field | Value |
| ----- | ----- |
| Severity | <Info / Low / Medium / High / Critical> |
| CWE | CWE-XXX: <name> |
| CVSS | <vector, required for High/Critical — e.g. CVSS:3.1/AV:N/AC:L/PR:L/UI:N/S:U/C:H/I:N/A:N> |
| Asset | <exact in-scope host> |
| Endpoint | <method + path> |
| Status | Lead / Confirmed / Verified / Drafted / Submitted / Triaged / Resolved / Duplicate / N-A |
| Found | <YYYY-MM-DD> |
| Report ID | — |

## What an attacker can do

<One sentence, concrete, in the form "An attacker can X by Y." State a capability, never a hedge.>

## Steps to reproduce

1. As account A, ...
2. As account B, ...
3. ...

## Evidence

- Baseline (control) request/response: `evidence/<date>-baseline.txt`
- Exploit request/response: `evidence/<date>-exploit.txt`
- For IDOR: the exploit response shows the VICTIM's actual data, not just 200 OK.

## Impact

<What the attacker gains, in terms of the program's data/money/users. Only what you proved.>

## Root cause

<Why it happens.>

## Verification gate  (run: bin/verify.sh on this file — every box must be ticked)

- [ ] Confirmed exploitable RIGHT NOW on the live target (not theoretical)
- [ ] Reproduced 3x from a clean state (3x / three times)
- [ ] Baseline-vs-exploit responses saved in `evidence/`
- [ ] PoC shows real impact (victim data / state change), not just a status code
- [ ] Duplicate check done (Hacktivity + disclosed + public writeups)
- [ ] Target re-verified in scope today (bin/scope-gate.sh)
- [ ] Severity honest; High/Critical have a CVSS vector + CWE
- [ ] Not on the never-submit list (rules/never-submit.md)

## Sibling / chain check  (rules/hunting-rules.md #10, #11)

- [ ] Checked every sibling of this pattern (other IDs, roles, endpoints)
- [ ] Spent 20 min hunting the A->B repeat of this bug before writing it up
- Detection rule learned (STÖK): <one line — the pattern to catch this class elsewhere>

## Duplicate notes

- Searched: <where>. Result: <new angle, or clear>.
