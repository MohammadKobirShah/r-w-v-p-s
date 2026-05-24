#!/bin/bash

set -e

LOG_FILE="/var/log/sshx.log"
LINK_FILE="/tmp/sshx_link.txt"

echo "============================================"
echo "  Starting sshx in background..."
echo "============================================"

# Start sshx in background and capture output
sshx run 2>&1 | tee "$LOG_FILE" &
SSHX_PID=$!

echo "sshx PID: $SSHX_PID"
echo ""

# Wait for sshx link to appear in logs
echo "Waiting for sshx link..."
TIMEOUT=60
ELAPSED=0

while [ $ELAPSED -lt $TIMEOUT ]; do
    # Extract sshx link from log
    LINK=$(grep -oP 'https://sshx\.io/s/[^\s]+' "$LOG_FILE" 2>/dev/null | head -1)
    
    if [ -n "$LINK" ]; then
        echo "$LINK" > "$LINK_FILE"
        echo ""
        echo "============================================"
        echo "  ✅ sshx is running!"
        echo "============================================"
        echo ""
        echo "  🔗 Access Link:"
        echo ""
        echo "     $LINK"
        echo ""
        echo "============================================"
        echo ""
        echo "  Open the link above in your browser"
        echo "  to access this container via sshx"
        echo ""
        echo "============================================"
        break
    fi
    
    sleep 1
    ELAPSED=$((ELAPSED + 1))
done

if [ -z "$LINK" ]; then
    echo "❌ Timeout: Could not get sshx link after ${TIMEOUT}s"
    echo "--- sshx log ---"
    cat "$LOG_FILE"
    exit 1
fi

# Keep container alive and monitor sshx
echo "Container is running. Press Ctrl+C to stop."
echo ""

# Monitor and reprint link every 30 seconds
while kill -0 $SSHX_PID 2>/dev/null; do
    sleep 30
    echo "🔗 sshx link: $(cat $LINK_FILE)"
done

echo "❌ sshx process died, restarting..."
exec /entrypoint.sh
