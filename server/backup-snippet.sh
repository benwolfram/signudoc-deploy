# Added to /opt/docker/.scripts/backup.sh:
#   1. this function, next to dump_postgres
#   2. `dump_signudoc` in the dump list
#   3. `signudoc/data` in the rsync SOURCES loop (PDFs; .env is picked up
#      by the existing find over */.env)
#   4. "$DUMP_DIR"/*.dump in the loop that copies dumps to $DEST/dumps

dump_signudoc() {
  local name="signudoc-db"
  if [ "$(docker inspect -f '{{.State.Running}}' "$name" 2>/dev/null)" != "true" ]; then
    say "  ${YELLOW}skip${RESET}  $name (container not running)"
    DUMP_RESULTS+=("$name: skipped")
    return 0
  fi
  say "  dumping $name ..."
  # Custom format: compressed, and pg_restore can check it (below).
  if ! docker exec "$name" pg_dump -U signudoc -d signudoc -Fc \
      > "$DUMP_DIR/signudoc.dump" 2> "$DUMP_DIR/signudoc.err"; then
    cat "$DUMP_DIR/signudoc.err" >&2
    DUMP_RESULTS+=("$name: failed")
    fail "signudoc pg_dump failed"
  fi
  if ! docker exec -i "$name" pg_restore --list < "$DUMP_DIR/signudoc.dump" > /dev/null 2>&1; then
    DUMP_RESULTS+=("$name: failed")
    fail "signudoc dump is not a readable pg_restore archive"
  fi
  say "  ${GREEN}ok${RESET}    $name (pg_restore --list: ok)"
  DUMP_RESULTS+=("$name: ok")
}
