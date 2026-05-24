FROM ubuntu:22.04

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    bash \
    python3 \
    && rm -rf /var/lib/apt/lists/*

# Install sshx
RUN curl -sSf https://sshx.io/get | sh

# Create entrypoint script inline
RUN cat > /entrypoint.sh << 'EOF'
#!/bin/bash

LOG_FILE="/var/log/sshx.log"
LINK_FILE="/tmp/sshx_link.txt"

echo "============================================"
echo "  Starting sshx in background..."
echo "============================================"

# Check sshx help to confirm correct usage
echo "--- sshx --help ---"
sshx --help 2>&1 || true
echo "-------------------"

# Start sshx without 'run' argument
sshx 2>&1 | tee "$LOG_FILE" &
SSHX_PID=$!

echo "sshx PID: $SSHX_PID"
echo ""

# Wait for sshx link to appear in logs
echo "Waiting for sshx link..."
TIMEOUT=60
ELAPSED=0

while [ $ELAPSED -lt $TIMEOUT ]; do
    # Try multiple link patterns
    LINK=$(grep -oE 'https://sshx\.io/s/[^[:space:]]+' "$LOG_FILE" 2>/dev/null | head -1)

    if [ -n "$LINK" ]; then
        echo "$LINK" > "$LINK_FILE"
        echo ""
        echo "============================================"
        echo "  sshx is running!"
        echo "============================================"
        echo ""
        echo "  Access Link:"
        echo ""
        echo "  --> $LINK"
        echo ""
        echo "============================================"

        # Start redirect server on port 8080
        python3 - "$LINK" &

        echo "Redirect server running on port 8080"
        break
    fi

    sleep 1
    ELAPSED=$((ELAPSED + 1))
done

if [ -z "$LINK" ]; then
    echo ""
    echo "Timeout: Could not get sshx link after ${TIMEOUT}s"
    echo "--- sshx log ---"
    cat "$LOG_FILE"
    exit 1
fi

# Keep container alive
echo ""
echo "Container running. Monitoring sshx..."
echo ""
while true; do
    sleep 30
    if ! kill -0 $SSHX_PID 2>/dev/null; then
        echo "sshx process died, restarting..."
        exec /entrypoint.sh
    fi
    echo "sshx still running --> $(cat $LINK_FILE 2>/dev/null)"
done
EOF

# Create python redirect server script
RUN cat > /redirect_server.py << 'EOF'
import http.server
import sys

REDIRECT_URL = sys.argv[1] if len(sys.argv) > 1 else "https://sshx.io"

class RedirectHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(302)
        self.send_header('Location', REDIRECT_URL)
        self.end_headers()
        html = f"""<html>
<head>
  <meta http-equiv="refresh" content="0;url={REDIRECT_URL}">
  <title>Redirecting to sshx...</title>
</head>
<body style="font-family:monospace;padding:40px;background:#1a1a1a;color:#00ff00;">
  <h2>🔗 Redirecting to sshx...</h2>
  <p>If not redirected automatically:</p>
  <p><a href="{REDIRECT_URL}" style="color:#00ff00;">{REDIRECT_URL}</a></p>
</body>
</html>"""
        self.wfile.write(html.encode())

    def log_message(self, format, *args):
        print(f"[redirect] {args[0]} {args[1]}")

print(f"[redirect] Server started on port 8080")
print(f"[redirect] Redirecting to: {REDIRECT_URL}")
server = http.server.HTTPServer(('0.0.0.0', 8080), RedirectHandler)
server.serve_forever()
EOF

# Fix entrypoint to use the python script properly
RUN sed -i 's|python3 - "$LINK" \&|python3 /redirect_server.py "$LINK" \&|' /entrypoint.sh

RUN chmod +x /entrypoint.sh

EXPOSE 8080

ENTRYPOINT ["/entrypoint.sh"]
