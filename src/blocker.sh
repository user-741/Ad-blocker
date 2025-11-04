#!/bin/bash

CONFIG_DIR="/etc/adblocker"
BLOCKLIST_DIR="/opt/adblocker/blocklists"
LOG_DIR="/opt/adblocker/logs"

case "$1" in
    start)
        echo "🛡️  Starting AdBlocker..."
        systemctl start adblocker
        systemctl is-active adblocker > /dev/null && echo "✅ AdBlocker started" || echo "❌ Failed to start"
        ;;
    stop)
        echo "🛑 Stopping AdBlocker..."
        systemctl stop adblocker
        echo "✅ AdBlocker stopped"
        ;;
    restart)
        systemctl restart adblocker
        echo "🔄 AdBlocker restarted"
        ;;
    status)
        systemctl status adblocker --no-pager -l
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status}"
        exit 1
        ;;
esac
