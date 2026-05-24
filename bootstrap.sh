#!/bin/bash
# ============================================================
# ULTRA VPS BOOTSTRAP SCRIPT - Railway Deploy Friendly
# Author: VPS Expert
# Version: 3.0
# Features: SSH Server, Web Panel, Security, Monitoring
# ============================================================

set -e

# ============================
# 🎨 COLORS & STYLING
# ============================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# ============================
# 📋 CONFIGURATION
# ============================
VPS_USER="${VPS_USER:-vpsuser}"
VPS_PASS="${VPS_PASS:-VpsSecure@2024}"
SSH_PORT="${SSH_PORT:-2222}"
WEB_PORT="${PORT:-8080}"
PANEL_PORT="${PANEL_PORT:-9090}"
ROOT_PASS="${ROOT_PASS:-RootSecure@2024}"
HOSTNAME="${HOSTNAME:-railway-vps}"

# ============================
# 🖨️ BANNER
# ============================
print_banner() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════╗"
    echo "║       🚀 ULTRA VPS BOOTSTRAP - RAILWAY READY        ║"
    echo "║              Real Boot VPS Environment               ║"
    echo "║                    Version 3.0                       ║"
    echo "╚══════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# ============================
# 📝 LOGGING FUNCTIONS
# ============================
log_info()    { echo -e "${GREEN}[INFO]${NC}  $1"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC}  $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1"; }
log_step()    { echo -e "${BLUE}[STEP]${NC}  ══> $1"; }
log_success() { echo -e "${GREEN}[✓]${NC} $1"; }

# ============================
# 🔍 SYSTEM DETECTION
# ============================
detect_system() {
    log_step "Detecting System..."
    
    # Detect OS
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
        OS_VERSION=$VERSION_ID
    elif [ -f /etc/debian_version ]; then
        OS="Debian"
    elif [ -f /etc/redhat-release ]; then
        OS="RedHat"
    else
        OS="Unknown"
    fi

    # Detect Architecture
    ARCH=$(uname -m)
    KERNEL=$(uname -r)
    CPU_CORES=$(nproc)
    RAM_TOTAL=$(free -m | awk '/^Mem:/{print $2}')
    DISK_TOTAL=$(df -h / | awk 'NR==2{print $2}')

    echo -e "${PURPLE}"
    echo "┌─────────────────────────────────────┐"
    echo "│           SYSTEM INFORMATION         │"
    echo "├─────────────────────────────────────┤"
    printf "│ %-12s : %-22s│\n" "OS" "$OS"
    printf "│ %-12s : %-22s│\n" "Version" "$OS_VERSION"
    printf "│ %-12s : %-22s│\n" "Kernel" "$KERNEL"
    printf "│ %-12s : %-22s│\n" "Arch" "$ARCH"
    printf "│ %-12s : %-22s│\n" "CPU Cores" "$CPU_CORES"
    printf "│ %-12s : %-22s│\n" "RAM" "${RAM_TOTAL}MB"
    printf "│ %-12s : %-22s│\n" "Disk" "$DISK_TOTAL"
    echo "└─────────────────────────────────────┘"
    echo -e "${NC}"
    
    log_success "System detected: $OS $OS_VERSION"
}

# ============================
# 📦 INSTALL DEPENDENCIES
# ============================
install_dependencies() {
    log_step "Installing Core Dependencies..."
    
    export DEBIAN_FRONTEND=noninteractive
    
    # Update system
    apt-get update -qq 2>/dev/null || yum update -y -q 2>/dev/null || true
    
    # Core packages
    PACKAGES=(
        "openssh-server"
        "openssh-client"
        "sudo"
        "curl"
        "wget"
        "git"
        "vim"
        "nano"
        "htop"
        "screen"
        "tmux"
        "net-tools"
        "netcat-openbsd"
        "iputils-ping"
        "dnsutils"
        "iptables"
        "ufw"
        "fail2ban"
        "unzip"
        "zip"
        "tar"
        "gzip"
        "python3"
        "python3-pip"
        "nodejs"
        "npm"
        "nginx"
        "supervisor"
        "cron"
        "rsync"
        "lsof"
        "strace"
        "tcpdump"
        "nmap"
        "whois"
        "jq"
        "bc"
        "pwgen"
    )

    for pkg in "${PACKAGES[@]}"; do
        if ! dpkg -l "$pkg" &>/dev/null; then
            apt-get install -y -qq "$pkg" 2>/dev/null && \
                log_success "Installed: $pkg" || \
                log_warn "Skipped: $pkg (not available)"
        else
            log_info "Already installed: $pkg"
        fi
    done
}

# ============================
# 🔐 SSH SERVER SETUP
# ============================
setup_ssh() {
    log_step "Configuring SSH Server..."

    # Generate host keys if missing
    ssh-keygen -A 2>/dev/null || true

    # Backup original config
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak 2>/dev/null || true

    # Write optimized SSH config
    cat > /etc/ssh/sshd_config << EOF
# ==============================
# Railway VPS - SSH Configuration
# ==============================
Port ${SSH_PORT}
AddressFamily any
ListenAddress 0.0.0.0

# Authentication
PermitRootLogin yes
PubkeyAuthentication yes
PasswordAuthentication yes
PermitEmptyPasswords no
ChallengeResponseAuthentication no
UsePAM yes

# Security
MaxAuthTries 10
MaxSessions 20
LoginGraceTime 60
ClientAliveInterval 60
ClientAliveCountMax 10

# Features
X11Forwarding no
PrintMotd no
AcceptEnv LANG LC_*
Subsystem sftp /usr/lib/openssh/sftp-server

# Performance
Compression yes
TCPKeepAlive yes
UseDNS no

# Logging
LogLevel INFO
SyslogFacility AUTH
EOF

    # Create privilege separation dir
    mkdir -p /var/run/sshd
    chmod 0755 /var/run/sshd

    log_success "SSH configured on port ${SSH_PORT}"
}

# ============================
# 👤 USER MANAGEMENT
# ============================
setup_users() {
    log_step "Setting up VPS Users..."

    # Set root password
    echo "root:${ROOT_PASS}" | chpasswd
    log_success "Root password set"

    # Create VPS user
    if ! id "$VPS_USER" &>/dev/null; then
        useradd -m -s /bin/bash -G sudo "$VPS_USER"
        log_success "User created: $VPS_USER"
    else
        log_info "User already exists: $VPS_USER"
    fi

    # Set user password
    echo "${VPS_USER}:${VPS_PASS}" | chpasswd
    log_success "Password set for: $VPS_USER"

    # Configure sudo without password
    echo "${VPS_USER} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${VPS_USER}
    chmod 440 /etc/sudoers.d/${VPS_USER}

    # Create SSH directory
    mkdir -p /home/${VPS_USER}/.ssh
    chmod 700 /home/${VPS_USER}/.ssh
    chown -R ${VPS_USER}:${VPS_USER} /home/${VPS_USER}/.ssh

    log_success "User setup complete: $VPS_USER"
}

# ============================
# 🌐 WEB PANEL SETUP
# ============================
setup_web_panel() {
    log_step "Building Web Management Panel..."

    mkdir -p /var/www/vps-panel
    
    # Generate dynamic stats script
    cat > /var/www/vps-panel/stats.sh << 'STATSEOF'
#!/bin/bash
CPU=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
RAM_USED=$(free -m | awk '/^Mem:/{print $3}')
RAM_TOTAL=$(free -m | awk '/^Mem:/{print $2}')
RAM_PERCENT=$(awk "BEGIN {printf \"%.1f\", ($RAM_USED/$RAM_TOTAL)*100}")
DISK_USED=$(df -h / | awk 'NR==2{print $3}')
DISK_TOTAL=$(df -h / | awk 'NR==2{print $2}')
DISK_PERCENT=$(df / | awk 'NR==2{print $5}' | tr -d '%')
UPTIME=$(uptime -p)
LOAD=$(uptime | awk -F'load average:' '{print $2}' | xargs)
USERS=$(who | wc -l)
PROCS=$(ps aux | wc -l)
NET_IN=$(cat /proc/net/dev | grep -E "eth0|ens3|enp" | head -1 | awk '{print $2}' 2>/dev/null || echo "0")
NET_OUT=$(cat /proc/net/dev | grep -E "eth0|ens3|enp" | head -1 | awk '{print $10}' 2>/dev/null || echo "0")

echo "{
  \"cpu\": \"$CPU\",
  \"ram_used\": \"$RAM_USED\",
  \"ram_total\": \"$RAM_TOTAL\",
  \"ram_percent\": \"$RAM_PERCENT\",
  \"disk_used\": \"$DISK_USED\",
  \"disk_total\": \"$DISK_TOTAL\",
  \"disk_percent\": \"$DISK_PERCENT\",
  \"uptime\": \"$UPTIME\",
  \"load\": \"$LOAD\",
  \"users\": \"$USERS\",
  \"processes\": \"$PROCS\",
  \"net_in\": \"$NET_IN\",
  \"net_out\": \"$NET_OUT\",
  \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"
}"
STATSEOF
    chmod +x /var/www/vps-panel/stats.sh

    # Create main HTML panel
    cat > /var/www/vps-panel/index.html << HTMLEOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>🚀 Railway VPS Panel</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #0a0a0a 0%, #1a1a2e 50%, #0f3460 100%);
            color: #e0e0e0;
            min-height: 100vh;
        }
        .header {
            background: rgba(255,255,255,0.05);
            backdrop-filter: blur(10px);
            border-bottom: 1px solid rgba(255,255,255,0.1);
            padding: 20px 30px;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        .header h1 { font-size: 24px; color: #00d4ff; }
        .status-dot {
            width: 12px; height: 12px;
            background: #00ff88;
            border-radius: 50%;
            display: inline-block;
            animation: pulse 2s infinite;
            margin-right: 8px;
        }
        @keyframes pulse {
            0% { box-shadow: 0 0 0 0 rgba(0,255,136,0.7); }
            70% { box-shadow: 0 0 0 10px rgba(0,255,136,0); }
            100% { box-shadow: 0 0 0 0 rgba(0,255,136,0); }
        }
        .container { max-width: 1400px; margin: 0 auto; padding: 30px; }
        .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 20px; margin-bottom: 30px; }
        .card {
            background: rgba(255,255,255,0.05);
            backdrop-filter: blur(10px);
            border: 1px solid rgba(255,255,255,0.1);
            border-radius: 15px;
            padding: 25px;
            transition: transform 0.3s, box-shadow 0.3s;
        }
        .card:hover { transform: translateY(-5px); box-shadow: 0 20px 40px rgba(0,212,255,0.1); }
        .card-title {
            font-size: 12px;
            text-transform: uppercase;
            letter-spacing: 2px;
            color: #888;
            margin-bottom: 15px;
        }
        .card-value { font-size: 36px; font-weight: bold; color: #00d4ff; }
        .card-sub { font-size: 13px; color: #888; margin-top: 5px; }
        .progress-bar {
            height: 8px;
            background: rgba(255,255,255,0.1);
            border-radius: 10px;
            margin-top: 15px;
            overflow: hidden;
        }
        .progress-fill {
            height: 100%;
            border-radius: 10px;
            transition: width 0.5s ease;
        }
        .progress-green { background: linear-gradient(90deg, #00ff88, #00d4ff); }
        .progress-yellow { background: linear-gradient(90deg, #ffd700, #ff6b35); }
        .progress-red { background: linear-gradient(90deg, #ff4444, #ff0000); }
        .info-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 15px;
            margin-bottom: 30px;
        }
        .info-card {
            background: rgba(0,212,255,0.05);
            border: 1px solid rgba(0,212,255,0.2);
            border-radius: 10px;
            padding: 15px;
        }
        .info-label { font-size: 11px; color: #888; text-transform: uppercase; letter-spacing: 1px; }
        .info-value { font-size: 16px; color: #00d4ff; margin-top: 5px; font-family: monospace; }
        .terminal {
            background: #0d0d0d;
            border: 1px solid #333;
            border-radius: 10px;
            padding: 20px;
            font-family: 'Courier New', monospace;
            font-size: 13px;
            max-height: 300px;
            overflow-y: auto;
        }
        .terminal-header {
            display: flex;
            align-items: center;
            margin-bottom: 15px;
            gap: 8px;
        }
        .dot { width: 12px; height: 12px; border-radius: 50%; }
        .dot-red { background: #ff5f57; }
        .dot-yellow { background: #ffbd2e; }
        .dot-green { background: #28ca41; }
        .terminal-line { color: #00ff88; margin: 3px 0; }
        .terminal-line span { color: #888; }
        .ssh-box {
            background: #0d0d0d;
            border: 1px solid #00d4ff;
            border-radius: 10px;
            padding: 20px;
            margin-bottom: 30px;
        }
        .ssh-title { color: #00d4ff; margin-bottom: 15px; font-size: 16px; }
        .ssh-cmd {
            background: #1a1a1a;
            border: 1px solid #333;
            border-radius: 8px;
            padding: 12px 15px;
            font-family: monospace;
            font-size: 14px;
            color: #00ff88;
            margin: 8px 0;
            cursor: pointer;
            position: relative;
            word-break: break-all;
        }
        .ssh-cmd:hover { background: #222; border-color: #00d4ff; }
        .copy-btn {
            position: absolute;
            right: 10px;
            top: 50%;
            transform: translateY(-50%);
            background: #00d4ff;
            color: #000;
            border: none;
            border-radius: 5px;
            padding: 3px 10px;
            font-size: 11px;
            cursor: pointer;
            font-weight: bold;
        }
        .refresh-btn {
            background: linear-gradient(135deg, #00d4ff, #0099bb);
            color: #000;
            border: none;
            border-radius: 8px;
            padding: 10px 20px;
            font-size: 14px;
            font-weight: bold;
            cursor: pointer;
            margin-bottom: 20px;
        }
        .refresh-btn:hover { opacity: 0.8; }
        .footer {
            text-align: center;
            padding: 20px;
            color: #444;
            font-size: 12px;
            border-top: 1px solid rgba(255,255,255,0.05);
            margin-top: 30px;
        }
        .badge {
            display: inline-block;
            padding: 3px 10px;
            border-radius: 20px;
            font-size: 11px;
            font-weight: bold;
        }
        .badge-green { background: rgba(0,255,136,0.2); color: #00ff88; border: 1px solid #00ff88; }
        .badge-blue { background: rgba(0,212,255,0.2); color: #00d4ff; border: 1px solid #00d4ff; }
    </style>
</head>
<body>
    <div class="header">
        <h1>🚀 Railway VPS Control Panel</h1>
        <div>
            <span class="status-dot"></span>
            <span class="badge badge-green">ONLINE</span>
            &nbsp;
            <span class="badge badge-blue" id="live-time">Loading...</span>
        </div>
    </div>

    <div class="container">
        <!-- SSH Connection Info -->
        <div class="ssh-box">
            <div class="ssh-title">🔐 SSH Connection Details</div>
            <div class="info-grid">
                <div class="info-card">
                    <div class="info-label">SSH Host</div>
                    <div class="info-value" id="ssh-host">Loading...</div>
                </div>
                <div class="info-card">
                    <div class="info-label">SSH Port</div>
                    <div class="info-value">${SSH_PORT}</div>
                </div>
                <div class="info-card">
                    <div class="info-label">Username</div>
                    <div class="info-value">${VPS_USER}</div>
                </div>
                <div class="info-card">
                    <div class="info-label">Root User</div>
                    <div class="info-value">root</div>
                </div>
            </div>
            <div class="ssh-cmd" onclick="copyText(this, 'ssh-cmd-1')">
                <span id="ssh-cmd-1">ssh ${VPS_USER}@YOUR_RAILWAY_HOST -p ${SSH_PORT}</span>
                <button class="copy-btn">COPY</button>
            </div>
            <div class="ssh-cmd" onclick="copyText(this, 'ssh-cmd-2')">
                <span id="ssh-cmd-2">ssh root@YOUR_RAILWAY_HOST -p ${SSH_PORT}</span>
                <button class="copy-btn">COPY</button>
            </div>
        </div>

        <!-- Stats Cards -->
        <button class="refresh-btn" onclick="fetchStats()">⟳ Refresh Stats</button>
        
        <div class="grid">
            <div class="card">
                <div class="card-title">CPU Usage</div>
                <div class="card-value" id="cpu-val">--%</div>
                <div class="card-sub" id="cpu-sub">Loading...</div>
                <div class="progress-bar">
                    <div class="progress-fill progress-green" id="cpu-bar" style="width:0%"></div>
                </div>
            </div>
            
            <div class="card">
                <div class="card-title">Memory Usage</div>
                <div class="card-value" id="ram-val">--%</div>
                <div class="card-sub" id="ram-sub">Loading...</div>
                <div class="progress-bar">
                    <div class="progress-fill progress-yellow" id="ram-bar" style="width:0%"></div>
                </div>
            </div>
            
            <div class="card">
                <div class="card-title">Disk Usage</div>
                <div class="card-value" id="disk-val">--%</div>
                <div class="card-sub" id="disk-sub">Loading...</div>
                <div class="progress-bar">
                    <div class="progress-fill progress-red" id="disk-bar" style="width:0%"></div>
                </div>
            </div>
            
            <div class="card">
                <div class="card-title">System Uptime</div>
                <div class="card-value" style="font-size:20px;" id="uptime-val">Loading...</div>
                <div class="card-sub" id="load-val">Load: ...</div>
                <div class="card-sub" id="proc-val">Processes: ...</div>
            </div>
        </div>

        <!-- System Info -->
        <div class="info-grid">
            <div class="info-card">
                <div class="info-label">Hostname</div>
                <div class="info-value">${HOSTNAME}</div>
            </div>
            <div class="info-card">
                <div class="info-label">Web Port</div>
                <div class="info-value">${WEB_PORT}</div>
            </div>
            <div class="info-card">
                <div class="info-label">Panel Port</div>
                <div class="info-value">${PANEL_PORT}</div>
            </div>
            <div class="info-card">
                <div class="info-label">Active Users</div>
                <div class="info-value" id="users-val">-</div>
            </div>
        </div>

        <!-- Terminal Output -->
        <div class="terminal">
            <div class="terminal-header">
                <div class="dot dot-red"></div>
                <div class="dot dot-yellow"></div>
                <div class="dot dot-green"></div>
                <span style="color:#888; font-size:13px; margin-left:10px;">Live System Log</span>
            </div>
            <div id="terminal-output">
                <div class="terminal-line"><span>[INFO]</span> VPS Bootstrap Complete ✓</div>
                <div class="terminal-line"><span>[INFO]</span> SSH Server Running on port ${SSH_PORT}</div>
                <div class="terminal-line"><span>[INFO]</span> Web Panel Active on port ${WEB_PORT}</div>
                <div class="terminal-line"><span>[INFO]</span> All services initialized</div>
                <div class="terminal-line"><span>[INFO]</span> Railway deployment active</div>
            </div>
        </div>
    </div>

    <div class="footer">
        🚀 Railway VPS Panel v3.0 | Built with Ultra VPS Bootstrap Script
    </div>

    <script>
        // Live time
        function updateTime() {
            document.getElementById('live-time').textContent = new Date().toUTCString();
        }
        setInterval(updateTime, 1000);
        updateTime();

        // Fetch real stats
        async function fetchStats() {
            try {
                const res = await fetch('/api/stats');
                const data = await res.json();
                
                // CPU
                const cpu = parseFloat(data.cpu) || 0;
                document.getElementById('cpu-val').textContent = cpu.toFixed(1) + '%';
                document.getElementById('cpu-sub').textContent = 'Real-time CPU load';
                document.getElementById('cpu-bar').style.width = cpu + '%';
                
                // RAM
                const ram = parseFloat(data.ram_percent) || 0;
                document.getElementById('ram-val').textContent = ram.toFixed(1) + '%';
                document.getElementById('ram-sub').textContent = data.ram_used + 'MB / ' + data.ram_total + 'MB';
                document.getElementById('ram-bar').style.width = ram + '%';
                
                // Disk
                const disk = parseFloat(data.disk_percent) || 0;
                document.getElementById('disk-val').textContent = disk.toFixed(0) + '%';
                document.getElementById('disk-sub').textContent = data.disk_used + ' / ' + data.disk_total;
                document.getElementById('disk-bar').style.width = disk + '%';
                
                // System
                document.getElementById('uptime-val').textContent = data.uptime;
                document.getElementById('load-val').textContent = 'Load: ' + data.load;
                document.getElementById('proc-val').textContent = 'Processes: ' + data.processes;
                document.getElementById('users-val').textContent = data.users;
                
                // Add terminal log
                const now = new Date().toLocaleTimeString();
                const terminal = document.getElementById('terminal-output');
                const line = document.createElement('div');
                line.className = 'terminal-line';
                line.innerHTML = '<span>[' + now + ']</span> Stats refreshed | CPU: ' + cpu.toFixed(1) + '% | RAM: ' + ram.toFixed(1) + '%';
                terminal.appendChild(line);
                terminal.scrollTop = terminal.scrollHeight;
                
            } catch(e) {
                console.log('Stats fetch error:', e);
            }
        }

        // SSH host detection
        document.getElementById('ssh-host').textContent = window.location.hostname;

        // Auto refresh every 10s
        setInterval(fetchStats, 10000);
        fetchStats();

        // Copy function
        function copyText(el, id) {
            const text = document.getElementById(id).textContent;
            navigator.clipboard.writeText(text).then(() => {
                const btn = el.querySelector('.copy-btn');
                btn.textContent = 'COPIED!';
                setTimeout(() => btn.textContent = 'COPY', 2000);
            });
        }
    </script>
</body>
</html>
HTMLEOF

    log_success "Web panel created"
}

# ============================
# 🖥️ API SERVER (Python)
# ============================
setup_api_server() {
    log_step "Setting up API Server..."

    cat > /var/www/vps-panel/server.py << 'PYEOF'
#!/usr/bin/env python3
"""
Railway VPS API Server
Serves web panel + system stats API
"""
import os
import json
import subprocess
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse

WEB_PORT = int(os.environ.get('PORT', 8080))
PANEL_DIR = '/var/www/vps-panel'

def get_system_stats():
    """Get real system statistics"""
    try:
        stats = {}
        
        # CPU
        with open('/proc/stat', 'r') as f:
            cpu = f.readline().split()
        idle = float(cpu[4])
        total = sum(float(x) for x in cpu[1:])
        stats['cpu'] = round((1 - idle/total) * 100, 2)
        
        # Memory
        with open('/proc/meminfo', 'r') as f:
            mem = {line.split(':')[0]: int(line.split()[1]) 
                   for line in f if ':' in line}
        mem_total = mem.get('MemTotal', 1)
        mem_free = mem.get('MemAvailable', 0)
        mem_used = mem_total - mem_free
        stats['ram_total'] = mem_total // 1024
        stats['ram_used'] = mem_used // 1024
        stats['ram_percent'] = round((mem_used / mem_total) * 100, 2)
        
        # Disk
        import shutil
        disk = shutil.disk_usage('/')
        stats['disk_total'] = f"{disk.total // (1024**3)}GB"
        stats['disk_used'] = f"{disk.used // (1024**3)}GB"
        stats['disk_percent'] = round((disk.used / disk.total) * 100, 2)
        
        # Load average
        with open('/proc/loadavg', 'r') as f:
            load = f.read().split()
        stats['load'] = f"{load[0]}, {load[1]}, {load[2]}"
        stats['processes'] = load[3].split('/')[1]
        
        # Uptime
        with open('/proc/uptime', 'r') as f:
            uptime_seconds = float(f.read().split()[0])
        hours = int(uptime_seconds // 3600)
        minutes = int((uptime_seconds % 3600) // 60)
        stats['uptime'] = f"{hours}h {minutes}m"
        
        # Users logged in
        try:
            result = subprocess.run(['who'], capture_output=True, text=True)
            stats['users'] = len([l for l in result.stdout.strip().split('\n') if l])
        except:
            stats['users'] = 0
            
        # Network
        try:
            with open('/proc/net/dev', 'r') as f:
                lines = f.readlines()
            for line in lines[2:]:
                if 'lo' not in line and ':' in line:
                    parts = line.split()
                    stats['net_in'] = int(parts[1])
                    stats['net_out'] = int(parts[9])
                    break
        except:
            stats['net_in'] = 0
            stats['net_out'] = 0
        
        import datetime
        stats['timestamp'] = datetime.datetime.utcnow().isoformat() + 'Z'
        
        return stats
    except Exception as e:
        return {'error': str(e), 'cpu': 0, 'ram_percent': 0, 'disk_percent': 0}


class VPSHandler(BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        pass  # Suppress default logs

    def do_GET(self):
        path = urlparse(self.path).path
        
        if path == '/api/stats':
            self.send_json(get_system_stats())
        
        elif path == '/api/health':
            self.send_json({'status': 'ok', 'service': 'Railway VPS Panel'})
        
        elif path == '/api/info':
            self.send_json({
                'hostname': os.uname().nodename,
                'kernel': os.uname().release,
                'arch': os.uname().machine,
                'python': f"{__import__('sys').version_info.major}.{__import__('sys').version_info.minor}"
            })
        
        elif path == '/' or path == '/index.html':
            self.serve_file('/var/www/vps-panel/index.html', 'text/html')
        
        else:
            filepath = PANEL_DIR + path
            if os.path.isfile(filepath):
                self.serve_file(filepath, 'application/octet-stream')
            else:
                self.send_error(404, 'Not Found')
    
    def send_json(self, data):
        body = json.dumps(data).encode()
        self.send_response(200)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Content-Length', len(body))
        self.send_header('Access-Control-Allow-Origin', '*')
        self.end_headers()
        self.wfile.write(body)
    
    def serve_file(self, filepath, mime):
        try:
            with open(filepath, 'rb') as f:
                content = f.read()
            self.send_response(200)
            self.send_header('Content-Type', mime)
            self.send_header('Content-Length', len(content))
            self.end_headers()
            self.wfile.write(content)
        except FileNotFoundError:
            self.send_error(404)


if __name__ == '__main__':
    print(f"[VPS-API] Starting server on port {WEB_PORT}")
    server = HTTPServer(('0.0.0.0', WEB_PORT), VPSHandler)
    print(f"[VPS-API] Panel ready at http://0.0.0.0:{WEB_PORT}")
    server.serve_forever()
PYEOF

    chmod +x /var/www/vps-panel/server.py
    log_success "API server created"
}

# ============================
# 🔒 SECURITY SETUP
# ============================
setup_security() {
    log_step "Configuring Security..."

    # Configure fail2ban
    cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime  = 3600
findtime = 600
maxretry = 5

[sshd]
enabled = true
port    = 2222
filter  = sshd
logpath = /var/log/auth.log
maxretry = 5
EOF

    # Basic iptables rules
    iptables -F 2>/dev/null || true
    iptables -A INPUT -i lo -j ACCEPT 2>/dev/null || true
    iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT 2>/dev/null || true
    iptables -A INPUT -p tcp --dport ${SSH_PORT} -j ACCEPT 2>/dev/null || true
    iptables -A INPUT -p tcp --dport ${WEB_PORT} -j ACCEPT 2>/dev/null || true
    iptables -A INPUT -p tcp --dport ${PANEL_PORT} -j ACCEPT 2>/dev/null || true

    log_success "Security configured"
}

# ============================
# 📊 SUPERVISOR CONFIG
# ============================
setup_supervisor() {
    log_step "Configuring Supervisor Process Manager..."

    mkdir -p /etc/supervisor/conf.d
    mkdir -p /var/log/supervisor

    # Main supervisor config
    cat > /etc/supervisor/supervisord.conf << EOF
[unix_http_server]
file=/var/run/supervisor.sock
chmod=0700

[supervisord]
logfile=/var/log/supervisor/supervisord.log
pidfile=/var/run/supervisord.pid
childlogdir=/var/log/supervisor
loglevel=info
nodaemon=true

[rpcinterface:supervisor]
supervisor.rpcinterface_factory = supervisor.rpcinterface:make_main_rpcinterface

[supervisorctl]
serverurl=unix:///var/run/supervisor.sock

[include]
files = /etc/supervisor/conf.d/*.conf
EOF

    # SSH service config
    cat > /etc/supervisor/conf.d/ssh.conf << EOF
[program:sshd]
command=/usr/sbin/sshd -D -p ${SSH_PORT} -e
autostart=true
autorestart=true
stderr_logfile=/var/log/supervisor/sshd.err.log
stdout_logfile=/var/log/supervisor/sshd.out.log
priority=10
EOF

    # Web panel API server
    cat > /etc/supervisor/conf.d/vps-panel.conf << EOF
[program:vps-panel]
command=python3 /var/www/vps-panel/server.py
autostart=true
autorestart=true
stderr_logfile=/var/log/supervisor/panel.err.log
stdout_logfile=/var/log/supervisor/panel.out.log
environment=PORT="${WEB_PORT}"
priority=20
EOF

    # Cron service
    cat > /etc/supervisor/conf.d/cron.conf << EOF
[program:cron]
command=/usr/sbin/cron -f
autostart=true
autorestart=true
stderr_logfile=/var/log/supervisor/cron.err.log
stdout_logfile=/var/log/supervisor/cron.out.log
priority=30
EOF

    log_success "Supervisor configured with all services"
}

# ============================
# 🎯 MOTD (Login Banner)
# ============================
setup_motd() {
    cat > /etc/motd << EOF

╔══════════════════════════════════════════════════╗
║          🚀 RAILWAY VPS - WELCOME BACK!          ║
╠══════════════════════════════════════════════════╣
║  Hostname : ${HOSTNAME}                          
║  SSH Port : ${SSH_PORT}                              
║  Web Panel: http://HOST:${WEB_PORT}                  
║  User     : ${VPS_USER}                          
╠══════════════════════════════════════════════════╣
║  🔒 Unauthorized access is strictly prohibited  ║
╚══════════════════════════════════════════════════╝

EOF
    log_success "MOTD configured"
}

# ============================
# 📋 HELPER SCRIPTS
# ============================
setup_helper_scripts() {
    log_step "Creating helper scripts..."

    # VPS Status script
    cat > /usr/local/bin/vps-status << 'EOF'
#!/bin/bash
echo "🚀 VPS Status Report"
echo "═══════════════════════════════"
echo "CPU:    $(top -bn1 | grep 'Cpu' | awk '{print $2}')% used"
echo "RAM:    $(free -h | awk '/^Mem:/{print $3"/"$2}')"
echo "Disk:   $(df -h / | awk 'NR==2{print $3"/"$2" ("$5")"}')"
echo "Uptime: $(uptime -p)"
echo "═══════════════════════════════"
echo "Services:"
supervisorctl status 2>/dev/null || true
EOF
    chmod +x /usr/local/bin/vps-status

    # VPS restart script
    cat > /usr/local/bin/vps-restart << 'EOF'
#!/bin/bash
echo "Restarting all VPS services..."
supervisorctl restart all
echo "Done!"
EOF
    chmod +x /usr/local/bin/vps-restart

    log_success "Helper scripts created: vps-status, vps-restart"
}

# ============================
# ✅ PRINT FINAL INFO
# ============================
print_final_info() {
    echo ""
    echo -e "${GREEN}"
    echo "╔══════════════════════════════════════════════════════╗"
    echo "║           ✅ VPS BOOTSTRAP COMPLETE!                 ║"
    echo "╠══════════════════════════════════════════════════════╣"
    echo "║                                                      ║"
    printf "║  %-20s : %-28s║\n" "SSH Port" "${SSH_PORT}"
    printf "║  %-20s : %-28s║\n" "Web Panel Port" "${WEB_PORT}"
    printf "║  %-20s : %-28s║\n" "Username" "${VPS_USER}"
    printf "║  %-20s : %-28s║\n" "User Password" "${VPS_PASS}"
    printf "║  %-20s : %-28s║\n" "Root Password" "${ROOT_PASS}"
    echo "║                                                      ║"
    echo "╠══════════════════════════════════════════════════════╣"
    echo "║  SSH CMD: ssh ${VPS_USER}@HOST -p ${SSH_PORT}        ║"
    echo "║  PANEL:   http://HOST:${WEB_PORT}                    ║"
    echo "╚══════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# ============================
# 🚀 MAIN EXECUTION
# ============================
main() {
    print_banner
    detect_system
    install_dependencies
    setup_users
    setup_ssh
    setup_web_panel
    setup_api_server
    setup_security
    setup_supervisor
    setup_motd
    setup_helper_scripts
    print_final_info

    log_step "Starting all services via Supervisor..."
    
    # Start supervisord (foreground for Railway)
    exec /usr/bin/supervisord -c /etc/supervisor/supervisord.conf
}

# Run main
main "$@"
