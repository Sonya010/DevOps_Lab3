#!/bin/bash
set -euo pipefail

RUNNER_VERSION="2.317.0"
RUNNER_USER="runner"
RUNNER_DIR="/opt/actions-runner"
ARCH="arm64"

echo "=== [1/3] Installing dependencies ==="
apt-get update
apt-get install -y curl tar docker.io docker-compose-plugin jq

echo "=== [2/3] Creating runner user ==="
id -u "$RUNNER_USER" &>/dev/null || useradd -m -s /bin/bash "$RUNNER_USER"
usermod -aG docker "$RUNNER_USER"

echo "=== [3/3] Downloading GitHub Actions Runner ==="
mkdir -p "$RUNNER_DIR"
chown "$RUNNER_USER":"$RUNNER_USER" "$RUNNER_DIR"

RUNNER_ARCHIVE="actions-runner-linux-${ARCH}-${RUNNER_VERSION}.tar.gz"
RUNNER_URL="https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/${RUNNER_ARCHIVE}"

sudo -u "$RUNNER_USER" bash -c "
  cd '$RUNNER_DIR'
  curl -fsSL '$RUNNER_URL' -o runner.tar.gz
  tar xzf runner.tar.gz
  rm runner.tar.gz
"

echo ""
echo "Runner is ready. Now register it MANUALLY:"
echo ""
echo "  sudo -u runner bash"
echo "  cd $RUNNER_DIR"
echo "  ./config.sh --url https://github.com/Sonya010/DevOps_Lab3 --token <YOUR_TOKEN>"
echo "  sudo ./svc.sh install runner"
echo "  sudo ./svc.sh start"
