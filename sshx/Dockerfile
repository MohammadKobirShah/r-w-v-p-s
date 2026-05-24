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
    LINK=$(grep -oP 'https://sshx\.io/s/[^\s]+' "$LOG_FILE" 2>/dev/null | head -1)

    if [ -n "$LINK" ]; then
        echo "$LINK" > "$LINK_FILE"
        echo ""
        echo "============================================"
        echo "  sshx is running!"
        echo "============================================"
        echo ""
        echo "  Access Link:"
        echo ""
        echo "     $LINK"
        echo ""
        echo "============================================"
        break
    fi

    sleep 1
    ELAPSED=$((ELAPSED + 1))
done

if [ -z "$LINK" ]; then
    echo "Timeout: Could not get sshx link after ${TIMEOUT}s"
    echo "--- sshx log ---"
    cat "$LOG_FILE"
    exit 1
fi

# Start redirect server on port 8080
REDIRECT_LINK="$LINK"
python3 -c "
import http.server

REDIRECT_URL = '${REDIRECT_LINK}'

class RedirectHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(302)
        self.send_header('Location', REDIRECT_URL)
        self.end_headers()
        html = f'''<html>
<head><meta http-equiv=\"refresh\" content=\"0;url={REDIRECT_URL}\"></head>
<body>
<h2>Redirecting to sshx...</h2>
<p><a href=\"{REDIRECT_URL}\">{REDIRECT_URL}</a></p>
</body></html>'''
        self.wfile.write(html.encode())

    def log_message(self, format, *args):
        pass

print('Redirect server started on port 8080')
server = http.server.HTTPServer(('0.0.0.0', 8080), RedirectHandler)
server.serve_forever()
" &

echo "Redirect server running on port 8080"
echo "Open http://localhost:8080 to auto-redirect to sshx"
echo ""

# Keep container alive and monitor sshx process
while kill -0 $SSHX_PID 2>/dev/null; do
    sleep 30
    echo "sshx link: $(cat $LINK_FILE)"
done

echo "sshx process died, restarting..."
exec /entrypoint.sh
EOF

RUN chmod +x /entrypoint.sh

EXPOSE 8080

ENTRYPOINT ["/entrypoint.sh"]
