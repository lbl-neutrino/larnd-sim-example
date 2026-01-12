#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./run_drishti_from_list.sh <LISTFILE>
# Example:
#   ./run_drishti_from_list.sh /pscratch/.../python3_logs_47551869.list

LISTFILE="${1:-}"

# ---- USER CONFIG ----
WORKDIR="/pscratch/sd/m/madan12/DUNE/darshan_try/larnd-sim-example/analysis_9jan26_ndlar_light_inter"
# ---------------------

timestamp() { date +"%a %d %b %Y %I:%M:%S %p %Z"; }
info() { echo "INFO: $*"; }
pass() { echo "PASS: $*"; }
fail() { echo "FAIL: $*"; }
have_cmd() { command -v "$1" >/dev/null 2>&1; }

if [[ -z "$LISTFILE" ]]; then
  echo "Usage: $0 <LISTFILE>"
  exit 2
fi

if [[ ! -f "$LISTFILE" ]]; then
  fail "List file not found: $LISTFILE"
  exit 1
fi

mkdir -p "$WORKDIR" 2>/dev/null || true

info "LISTFILE = $LISTFILE"
info "WORKDIR  = $WORKDIR"
info "Generated: $(timestamp)"

# Prefer shifter-based drishti image
if ! have_cmd shifter; then
  fail "shifter not found in PATH"
  exit 1
fi

INDEX="${WORKDIR}/drishti_perlog.index"
: > "$INDEX"

# Run per-log Drishti (recommended; avoids merged heatmap nbins issue)
while read -r f; do
  [[ -z "$f" ]] && continue
  [[ -f "$f" ]] || { echo "SKIP: missing $f" >> "$INDEX"; continue; }

  base=$(basename "$f")
  out="${WORKDIR}/${base}.drishti.txt"
  err="${WORKDIR}/${base}.drishti.err"

  echo "Running Drishti on: $f"
  if shifter --image=docker:hpcio/drishti -- drishti "$f" > "$out" 2> "$err"; then
    echo "PASS  $out" >> "$INDEX"
  else
    echo "FAIL  $out (see $err)" >> "$INDEX"
  fi
done < "$LISTFILE"

pass "Drishti per-log complete"
info "Index: $INDEX"

# Quick “what to fix” view (best-effort)
echo
info "Top findings (best-effort grep):"
grep -nEi 'warn|recommend|issue|fix|bottleneck|small|metadata|open|stat|seek|stride|alignment|random' \
  "$WORKDIR"/*.drishti.txt 2>/dev/null | head -n 80 || true
