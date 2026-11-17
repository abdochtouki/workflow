# Learning from writeups (the study loop)

Reading disclosed reports and public writeups is a core, repeatable skill, not a
one-off. One study of ~10,000 HackerOne reports found the same classes recur
(XSS, IDOR, CSRF) — which means the *patterns* are learnable and reusable. The
goal of reading a writeup is not entertainment; it's to extract a **detection
rule** you can apply to your own targets (phase 7).

## What the public corpus looks like (and what it tells you)

From a 641-writeup index, by class:

| Class | Share | Read as |
| ----- | ----- | ------- |
| XSS | ~46% | Most-documented → most-hunted → **most duplicates**. Learn the escalations, not the basic payloads. |
| RCE | ~11% | Almost always the *top* of a chain (upload/traversal/SSRF → RCE). Study the chains. |
| CSRF | ~8% | Mostly a *gadget* to turn a weak bug into impact. |
| SQLi | ~5% | Rarer on modern stacks; high value where it lives. |
| SSRF | ~4% | Entry points (image/PDF/webhook) + metadata escalation. |
| Subdomain takeover | ~3% | Recon-detectable, high certainty. |
| CORS, LFI, Race, Auth, 2FA | 2–3% each | Dense gadget territory. |
| **IDOR** | **~1%** | **Under-documented publicly = less crowded.** Pair with business logic. |

The lesson: the most-written-about class (XSS) is the most crowded. The
best-paying, least-saturated work (IDOR, access control, business logic) is
*under*-represented in public writeups. Learn technique from the XSS/RCE/SSRF
corpus, but aim your hunting where the crowd isn't.

## The 10-question template (run on every writeup you read)

For each writeup, answer:

1. **Class** — what vulnerability class / sub-type?
2. **Entry point** — what feature or parameter exposed it?
3. **Root cause** — what did the developer assume that was false?
4. **Escalation** — was it chained? From what primitive to what impact?
5. **Detection** — what observable signal would have flagged it?
6. **PoC shape** — how did they prove it (request/response, victim data)?
7. **Report style** — title, structure, length. What made it clear?
8. **Bounty vs severity** — did the payout match the class, or the *impact*?
9. **Similar targets** — where on my targets does this pattern exist?
10. **Takeaway → detection rule** — one line I add to my notes to catch this
    class elsewhere.

Only #10 is mandatory to keep. A writeup you can't turn into a detection rule
taught you nothing reusable.

## A simple cadence

- **Per program (phase 2):** read that program's disclosed reports before you
  scan — your duplicate map and a read on how the team scores.
- **Per class you're learning:** read 10–20 writeups of one class back to back
  (e.g. all IDOR, or all OAuth). Patterns jump out only in bulk.
- **Weekly:** add any new detection rules to your notes / a shared
  `detection-rules.md`.

## Sources to mine

- Curated indexes: `github.com/devanshbatham/Awesome-Bugbounty-Writeups`,
  `github.com/alexbieber/Bug_Bounty_writeups` (the 641-link index this table
  came from), `pentester.land/writeups`.
- HackerOne Hacktivity (disclosed), per program.
- PortSwigger Web Security Academy + Hacker101 for the lab version of each class.
- Search patterns: `"<class> bug bounty writeup <year>"`, `"HackerOne <class>
  disclosure"`, `"$<amount> report <class>"`.

Reading writeups without extracting rules is just reading. The loop is: read →
10 questions → detection rule → apply on your targets. That's how a corpus of
other people's bugs becomes your methodology.
