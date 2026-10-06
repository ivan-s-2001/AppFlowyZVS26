#!/usr/bin/env bash
set -euo pipefail

: "${ZVS26_BACKUP_URL:?ZVS26_BACKUP_URL is required}"
: "${ZVS26_BACKUP_TOKEN:?ZVS26_BACKUP_TOKEN is required}"

output="${1:-/tmp/zvs26-latest.tar.gz}"

curl --fail --silent --show-error --location \
  --retry 3 --retry-all-errors \
  --connect-timeout 20 --max-time 900 \
  -H "Authorization: Bearer ${ZVS26_BACKUP_TOKEN}" \
  -H "Accept: application/gzip, application/octet-stream" \
  "${ZVS26_BACKUP_URL}" \
  --output "${output}"

if [[ ! -s "${output}" ]]; then
  echo "Backup endpoint returned an empty file" >&2
  exit 1
fi

echo "Backup snapshot saved to ${output}"
