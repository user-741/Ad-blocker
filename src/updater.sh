#!/bin/bash

set -e

SOURCES_FILE="/opt/adblocker/sources.txt"
BLOCKLIST_FILE="/opt/adblocker/blocklists/ads.hosts"
TEMP_FILE=$(mktemp)
LOG_FILE="/opt/adblocker/logs/update.log"

# Create logs directory
mkdir -p /opt/adblocker/logs

# Log function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log "Starting blocklist update..."

# Check if sources file exists
if [ ! -f "$SOURCES_FILE" ]; then
    log "❌ Sources file not found: $SOURCES_FILE"
    exit 1
fi

log "📥 Downloading blocklists from sources..."

# Counter for successful downloads
SUCCESS_COUNT=0
TOTAL_SOURCES=$(grep -v '^#' "$SOURCES_FILE" | grep -v '^$' | wc -l)

# Download from all sources
while IFS= read -r url; do
    [[ $url = \#* ]] || [[ -z $url ]] && continue
    
    log "Downloading: $url"
    if curl -s --connect-timeout 30 "$url" >> "$TEMP_FILE"; then
        ((SUCCESS_COUNT++))
        log "  ✅ Success"
    else
        log "  ❌ Failed"
    fi
done < "$SOURCES_FILE"

if [ "$SUCCESS_COUNT" -eq 0 ]; then
    log "❌ Failed to download any blocklists"
    rm -f "$TEMP_FILE"
    exit 1
fi

log "🧹 Processing and deduplicating blocklists..."

# Process hosts files: extract domains, deduplicate, and format
grep -h '^0\.0\.0\.0' "$TEMP_FILE" | awk '{print $2}' | \
    sort -u | \
    awk '{print "0.0.0.0 "$0}' > "$BLOCKLIST_FILE"

FINAL_COUNT=$(wc -l < "$BLOCKLIST_FILE")
rm -f "$TEMP_FILE"

log "🔄 Restarting dnsmasq to apply changes..."
systemctl restart dnsmasq

log "✅ Update complete! Successfully downloaded from $SUCCESS_COUNT/$TOTAL_SOURCES sources"
log "✅ Now blocking $FINAL_COUNT domains"

# Show final status
echo ""
echo "📊 Update Summary:"
echo "   Sources: $SUCCESS_COUNT/$TOTAL_SOURCES successful"
echo "   Domains blocked: $FINAL_COUNT"
echo "   Log file: $LOG_FILE"
