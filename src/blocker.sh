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
    if [ ! -d "/opt/adblocker" ]; then
        echo "❌ AdBlocker not installed. Run installer first."
        exit 1
    fi
}

ensure_config() {
    # Ensure config directory exists
    mkdir -p /etc/dnsmasq.d
    
    # Create config file if missing
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "📄 Creating adblocker configuration..."
        cat > "$CONFIG_FILE" << 'CONFIG_EOF'
# AdBlocker Configuration
interface=eth0
interface=wlan0
domain-needed
bogus-priv
server=8.8.8.8
server=1.1.1.1
filter-AAAA
log-queries
log-facility=/opt/adblocker/logs/dnsmasq.log
addn-hosts=/opt/adblocker/blocklists/ads.hosts
CONFIG_EOF
    fi
}

case "$1" in
    start|enable)
        check_installed
        echo "🛡️  Starting AdBlocker..."
        
        # Ensure config exists
        ensure_config
        
        if [ ! -f "$BLOCKLIST_FILE" ]; then
            echo "📥 No blocklists found. Downloading..."
            adblocker-update
        fi
        
        # Restart dnsmasq to apply config
        systemctl restart dnsmasq
        
        # Start and enable the boot service
        systemctl enable adblocker-boot.service > /dev/null 2>&1 || true
        systemctl start adblocker-boot.service > /dev/null 2>&1 || true
        
        echo "✅ AdBlocker started"
        echo "📡 Set device DNS to: $(hostname -I | awk '{print $1}')"
        echo "🔌 Auto-start: ENABLED"
        ;;
        
    stop|disable)
        echo "🛑 Stopping AdBlocker..."
        if [ -f "$CONFIG_FILE" ]; then
            rm -f "$CONFIG_FILE"
        fi
        systemctl restart dnsmasq
        systemctl stop adblocker-boot.service > /dev/null 2>&1 || true
        systemctl disable adblocker-boot.service > /dev/null 2>&1 || true
        echo "✅ AdBlocker stopped"
        echo "🔌 Auto-start: DISABLED"
        ;;
        
    restart)
        check_installed
        echo "🔄 Restarting AdBlocker..."
        ensure_config
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
        
        echo -e "\n=== Services ==="
        systemctl is-active dnsmasq > /dev/null && echo "🟢 dnsmasq: RUNNING" || echo "🔴 dnsmasq: STOPPED"
        systemctl is-enabled adblocker-boot.service > /dev/null 2>&1 && echo "🟢 auto-start: ENABLED" || echo "🔴 auto-start: DISABLED"
        
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
            echo "   Last updated: $(stat -c %y "$BLOCKLIST_FILE" 2>/dev/null | cut -d' ' -f1 || echo "Unknown")"
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
