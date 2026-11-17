#!/usr/bin/env bash
# recon.sh — Discover -> Enrich -> Detect recon, scope-filtered at every step.
#
# Design (merged from the sources in docs/sources.md)
#   - ProjectDiscovery / reconductor "Discover -> Enrich -> Detect" taxonomy.
#   - Ordering rules: passive before active; breadth before depth; collect
#     everything, then rank; structured output with scope filtering AT
#     INGESTION (not just at the start).
#   - Haddix TBHM "Two-Eye": automation does breadth, you do the 10%. This
#     script is the breadth half. It ends by writing a HOTLIST for you.
#   - THE FIX over a naive subfinder->httpx->nuclei chain: every host that
#     enumeration discovers is pushed back through scope-gate.sh before it is
#     probed. Enumeration finds out-of-scope subdomains constantly; probing
#     them is how people get banned.
#
# Tools are all OPTIONAL. A missing tool is skipped and logged, never faked.
# A failing tool never aborts the run. Nothing here needs root.
#
# Usage:
#   recon.sh [--fast|--slow] [--dry-run] <program-dir> <root-domain>
#   recon.sh programs/acme acme.com
#   recon.sh --slow programs/acme acme.com
#
# Env overrides: RATE (global req/s, default 50), RECON_DATE (output subdir).
set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
SCOPE_GATE="$HERE/scope-gate.sh"

RATE="${RATE:-50}"
MODE="normal"
DRY=0
POS=()
while [ $# -gt 0 ]; do
  case "$1" in
    --fast) MODE="fast"; shift ;;
    --slow) MODE="slow"; shift ;;
    --dry-run) DRY=1; shift ;;
    -h|--help) sed -n '2,/^set -u/p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*) echo "[!] Unknown flag: $1" >&2; exit 1 ;;
    *) POS+=("$1"); shift ;;
  esac
done

PROGRAM_DIR="${POS[0]:-}"
ROOT="${POS[1]:-}"
if [ -z "$PROGRAM_DIR" ] || [ -z "$ROOT" ]; then
  echo "[!] Usage: $0 [--fast|--slow] [--dry-run] <program-dir> <root-domain>" >&2
  exit 1
fi
[ -d "$PROGRAM_DIR" ] || { echo "[!] No such program dir: $PROGRAM_DIR" >&2; exit 1; }

case "$MODE" in
  fast) RATE=$((RATE*2)) ;;
  slow) RATE=$((RATE/2)); [ "$RATE" -lt 5 ] && RATE=5 ;;
esac

have() { command -v "$1" >/dev/null 2>&1; }
inscope() { bash "$SCOPE_GATE" --quiet "$PROGRAM_DIR" "$1" >/dev/null 2>&1; }

# Gate the root before anything else.
if ! inscope "$ROOT"; then
  echo "[x] $ROOT is not in scope for $PROGRAM_DIR. Aborting." >&2
  exit 1
fi

DATE="${RECON_DATE:-$(date +%Y-%m-%d)}"
OUT="$PROGRAM_DIR/recon/$DATE"
LOG="$OUT/RUN-LOG.md"

if [ "$DRY" -eq 1 ]; then
  echo "DRY RUN"
  echo "  program : $PROGRAM_DIR"
  echo "  root    : $ROOT (in scope)"
  echo "  output  : $OUT"
  echo "  rate    : $RATE req/s ($MODE)"
  echo "  tools   :"
  for t in subfinder assetfinder alterx dnsx httpx katana nuclei jsluice gau waybackurls notify; do
    if have "$t"; then echo "    [+] $t"; else echo "    [-] $t (will skip)"; fi
  done
  exit 0
fi

mkdir -p "$OUT"
{
  echo "# Recon run — $ROOT"
  echo "- Date: $DATE"
  echo "- Program: $PROGRAM_DIR"
  echo "- Rate: $RATE req/s ($MODE)"
  echo ""
  echo "## Tool steps"
} > "$LOG"

log() { echo "- $1: **$2** $3" >> "$LOG"; }
count() { [ -f "$1" ] && wc -l < "$1" | tr -d ' ' || echo 0; }

echo "[*] Discover -> Enrich -> Detect on $ROOT  (rate ${RATE}/s)"

# ============================================================
# STAGE 1 — DISCOVER (passive first), then SCOPE-FILTER everything.
# ============================================================
RAW="$OUT/_raw-subdomains.txt"; : > "$RAW"

if have subfinder; then
  subfinder -silent -all -d "$ROOT" >> "$RAW" 2>/dev/null && log "subfinder" "ok" "" || log "subfinder" "failed" ""
else log "subfinder" "skipped" "(not installed)"; fi

if have assetfinder; then
  assetfinder --subs-only "$ROOT" >> "$RAW" 2>/dev/null && log "assetfinder" "ok" "" || log "assetfinder" "failed" ""
else log "assetfinder" "skipped" "(not installed)"; fi

# Passive URL history also yields hostnames + endpoints for later.
if have gau; then gau --subs "$ROOT" 2>/dev/null | sort -u > "$OUT/urls-historical.txt" && log "gau" "ok" "($(count "$OUT/urls-historical.txt") urls)" || log "gau" "failed" ""
elif have waybackurls; then waybackurls "$ROOT" 2>/dev/null | sort -u > "$OUT/urls-historical.txt" && log "waybackurls" "ok" "" || log "waybackurls" "failed" ""
else log "historical-urls" "skipped" "(no gau/waybackurls)"; fi

# Target-aware permutation ONLY after we have passive results (no blind brute).
if have alterx && [ -s "$RAW" ]; then
  sort -u "$RAW" | alterx -silent 2>/dev/null >> "$RAW" && log "alterx" "ok" "(permutations)" || log "alterx" "failed" ""
fi

# --- Scope filter at ingestion: this is the guardrail. ---
sort -u "$RAW" | sed '/^$/d' > "$OUT/_all-subdomains.txt"
INSCOPE="$OUT/subdomains-inscope.txt"; : > "$INSCOPE"
DROPPED="$OUT/subdomains-dropped-oos.txt"; : > "$DROPPED"
while IFS= read -r h; do
  [ -z "$h" ] && continue
  if inscope "$h"; then echo "$h" >> "$INSCOPE"; else echo "$h" >> "$DROPPED"; fi
done < "$OUT/_all-subdomains.txt"
# Always include the root itself.
echo "$ROOT" >> "$INSCOPE"; sort -u "$INSCOPE" -o "$INSCOPE"
log "scope-filter" "ok" "($(count "$INSCOPE") in scope, $(count "$DROPPED") dropped OOS)"
echo "[+] Discover: $(count "$INSCOPE") in-scope hosts ($(count "$DROPPED") out-of-scope dropped)"

# ============================================================
# STAGE 2 — ENRICH (resolve, probe, fingerprint, mine JS).
# ============================================================
LIVE="$OUT/live.txt"
if have httpx; then
  httpx -silent -l "$INSCOPE" -rate-limit "$RATE" -timeout 10 \
        -sc -title -tech-detect -o "$LIVE" >/dev/null 2>&1 && log "httpx" "ok" "($(count "$LIVE") live)" || log "httpx" "failed" ""
elif have httprobe; then
  httprobe < "$INSCOPE" > "$LIVE" 2>/dev/null && log "httprobe" "ok" "" || log "httprobe" "failed" ""
else
  cp "$INSCOPE" "$LIVE"; log "httpx" "skipped" "(not installed; using raw host list)"
fi
echo "[+] Enrich: $(count "$LIVE") live endpoints"

# URL field only (httpx -sc output has extra columns).
awk '{print $1}' "$LIVE" | sed 's/[][]//g' | grep -E '^https?://' > "$OUT/_live-urls.txt" 2>/dev/null || awk '{print $1}' "$LIVE" > "$OUT/_live-urls.txt"

if have katana && [ -s "$OUT/_live-urls.txt" ]; then
  katana -silent -list "$OUT/_live-urls.txt" -jc -rate-limit "$RATE" -o "$OUT/urls-crawled.txt" >/dev/null 2>&1 \
    && log "katana" "ok" "($(count "$OUT/urls-crawled.txt") urls)" || log "katana" "failed" ""
else log "katana" "skipped" "(not installed or no live hosts)"; fi

# JS mining: endpoints + secrets. jsluice if present, else grep patterns.
JS_URLS="$OUT/_js-urls.txt"
cat "$OUT/urls-crawled.txt" "$OUT/urls-historical.txt" 2>/dev/null | grep -iE '\.js(\?|$)' | sort -u > "$JS_URLS" 2>/dev/null || : > "$JS_URLS"
if [ -s "$JS_URLS" ]; then
  if have jsluice; then
    log "js-mining" "note" "(jsluice available — run: cat $JS_URLS | while read u; do curl -s \$u | jsluice urls; done)"
  else
    log "js-mining" "note" "($(count "$JS_URLS") JS files found; grep them for endpoints/keys — see docs/phases/3-recon.md)"
  fi
fi

# ============================================================
# STAGE 3 — DETECT (templated scan; a hit is a LEAD, not a bug).
# ============================================================
if have nuclei && [ -s "$OUT/_live-urls.txt" ]; then
  nuclei -silent -l "$OUT/_live-urls.txt" -rate-limit "$RATE" -o "$OUT/nuclei.txt" >/dev/null 2>&1 \
    && log "nuclei" "ok" "($(count "$OUT/nuclei.txt") hits)" || log "nuclei" "failed" ""
else log "nuclei" "skipped" "(not installed or no live hosts)"; fi

# ============================================================
# HOTLIST — rank by business criticality so manual time goes to the money.
# ============================================================
HOT="$OUT/HOTLIST.txt"
cat "$LIVE" "$OUT/urls-crawled.txt" "$OUT/urls-historical.txt" 2>/dev/null \
  | grep -iE 'admin|payment|billing|invoice|upload|account|api|internal|dev|staging|graphql|oauth|sso|token|password|export|invite|webhook' \
  | sort -u > "$HOT" 2>/dev/null || : > "$HOT"
log "hotlist" "ok" "($(count "$HOT") high-interest endpoints)"

# ============================================================
# INDEX + optional notify.
# ============================================================
{
  echo ""
  echo "## Index"
  echo "- In-scope hosts: \`subdomains-inscope.txt\` ($(count "$INSCOPE"))"
  echo "- Dropped out-of-scope: \`subdomains-dropped-oos.txt\` ($(count "$DROPPED"))"
  echo "- Live endpoints: \`live.txt\` ($(count "$LIVE"))"
  echo "- Crawled URLs: \`urls-crawled.txt\` ($(count "$OUT/urls-crawled.txt"))"
  echo "- Historical URLs: \`urls-historical.txt\` ($(count "$OUT/urls-historical.txt"))"
  echo "- JS files: \`_js-urls.txt\` ($(count "$JS_URLS"))"
  echo "- Nuclei leads: \`nuclei.txt\` ($(count "$OUT/nuclei.txt"))"
  echo "- **HOTLIST (start here): \`HOTLIST.txt\`** ($(count "$HOT"))"
  echo ""
  echo "> A scanner hit is a LEAD, not a bug. Take the HOTLIST into manual"
  echo "> testing (docs/phases/4-hunt.md). Automation finds doors; you prove"
  echo "> they open."
} >> "$LOG"

if have notify && [ -s "$HOT" ]; then
  echo "recon $ROOT: $(count "$INSCOPE") hosts, $(count "$LIVE") live, $(count "$HOT") hotlist" | notify -silent 2>/dev/null || true
fi

echo "[✓] Done. Start with: $HOT"
echo "    Full index: $LOG"
