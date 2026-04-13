#!/bin/bash
set -e

# --- Detect Docker ---
# On Windows (Git Bash / MSYS2), `docker` may resolve to a WSL shim that
# fails with "Exec format error". Use `docker.exe` explicitly instead.
DOCKER=""
case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*)
    # Windows — need the native .exe
    if command -v "docker.exe" &>/dev/null 2>&1; then
      DOCKER="docker.exe"
    fi
    ;;
  *)
    # macOS / Linux
    if command -v docker &>/dev/null 2>&1; then
      DOCKER="docker"
    fi
    ;;
esac

if [ -z "$DOCKER" ]; then
  echo "[setup] ERROR: Docker not found."
  echo "  Install Docker Desktop and make sure it's in your PATH."
  echo "  Windows: https://docs.docker.com/desktop/install/windows-install/"
  echo "  macOS:   https://docs.docker.com/desktop/install/mac-install/"
  echo "  Linux:   https://docs.docker.com/engine/install/"
  exit 1
fi

# Verify Docker daemon is running
if ! $DOCKER info &>/dev/null; then
  echo "[setup] ERROR: Docker is installed but the daemon is not running."
  echo "  Start Docker Desktop and wait for it to finish initializing, then try again."
  exit 1
fi

# --- Generate password ---
if [ ! -f .env ]; then
  PASSWORD=$(LC_ALL=C tr -dc 'a-zA-Z0-9' </dev/urandom 2>/dev/null | head -c 24 || python3 -c "import secrets,string; print(''.join(secrets.choice(string.ascii_letters+string.digits) for _ in range(24)))")
  printf 'LAVALINK_PASSWORD=%s\nIDLE_TIMEOUT_MINUTES=15\n' "$PASSWORD" > .env
  echo "[setup] Generated .env with random password"
else
  echo "[setup] Using existing .env"
  PASSWORD=$(grep '^LAVALINK_PASSWORD=' .env | cut -d= -f2)
fi

# --- Start containers ---
echo "[setup] Starting containers..."
$DOCKER compose up -d --build

# --- Wait for tunnel URL ---
echo "[setup] Waiting for Cloudflare tunnel..."
TUNNEL_URL=""
for i in $(seq 1 30); do
  TUNNEL_URL=$($DOCKER compose logs tunnel 2>&1 | grep -oE 'https://[a-z0-9-]+\.trycloudflare\.com' | head -1)
  if [ -n "$TUNNEL_URL" ]; then
    break
  fi
  sleep 2
done

if [ -z "$TUNNEL_URL" ]; then
  echo "[setup] ERROR: Tunnel URL not found after 60s. Check: $DOCKER compose logs tunnel"
  exit 1
fi

echo ""
echo "========================================================"
echo "  Jacky Music - Local Audio Node"
echo "========================================================"
echo ""
echo "  Tunnel URL : ${TUNNEL_URL}"
echo "  Password   : ${PASSWORD}"
echo ""
echo "  Run in Discord:"
echo "    j!localnode connect ${TUNNEL_URL} ${PASSWORD}"
echo ""
echo "  Auto-shutdown after 15 min of no music."
echo "  Restart anytime: ./setup.sh"
echo ""
echo "========================================================"
