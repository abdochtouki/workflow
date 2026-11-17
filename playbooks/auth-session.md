# Auth / session / OAuth / SAML

Account takeover is among the highest-paying outcomes. CWE-287 / CWE-384 /
CWE-613. OAuth/OIDC/SAML misconfigs are a dense, rising surface.

## Trigger

Login, registration, password reset, email change, MFA, SSO (OAuth/OIDC/SAML),
session/token handling, "remember me", API keys.

## What to test

**Session / token**
- Session survival after logout, password change, email change, MFA enable,
  account deactivation — does the old token still work?
- Session fixation: does the session ID stay the same across login?
- JWT: `alg:none`, weak/guessable secret, `kid` injection, unsigned
  acceptance, not checking `exp`/`aud`/`iss`.

**Password reset / email change**
- Reset token: predictable, no expiry, reusable, not bound to the user, leaked
  in the response or a redirect/Referer.
- Host-header / `X-Forwarded-Host` poisoning of the reset link.
- Email change without re-auth or without confirming the new address.

**MFA**
- MFA bypass by skipping the step (go straight to the post-MFA endpoint),
  brute-forcing a weak OTP (don't — against the rules), or response tampering
  (`"mfa":true`).

**OAuth / OIDC (dense surface)**
- `redirect_uri` manipulation → steal the code/token (chain with open redirect).
- `state` missing/not validated → CSRF on the OAuth flow.
- Pre-account-takeover: register the victim's email before they SSO in; the
  fallback trusts a caller-influenced identifier.
- Email/username fallback that trusts an unverified identifier instead of the
  verified one.

**SAML**
- Signature not verified / stripped; XML signature wrapping; `audience` not
  checked; reuse of assertions.

## The method

Two accounts, A and B. Try to use A's actions to reach B's account or to
authenticate as B. Account takeover of your *own* second account (B), proven
cleanly, is the deliverable — never target a real user.

## Proof

The request sequence that takes over B's account (or bypasses the control),
with the resulting authenticated access to B shown. State the precondition.

## Detection rule to save

"Any identifier the server trusts for identity (email, username, reset token,
`redirect_uri`) → check it's the *verified* one and bound to the session."
