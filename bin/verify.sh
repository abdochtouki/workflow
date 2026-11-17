#!/usr/bin/env bash
# verify.sh — the independent validation gate. Run it on a finding BEFORE you
# write the report. Its only job is to destroy false positives before triage
# does.
#
# Sources merged here
#   - hydra (sricharan996): a separate verifier whose bar is zero false
#     positives — 3-request reproducibility, baseline-vs-exploit diff, >=80%
#     confidence, CVSS calibration.
#   - federicopinan/ai-bug-bounty-hunter: validation gate — confirmed
#     exploitable, PoC shows real impact, evidence captured, duplicates
#     checked, target re-verified in scope, High/Critical need CVSS + CWE.
#   - shuvonsec/claude-bug-bounty: validate before you spend 30 min writing.
#
# It checks a finding file (see templates/finding.md) for an unticked
# verification gate, missing evidence, missing CVSS/CWE on high severity, and
# theoretical language. Exit 0 only if the gate is clean.
#
# Usage: verify.sh <finding-file.md>
set -u

F="${1:-}"
[ -n "$F" ] && [ -f "$F" ] || { echo "[!] Usage: $0 <finding-file.md>" >&2; exit 1; }

fail=0
warn=0
say_fail() { echo "  [FAIL] $1"; fail=$((fail+1)); }
say_warn() { echo "  [warn] $1"; warn=$((warn+1)); }
say_ok()   { echo "  [ ok ] $1"; }

echo "== Verification gate: $F =="

# 1. Unticked checkboxes in the verification gate = not verified.
unticked="$(grep -cE '^[[:space:]]*-[[:space:]]*\[ \]' "$F" 2>/dev/null)"
unticked="${unticked:-0}"
if [ "$unticked" -gt 0 ]; then
  say_fail "$unticked gate item(s) still unchecked — finish verifying before reporting:"
  grep -nE '^[[:space:]]*-[[:space:]]*\[ \]' "$F" | sed 's/^/       /'
else
  say_ok "all verification-gate checkboxes ticked"
fi

# 2. Severity + CVSS/CWE for High/Critical.
sev="$(grep -iE '^\s*(\|\s*)?severity' "$F" | head -1)"
if printf '%s' "$sev" | grep -qiE 'high|critical'; then
  grep -qiE 'CVSS:?3' "$F" && say_ok "CVSS vector present (required for High/Critical)" \
    || say_fail "High/Critical finding has no CVSS:3.x vector"
  grep -qiE 'CWE-[0-9]+' "$F" && say_ok "CWE present" \
    || say_fail "High/Critical finding has no CWE-XXX"
fi

# 3. Evidence must exist, not just be promised.
if grep -qiE 'evidence|request/response|poc' "$F"; then
  say_ok "evidence/PoC section referenced"
else
  say_fail "no evidence / PoC section found"
fi

# 4. Reproduced at least 3x from clean state (hydra bar).
if grep -qiE 'reproduc(ed|ible).*(3|three|x3|3x)|3.?(x|times)' "$F"; then
  say_ok "reproduction count recorded"
else
  say_warn "no '3x reproduced from clean state' note — reproduce 3 times before filing"
fi

# 5. Theoretical language is a triage-killer.
theo="$(grep -inwE '(could|may|might|potentially|theoretically|possibly)' "$F" || true)"
if [ -n "$theo" ]; then
  say_warn "theoretical language found — rewrite as 'an attacker can X by Y':"
  printf '%s\n' "$theo" | sed 's/^/       /'
fi

echo ""
if [ "$fail" -gt 0 ]; then
  echo "RESULT: NOT VERIFIED ($fail blocker(s), $warn warning(s)). Do not file yet."
  exit 1
else
  echo "RESULT: VERIFIED (0 blockers, $warn warning(s)). Clear to write the report."
  exit 0
fi
