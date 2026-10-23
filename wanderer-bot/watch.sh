#!/usr/bin/env bash
# Starts the wanderer bot when $TARGET_PLAYER is online, stops it when they
# leave. Polls RCON every $POLL_SECONDS -- no LLM calls here, this is cheap.
# Writes directive.json so the bot knows to stay near them rather than
# wander on its own.
set -euo pipefail
cd "$(dirname "$0")"

: "${TARGET_PLAYER:?set TARGET_PLAYER (e.g. in .env)}"
POLL_SECONDS="${POLL_SECONDS:-20}"
PID_FILE="wanderer-bot.pid"
DIRECTIVE_FILE="directive.json"

log() { echo "$(date -Is) $*"; }

is_running() {
  [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null
}

start_bot() {
  echo "{\"type\":\"stay_near\",\"player\":\"$TARGET_PLAYER\"}" > "$DIRECTIVE_FILE"
  ( set -a; source .env; set +a
    exec setsid node index.js >> bot.log 2>&1 < /dev/null
  ) &
  echo $! > "$PID_FILE"
  log "$TARGET_PLAYER online, started wanderer-bot (pid $(cat "$PID_FILE"))"
}

stop_bot() {
  if is_running; then
    local pid
    pid="$(cat "$PID_FILE")"
    kill -TERM "$pid" 2>/dev/null || true
    for _ in $(seq 1 15); do
      kill -0 "$pid" 2>/dev/null || break
      sleep 1
    done
    kill -0 "$pid" 2>/dev/null && kill -KILL "$pid" 2>/dev/null || true
    log "$TARGET_PLAYER offline, stopped wanderer-bot"
  fi
  rm -f "$PID_FILE" "$DIRECTIVE_FILE"
}

cleanup() { stop_bot; exit 0; }
trap cleanup SIGTERM SIGINT

log "watching for $TARGET_PLAYER (poll every ${POLL_SECONDS}s)"
while true; do
  online="$(docker exec minecraft rcon-cli list 2>/dev/null | grep -o -F "$TARGET_PLAYER" || true)"
  if [ -n "$online" ]; then
    is_running || start_bot
  else
    is_running && stop_bot
  fi
  sleep "$POLL_SECONDS"
done
