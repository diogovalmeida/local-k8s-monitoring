# install-prerequisites.ps1
# Run as Administrator in PowerShell
# This script installs WSL2, Docker Desktop, Kind, kubectl and Helm on Windows

$ErrorActionPreference = "Stop"

function log  { Write-Host "[INFO]  $args" -ForegroundColor Green }
function warn { Write-Host "[WARN]  $args" -ForegroundColor Yellow }
function error { Write-Host "[ERROR] $args" -ForegroundColor Red; exit 1 }

Write-Host ""
Write-Host "📦 Installing Prerequisites (Windows)" -ForegroundColor Cyan
Write-Host "======================================="
Write-Host ""

# Check running as Administrator
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
  error "Please run this script as Administrator. Right-click PowerShell → Run as Administrator."
}

# ─────────────────────────────────────────────
# 1. WSL2
# ─────────────────────────────────────────────
log "Checking WSL2..."
$wslStatus = wsl --status 2>&1
if ($LASTEXITCODE -ne 0 -or $wslStatus -notmatch "Default Version: 2") {
  log "Installing WSL2..."
  wsl --install
  log "WSL2 installed. A reboot may be required."
  warn "After rebooting, re-run this script to continue."
  Read-Host "Press Enter to reboot now, or Ctrl+C to reboot manually later"
  Restart-Computer
} else {
  warn "WSL2 already installed. Skipping."
}

# ─────────────────────────────────────────────
# 2. Chocolatey (package manager)
# ─────────────────────────────────────────────
log "Checking Chocolatey..."
if (-NOT (Get-Command choco -ErrorAction SilentlyContinue)) {
  log "Installing Chocolatey..."
  Set-ExecutionPolicy Bypass -Scope Process -Force
  [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
  Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
  $env:PATH += ";$env:ALLUSERSPROFILE\chocolatey\bin"
} else {
  warn "Chocolatey already installed. Skipping."
}

# ─────────────────────────────────────────────
# 3. Docker Desktop
# ─────────────────────────────────────────────
log "Checking Docker Desktop..."
if (-NOT (Get-Command docker -ErrorAction SilentlyContinue)) {
  log "Installing Docker Desktop..."
  choco install docker-desktop -y
  log "Docker Desktop installed. Please open it and enable WSL2 backend in Settings."
} else {
  warn "Docker already installed. Skipping."
}

# ─────────────────────────────────────────────
# 4. Kind
# ─────────────────────────────────────────────
log "Checking Kind..."
if (-NOT (Get-Command kind -ErrorAction SilentlyContinue)) {
  log "Installing Kind..."
  choco install kind -y
} else {
  warn "Kind already installed. Skipping."
}

# ─────────────────────────────────────────────
# 5. kubectl
# ─────────────────────────────────────────────
log "Checking kubectl..."
if (-NOT (Get-Command kubectl -ErrorAction SilentlyContinue)) {
  log "Installing kubectl..."
  choco install kubernetes-cli -y
} else {
  warn "kubectl already installed. Skipping."
}

# ─────────────────────────────────────────────
# 6. Helm
# ─────────────────────────────────────────────
log "Checking Helm..."
if (-NOT (Get-Command helm -ErrorAction SilentlyContinue)) {
  log "Installing Helm..."
  choco install kubernetes-helm -y
} else {
  warn "Helm already installed. Skipping."
}

# ─────────────────────────────────────────────
# DONE
# ─────────────────────────────────────────────
Write-Host ""
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host "✅ Prerequisites installed!" -ForegroundColor Green
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Next steps:" -ForegroundColor White
Write-Host "  1. Open Docker Desktop and make sure it's running" -ForegroundColor White
Write-Host "  2. Open WSL2 terminal (e.g. Ubuntu from the Start menu)" -ForegroundColor White
Write-Host "  3. Clone the repo and run: ./setup.sh" -ForegroundColor White
Write-Host ""
