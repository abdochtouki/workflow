# Phase 3 — Recon (Discover → Enrich → Detect)

Automation does breadth here, and nothing more. The output is a **HOTLIST** you
take into manual testing. A scanner hit is a lead, not a bug.

Run it: `bin/recon.sh [--fast|--slow] programs/<name> <root-domain>`

The script skips any tool you don't have and never fakes output. Install what
you can (see the tool list below). Ordering rules, from the ProjectDiscovery /
reconftw / TBHM synthesis: **passive before active, breadth before depth,
collect everything then rank, scope-filter at ingestion, diff over time.**

## Stage 1 — Discover (map the surface, passively first)

- **Org-level seeds first:** acquisitions, ASNs (`asnmap`), reverse WHOIS,
  cloud tenants (`cloudlist`). Start from the org, work down to hosts.
- **Passive enumeration:** `subfinder -all`, `assetfinder`. Add API keys to
  subfinder for far better coverage.
- **Historical URLs:** `gau` / `waybackurls` — old endpoints, parameters, and
  JS paths others have forgotten. A goldmine for wordlists and leads.
- **Target-aware permutation only after passive results exist:** `alterx
  -enrich`. Never blind-permute from a generic wordlist.
- **Scope filter at ingestion:** every discovered host is pushed back through
  `scope-gate.sh`. Out-of-scope hosts are dropped to
  `recon/<date>/subdomains-dropped-oos.txt` and never probed. **This is the
  guardrail** — enumeration finds OOS subdomains constantly.

## Stage 2 — Enrich (turn names into characterized web assets)

- **Resolve/validate:** `dnsx` (wildcards, records).
- **TLS:** `tlsx` — certs often leak extra hostnames.
- **HTTP probe (the pivot):** `httpx` — status, title, tech fingerprint.
- **Takeover checks:** dangling CNAME/NS on resolved subdomains.
- **Crawl:** `katana -jc` collects URLs and JavaScript.
- **JS mining (do not skip):** extract endpoints and secrets from JS.
  - with `jsluice`: `cat _js-urls.txt | while read u; do curl -s "$u" | jsluice urls; done`
  - without it, grep JS for: `fetch(`, `axios`, `/api/`, `apiKey`, `token`,
    `s3.amazonaws`, `firebaseio`, `Authorization`, hard-coded hosts.
  - verified secret scanning: `trufflehog` in verified mode on the org's repos.

## Stage 3 — Detect (templated checks; every hit is a lead)

- `nuclei` on live hosts, rate-limited, including DAST mode.
- Out-of-band: self-hosted `interactsh` for blind SSRF/XXE/blind-XSS.
- `notify` to push new findings to your chat.

## The HOTLIST

`recon.sh` ranks everything with `admin|payment|billing|upload|account|api|
internal|dev|staging|graphql|oauth|sso|token|export|invite|webhook` into
`recon/<date>/HOTLIST.txt`. **Start manual testing there** — admin, payments,
upload, and account features are where impact lives.

## Automate vs. do by hand

- **Automate:** enumeration, probing, fingerprinting, screenshots, template
  scans, fresh-CVE templates, report drafts, scheduled re-runs with alerts.
- **By hand (phase 4):** business logic, authorization / IDOR matrices,
  validating findings, investigating odd behavior and naming inconsistencies.

## Tools worth installing

ProjectDiscovery: `subfinder httpx katana nuclei dnsx tlsx naabu asnmap
alterx notify interactsh-client`. Others: `assetfinder gau waybackurls jsluice
trufflehog puredns`. See `wordlists/README.md`.

**Done when:** `inventory` exists — in-scope live hosts, endpoints, JS
findings, and a HOTLIST ranked for manual work.
