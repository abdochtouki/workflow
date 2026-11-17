# Race conditions / TOCTOU

Scanners can't find these — they need timing. CWE-362 / CWE-367. High impact on
money and limit flows.

## Trigger

Any action that checks a condition then acts on it, where the two aren't atomic:
redeem a coupon/gift card, withdraw/transfer funds, apply a referral credit,
submit once, claim a limited resource, upgrade/downgrade, vote/like once, OTP
verification attempts.

## The exact test

1. Find a one-shot or limited action (something you should be able to do N
   times but do once).
2. Fire the **same request many times in parallel** within the same instant.
   - Burp Repeater "send group in parallel" (single-packet attack), or
   - a small script firing concurrent requests, or `turbo-intruder`.
3. Compare the expected outcome (1 redemption) to the actual (N redemptions).

## Classic wins

- Redeem one gift card/coupon multiple times → balance multiplied.
- Withdraw/transfer the same balance twice before it's debited → money
  duplicated.
- Bypass a "one per account" limit (invites, votes, signups for a bonus).
- Over-claim a limited stock/seat.

## Safety

- Use demo/test funds only. Never move real money.
- Parallel bursts look like load — keep counts modest, prove the race, stop.
  Respect rate limits elsewhere; this is the one place brief parallelism is the
  technique, not an attack.

## False positives

- The backend serializes correctly and only one succeeds (the others 409/rej
  — the control working).
- A UI-only "limit" that the backend never enforced (that's just missing
  access control, report it as that).

## Proof

The parallel requests and the resulting state showing the condition bypassed N
times (N balances credited, N redemptions, limit exceeded). Show the before and
after balance/count.

## Detection rule to save

"Any check-then-act on money or a one-time limit → fire it in parallel and see
if the check and the act are atomic."
