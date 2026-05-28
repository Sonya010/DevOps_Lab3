#!/bin/bash
set -euo pipefail

REPO_URL="https://github.com/Sonya010/DevOps_Lab3.git"
APP_DIR="/opt/mywebapp"
APP_USER="app"

echo "=== [1/5] Installing Docker ==="
if ! command -v docker &>/dev/null; then
  apt-get update
  apt-get install -y ca-certificates curl gnupg
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  chmod a+r /etc/apt/keyrings/docker.gpg
  # shellcheck disable=SC1091
  . /etc/os-release
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu ${VERSION_CODENAME} stable" \
    | tee /etc/apt/sources.list.d/docker.list > /dev/null
  apt-get update
  apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
fi

systemctl disable --now nginx 2>/dev/null || true

echo "=== [2/5] Creating users ==="
id -u "$APP_USER" &>/dev/null || useradd -r -m -s /bin/bash "$APP_USER"
usermod -aG docker "$APP_USER"

for USER_NAME in student teacher; do
  id -u "$USER_NAME" &>/dev/null || useradd -m -s /bin/bash "$USER_NAME"
  echo "${USER_NAME}:12345678" | chpasswd
  usermod -aG sudo "$USER_NAME"
  chage -d 0 "$USER_NAME"
done

echo "=== [3/5] Cloning repository ==="
mkdir -p "$APP_DIR"
chown "$APP_USER":"$APP_USER" "$APP_DIR"
if [ -d "$APP_DIR/.git" ]; then
  sudo -u "$APP_USER" git -C "$APP_DIR" pull
else
  sudo -u "$APP_USER" git clone "$REPO_URL" "$APP_DIR"
fi

echo "=== [4/5] Configuring env file ==="
mkdir -p /etc/mywebapp
if [ ! -f /etc/mywebapp/env ]; then
  echo "DB_PASSWORD=yourpassword" > /etc/mywebapp/env
fi

echo "=== [5/5] Configuring systemd ==="
cp "$APP_DIR/deploy/mywebapp-docker.service" /etc/systemd/system/mywebapp.service
systemctl daemon-reload
systemctl enable mywebapp

echo "Target VM is ready!"
