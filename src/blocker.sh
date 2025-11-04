#!/bin/bash

VERSION="2025.1"
CONFIG_FILE="/etc/dnsmasq.d/adblocker.conf"
BLOCKLIST_FILE="/opt/adblocker/blocklists/ads.hosts"

show_help() {
    echo "AdBlocker v$VERSION - Network-wide ad blocking"
    echo ""
    echo "Usage: adblocker [command]"
    echo ""
    echo "Commands:"
    echo "  start, enable    - Enable ad blocking"
    echo "  stop, disable    - Disable ad blocking"
    echo "  restart          - Restart ad blocking"
    echo "  status           - Show current status"
    echo "  update           - Update blocklists"
    echo "  test             - Test if blocking works"
    echo "  stats            - Show blocking statistics"
    echo ""
    echo "Examples:"
    echo "  adblocker start    # Enable blocking"
    echo "  adblocker status   # Check status"
    echo "  adblocker-update   # Update blocklists"
}

check_installed() {
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "❌ AdBlocker not installed. Run installer first."
        exit 1
    fi
}

case "$1" in
    start|enable)
        check_installed
        echo "🛡️  Starting AdBlocker..."
        if [ ! -f "$BLOCKLIST_FILE" ]; then
            echo "📥 No blocklists found. Downloading..."
            adblocker-update
        fi
        # Ensure config is in place
        if [ ! -f "$CONFIG_FILE" ]; then
            echo "❌ Config missing. Re-run installer."
            exit 1
        fi
        systemctl restart dnsmasq
        echo "✅ AdBlocker started"
        echo "📡 Set device DNS to: $(hostname -I | awk '{print $1}')"
        ;;
        
    stop|disable)
        echo "🛑 Stopping AdBlocker..."
        if [ -f "$CONFIG_FILE" ]; then
            rm -f "$CONFIG_FILE"
        fi
        systemctl restart dnsmasq
        echo "✅ AdBlocker stopped"
        ;;
        
    restart)
        check_installed
        echo "🔄 Restarting AdBlocker..."
        systemctl restart dnsmasq
        echo "✅ AdBlocker restarted"
        ;;
        
    status)
        echo "=== AdBlocker Status ==="
        if [ -f "$CONFIG_FILE" ]; then
            echo "🟢 AdBlocker: ENABLED"
        else
            echo "🔴 AdBlocker: DISABLED"
        fi
        
        if [ -f "$BLOCKLIST_FILE" ]; then
            COUNT=$(wc -l < "$BLOCKLIST_FILE" 2>/dev/null || echo "0")
            echo "📊 Blocking $COUNT domains"
        else
            echo "📊 Blocklists: Not downloaded"
        fi
        
        echo -e "\n=== dnsmasq Service ==="
        systemctl is-active dnsmasq > /dev/null && echo "🟢 dnsmasq: RUNNING" || echo "🔴 dnsmasq: STOPPED"
        
        echo -e "\n=== Network Info ==="
        echo "📡 Pi IP Address: $(hostname -I | awk '{print $1}')"
        ;;
        
    update)
        check_installed
        /opt/adblocker/updater.sh
        ;;
        
    test)
        echo "🧪 Testing AdBlocker..."
        echo "Testing blocked domain (doubleclick.net):"
        nslookup doubleclick.net 2>&1 | grep -E "(Address:|can't find)"
        echo -e "\nTesting allowed domain (google.com):"
        nslookup google.com 2>&1 | grep "Address:" | head -1
        ;;
        
    stats)
        if [ -f "$BLOCKLIST_FILE" ]; then
            COUNT=$(wc -l < "$BLOCKLIST_FILE")
            echo "📊 Blocking Statistics:"
            echo "   Total domains blocked: $COUNT"
            echo "   Last updated: $(stat -c %y "$BLOCKLIST_FILE" 2>/dev/null | cut -d' ' -f1) || echo "Unknown")"
        else
            echo "❌ No blocklists found. Run 'adblocker-update' first."
        fi
        ;;
        
    -h|--help|help)
        show_help
        ;;
        
    *)
        echo "❌ Unknown command: $1"
        echo ""
        show_help
        exit 1
        ;;
esac
