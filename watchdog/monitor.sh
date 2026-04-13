#!/bin/sh
set -e

TIMEOUT_SECONDS=$((IDLE_TIMEOUT_MINUTES * 60))
POLL_INTERVAL=60
LAVALINK_URL="http://${LAVALINK_HOST}:${LAVALINK_PORT}"

echo "[watchdog] Idle timeout: ${IDLE_TIMEOUT_MINUTES} minutes"
echo "[watchdog] Polling every ${POLL_INTERVAL}s"

# Wait for Lavalink to be fully ready
until curl -sf "${LAVALINK_URL}/version" > /dev/null 2>&1; do
  echo "[watchdog] Waiting for Lavalink..."
  sleep 5
done
echo "[watchdog] Lavalink is ready"

last_active=$(date +%s)

while true; do
  sleep "$POLL_INTERVAL"

  # Query Lavalink stats — playingPlayers is the key field
  stats=$(curl -sf \
    -H "Authorization: ${LAVALINK_PASSWORD}" \
    "${LAVALINK_URL}/v4/stats" 2>/dev/null) || continue

  playing=$(echo "$stats" | jq -r '.playingPlayers // 0')

  if [ "$playing" -gt 0 ]; then
    last_active=$(date +%s)
  fi

  now=$(date +%s)
  idle_seconds=$((now - last_active))

  if [ "$idle_seconds" -ge "$TIMEOUT_SECONDS" ]; then
    echo "[watchdog] No active players for ${IDLE_TIMEOUT_MINUTES} minutes — shutting down"
    cd /compose
    docker compose down
    exit 0
  fi
done
