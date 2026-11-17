# Cross-Site Request Forgery (CSRF)

A state-changing request that succeeds without a token the attacker can't
predict, forcing a logged-in victim to perform an action. On its own often low;
as a **gadget** it turns weak bugs into account takeover. CWE-352.

## Trigger

A state-changing action (change email/password, add a payment method, change
settings, transfer, invite, delete) whose request carries no anti-CSRF token, or
a token that isn't validated.

## Method

1. Capture the state-changing request.
2. Remove / blank / reuse-across-accounts the CSRF token and replay — does it
   still succeed?
3. Test token binding: does account A's token work on account B? Is it tied to
   the session at all?
4. Test `SameSite`: if cookies are `SameSite=Lax/Strict`, classic cross-site
   CSRF may be blunted — check for method downgrades (GET state change),
   top-level navigation POSTs, or subdomain positioning.
5. Check content-type / CORS tricks that let a cross-site form or `fetch` deliver
   the request.

## Escalate (CSRF shines as a gadget)

See `docs/escalation-ladders.md`:
- CSRF on **change email → password reset → account takeover**.
- CSRF that turns a **self-XSS into stored XSS** (submit the payload as the
  victim).
- CSRF on OAuth flow (missing `state`) → account linking takeover.

## False positives

- A token **is** validated (you removed it and the request failed) — not CSRF.
- `SameSite` cookies fully block the cross-site request in modern browsers and no
  downgrade exists.
- The action isn't security-relevant (no state change worth forcing).

## Proof

An attacker-hosted page (different origin) that, when a logged-in victim opens
it, performs the action — and the resulting state change on the victim's
account. Title by the impact (e.g. "CSRF on email change → account takeover").

## Detection rule to save

"Every state-changing request → strip/retest the CSRF token and check SameSite;
if it fires cross-site, ask what account-impacting action it can be pointed at."
