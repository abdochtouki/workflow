# [Bug Class] in [Endpoint] allows [role] to [impact]

<!-- Title formula: "[Bug Class] in [Endpoint] allows [role] to [impact]"
     Keep the whole report under 600 words. Run: bin/report-lint.sh on it. -->

## Summary

<2-3 sentences. What the bug is, who can exploit it, what they gain. Concrete:
"Any authenticated user can read another tenant's invoices by changing the
account_id parameter. No admin rights are needed." State impact, not theory. -->

## Severity

- Severity: <Low / Medium / High / Critical>
- CVSS: <CVSS:3.1/... — justify each metric in one line if High/Critical>
- CWE: <CWE-XXX: name>
- Asset: <exact in-scope asset>
- Affected version: <if applicable>

## Steps to reproduce

### Prerequisites
<Test accounts A and B, setup.>

### Steps
1. As account A, ...
2. As account B, same request with A's object ID ...
3. ...

- Expected: <e.g. 403 Forbidden>
- Actual: <e.g. 200 with B's data>

## Proof of concept

<Exact request/response pair. For IDOR show the VICTIM's real data, not a 200.
Redact only what you must; strip your own PII.>

```
<request>
```
```
<response — the part that proves impact>
```

## Impact

<What an attacker achieves against real users/data/money. Only what you proved.
If you can elevate impact with proof, do it here — triage rewards it.>

## Remediation

<Concrete fix.>

## References

<Prior art / CWE / advisory, if any.>
