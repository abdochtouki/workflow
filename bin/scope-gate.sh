#!/usr/bin/env bash
# scope-gate.sh — deny-first scope enforcement, callable before EVERY live action.
#
# Why this exists
#   One out-of-scope request can get you banned. So scope is not a one-time
#   check at the start of recon — it is a gate in front of every host you
#   touch. recon.sh calls this on every discovered subdomain before probing
#   it; you call it by hand before testing anything new.
#
# Sources merged here
#   - federicopinan/ai-bug-bounty-hunter: scope-guard is deny-first; a
#     candidate host must be CONCRETE (no * ? [ ]); a matching out-of-scope
#     rule can't be overridden by a later broad in-scope rule.
#   - HuntMCP (ankitsingh015): scope gate on every live action.
#   - DevCop95 / your own scope-check: no scope file, no test.
#
# Scope file format: <program-dir>/assets.txt, one rule per line.
#   example.com        exact host, in scope
#   *.example.com      any subdomain of example.com, in scope
#   !admin.example.com explicit OUT of scope (deny-first, wins over any allow)
#   !*.internal.example.com  whole subtree out of scope
#   # comment          ignored
#
# Usage:
#   scope-gate.sh <program-dir> <host>
#   scope-gate.sh --quiet <program-dir> <host>   # verdict line only
#   scope-gate.sh -h
#
# Exit codes: 0 = in scope. 1 = out of scope or bad input.
set -u

QUIET=0
POSITIONAL=()
while [ $# -gt 0 ]; do
  case "$1" in
    --quiet) QUIET=1; shift ;;
    -h|--help)
      sed -n '2,/^set -u/p' "$0" | sed 's/^# \{0,1\}//; s/^#$//'
      exit 0 ;;
    --) shift; while [ $# -gt 0 ]; do POSITIONAL+=("$1"); shift; done ;;
    -*) echo "[!] Unknown flag: $1" >&2; exit 1 ;;
    *) POSITIONAL+=("$1"); shift ;;
  esac
done

PROGRAM_DIR="${POSITIONAL[0]:-}"
HOST="${POSITIONAL[1]:-}"

if [ -z "$PROGRAM_DIR" ] || [ -z "$HOST" ]; then
  echo "[!] Usage: $0 [--quiet] <program-dir> <host>" >&2
  exit 1
fi

# --- Candidate must be concrete: no scheme, no whitespace, no glob chars. ---
case "$HOST" in
  *://*)        echo "[!] DENY — pass a bare host, not a URL: $HOST" >&2; exit 1 ;;
  *[[:space:]]*) echo "[!] DENY — host contains whitespace: $HOST" >&2; exit 1 ;;
  *'*'*|*'?'*|*'['*|*']'*)
    echo "[!] DENY — candidate host must be concrete (no * ? [ ]): $HOST" >&2; exit 1 ;;
esac

ASSETS="$PROGRAM_DIR/assets.txt"
if [ ! -f "$ASSETS" ]; then
  echo "[!] DENY — no scope file at $ASSETS. No scope, no test." >&2
  exit 1
fi

host_lc="$(printf '%s' "$HOST" | tr '[:upper:]' '[:lower:]')"

# Load rules: strip CR, trim, drop comments/blanks.
mapfile -t RULES < <(tr -d '\r' < "$ASSETS" \
  | sed 's/^[[:space:]]*//; s/[[:space:]]*$//' \
  | grep -v '^#' | grep -v '^$')

if [ "${#RULES[@]}" -eq 0 ]; then
  echo "[!] DENY — scope file $ASSETS is empty." >&2
  exit 1
fi

# matches <host> <pattern> -> 0 if the host matches (exact or *. wildcard).
matches() {
  local h="$1" p="$2"
  p="$(printf '%s' "$p" | tr '[:upper:]' '[:lower:]')"
  if [ "$h" = "$p" ]; then return 0; fi
  case "$p" in
    \*.*)
      local suffix="${p#\*.}"
      case "$h" in
        *".$suffix") return 0 ;;
      esac
      ;;
  esac
  return 1
}

# Pass 1: deny-first. Any matching ! rule wins, full stop.
for rule in "${RULES[@]}"; do
  case "$rule" in
    '!'*)
      pat="${rule#!}"
      if matches "$host_lc" "$pat"; then
        [ "$QUIET" -eq 1 ] || echo "[x] OUT OF SCOPE — $HOST is denied by rule '!$pat'. Do not test it." >&2
        exit 1
      fi
      ;;
  esac
done

# Pass 2: allow. First matching positive rule wins.
for rule in "${RULES[@]}"; do
  case "$rule" in
    '!'*) : ;;  # deny rules already handled
    *)
      if matches "$host_lc" "$rule"; then
        [ "$QUIET" -eq 1 ] && echo "IN_SCOPE $HOST" || echo "[OK] In scope — $HOST matches '$rule'."
        exit 0
      fi
      ;;
  esac
done

[ "$QUIET" -eq 1 ] || echo "[x] OUT OF SCOPE — $HOST matches no in-scope rule in $ASSETS. Treat it as nonexistent." >&2
exit 1
