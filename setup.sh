#!/bin/bash

# DST Server Auto-Install Script
set -e

echo "=== Don't Starve Together Server Installation ==="

# 1. System update and package installation
echo "Updating system and installing dependencies..."
apt update && apt upgrade -y
dpkg --add-architecture i386
apt update
apt install -y lib32stdc++6 lib32z1 libcurl4-gnutls-dev:i386 libsdl2-2.0-0:i386 wget ca-certificates screen ufw

# 2. Create dedicated user
echo "Creating dedicated user 'dst'..."
useradd -m dst

# 3. Install SteamCMD and DST server
echo "Installing SteamCMD and DST server..."
su - dst -c "
cd ~
wget -q https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz
tar -xzf steamcmd_linux.tar.gz
./steamcmd.sh +force_install_dir ./dst +login anonymous +app_update 343050 validate +quit
rm steamcmd_linux.tar.gz
"

# 4. Create directory structure and copy configuration
echo "Setting up directory structure and configuration..."
mkdir -p /home/dst/.klei/DoNotStarveTogether/MyDediServer
mkdir -p /home/dst/dst/mods
mkdir -p /home/dst/.klei/DoNotStarveTogether/MyDediServer/save

# Create cluster configuration
cat > /home/dst/.klei/DoNotStarveTogether/MyDediServer/cluster.ini << 'EOF'
[GAMEPLAY]
game_mode = survival
max_players = 7
pvp = false
pause_when_empty = true

[NETWORK]
cluster_password = roma-chort
cluster_name = Wortoxxx_server
cluster_description = YouTube: Голодный Чорт
cluster_language = ru

[MISC]
console_enabled = true

[SHARD]
shard_enabled = true
bind_ip = 0.0.0.0
master_ip = 127.0.0.1
master_port = 10889
cluster_key = supersecretkey
EOF

# Create Master server configuration
mkdir -p /home/dst/.klei/DoNotStarveTogether/MyDediServer/Master
cat > /home/dst/.klei/DoNotStarveTogether/MyDediServer/Master/server.ini << 'EOF'
[SHARD]
is_master = true
EOF

cat > /home/dst/.klei/DoNotStarveTogether/MyDediServer/Master/modoverrides.lua << 'EOF'
return {
}
EOF

# Create Caves server configuration
mkdir -p /home/dst/.klei/DoNotStarveTogether/MyDediServer/Caves
cat > /home/dst/.klei/DoNotStarveTogether/MyDediServer/Caves/server.ini << 'EOF'
[SHARD]
is_master = false
EOF

cat > /home/dst/.klei/DoNotStarveTogether/MyDediServer/Caves/modoverrides.lua << 'EOF'
return {
}
EOF

# Create empty mods setup
cat > /home/dst/dst/mods/dedicated_server_mods_setup.lua << 'EOF'
-- Add mods here using: ServerModSetup("mod_id")
EOF

# 5. Create start script
cat > /home/dst/start_server.sh << 'EOF'
#!/bin/bash

cd ~/dst/bin

# Start Master server
echo "Starting Master server..."
./dontstarve_dedicated_server_nullrenderer -console -cluster MyDediServer -shard Master &

# Wait before starting Caves
sleep 5

# Start Caves server
echo "Starting Caves server..."
./dontstarve_dedicated_server_nullrenderer -console -cluster MyDediServer -shard Caves &

echo "Servers started. Use 'screen -r' to view console output."
EOF

chmod +x /home/dst/start_server.sh

# 6. Setup firewall
echo "Configuring firewall..."
ufw allow ssh
ufw allow 10999/udp
ufw allow 10998/udp
ufw allow 27018:27019/tcp
ufw --force enable

# 7. Create systemd service for Master
cat > /etc/systemd/system/dst-master.service << 'EOF'
[Unit]
Description=Don't Starve Together Master Server
After=network.target

[Service]
Type=simple
User=dst
Group=dst
WorkingDirectory=/home/dst/dst/bin
ExecStart=/home/dst/dst/bin/dontstarve_dedicated_server_nullrenderer -console -cluster MyDediServer -shard Master
Restart=on-failure
RestartSec=30

[Install]
WantedBy=multi-user.target
EOF

# 8. Create systemd service for Caves
cat > /etc/systemd/system/dst-caves.service << 'EOF'
[Unit]
Description=Don't Starve Together Caves Server
After=network.target dst-master.service

[Service]
Type=simple
User=dst
Group=dst
WorkingDirectory=/home/dst/dst/bin
ExecStart=/home/dst/dst/bin/dontstarve_dedicated_server_nullrenderer -console -cluster MyDediServer -shard Caves
Restart=on-failure
RestartSec=30

[Install]
WantedBy=multi-user.target
EOF

# 9. Fix permissions
chown -R dst:dst /home/dst

# 10. Enable and start services
echo "Enabling and starting services..."
systemctl daemon-reload
systemctl enable dst-master dst-caves
systemctl start dst-master

# Wait a bit before starting Caves to avoid port conflicts
sleep 10
systemctl start dst-caves

echo "=== Installation Complete ==="
echo "Server configuration:"
echo "- Master server: port 10999/udp"
echo "- Caves server: port 10998/udp"
echo "- Cluster key: supersecretkey"
echo ""
echo "Management commands:"
echo "  systemctl status dst-master    # Check Master server status"
echo "  systemctl status dst-caves     # Check Caves server status"
echo "  journalctl -u dst-master -f    # View Master server logs"
echo "  journalctl -u dst-caves -f     # View Caves server logs"
echo ""
echo "Don't forget to:"
echo "1. Place your cluster token in /home/dst/.klei/DoNotStarveTogether/MyDediServer/cluster_token.txt"
echo "2. Add mods to /home/dst/dst/mods/dedicated_server_mods_setup.lua if needed"
echo "3. Configure mod settings in modoverrides.lua files"