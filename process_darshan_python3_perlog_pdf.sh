#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./process_darshan_python3_perlog_pdf.sh <JOBID> <LOGDIR>
# Example:
#   ./process_darshan_python3_perlog_pdf.sh 47551869 /pscratch/darshanlogs/2026/1/9

JOBID="${1:-}"
LOGDIR="${2:-}"

# ---- USER CONFIG ----
WORKDIR="/pscratch/sd/m/madan12/DUNE/darshan_try/larnd-sim-example/analysis_9jan26_ndlar_light_inter"
# ---------------------

timestamp() { date +"%a %d %b %Y %I:%M:%S %p %Z"; }
info() { echo "INFO: $*"; }
abort() { echo "ABORT: $*"; exit 1; }
have_cmd() { command -v "$1" >/dev/null 2>&1; }

if [[ -z "${JOBID}" || -z "${LOGDIR}" ]]; then
  echo "ERROR: missing args"
  echo "Usage: $0 <JOBID> <LOGDIR>"
  exit 2
fi

info "JOBID   = ${JOBID}"
info "LOGDIR  = ${LOGDIR}"
info "WORKDIR = ${WORKDIR}"
info "Started: $(timestamp)"

# ---- Load modules ----
module load darshan >/dev/null 2>&1 || abort "cannot load darshan module"
module load texlive >/dev/null 2>&1 || info "texlive module load failed (PDF may fail)"

have_cmd darshan-job-summary.pl || abort "darshan-job-summary.pl not found"

# ---- Prep dirs ----
[[ -d "$LOGDIR" ]] || abort "LOGDIR does not exist: $LOGDIR"
mkdir -p "$WORKDIR" || abort "cannot create WORKDIR: $WORKDIR"
[[ -w "$WORKDIR" ]] || abort "WORKDIR not writable: $WORKDIR"

# ---- Find python3 logs for this JOBID ----
LOG_LIST="${WORKDIR}/python3_logs_${JOBID}.list"
find "$LOGDIR" -maxdepth 1 -type f -name "*python3*id${JOBID}*.darshan" ! -name "*.pdf" | sort > "$LOG_LIST" || true

nlogs=$(wc -l < "$LOG_LIST" | tr -d ' ')
[[ "$nlogs" -gt 0 ]] || abort "no python3 logs found for JOBID=$JOBID in $LOGDIR"

info "Found ${nlogs} python3 darshan logs"
info "Log list: $LOG_LIST"
cat "$LOG_LIST"

# ---- Generate one PDF per log ----
INDEX="${WORKDIR}/perlog_pdf_${JOBID}.index"
: > "$INDEX"
info "Writing index: $INDEX"
info "Generating per-log PDFs in: $WORKDIR"
info "Note: PDFs may warn about 'incomplete data' if Darshan ran out of record memory."

while read -r f; do
  [[ -z "$f" ]] && continue
  [[ -f "$f" ]] || { echo "SKIP: missing $f" >> "$INDEX"; continue; }

  base=$(basename "$f")
  pdf="${WORKDIR}/${base}.pdf"

  info "PDF -> $base.pdf"
  if ( cd "$WORKDIR" && darshan-job-summary.pl "$f" >/dev/null 2>&1 ); then
    if [[ -f "$pdf" ]]; then
      echo "PASS: $pdf" >> "$INDEX"
    else
      # Some setups may name the pdf slightly differently; record anyway.
      echo "WARN: generated (check WORKDIR) for $f" >> "$INDEX"
    fi
  else
    echo "FAIL: $f" >> "$INDEX"
  fi
done < "$LOG_LIST"

echo
info "DONE. Outputs:"
echo "  - Log list:  $LOG_LIST"
echo "  - PDF index: $INDEX"
echo "  - PDFs are in: $WORKDIR"
