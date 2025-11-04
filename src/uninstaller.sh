#!/bin/bash

echo "🗑️  AdBlocker Uninstaller"
echo "========================"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ Please run as root: sudo adblocker-uninstall"
    exit 1
fi

echo "This will completely remove AdBlocker from your system."
read -p "Are you sure? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Uninstall cancelled."
    exit 1
fi

echo "🛑 Stopping services..."
systemctl stop dnsmasq 2>/dev/null || true

echo "📁 Removing configuration files..."
rm -f /etc/dnsmasq.d/adblocker.conf

echo "🔧 Restoring dnsmasq..."
systemctl restart dnsmasq

echo "📄 Removing scripts and data..."
rm -rf /opt/adblocker

echo "🔗 Removing symlinks..."
rm -f /usr/local/bin/adblocker
rm -f /usr/local/bin/adblocker-update
rm -f /usr/local/bin/adblocker-uninstall

echo "✅ AdBlocker completely uninstalled!"
echo ""
echo "Note: dnsmasq is still installed but running with default configuration."
