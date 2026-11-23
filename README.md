# signudoc-deploy

Builds [SignuDoc](https://github.com/NYLLON-SOFTWARE/SignuDoc) from an upstream release tag into `ghcr.io/benwolfram/signudoc`, plus the config for running it on `server` behind the existing edge tunnel and tailnet proxy.

## Upgrade

1. Read the upstream release notes.
2. Set `VERSION` to the new tag and push. CI builds `ghcr.io/benwolfram/signudoc:<tag>`.
3. On the server, bump the image tag in `/opt/docker/signudoc/docker-compose.yml`, then `docker compose pull && docker compose up -d`. Migrations run on start.
4. If a signing link breaks, re-check the path allowlist in `server/edge.Caddyfile` against `src/app`.

## Layout on the server

| What | Where |
| --- | --- |
| Compose, `.env`, `daily.sh` | `/opt/docker/signudoc` |
| PDFs | `/opt/docker/signudoc/data/storage` (rsynced nightly) |
| Postgres | volume `signudoc_pgdata` (pg_dump nightly, never rsynced) |
| Public signer pages | `sign.brioche.studio`: Cloudflare tunnel, then `edge-filter` allowlist |
| Admin | `sign-admin.brioche.studio`: tailnet only |
| Daily jobs | crontab, `daily.sh` at 09:00 |

## Traps

- `BETTER_AUTH_SECRET` encrypts the seal key. Losing or changing it makes a new seal key; it is backed up with the other `.env` files.
- The `X-Forwarded-For` line in `edge.Caddyfile` is what keeps visitor IPs in the audit trail honest. Don't drop it.
- Restore: `pg_restore -U signudoc -d signudoc --clean` from the nightly `signudoc.dump`, then copy `data/storage` back and `chown -R 1000:1000` it.
