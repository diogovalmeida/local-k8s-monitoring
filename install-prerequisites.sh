#!/bin/bash

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log()  { echo -e "${GREEN}[INFO]${NC}  $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC}  $1"; }
error(){ echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

OS="$(uname -s)"

echo ""
echo "📦 Installing Prerequisites"
echo "==========================="
echo ""

# ─────────────────────────────────────────────
# macOS
# ─────────────────────────────────────────────
if [ "$OS" = "Darwin" ]; then
  log "Detected macOS."

  # Homebrew
  if ! command -v brew &>/dev/null; then
    log "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  else
    warn "Homebrew already installed. Skipping."
  fi

  # Docker Desktop
  if ! command -v docker &>/dev/null; then
    log "Installing Docker Desktop..."
    brew install --cask docker
    log "Docker Desktop installed. Please open it manually to complete setup."
  else
    warn "Docker already installed. Skipping."
  fi

  # Kind
  if ! command -v kind &>/dev/null; then
    log "Installing Kind..."
    brew install kind
  else
    warn "Kind already installed. Skipping."
  fi

  # kubectl
  if ! command -v kubectl &>/dev/null; then
    log "Installing kubectl..."
    brew install kubectl
  else
    warn "kubectl already installed. Skipping."
  fi

  # Helm
  if ! command -v helm &>/dev/null; then
    log "Installing Helm..."
    brew install helm
  else
    warn "Helm already installed. Skipping."
  fi

# ─────────────────────────────────────────────
# Linux
# ─────────────────────────────────────────────
elif [ "$OS" = "Linux" ]; then
  log "Detected Linux."

  # Detect package manager
  if command -v apt-get &>/dev/null; then
    PKG="apt"
  elif command -v dnf &>/dev/null; then
    PKG="dnf"
  elif command -v pacman &>/dev/null; then
    PKG="pacman"
  else
    error "Unsupported package manager. Install dependencies manually."
  fi

  # Docker
  if ! command -v docker &>/dev/null; then
    log "Installing Docker..."
    if [ "$PKG" = "apt" ]; then
      sudo apt-get update -q
      sudo apt-get install -y ca-certificates curl gnupg
      sudo install -m 0755 -d /etc/apt/keyrings
      curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
      echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
        https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
        sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
      sudo apt-get update -q
      sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
      sudo usermod -aG docker "$USER"
      log "Docker installed. Log out and back in for group changes to take effect."
    elif [ "$PKG" = "dnf" ]; then
      sudo dnf -y install dnf-plugins-core
      sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
      sudo dnf install -y docker-ce docker-ce-cli containerd.io
      sudo systemctl enable --now docker
      sudo usermod -aG docker "$USER"
    elif [ "$PKG" = "pacman" ]; then
      sudo pacman -Sy --noconfirm docker
      sudo systemctl enable --now docker
      sudo usermod -aG docker "$USER"
    fi
  else
    warn "Docker already installed. Skipping."
  fi

  # Kind
  if ! command -v kind &>/dev/null; then
    log "Installing Kind..."
    ARCH=$(uname -m)
    [ "$ARCH" = "x86_64" ] && ARCH="amd64"
    [ "$ARCH" = "aarch64" ] && ARCH="arm64"
    curl -Lo /tmp/kind "https://kind.sigs.k8s.io/dl/v0.22.0/kind-linux-$ARCH"
    chmod +x /tmp/kind
    sudo mv /tmp/kind /usr/local/bin/kind
  else
    warn "Kind already installed. Skipping."
  fi

  # kubectl
  if ! command -v kubectl &>/dev/null; then
    log "Installing kubectl..."
    ARCH=$(uname -m)
    [ "$ARCH" = "x86_64" ] && ARCH="amd64"
    [ "$ARCH" = "aarch64" ] && ARCH="arm64"
    curl -LO "https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/$ARCH/kubectl"
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/kubectl
  else
    warn "kubectl already installed. Skipping."
  fi

  # Helm
  if ! command -v helm &>/dev/null; then
    log "Installing Helm..."
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
  else
    warn "Helm already installed. Skipping."
  fi

else
  error "Unsupported OS: $OS. On Windows, use WSL2 and run this script inside it."
fi

# ─────────────────────────────────────────────
# DONE
# ─────────────────────────────────────────────
echo ""
echo "==========================="
echo -e "${GREEN}✅ Prerequisites installed!${NC}"
echo "==========================="
echo ""
echo "  Next step: ./setup.sh"
echo ""
