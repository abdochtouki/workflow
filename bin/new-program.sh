#!/usr/bin/env bash
# new-program.sh — scaffold a new program folder from the template.
# Usage: new-program.sh <ProgramName>
set -u

NAME="${1:-}"
[ -n "$NAME" ] || { echo "[!] Usage: $0 <ProgramName>" >&2; exit 1; }

HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
SRC="$ROOT/programs/_template"
DST="$ROOT/programs/$NAME"

[ -d "$SRC" ] || { echo "[!] Template missing: $SRC" >&2; exit 1; }
[ -e "$DST" ] && { echo "[!] Already exists: $DST" >&2; exit 1; }

cp -r "$SRC" "$DST"
echo "[✓] Created $DST"
echo "    Next:"
echo "    1. Fill programs/$NAME/scope.md and assets.txt from the LIVE policy page."
echo "    2. Read docs/phases/2-learn.md and study disclosed reports first."
echo "    3. Recon:  bin/recon.sh programs/$NAME <root-domain>"
