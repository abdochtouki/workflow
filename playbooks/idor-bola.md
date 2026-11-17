# IDOR / BOLA (Broken Object-Level Authorization)

The single most consistently rewarded class. Low exploitation complexity, high
business impact. CWE-639 / CWE-862.

## Trigger

An endpoint takes a caller-supplied object ID (path, query, or body):
`/users/{id}`, `/orders/{id}`, `/files/{id}`, `account_from`, `contract_id`.
The object belongs to a user, tenant, or account, and the action reads,
updates, deletes, shares, or transfers it.

## The exact test (A vs B)

1. As account **A**, create object `O_A`. Record its ID and response.
2. As account **B**, create object `O_B`. Record its ID.
3. As **A**, request `O_B` by ID — **read, then update, delete, share,
   transfer** (every verb, not just read). Save both request/response pairs.
4. Compare: `200` with B's data = the finding. `403/404` = the control.
5. **Neighbours (sibling rule):** `O_B±1`, id `1`, a third tenant's object;
   the old API version (`/api/v1/`); the mobile API.
6. **Mass form:** bulk endpoints taking an array of IDs — slip B's ID into A's
   list.

## False positives

- `200` that returns only *your* data (server ignores the ID). Read the body,
  not the status.
- `200` on a genuinely public object (shared link, public profile) — check the
  sharing state first.
- `403` that leaks existence via a different error/timing — that's an oracle
  (a lead), not an IDOR.
- IDs that are random per tenant and only work inside your own tenant.

## Proof

Two requests: A asking for B's object, both responses saved. A's own object
returns A's data; A's request for B's object returns **B's field values that
only B should see**. In the report, show the victim data — never just a 200.

## A→B

The same handler pattern repeats. The moment one IDOR confirms, sweep every
sibling endpoint for 20 minutes before writing it up.

## Detection rule to save

"Any endpoint taking a caller-supplied `*_id` returning an object → run the
A-vs-B test on every verb."
