#!/usr/bin/env bash
# report-lint.sh — lint a report before you submit it. Triage queues in 2026
# are flooded; a tight, concrete, reproducible report is how you stay out of
# the noise.
#
# Sources merged here
#   - federicopinan/ai-bug-bounty-hunter reporting rules: no theoretical
#     language ("an attacker can X by Y"); always a PoC; keep it under 600
#     words; title formula "[Bug Class] in [Endpoint] allows [role] to
#     [impact]"; never submit from the always-rejected list.
#   - Hacker101 "writing a good report": clear repro + demonstrated impact.
#
# Usage: report-lint.sh <report.md>
set -u

F="${1:-}"
[ -n "$F" ] && [ -f "$F" ] || { echo "[!] Usage: $0 <report.md>" >&2; exit 1; }

fail=0; warn=0
say_fail(){ echo "  [FAIL] $1"; fail=$((fail+1)); }
say_warn(){ echo "  [warn] $1"; warn=$((warn+1)); }
say_ok(){   echo "  [ ok ] $1"; }

echo "== Report lint: $F =="

# Word count of the body (<=600 target).
words="$(wc -w < "$F" | tr -d ' ')"
if [ "$words" -gt 600 ]; then
  say_warn "report is $words words (target <=600). Cut to the repro + impact."
else
  say_ok "length $words words (<=600)"
fi

# Required sections.
for sec in 'summary' 'steps to reproduce' 'impact'; do
  if grep -qiE "^#{1,6}.*$sec" "$F"; then say_ok "has section: $sec"
  else say_fail "missing section: $sec"; fi
done
if grep -qiE 'proof of concept|poc|request|response|evidence' "$F"; then
  say_ok "has PoC/evidence"
else
  say_fail "no PoC/evidence — triage needs to reproduce it"
fi

# Title formula: "[Class] in [Endpoint] allows [role] to [impact]".
title="$(grep -m1 -E '^#\s' "$F" | sed 's/^#\s*//')"
if printf '%s' "$title" | grep -qiE '\bin\b.+\ballows?\b.+\bto\b'; then
  say_ok "title follows the 'X in Y allows Z to W' shape"
else
  say_warn "title: '$title'"
  say_warn "  prefer: [Bug Class] in [Endpoint] allows [role] to [impact]"
fi

# Theoretical language.
theo="$(grep -inwE '(could|may|might|potentially|theoretically|possibly)' "$F" || true)"
if [ -n "$theo" ]; then
  say_warn "theoretical language (state what an attacker CAN do):"
  printf '%s\n' "$theo" | sed 's/^/       /'
fi

# Never-submit list — block low-value lone classes.
body_lc="$(tr '[:upper:]' '[:lower:]' < "$F")"
nevit=0
case "$body_lc" in
  *"self-xss"*|*"self xss"*) say_fail "mentions self-XSS — on the never-submit list (alone)"; nevit=1 ;;
esac
if printf '%s' "$body_lc" | grep -qE 'missing (csp|content.security)' && ! printf '%s' "$body_lc" | grep -qE 'chain|lead|combined'; then
  say_warn "missing-CSP alone is on the never-submit list unless chained"
fi
if printf '%s' "$body_lc" | grep -qE 'introspection' && ! printf '%s' "$body_lc" | grep -qE 'chain|idor|auth|data'; then
  say_warn "GraphQL introspection alone is on the never-submit list"
fi
if printf '%s' "$body_lc" | grep -qE 'open redirect' && ! printf '%s' "$body_lc" | grep -qE 'oauth|token|chain|ssrf'; then
  say_warn "open redirect alone is on the never-submit list unless chained"
fi

# IDOR reminder.
if printf '%s' "$body_lc" | grep -qE 'idor|bola|object reference'; then
  if printf '%s' "$body_lc" | grep -qE "victim|another user's data|b's data|other tenant"; then
    say_ok "IDOR shows victim data (not just a 200)"
  else
    say_warn "IDOR: show the VICTIM'S actual data in the PoC, not just a 200 OK"
  fi
fi

echo ""
if [ "$fail" -gt 0 ]; then
  echo "RESULT: NOT READY ($fail blocker(s), $warn warning(s))."
  exit 1
else
  echo "RESULT: READY ($warn warning(s) to consider)."
  exit 0
fi
