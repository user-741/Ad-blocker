#!/bin/bash

echo "📥 Updating ad blocklists..."
SOURCES="/opt/adblocker/sources.txt"
BLOCKLIST="/opt/adblocker/blocklists/ads.hosts"
TEMP_FILE=$(mktemp)

# Download from all sources
while IFS= read -r url; do
    [[ $url = \#* ]] || [[ -z $url ]] && continue
    echo "Downloading from: $url"
    curl -s "$url" >> "$TEMP_FILE"
done < "$SOURCES"

# Process and deduplicate
echo "🧹 Processing blocklists..."
grep -h '^0\.0\.0\.0' "$TEMP_FILE" | awk '{print $2}' | sort -u | awk '{print "0.0.0.0 "$0}' > "$BLOCKLIST"

COUNT=$(wc -l < "$BLOCKLIST")
rm "$TEMP_FILE"

# Restart dnsmasq to apply changes
systemctl restart dnsmasq

echo "✅ Updated! Now blocking $COUNT domains"
