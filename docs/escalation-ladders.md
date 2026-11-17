# Escalation ladders (gadget chaining)

The single clearest lesson from reading hundreds of public writeups: the reports
that pay take a **low-impact primitive and escalate it to critical impact.** A
bug type is not an impact. Clickjacking sounds low; chained right it isn't. SSRF
sounds high; blind and firewalled it may be a P4. What gets paid is the *proven
chain to impact*.

This reframes "weak" findings. A low-severity bug is not a report and not
trash — it's a **gadget**: save it, and look for the ladder that turns it into
impact. Don't settle for Informative, and don't throw it away. Note it, keep
hunting for the rung above it.

## How to use this

1. When you find a primitive, don't file it alone (see `rules/never-submit.md`).
2. Find its position on a ladder below. Look for the next rung on *this* target.
3. Climb until you hit demonstrable impact (account takeover, data theft, money,
   code execution), then file the **chain**, titled by the end impact.
4. If you can't climb it, keep the gadget in `notes.md` and move on — it may
   combine with something you find later.

## Common ladders (observed across the writeup corpus)

**XSS family**
- Self-XSS → (CSRF or login/CSRF trick) → **stored XSS** → **account takeover**
- HTML injection → **XSS** → session/cookie theft → ATO
- Reflected XSS → steal session / CSRF-token → act as victim
- XSS on a CDN / signature-protected host → bypass → wide impact

**Open redirect (the classic gadget)**
- Open redirect → **OAuth `redirect_uri` token theft** → account takeover
- Open redirect → SSRF filter bypass → internal fetch
- Open redirect → bypass an allowlist used elsewhere

**SSRF**
- SSRF entry point (image resize, PDF/HTML render, webhook, URL import, ffmpeg,
  DNS rebinding) → reach **cloud metadata** → **credentials** → **RCE / account
  pivot**
- SSRF → internal service / local file read → secrets → RCE
- Blind SSRF → confirm with OOB, then escalate reach

**File handling**
- File upload (or path traversal in upload) → web-executable file (web.config,
  .jsp, polyglot image) → **RCE**
- LFI → log poisoning / wrapper → RCE
- Path traversal → read secrets/config → auth bypass → escalate

**Auth / OAuth / SSO**
- Open redirect + missing `state` → OAuth CSRF → account link takeover
- Email/username fallback trusting an unverified identifier → pre-account-takeover
- SAML signature not verified → authenticate as any user

**CORS**
- Reflected/`null` origin with credentials → cross-origin read of private data →
  steal tokens → **account takeover**
- CORS misconfig (out-of-scope host) → reach in-scope data

**CSRF**
- CSRF on a state-changing action → change email/password → **account takeover**
- CSRF → turn a self-XSS into stored XSS

**IDOR / access control**
- IDOR on one object → enumerate → **mass data exposure**
- IDOR on a role/permission field → **privilege escalation** → admin

**Race condition**
- Race on redeem/withdraw/transfer → **money duplication** / limit bypass
- Race + improper authorization → harvest another user's data

**Subdomain takeover**
- Dangling CNAME to a deprovisioned service → claim it → **cookie/session theft,
  phishing on a trusted domain, OAuth redirect abuse**

## The mindset

Chaining needs patience and a different eye: see potential where others see
low-hanging fruit. Keep a running list of gadgets per target. The hunters who
earn consistently aren't finding rarer bugs — they're *combining* common ones
into impact no single bug has alone.

See `rules/never-submit.md` for which primitives are worthless alone, and each
`playbooks/*.md` for how to find the rungs.
