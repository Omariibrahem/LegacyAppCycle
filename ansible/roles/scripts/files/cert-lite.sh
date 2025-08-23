#!/usr/bin/env bash
set -Eeuo pipefail

CERT_DIR="/etc/ssl/patrol"
OUT_DIR="/var/reports"
OUT_FILE="$OUT_DIR/cert-lite.txt"

mkdir -p "$OUT_DIR"

{
  echo "cert_name | NotAfter_date | days_remaining"
  shopt -s nullglob
  for crt in "$CERT_DIR"/*.crt; do
    not_after_raw=$(openssl x509 -in "$crt" -noout -enddate 2>/dev/null | sed 's/^notAfter=//') || not_after_raw=""
    if [[ -z "$not_after_raw" ]]; then
      echo "$(basename "$crt") | INVALID | -"
      continue
    fi
    end_epoch=$(date -d "$not_after_raw" +%s)
    now_epoch=$(date +%s)
    days_left=$(( (end_epoch - now_epoch) / 86400 ))
    echo "$(basename "$crt") | $not_after_raw | $days_left"
  done
} > "$OUT_FILE"

