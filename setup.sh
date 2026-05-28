#!/bin/bash

# --- VARIABLES ---
REPO_URL="https://github.com/Sonya010/mywebapp.git"
DB_NAME="tasktracker"
DB_USER="student"
DB_PASS="yourpassword"
STUDENT_ID="13"

# 1. Update and install packages
sudo apt update
sudo apt install -y nodejs npm postgresql postgresql-contrib nginx git

# 2. Create users
# student and teacher with sudo access
sudo useradd -m -s /bin/bash student
sudo useradd -m -s /bin/bash teacher
echo "student:12345678" | sudo chpasswd
echo "teacher:12345678" | sudo chpasswd
sudo usermod -aG sudo student
sudo usermod -aG sudo teacher
# Force password change on first login
sudo chage -d 0 student
sudo chage -d 0 teacher

# app user for service
sudo useradd -r -m -s /bin/bash app

# operator user with restricted sudo
sudo useradd -m -s /bin/bash operator
echo "operator:12345678" | sudo chpasswd
sudo chage -d 0 operator

# 3. Database setup
sudo -u postgres psql -c "CREATE DATABASE $DB_NAME;"
sudo -u postgres psql -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASS';"
sudo -u postgres psql -c "ALTER DATABASE $DB_NAME OWNER TO $DB_USER;"

# 4. Deploy Application
sudo mkdir -p /opt/mywebapp
sudo chown app:app /opt/mywebapp
sudo -u app git clone $REPO_URL /tmp/mywebapp-clone
sudo cp -r /tmp/mywebapp-clone/* /opt/mywebapp/
sudo cp -r /tmp/mywebapp-clone/.* /opt/mywebapp/ 2>/dev/null
sudo rm -rf /tmp/mywebapp-clone
sudo chown -R app:app /opt/mywebapp
cd /opt/mywebapp || exit 1
sudo -u app npm install

# 5. Configuration files
sudo mkdir -p /etc/mywebapp
cat <<EOF | sudo tee /etc/mywebapp/config.json
{
  "port": 8000,
  "db": {
    "user": "$DB_USER",
    "host": "127.0.0.1",
    "database": "$DB_NAME",
    "password": "$DB_PASS",
    "port": 5432
  }
}
EOF
sudo chown -R app:app /etc/mywebapp
# 6. Налаштування Systemd та Nginx
# Копіюємо конфіги з нашої папки deploy
sudo cp /opt/mywebapp/deploy/mywebapp.service /etc/systemd/system/
sudo cp /opt/mywebapp/deploy/mywebapp.socket /etc/systemd/system/

# Налаштовуємо Nginx
sudo cp /opt/mywebapp/deploy/nginx.conf /etc/nginx/sites-available/mywebapp
sudo ln -sf /etc/nginx/sites-available/mywebapp /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# Запускаємо сервіси
sudo systemctl daemon-reload
sudo systemctl enable --now mywebapp.socket
sudo systemctl restart nginx

# 7. Gradebook
echo "$STUDENT_ID" | sudo tee /home/student/gradebook
sudo chown student:student /home/student/gradebook

# 8. Sudoers for operator
cat <<EOF | sudo tee /etc/sudoers.d/operator
operator ALL=(ALL) NOPASSWD: /usr/bin/systemctl start mywebapp.socket, /usr/bin/systemctl stop mywebapp.service, /usr/bin/systemctl restart mywebapp.socket, /usr/bin/systemctl status mywebapp.service, /usr/bin/systemctl status mywebapp.socket, /usr/bin/systemctl reload nginx
EOF

echo "Setup completed successfully!"

# 9. Lock default user
usermod -L "$SUDO_USER"