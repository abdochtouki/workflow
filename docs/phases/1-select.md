# Phase 1 — Select

Pick a target worth hunting. Most hunters lose here by chasing prestige or
bounty size and landing on the most-crowded programs on the platform.

## Choose by

- **Attack surface, not money.** The question is "can I find a REAL,
  verifiable bug here?" — not "what pays most?".
- **Freshness.** Fresh code has had less review. Rank highest:
  - newly-added scope (just added to the program),
  - recently-shipped features,
  - new releases (< 3 months),
  - products with no public hunting writeups yet.
- **Multi-role / multi-tenant apps.** Anything with admin / manager / member /
  viewer roles, or free vs paid tiers, hides access-control gaps between what
  each role should and shouldn't see. This is the richest vein.
- **Large, convergent surface.** Many endpoints sharing one handler/parameter
  pattern — one PoC pattern tests all of them (feeds the sibling rule).

## Avoid (unless you have a specific new angle)

- Mature, maximally-hunted targets with a long Hacktivity history and no recent
  change. Your own freshness score says these are low-yield.
- Programs whose scope is tiny and static.

## Record before moving on

In `programs/<name>/scope.md`:
- the program's payout range and rules of engagement,
- the testing route (where to submit),
- any special requirements (no automated scanning? specific test accounts?),
- account plan: you will need **two** test accounts (A and B) for diffing.

Fill `programs/<name>/assets.txt` from the **live** policy page — never from
memory. Comment out anything you haven't verified as in scope.

**Done when:** the program is open, scope is read and saved, and you have (or
can create) test accounts A and B.
