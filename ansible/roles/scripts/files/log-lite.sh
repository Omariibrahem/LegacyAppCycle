#!/usr/bin/env bash
set -Eeuo pipefail

LOG_DIR="/var/log/barq"
LOCK="/var/lock/log-lite.lock"

exec 9>"$LOCK" || { echo "Cannot open lock $LOCK" >&2; exit 1; }
flock -n 9 || { echo "Another run in progress." >&2; exit 0; }

yesterday_epoch=$(date -d "yesterday" +%s) || exit 1

compress_yesterday() {
  # Compress files with mtime exactly "yesterday"
  find "$LOG_DIR" -maxdepth 1 -type f -name "*.log" -daystart -mtime 1 -print0 \
    | while IFS= read -r -d '' f; do
        gzip -f "$f" || echo "WARN: failed to gzip $f" >&2
      done
}

purge_old() {
  # Delete compressed logs older than 7 days
  find "$LOG_DIR" -type f -name "*.gz" -mtime +7 -print0 \
    | xargs -0 -r rm -f
}

main() {
  [[ -d "$LOG_DIR" ]] || { echo "Missing $LOG_DIR" >&2; exit 0; }
  compress_yesterday
  purge_old
}

main

