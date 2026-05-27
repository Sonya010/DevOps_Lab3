#!/bin/bash
set -euo pipefail

REPO_URL="https://github.com/Sonya010/DevOps_Lab3.git"
APP_DIR="/opt/mywebapp"
APP_USER="app"

echo "=== [1/6] Installing Docker ==="
if ! command -v docker &>/dev/null; then
  apt-get update
  apt-get install -y ca-certificates curl gnupg
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  chmod a+r /etc/apt/keyrings/docker.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
    | tee /etc/apt/sources.list.d/docker.list > /dev/null
  apt-get update
  apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
fi

echo "=== [2/6] Installing Nginx ==="
apt-get install -y nginx

echo "=== [3/6] Creating users ==="
id -u "$APP_USER" &>/dev/null || useradd -r -m -s /bin/bash "$APP_USER"
usermod -aG docker "$APP_USER"

for USER_NAME in student teacher; do
  id -u "$USER_NAME" &>/dev/null || useradd -m -s /bin/bash "$USER_NAME"
  echo "${USER_NAME}:12345678" | chpasswd
  usermod -aG sudo "$USER_NAME"
  chage -d 0 "$USER_NAME"
done

echo "=== [4/6] Cloning repository ==="
mkdir -p "$APP_DIR"
chown "$APP_USER":"$APP_USER" "$APP_DIR"
if [ -d "$APP_DIR/.git" ]; then
  sudo -u "$APP_USER" git -C "$APP_DIR" pull
else
  sudo -u "$APP_USER" git clone "$REPO_URL" "$APP_DIR"
fi

echo "=== [5/6] Configuring Nginx ==="
cp "$APP_DIR/deploy/nginx.conf" /etc/nginx/sites-available/mywebapp
ln -sf /etc/nginx/sites-available/mywebapp /etc/nginx/sites-enabled/mywebapp
rm -f /etc/nginx/sites-enabled/default
nginx -t
systemctl enable --now nginx

echo "=== [6/6] Configuring systemd ==="
cp "$APP_DIR/deploy/mywebapp-docker.service" /etc/systemd/system/mywebapp.service
systemctl daemon-reload
systemctl enable mywebapp

echo "Target VM is ready!"
