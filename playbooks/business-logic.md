# Business logic

The class hunters most cite as AI-resistant and rising in payout. Scanners
can't find these — they require understanding what the app is *for*. No single
CWE; map to the flow abused.

## Trigger

Any multi-step flow involving money, quotas, state, or trust: checkout, refunds,
transfers, plan upgrades/downgrades, coupons, invites, referrals, limits.

## Where to look (from phase 2's threat model)

- **Money flows:** can you pay less, refund more than you paid, transfer from an
  account you don't own, get a negative quantity to credit yourself?
- **Quota / limit abuse:** free-tier limits enforced only in the UI; create
  past the cap via the API; reuse a one-time coupon/invite.
- **State machine skips:** reach step 3 without step 2 (pay-after-ship, verify
  after access, approve your own request).
- **Ownership on "transfer/share/move":** server trusts a caller-supplied
  `account_from` / owner field instead of the token owner. (Overlaps IDOR.)
- **Value tampering:** price, currency, discount %, tax, quantity sent by the
  client and trusted by the server.
- **Time / sequence:** does re-ordering or replaying steps change the outcome?
  (If timing matters, see `race-conditions.md`.)

## The method

1. Understand the intended flow fully (phase 2). Capture the happy path.
2. Ask, at each step: *what does the server assume the client won't do?*
3. Break exactly that assumption, one at a time, with accounts A and B.
4. Prove the business impact: money gained, limit bypassed, another user
   affected.

## False positives

- The server corrects the value later (re-reads price at charge time).
- A "discount" that's within intended promo rules.
- An abuse that costs more than it gains (no real impact).

## Proof

The before/after that shows the business outcome: the $0 charge for a paid
plan, the refund exceeding the payment, the transfer from B's account, the
quota exceeded. State the impact in money/users.

## Detection rule to save

"Any client-supplied value that affects money or limits → change it server-side
and check the server re-validates at the decision point, not just at display."
