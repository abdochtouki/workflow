# Wordlists & tool setup

This folder holds starter wordlists. Big wordlists don't belong in git — pull
them with the commands below.

## Recommended wordlists

- **SecLists** — the standard. `git clone https://github.com/danielmiessler/SecLists`
  - Discovery: `SecLists/Discovery/Web-Content/` (raft, directory-list)
  - DNS: `SecLists/Discovery/DNS/` (for subdomain brute with puredns)
- **assetnote wordlists** — https://wordlists.assetnote.io/ (best for content
  discovery; `httparchive_*`, `best-dns-wordlist.txt`).
- **Build your own from historical URLs** (highest signal per phase 3):
  ```bash
  gau --subs TARGET | unfurl paths | sort -u > custom-paths.txt
  gau --subs TARGET | unfurl keys  | sort -u > custom-params.txt
  ```

## Recon tools to install

ProjectDiscovery (one installer: `pdtm`), then the rest:

```bash
# ProjectDiscovery toolkit
go install github.com/projectdiscovery/pdtm/cmd/pdtm@latest
pdtm -ia   # installs subfinder httpx katana nuclei dnsx tlsx naabu asnmap alterx notify interactsh-client ...

# others
go install github.com/tomnomnom/assetfinder@latest
go install github.com/lc/gau/v2/cmd/gau@latest
go install github.com/tomnomnom/waybackurls@latest
go install github.com/BishopFox/jsluice/cmd/jsluice@latest
# trufflehog: see github.com/trufflesecurity/trufflehog releases
```

`bin/recon.sh` uses whatever is installed and skips the rest — nothing here is
mandatory, but subfinder + httpx + katana + nuclei + gau is the practical
minimum for the Discover→Enrich→Detect pipeline.

Keep nuclei templates updated: `nuclei -update-templates`.
