#!/bin/bash

set -e

echo "🧹 AdBlocker for Raspberry Pi - Installer"
echo "=========================================="

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ Please run as root: sudo ./installer.sh"
    exit 1
fi

# Install dependencies
echo "📦 Installing dependencies..."
apt update
apt install -y dnsmasq curl

# Create directories
echo "📁 Creating directory structure..."
mkdir -p /opt/adblocker/blocklists
mkdir -p /opt/adblocker/logs
mkdir -p /etc/dnsmasq.d

# Create adblocker config
echo "⚙️  Setting up configuration..."
cat > /etc/dnsmasq.d/adblocker.conf << 'EOF'
# AdBlocker Configuration
interface=eth0
interface=wlan0

# Basic settings
domain-needed
bogus-priv

# Upstream DNS
server=8.8.8.8
server=1.1.1.1

# Block IPv6
filter-AAAA

# Logging
log-queries
log-facility=/opt/adblocker/logs/dnsmasq.log

# Blocklists
addn-hosts=/opt/adblocker/blocklists/ads.hosts
EOF

# Create sources file
cat > /opt/adblocker/sources.txt << 'EOF'
https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts
https://adaway.org/hosts.txt
https://www.github.developerdan.com/hosts/lists/ads-and-tracking-extended.txt
https://pgl.yoyo.org/adservers/serverlist.php?hostformat=hosts&showintro=0&mimetype=plaintext
https://raw.githubusercontent.com/jerryn70/GoodbyeAds/master/Hosts/GoodbyeAds.txt

# YouTube Specific Blocklists
https://raw.githubusercontent.com/kboghdady/youTube_ads_4_pi-hole/master/blacklist.txt
https://raw.githubusercontent.com/Perflyst/PiHoleBlocklist/master/SmartTV-AGH.txt
https://raw.githubusercontent.com/badmojr/1Hosts/master/mini/hosts.txt
EOF

# Copy scripts to /opt/adblocker
echo "📄 Installing scripts..."
cp blocker.sh updater.sh uninstaller.sh /opt/adblocker/

# Make scripts executable
chmod +x /opt/adblocker/*.sh

# Create symlinks for easy commands
ln -sf /opt/adblocker/blocker.sh /usr/local/bin/adblocker
ln -sf /opt/adblocker/updater.sh /usr/local/bin/adblocker-update
ln -sf /opt/adblocker/uninstaller.sh /usr/local/bin/adblocker-uninstall

# Download initial blocklists
echo "📥 Downloading blocklists..."
/opt/adblocker/updater.sh

# Create and enable boot service
echo "🔧 Creating auto-start service..."
cat > /etc/systemd/system/adblocker-boot.service << 'EOF'
[Unit]
Description=AdBlocker Auto-Start Service
After=network.target
Wants=network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/local/bin/adblocker start
ExecStop=/usr/local/bin/adblocker stop
TimeoutStartSec=300

[Install]
WantedBy=multi-user.target
EOF

# Enable services
systemctl daemon-reload
systemctl enable adblocker-boot.service
systemctl enable dnsmasq

# Start services
systemctl start adblocker-boot.service

echo "✅ Installation complete!"
echo ""
echo "Quick Commands:"
echo "  sudo adblocker start    - Start blocking"
echo "  sudo adblocker stop     - Stop blocking"
echo "  sudo adblocker status   - Check status"
echo "  sudo adblocker-update   - Update blocklists"
echo ""
echo "Set your device DNS to: $(hostname -I | awk '{print $1}')"
echo "Test with: nslookup doubleclick.net"
echo ""
echo "🔌 Auto-start: ENABLED - Will start automatically on boot!"
