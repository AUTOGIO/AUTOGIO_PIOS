#!/bin/zsh
set -euo pipefail

# Prune generated reports older than KEEP_DAYS (default 30).
# Keeps executive_report_*.md and does not touch intelligence SQLite.

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
REPORT_DIR="${BASE_DIR}/data/reports"
KEEP_DAYS="${KEEP_DAYS:-30}"

mkdir -p "${REPORT_DIR}"

print -r -- "Pruning ${REPORT_DIR} files older than ${KEEP_DAYS} days (excluding executive_report_*.md)"

# macOS find: -mtime +N = last modified more than N days ago
deleted=0
while IFS= read -r f; do
  base="$(basename "${f}")"
  case "${base}" in
    executive_report_*.md) continue ;;
  esac
  rm -f "${f}"
  deleted=$((deleted + 1))
done < <(find "${REPORT_DIR}" -type f -mtime "+${KEEP_DAYS}" ! -name '.DS_Store' 2>/dev/null)

print -r -- "Removed ${deleted} file(s)."
