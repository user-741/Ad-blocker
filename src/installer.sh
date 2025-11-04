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
mkdir -p /etc/adblocker

# Copy configuration
echo "⚙️  Setting up configuration..."
cp config/dnsmasq.conf /etc/dnsmasq.conf
cp blocklists/sources.txt /opt/adblocker/

# Download initial blocklists
echo "📥 Downloading blocklists..."
/opt/adblocker/updater.sh

# Backup original resolv.conf
cp /etc/resolv.conf /etc/resolv.conf.backup.adblocker

# Create systemd service
echo "🎯 Creating system service..."
cat > /etc/systemd/system/adblocker.service << EOF
[Unit]
Description=AdBlocker DNS Service
After=network.target

[Service]
Type=forking
ExecStart=/opt/adblocker/blocker.sh start
ExecStop=/opt/adblocker/blocker.sh stop
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

# Make scripts executable
chmod +x /opt/adblocker/*.sh

# Enable and start service
systemctl daemon-reload
systemctl enable adblocker
systemctl start adblocker

echo "✅ Installation complete!"
echo ""
echo "Quick Commands:"
echo "  sudo adblocker start    - Start blocking"
echo "  sudo adblocker stop     - Stop blocking" 
echo "  sudo adblocker update   - Update blocklists"
echo "  sudo adblocker status   - Check status"
echo ""
echo "Set your device DNS to: $(hostname -I | awk '{print $1}')"
