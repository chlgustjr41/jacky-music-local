# Jacky Music — Local Audio Node

Run a local Lavalink audio server and connect it to the [Jacky Music](https://discord-bot-jacky-music.web.app/) Discord bot for lower latency audio streaming.

The bot stays on the cloud — this only runs the audio engine locally so the audio stream takes a shorter path to Discord's voice servers.

> **New to Jacky Music?** Visit the [Setup Guide](https://discord-bot-jacky-music.web.app/guide) to invite the bot and activate your server first.

## Supported Platforms

| Platform | Shell | Setup Command |
|----------|-------|---------------|
| **Windows** | PowerShell | `.\setup.ps1` |
| **Windows** | Git Bash / MSYS2 | `bash setup.sh` |
| **macOS** | Terminal | `bash setup.sh` |
| **Linux** | Any shell | `bash setup.sh` |

All platforms require [Docker Desktop](https://docs.docker.com/get-docker/) (or Docker Engine on Linux) with Docker Compose v2.

## Prerequisites

- [Docker Desktop](https://docs.docker.com/get-docker/) installed and **running**
  - Windows: Docker Desktop with WSL 2 backend
  - macOS: Docker Desktop for Mac
  - Linux: Docker Engine + docker-compose-plugin

## Quick Start

```bash
git clone https://github.com/chlgustjr41/jacky-music-local.git
cd jacky-music-local
```

**Windows (PowerShell):**
```powershell
.\setup.ps1
```

**macOS / Linux / Git Bash:**
```bash
bash setup.sh
```

The setup script will:
1. Generate a random Lavalink password
2. Start Lavalink + a Cloudflare tunnel + an idle watchdog
3. Print a Discord command to connect your server

```
========================================================
  Jacky Music - Local Audio Node
========================================================

  Tunnel URL : https://abc123.trycloudflare.com
  Password   : xK9mQ2rT...

  Run in Discord:
    j!localnode connect https://abc123.trycloudflare.com xK9mQ2rT...

  Auto-shutdown after 15 min of no music.
  Restart anytime: ./setup.sh

========================================================
```

Paste the `j!localnode connect ...` command in your Discord server and you're done.

> **Security note**: The connect command contains your password. Run it in a private or bot-only channel, or delete the message after the bot confirms the connection. The tunnel URL changes every time you restart — old Discord messages with a past URL are harmless.

You can also connect via the [web dashboard](https://discord-bot-jacky-music.web.app/) — click the **Cloud** badge in the header and enter the tunnel URL and password.

## How It Works

```
Your machine                          Cloud (GCP)
┌──────────────┐   Cloudflare    ┌─────────────────┐
│  Lavalink    │◄──  Tunnel  ───►│  Jacky Music Bot │
│  (audio)     │                 │  (commands)       │
└──────┬───────┘                 └─────────────────┘
       │ UDP audio
       ▼
  Discord Voice
```

- **Lavalink** handles audio fetching (YouTube, etc.) and streams it directly to Discord voice servers from your local network.
- **Cloudflare Tunnel** exposes Lavalink to the cloud bot securely — no port forwarding needed.
- **Watchdog** monitors activity and shuts everything down after 15 minutes of no music playing, for security.

## Commands

In Discord (after connecting):

| Command | Description |
|---|---|
| `j!localnode connect <url> <password>` | Connect to your local node |
| `j!localnode disconnect` | Switch back to cloud audio |
| `j!localnode status` | Show which audio backend is active |

## Configuration

Edit `.env` to customize:

| Variable | Default | Description |
|---|---|---|
| `LAVALINK_PASSWORD` | (auto-generated) | Lavalink authentication password |
| `IDLE_TIMEOUT_MINUTES` | `15` | Minutes of no music before auto-shutdown |

## Managing

```bash
# View logs
docker compose logs -f

# Stop manually
docker compose down

# Restart
bash setup.sh
```

## Troubleshooting

| Issue | Fix |
|---|---|
| Tunnel URL not showing | Wait 30s, then check `docker compose logs tunnel` |
| "Connection refused" in Discord | Lavalink may still be starting — wait 15s and retry |
| Watchdog shut things down too early | Increase `IDLE_TIMEOUT_MINUTES` in `.env` |
| Port 2333 conflict | Lavalink only binds inside Docker — no host port conflict |
| `docker` not found (WSL error on Windows) | Use PowerShell (`.\setup.ps1`) instead of bash, or ensure Docker Desktop WSL integration is enabled |
| "Exec format error" on Windows Git Bash | The script auto-detects Windows and uses `docker.exe` — make sure Docker Desktop is installed (not just WSL Docker) |

## License

MIT
