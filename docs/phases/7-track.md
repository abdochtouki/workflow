# Phase 7 — Track (and learn the pattern)

The workflow is a loop. What you learn from each bug should make the next one
faster. Keep this light — a tracking system that needs maintenance fails when
you're busy.

## Track status

In each finding file and in `programs/<name>/notes.md`, move the status through
its lifecycle:

```
Lead → Confirmed → Verified → Drafted → Submitted → Triaged →
  → Bounty / Resolved / Duplicate / N-A
```

Record the report ID, submission date, and outcome. That's it — don't build a
transcript of every session. The stable residue (the finding, the decision, the
outcome) is what's worth keeping; the day-to-day moving state expires.

## Learn the detection rule (STÖK: hack, learn, share)

After every confirmed bug, write one line: **the pattern that would catch this
class elsewhere.** Keep these in `programs/<name>/notes.md` (or a shared
`detection-rules.md`). Examples:

- "Any endpoint taking a caller-supplied `*_id` that returns an object → run the
  A-vs-B IDOR test."
- "Any `transfer`/`move`/`share` action with a free-form account field → check
  the server enforces ownership of *both* accounts."
- "Any OAuth flow with an open redirect in `redirect_uri` → try token theft."

This is what turns a one-off payout into a repeatable edge. Over time these
rules become your personal methodology — more valuable than any tool list.

## Re-test on code change

When the target ships a new release, re-run recon's diff and re-test your old
reports' areas — fixed-then-regressed bugs are easy wins, and a bug fixed in
the latest version is dead, so always verify against the latest release and
re-check the version on filing day.

## Weekly rhythm

- A block for recon/diff across your programs.
- Most blocks for manual hunting on one program (depth).
- A short weekly review: what leads are open, what to test next, which
  detection rules to add.

**Done when:** the finding's outcome is recorded and its detection rule is
written. Then back to phase 1 or 4.
