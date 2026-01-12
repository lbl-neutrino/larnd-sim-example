#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./process_darshan_python3_logs.sh <JOBID> <LOGDIR>
# Example:
#   ./process_darshan_python3_logs_mergedPDF.sh 47551869 /pscratch/darshanlogs/2026/1/9

JOBID="${1:-}"
LOGDIR="${2:-}"

# ---- USER CONFIG ----
WORKDIR="/pscratch/sd/m/madan12/DUNE/darshan_try/larnd-sim-example/analysis_9jan26_ndlar_light_inter"
# ---------------------

# ---------- helpers ----------
timestamp() { date +"%a %d %b %Y %I:%M:%S %p %Z"; }
info() { echo "INFO: $*"; }
abort() { echo "ABORT: $*"; exit 1; }
have_cmd() { command -v "$1" >/dev/null 2>&1; }
# ----------------------------

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

# Basic tool sanity (keep minimal)
have_cmd darshan-merge || abort "darshan-merge not found"
have_cmd darshan-job-summary.pl || info "darshan-job-summary.pl not found (PDF step will be skipped)"

# ---- Prepare workdir ----
mkdir -p "$WORKDIR" || abort "cannot create WORKDIR: $WORKDIR"
[[ -d "$WORKDIR" && -w "$WORKDIR" ]] || abort "WORKDIR not writable: $WORKDIR"

# ---- Find python3 logs for this JOBID ----
[[ -d "$LOGDIR" ]] || abort "LOGDIR does not exist: $LOGDIR"

LOG_LIST="${WORKDIR}/python3_logs_${JOBID}.list"
find "$LOGDIR" -maxdepth 1 -type f -name "*python3*id${JOBID}*.darshan" ! -name "*.pdf" | sort > "$LOG_LIST" || true

nlogs=$(wc -l < "$LOG_LIST" | tr -d ' ')
if [[ "$nlogs" -le 0 ]]; then
  abort "no python3 logs found for JOBID=$JOBID in $LOGDIR"
fi

info "Found ${nlogs} python3 darshan logs"
info "Log list: $LOG_LIST"
cat "$LOG_LIST"

# ---- Merge logs ----
MERGED="${WORKDIR}/merged_${JOBID}_python3.darshan"
info "Merging logs -> $MERGED"
darshan-merge --output "$MERGED" $(cat "$LOG_LIST") >/dev/null 2>&1 || abort "darshan-merge failed"
info "Merged log created: $MERGED"
info "Quick check (optional): darshan-parser --show-incomplete $MERGED | head -n 60"

# ---- Generate PDF report from merged log ----
if have_cmd darshan-job-summary.pl; then
  info "Generating PDF from merged log (in WORKDIR)"
  ( cd "$WORKDIR" && darshan-job-summary.pl "$MERGED" >/dev/null 2>&1 ) \
    && info "PDF created: ${WORKDIR}/$(basename "$MERGED").pdf" \
    || info "PDF generation failed (check texlive / darshan-job-summary.pl output)"
else
  info "Skipping PDF (darshan-job-summary.pl not available)"
fi

# echo
# info "DONE. Outputs:"
# echo "  - Log list:  $LOG_LIST"
# echo "  - Merged log: $MERGED"
# echo "  - Merged PDF: ${WORKDIR}/$(basename "$MERGED").pdf"
