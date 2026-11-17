# Broken Access Control (function/role level)

OWASP A01, #1 for a reason. IDOR is the object-level case (own file); this is
the function- and role-level case. CWE-285 / CWE-862.

## Trigger

An app with roles (admin / manager / member / viewer) or tiers (free / paid).
Actions that *should* be gated by role: user management, billing, settings,
exports, invites, feature flags, admin panels.

## The exact test

1. Enumerate actions available to the **high-privilege** role (admin) — capture
   each request.
2. As the **low-privilege** role (B), **replay those exact requests.**
   - Forced browsing: hit admin URLs/endpoints directly as B.
   - Method swap: if `GET /admin/x` is blocked, try `POST`, `PUT`, `DELETE`.
   - Parameter/role tampering: `role=admin`, `isAdmin=true`, `?debug=1`.
   - Missing function-level checks: the UI hides the button, but the API still
     honors the call.
3. Compare: B performing an admin-only action = the finding.

## Vertical vs horizontal

- **Vertical:** low role does a high-role action (member → admin).
- **Horizontal:** same role reaches another user's/tenant's function (that's
  usually IDOR — see `idor-bola.md`).

## Siblings

Every admin action is a candidate. Test the whole admin surface, the old API
version, and the mobile API. Export/download and invite/sharing features are
especially bug-dense (they cross trust boundaries).

## False positives

- The action fails server-side even though the request was accepted (read the
  effect, not the 200).
- A "soft" admin feature that's intentionally open to all roles.

## Proof

B's request performing the privileged action, with the resulting state change
shown (the created admin user, the changed setting, the exported data).

## Detection rule to save

"UI hides an action for a role → replay the raw API call as that role; the
check is often only in the frontend."
