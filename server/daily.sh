#!/usr/bin/env bash
# SignuDoc's daily jobs (Vercel cron does this upstream; see vercel.json):
#   retention: stale drafts, account deletions, expired links, reminders,
#              deadline notices
#   webhooks:  retries for webhook deliveries
# Called from crontab. Hits the app on loopback, not the public host.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

secret=$(grep -E '^RETENTION_JOB_SECRET=' .env | cut -d= -f2-)
[ -n "$secret" ] || { echo "RETENTION_JOB_SECRET missing in .env" >&2; exit 1; }

for job in retention webhooks; do
  curl -fsS --max-time 300 -X POST \
    -H "Authorization: Bearer $secret" \
    "http://127.0.0.1:5200/api/internal/$job" || {
      echo "signudoc $job job failed" >&2
      exit 1
    }
  echo
done
