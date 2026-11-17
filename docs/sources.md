# Sources

This workflow is a synthesis. Below is every source and what was borrowed from
it. Study the originals — this repo organizes their ideas, it does not replace
them.

## Methodologies & hunters

- **The Bug Hunter's Methodology (TBHM) — Jason Haddix** ·
  github.com/jhaddix/tbhm · talks: TBHM v4 Recon Edition (NahamCon2020),
  Application Analysis v1 (NahamCon2022), "Easy EASM" (DC31).
  Borrowed: the two-eye split (automation does breadth, human finds the 10%);
  org-level seed expansion and attack-surface multiplication; "forgotten
  subdomains run old code"; JS files as goldmines; wordlists from historical
  URLs / crt.sh.
- **NahamSec** · nahamsec.com. Borrowed: recon-first 7-phase shape; "master
  specific bug classes, apply pattern recognition across frameworks."
- **STÖK**. Borrowed: "hack, learn, share" → turn every confirmed bug into a
  reusable detection rule; reproducible, impact-first reports as a force
  multiplier; focused, time-boxed recon over blind tool-running.
- **zseano** · bugbountyhunter.com/zseano. Borrowed: focus on one program and
  learn it deeply to find what others miss and cut duplicates.
- **Corben Leo** · Critical Thinking podcast ep. 21. Borrowed: ~3-hour cap per
  area, then rotate.
- **Farah Hawa**. Borrowed: manual, tool-light business-logic hunting.
- **Th3G3nt3lman** (via NahamSec). Borrowed: recon depth for consistent
  high-value findings.

## Recon pipeline

- **reconftw — six2dez** · github.com/six2dez/reconftw. Model for the ordered,
  rate-limited recon runner.
- **reconductor recon-methodology-research — zaakirio** and **ProjectDiscovery**
  · projectdiscovery.io. Borrowed: the **Discover → Enrich → Detect** taxonomy;
  passive-before-active; breadth-before-depth; target-aware permutation only
  after passive results; scope-filter at ingestion; diff over time; structured
  per-program output; hotlist ranking by business criticality; the
  automate-vs-manual split.
- **Gunnar Andrews** · "Efficient Bug Bounty Automation" (DC32), "Recon to Scale
  with Serverless" (DC31). Borrowed: judge a recon run by findings per hour, not
  gigabytes collected; step order over infrastructure.

## Gates, rules & agentic workflows

- **claude-bug-bounty — shuvonsec** · github.com/shuvonsec/claude-bug-bounty.
  Borrowed: the Recon→Hunt→Validate→Report pipeline with a gate before
  reporting; "real bugs only — can an attacker do this RIGHT NOW?"; the
  30-second kill check; the 5-minute rule; validate before you spend time
  writing; A→B chaining.
- **ai-bug-bounty-hunter — federicopinan** ·
  github.com/federicopinan/ai-bug-bounty-hunter. Borrowed: deny-first scope
  guard with concrete-candidate enforcement; "never hunt theoretical bugs";
  "automation has the highest duplicate rate"; the **sibling rule** (#10); the
  **A→B signal within 20 minutes** (#11); mobile/CI-CD/SAML as the densest
  2025–26 surfaces; reporting rules — no theoretical language, always a PoC
  (show victim data for IDOR), **under 600 words**, the **title formula**, and
  the **never-submit list**; the validation-gate checklist; evidence vault with
  PII stripping and size caps.
- **hydra — sricharan996** · github.com/sricharan996/hydra. Borrowed: a
  **separate verifier** whose bar is zero false positives — 3-request
  reproducibility, baseline-vs-exploit diff, ≥80% confidence, CVSS calibration;
  keeping validation independent from discovery; a debug/lessons loop feeding
  future runs.
- **HuntMCP — ankitsingh015** · github.com/ankitsingh015/HuntMCP. Borrowed:
  scope gate on every live action; scan output is always a candidate, never
  confirmed.
- **agent-workspace — naliazheli** · github.com/naliazheli/agent-workspace.
  Borrowed: Duplicate Radar — check Hacktivity before committing to a direction.
- **security-prompts — mert-erkoc** · github.com/mert-erkoc/security-prompts.
  Borrowed: validate before reporting.

## Payloads, references, severity

- **PayloadsAllTheThings — swisskyrepo** · github.com/swisskyrepo/
  PayloadsAllTheThings. The payload/bypass reference for the playbooks.
- **Bugcrowd Vulnerability Rating Taxonomy** · github.com/bugcrowd/
  vulnerability-rating-taxonomy. Severity classification reference.
- **Hacker101 — Writing a Good Report & CVSS** · hacker101.com. Report quality
  and CVSS scoring.
- **PortSwigger Web Security Academy** · portswigger.net/web-security. Practice
  labs for every playbook class.
- **OWASP Top 10 (2025)**. Broken Access Control stays #1 and now includes
  SSRF; Security Misconfiguration rose to #2.

## DEF CON talks referenced

- "Eating Our Own Dogfood" (DC34) — write reports triage can reproduce without
  asking.
- "Hackbots" (DC34) — evidence, not confidence.
- "Leveraging AI for Smarter Bug Bounties" (DC32) — an agent that hunts like a
  human.
- Classics: "How to Shot Web" (DC23), "Domain Discovery" (DC25), "Bug Bounty
  Hunting on Steroids" (DC26).

## Platform context (2026)

HackerOne's 2026 research and triage guidance: submission volume is up sharply
year over year with roughly a quarter valid; triage rewards clear reproduction
and demonstrated impact over volume; business logic is the class hunters most
cite as AI-resistant and higher-paying. This is the reason the workflow
optimizes for one validated, high-impact, non-duplicate report.
