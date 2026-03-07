#!/bin/bash

# ==============================
# Root privilege enforcement
# ==============================
if [ "$EUID" -ne 0 ]; then
  echo "❌ This installer must be run as root."
  echo "Use: sudo bash setup_mc.sh"
  exit 1
fi

set -e

echo "Updating system..."
apt update -y
apt upgrade -y

echo "Installing dependencies..."
apt install -y openjdk-21-jdk-headless curl wget jq ufw

echo "Creating server directory..."
mkdir -p /root/server
cd /root/server

echo "Fetching latest Paper version..."
LATEST_VERSION=$(curl -s https://api.papermc.io/v2/projects/paper | jq -r '.versions[-1]')
LATEST_BUILD=$(curl -s https://api.papermc.io/v2/projects/paper/versions/$LATEST_VERSION | jq -r '.builds[-1]')

echo "Downloading Paper $LATEST_VERSION build $LATEST_BUILD..."
wget -O server.jar \
https://api.papermc.io/v2/projects/paper/versions/$LATEST_VERSION/builds/$LATEST_BUILD/downloads/paper-$LATEST_VERSION-$LATEST_BUILD.jar

echo "Accepting EULA..."
echo "eula=true" > eula.txt

echo "Creating start script..."
cat > start.sh << 'EOF'
#!/bin/bash
java -Xms8G -Xmx12G \
-XX:+UseG1GC \
-XX:+ParallelRefProcEnabled \
-XX:MaxGCPauseMillis=200 \
-XX:+UnlockExperimentalVMOptions \
-XX:+DisableExplicitGC \
-XX:+AlwaysPreTouch \
-XX:G1NewSizePercent=30 \
-XX:G1MaxNewSizePercent=40 \
-XX:G1HeapRegionSize=8M \
-XX:G1ReservePercent=20 \
-XX:G1HeapWastePercent=5 \
-XX:G1MixedGCCountTarget=4 \
-XX:InitiatingHeapOccupancyPercent=15 \
-XX:G1MixedGCLiveThresholdPercent=90 \
-XX:G1RSetUpdatingPauseTimePercent=5 \
-XX:SurvivorRatio=32 \
-XX:+PerfDisableSharedMem \
-XX:MaxTenuringThreshold=1 \
-jar server.jar nogui
EOF

chmod +x start.sh

echo "Configuring firewall..."
ufw allow 25565/tcp
ufw allow 19132/udp
ufw --force enable

echo "Creating plugins directory..."
mkdir -p plugins
cd plugins

echo "Downloading ViaBackwards..."
wget -O ViaBackwards-5.7.2.jar \
https://hangarcdn.papermc.io/plugins/ViaVersion/ViaBackwards/versions/5.7.2/PAPER/ViaBackwards-5.7.2.jar

echo "Downloading ViaVersion..."
wget -O ViaVersion-5.7.2.jar \
https://hangarcdn.papermc.io/plugins/ViaVersion/ViaVersion/versions/5.7.2/PAPER/ViaVersion-5.7.2.jar

echo "Downloading Geyser..."
wget --content-disposition \
https://download.geysermc.org/v2/projects/geyser/versions/latest/builds/latest/downloads/spigot

echo "Downloading Floodgate..."
wget --content-disposition \
https://download.geysermc.org/v2/projects/floodgate/versions/latest/builds/latest/downloads/spigot

cd ..

echo "Creating server.properties..."
cat > server.properties << 'EOF'
online-mode=false
max-players=99
allow-flight=true
motd=§0§l§kgg§4§l§n1.21.11§0§l§kgg
EOF

SERVER_DIR="/root/server"

echo ""
echo "======================================="
echo " Installation Complete"
echo "======================================="
echo "Switching to server directory..."
echo ""

cd "$SERVER_DIR" || {
    echo "Failed to enter $SERVER_DIR"
    exit 1
}

exec bash
