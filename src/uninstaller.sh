#!/bin/bash

echo "🗑️  Uninstalling AdBlocker..."

systemctl stop adblocker
systemctl disable adblocker
rm -f /etc/systemd/system/adblocker.service
systemctl daemon-reload

# Restore original dnsmasq config
apt install --reinstall -y dnsmasq

# Remove files
rm -rf /opt/adblocker
rm -rf /etc/adblocker

# Restore original resolv.conf if backup exists
[ -f /etc/resolv.conf.backup.adblocker ] && mv /etc/resolv.conf.backup.adblocker /etc/resolv.conf

echo "✅ AdBlocker completely uninstalled"
