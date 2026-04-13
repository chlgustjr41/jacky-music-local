$ErrorActionPreference = "Stop"

# Check Docker is installed
if (!(Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "[setup] ERROR: Docker not found. Install Docker Desktop and make sure it's in your PATH."
    Write-Host "  https://docs.docker.com/desktop/install/windows-install/"
    exit 1
}

# Check Docker daemon is running
$dockerInfo = docker info 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "[setup] ERROR: Docker is installed but the daemon is not running."
    Write-Host "  Start Docker Desktop and wait for it to finish initializing, then try again."
    exit 1
}

# Generate a random password if .env doesn't exist
if (!(Test-Path .env)) {
    $bytes = New-Object byte[] 24
    [System.Security.Cryptography.RandomNumberGenerator]::Fill($bytes)
    $Password = -join ($bytes | ForEach-Object { "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"[$_ % 62] })
    "LAVALINK_PASSWORD=$Password" | Out-File -Encoding ascii .env
    "IDLE_TIMEOUT_MINUTES=15" | Out-File -Encoding ascii -Append .env
    Write-Host "[setup] Generated .env with random password"
} else {
    Write-Host "[setup] Using existing .env"
    $Password = (Get-Content .env | Where-Object { $_ -match '^LAVALINK_PASSWORD=' }) -replace '^LAVALINK_PASSWORD=', ''
}

# Start the stack
Write-Host "[setup] Starting containers..."
docker compose up -d --build
if ($LASTEXITCODE -ne 0) { throw "docker compose failed" }

# Wait for tunnel to print its URL
Write-Host "[setup] Waiting for Cloudflare tunnel..."
$TunnelUrl = ""
for ($i = 0; $i -lt 30; $i++) {
    $logs = docker compose logs tunnel 2>&1 | Out-String
    if ($logs -match '(https://[a-z0-9-]+\.trycloudflare\.com)') {
        $TunnelUrl = $Matches[1]
        break
    }
    Start-Sleep -Seconds 2
}

if ([string]::IsNullOrEmpty($TunnelUrl)) {
    Write-Host "[setup] ERROR: Tunnel URL not found after 60s. Check: docker compose logs tunnel"
    exit 1
}

Write-Host ""
Write-Host "========================================================"
Write-Host "  Jacky Music - Local Audio Node"
Write-Host "========================================================"
Write-Host ""
Write-Host "  Tunnel URL : $TunnelUrl"
Write-Host "  Password   : $Password"
Write-Host ""
Write-Host "  Run in Discord:"
Write-Host "    j!localnode connect $TunnelUrl $Password"
Write-Host ""
Write-Host "  Auto-shutdown after 15 min of no music."
Write-Host "  Restart anytime: .\setup.ps1"
Write-Host ""
Write-Host "========================================================"
