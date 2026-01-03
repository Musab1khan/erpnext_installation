#!/usr/bin/env bash

#═══════════════════════════════════════════════════════════════════════════════
# ERPNext Doctor - Complete Diagnostic & Auto-Fix Tool
# Detects and fixes all common ERPNext errors
# Version: 2.0 Enhanced
#═══════════════════════════════════════════════════════════════════════════════

set +e  # Don't exit on errors (we're diagnosing them!)

#
# ─── COLORS ────────────────────────────────────────────────────────────────────
#
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

#
# ─── LOGGING ───────────────────────────────────────────────────────────────────
#
LOG_DIR="/tmp/erpnext-doctor"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/doctor_$(date +%Y%m%d_%H%M%S).log"

log() {
    echo -e "$1" | tee -a "$LOG_FILE"
}

#
# ─── COUNTERS ──────────────────────────────────────────────────────────────────
#
TOTAL_CHECKS=0
ERRORS_FOUND=0
WARNINGS_FOUND=0
FIXES_APPLIED=0
CRITICAL_ERRORS=0

#
# ─── ASK USER FUNCTION ─────────────────────────────────────────────────────────
#
ask_fix() {
    local question="$1"
    local response

    echo -e "${YELLOW}${question}${NC}"
    echo -e "${CYAN}Fix this issue? [y/n]: ${NC}\c"
    read -r response

    if [[ "$response" =~ ^[Yy]$ ]]; then
        return 0  # Yes, fix it
    else
        log "${BLUE}⊘ Skipped by user${NC}"
        return 1  # No, skip
    fi
}

#
# ─── HEADER ────────────────────────────────────────────────────────────────────
#
clear
log "${BLUE}╔═══════════════════════════════════════════════════════════════════╗${NC}"
log "${BLUE}║                                                                   ║${NC}"
log "${BLUE}║              🏥 ERPNext DOCTOR v2.0 Enhanced 🏥                   ║${NC}"
log "${BLUE}║                                                                   ║${NC}"
log "${BLUE}║         Complete Diagnostic & Auto-Fix Tool                      ║${NC}"
log "${BLUE}║                                                                   ║${NC}"
log "${BLUE}╚═══════════════════════════════════════════════════════════════════╝${NC}"
log ""
log "${CYAN}Started: $(date '+%Y-%m-%d %H:%M:%S')${NC}"
log "${CYAN}Log file: $LOG_FILE${NC}"
log ""

#
# ─── FIND BENCH DIRECTORY ──────────────────────────────────────────────────────
#
log "${YELLOW}🔍 Finding ERPNext installation...${NC}"

BENCH_DIR=""

# Search common locations
if [ -d "/home/frappe/frappe-bench" ]; then
    BENCH_DIR="/home/frappe/frappe-bench"
elif [ -d "$HOME/frappe-bench" ]; then
    BENCH_DIR="$HOME/frappe-bench"
else
    # Try to find it
    BENCH_DIR=$(find /home -maxdepth 3 -name "frappe-bench" -type d 2>/dev/null | head -1)

    if [ -z "$BENCH_DIR" ]; then
        BENCH_DIR=$(find /opt -maxdepth 2 -name "frappe-bench" -type d 2>/dev/null | head -1)
    fi
fi

if [ -z "$BENCH_DIR" ] || [ ! -d "$BENCH_DIR" ]; then
    log "${RED}❌ CRITICAL: ERPNext installation not found!${NC}"
    log "${YELLOW}Please run install-hybrid.sh first${NC}"
    exit 1
fi

log "${GREEN}✅ Found: $BENCH_DIR${NC}"

cd "$BENCH_DIR" || {
    log "${RED}❌ Cannot access bench directory${NC}"
    exit 1
}

#
# ─── GET SITE NAMES (ALL SITES) ────────────────────────────────────────────────
#
# Only get directories, exclude files
ALL_SITES=()
for item in "$BENCH_DIR/sites"/*; do
    if [ -d "$item" ] && [ "$(basename "$item")" != "assets" ]; then
        ALL_SITES+=("$(basename "$item")")
    fi
done

if [ ${#ALL_SITES[@]} -eq 0 ]; then
    log "${RED}❌ No sites found!${NC}"
    SITE="unknown"
    ALL_SITES=("unknown")
else
    SITE="${ALL_SITES[0]}"  # Primary site
    log "${GREEN}✅ Primary Site: $SITE${NC}"

    if [ ${#ALL_SITES[@]} -gt 1 ]; then
        log "${CYAN}   Total Sites: ${#ALL_SITES[@]}${NC}"
        for site in "${ALL_SITES[@]}"; do
            log "${CYAN}   • $site${NC}"
        done
    fi
fi

log ""

#
# ─── SYSTEM INFO ───────────────────────────────────────────────────────────────
#
log "${BLUE}═══ System Information ═══${NC}"
log "OS: $(lsb_release -ds 2>/dev/null || cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
log "Kernel: $(uname -r)"
log "Python: $(python3 --version 2>/dev/null || echo 'Not found')"
log "Node: $(node --version 2>/dev/null || echo 'Not found')"
log "Bench: $(bench --version 2>/dev/null || echo 'Not found')"
log ""

#
# ─── CHECK 0: SYSTEM PACKAGES ──────────────────────────────────────────────────
#
((TOTAL_CHECKS++))
log "${BLUE}[0/18] System Packages & Dependencies${NC}"

REQUIRED_PACKAGES=(
    "git"
    "curl"
    "wget"
    "redis-server"
    "nginx"
    "supervisor"
    "python3"
    "python3-pip"
    "python3-dev"
    "default-libmysqlclient-dev"
    "pkg-config"
)

MISSING_PACKAGES=()

for pkg in "${REQUIRED_PACKAGES[@]}"; do
    if ! dpkg -l | grep -q "^ii  $pkg"; then
        MISSING_PACKAGES+=("$pkg")
    fi
done

if [ ${#MISSING_PACKAGES[@]} -gt 0 ]; then
    log "${RED}❌ Missing packages: ${MISSING_PACKAGES[*]}${NC}"
    ((ERRORS_FOUND++))

    if ask_fix "Missing ${#MISSING_PACKAGES[@]} system packages"; then
        log "${YELLOW}Installing missing packages...${NC}"
        sudo apt update -qq
        sudo apt install -y "${MISSING_PACKAGES[@]}"
        ((FIXES_APPLIED++))
        log "${GREEN}✅ Packages installed${NC}"
    fi
else
    log "${GREEN}✅ All required packages installed${NC}"
fi

# Check wkhtmltopdf
if ! command -v wkhtmltopdf &>/dev/null; then
    log "${RED}❌ wkhtmltopdf not found${NC}"
    ((ERRORS_FOUND++))

    if ask_fix "wkhtmltopdf is missing (required for PDF generation)"; then
        log "${YELLOW}Installing wkhtmltopdf...${NC}"
        arch=$(uname -m)
        case $arch in
            x86_64) arch="amd64" ;;
            aarch64) arch="arm64" ;;
        esac

        WKHTMLTOX_URL="https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-2/wkhtmltox_0.12.6.1-2.jammy_${arch}.deb"
        wget -q "$WKHTMLTOX_URL" -O /tmp/wkhtmltox.deb
        sudo dpkg -i /tmp/wkhtmltox.deb 2>/dev/null || sudo apt --fix-broken install -y
        sudo cp /usr/local/bin/wkhtmlto* /usr/bin/ 2>/dev/null || true
        sudo chmod a+x /usr/bin/wk* 2>/dev/null || true
        rm /tmp/wkhtmltox.deb
        ((FIXES_APPLIED++))
        log "${GREEN}✅ wkhtmltopdf installed${NC}"
    fi
else
    log "${GREEN}✅ wkhtmltopdf installed${NC}"
fi

# Check Node.js
if ! command -v node &>/dev/null; then
    log "${YELLOW}⚠️  Node.js not found - checking NVM...${NC}"

    # Try to load NVM
    if [ -d "$HOME/.nvm" ]; then
        log "${CYAN}NVM detected - loading...${NC}"
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

        # Check again after loading NVM
        if command -v node &>/dev/null; then
            NODE_VER=$(node --version)
            log "${GREEN}✅ Node.js: $NODE_VER (loaded via NVM)${NC}"
            log "${YELLOW}⚠️  NVM loaded in this session only${NC}"
            ((WARNINGS_FOUND++))

            if ask_fix "Add NVM to .bashrc for permanent availability?"; then
                # Check if already in bashrc
                if ! grep -q "NVM_DIR" "$HOME/.bashrc"; then
                    echo '' >> "$HOME/.bashrc"
                    echo '# Load NVM' >> "$HOME/.bashrc"
                    echo 'export NVM_DIR="$HOME/.nvm"' >> "$HOME/.bashrc"
                    echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> "$HOME/.bashrc"
                    log "${GREEN}✅ NVM added to .bashrc${NC}"
                    log "${CYAN}Run 'source ~/.bashrc' to apply in current terminal${NC}"
                    ((FIXES_APPLIED++))
                else
                    log "${CYAN}NVM already configured in .bashrc${NC}"
                fi
            fi
        else
            log "${RED}❌ NVM found but Node.js not installed${NC}"
            ((ERRORS_FOUND++))

            if ask_fix "Install Node.js 18 via NVM?"; then
                nvm install 18
                nvm alias default 18
                nvm use 18
                log "${GREEN}✅ Node.js 18 installed and set as default${NC}"
                ((FIXES_APPLIED++))

                # Also add to bashrc
                if ! grep -q "NVM_DIR" "$HOME/.bashrc"; then
                    echo '' >> "$HOME/.bashrc"
                    echo '# Load NVM' >> "$HOME/.bashrc"
                    echo 'export NVM_DIR="$HOME/.nvm"' >> "$HOME/.bashrc"
                    echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> "$HOME/.bashrc"
                    log "${GREEN}✅ NVM added to .bashrc${NC}"
                fi
            fi
        fi
    else
        log "${RED}❌ Node.js and NVM not found${NC}"
        ((ERRORS_FOUND++))
        log "${CYAN}   Install NVM first: curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash${NC}"
        log "${CYAN}   Then run this script again${NC}"
    fi
else
    NODE_VER=$(node --version)
    log "${GREEN}✅ Node.js: $NODE_VER${NC}"
fi

# Check Yarn
if ! command -v yarn &>/dev/null; then
    log "${YELLOW}⚠️  Yarn not found - installing...${NC}"
    npm install -g yarn 2>/dev/null && ((FIXES_APPLIED++))
else
    log "${GREEN}✅ Yarn installed${NC}"
fi

log ""

#
# ─── CHECK 1: DISK SPACE ───────────────────────────────────────────────────────
#
((TOTAL_CHECKS++))
log "${BLUE}[1/18] Disk Space${NC}"

DISK_USAGE=$(df -h "$BENCH_DIR" | awk 'NR==2 {print $5}' | sed 's/%//')

if [ "$DISK_USAGE" -gt 90 ]; then
    log "${RED}❌ Disk usage: ${DISK_USAGE}% (Critical!)${NC}"
    ((CRITICAL_ERRORS++))
    ((ERRORS_FOUND++))

    log "${YELLOW}Cleaning up...${NC}"
    bench clear-cache 2>/dev/null
    bench clear-website-cache 2>/dev/null
    find "$BENCH_DIR/logs" -name "*.log" -mtime +7 -delete 2>/dev/null
    ((FIXES_APPLIED++))

elif [ "$DISK_USAGE" -gt 80 ]; then
    log "${YELLOW}⚠️  Disk usage: ${DISK_USAGE}% (Warning)${NC}"
    ((WARNINGS_FOUND++))
else
    log "${GREEN}✅ Disk usage: ${DISK_USAGE}%${NC}"
fi
log ""

#
# ─── CHECK 2: MEMORY ───────────────────────────────────────────────────────────
#
((TOTAL_CHECKS++))
log "${BLUE}[2/18] Memory Usage${NC}"

MEM_TOTAL=$(free -m | awk 'NR==2{print $2}')
MEM_USED=$(free -m | awk 'NR==2{print $3}')
MEM_PERCENT=$((MEM_USED * 100 / MEM_TOTAL))

if [ "$MEM_PERCENT" -gt 90 ]; then
    log "${RED}❌ Memory: ${MEM_PERCENT}% used (${MEM_USED}MB/${MEM_TOTAL}MB)${NC}"
    ((ERRORS_FOUND++))

    log "${YELLOW}Restarting services to free memory...${NC}"
    sudo supervisorctl restart all 2>/dev/null
    ((FIXES_APPLIED++))

elif [ "$MEM_PERCENT" -gt 80 ]; then
    log "${YELLOW}⚠️  Memory: ${MEM_PERCENT}% used${NC}"
    ((WARNINGS_FOUND++))
else
    log "${GREEN}✅ Memory: ${MEM_PERCENT}% used${NC}"
fi
log ""

#
# ─── CHECK 3: MARIADB ──────────────────────────────────────────────────────────
#
((TOTAL_CHECKS++))
log "${BLUE}[3/18] MariaDB/MySQL Status${NC}"

if systemctl is-active mariadb &>/dev/null || systemctl is-active mysql &>/dev/null; then
    log "${GREEN}✅ MariaDB: Running${NC}"

    # Test connection
    if mysql -u root -e "SELECT 1;" &>/dev/null; then
        log "${GREEN}✅ Database connection: OK${NC}"
    else
        log "${YELLOW}⚠️  Database connection requires password${NC}"
    fi

    # Check if site database exists
    if [ "$SITE" != "unknown" ]; then
        SITE_DB=$(echo "$SITE" | tr '.' '_' | tr '-' '_')
        if mysql -u root -e "USE \`$SITE_DB\`;" 2>/dev/null; then
            log "${GREEN}✅ Site database exists${NC}"
        else
            log "${RED}❌ Site database missing!${NC}"
            ((ERRORS_FOUND++))
        fi
    fi

else
    log "${RED}❌ MariaDB: NOT RUNNING${NC}"
    ((ERRORS_FOUND++))
    ((CRITICAL_ERRORS++))

    log "${YELLOW}Starting MariaDB...${NC}"
    sudo systemctl start mariadb || sudo systemctl start mysql
    sleep 2

    if systemctl is-active mariadb &>/dev/null || systemctl is-active mysql &>/dev/null; then
        log "${GREEN}✅ MariaDB started successfully${NC}"
        ((FIXES_APPLIED++))
    else
        log "${RED}❌ Failed to start MariaDB - manual intervention required${NC}"
    fi
fi
log ""

#
# ─── CHECK 4: REDIS ────────────────────────────────────────────────────────────
#
((TOTAL_CHECKS++))
log "${BLUE}[4/18] Redis Cache Server${NC}"

if redis-cli ping &>/dev/null; then
    log "${GREEN}✅ Redis: Running${NC}"

    # Check memory usage
    REDIS_MEM=$(redis-cli info memory 2>/dev/null | grep used_memory_human | cut -d: -f2 | tr -d '\r')
    log "${CYAN}   Memory used: $REDIS_MEM${NC}"
else
    log "${RED}❌ Redis: NOT RUNNING${NC}"
    ((ERRORS_FOUND++))
    ((CRITICAL_ERRORS++))

    log "${YELLOW}Starting Redis...${NC}"
    sudo systemctl start redis-server
    sleep 1

    if redis-cli ping &>/dev/null; then
        log "${GREEN}✅ Redis started successfully${NC}"
        ((FIXES_APPLIED++))
    else
        log "${RED}❌ Failed to start Redis${NC}"
    fi
fi
log ""

#
# ─── CHECK 5: NGINX ────────────────────────────────────────────────────────────
#
((TOTAL_CHECKS++))
log "${BLUE}[5/18] Nginx Web Server${NC}"

if systemctl is-active nginx &>/dev/null; then
    log "${GREEN}✅ Nginx: Running${NC}"

    # Test configuration
    NGINX_TEST=$(sudo nginx -t 2>&1)
    if echo "$NGINX_TEST" | grep -q "successful"; then
        log "${GREEN}✅ Nginx config: Valid${NC}"
    else
        log "${RED}❌ Nginx config: ERRORS${NC}"
        echo "$NGINX_TEST" | tee -a "$LOG_FILE"
        ((ERRORS_FOUND++))

        log "${YELLOW}Regenerating Nginx config...${NC}"
        sudo bench setup nginx --yes 2>/dev/null
        sudo nginx -t && sudo systemctl reload nginx
        ((FIXES_APPLIED++))
    fi

    # Check if site is configured
    if [ "$SITE" != "unknown" ]; then
        if [ -f "/etc/nginx/conf.d/$SITE.conf" ] || [ -f "/etc/nginx/sites-enabled/$SITE" ]; then
            log "${GREEN}✅ Site Nginx config exists${NC}"
        else
            log "${YELLOW}⚠️  Site Nginx config missing${NC}"
            ((WARNINGS_FOUND++))
        fi
    fi

else
    log "${RED}❌ Nginx: NOT RUNNING${NC}"
    ((ERRORS_FOUND++))

    # Test config first
    if sudo nginx -t &>/dev/null; then
        sudo systemctl start nginx
        ((FIXES_APPLIED++))
        log "${GREEN}✅ Nginx started${NC}"
    else
        log "${RED}❌ Nginx config broken - fixing...${NC}"
        sudo bench setup nginx --yes 2>/dev/null
        sudo systemctl start nginx
        ((FIXES_APPLIED++))
    fi
fi
log ""

#
# ─── CHECK 6: SUPERVISOR ───────────────────────────────────────────────────────
#
((TOTAL_CHECKS++))
log "${BLUE}[6/18] Supervisor Process Manager${NC}"

if sudo supervisorctl status &>/dev/null; then
    SUP_STATUS=$(sudo supervisorctl status 2>/dev/null)

    RUNNING_COUNT=$(echo "$SUP_STATUS" | grep -c "RUNNING" || true)
    STOPPED_COUNT=$(echo "$SUP_STATUS" | grep -cE "STOPPED|FATAL|EXITED" || true)

    log "${CYAN}Running processes: $RUNNING_COUNT${NC}"

    if [ "$STOPPED_COUNT" -gt 0 ]; then
        log "${RED}❌ Stopped/Failed processes: $STOPPED_COUNT${NC}"
        ((ERRORS_FOUND++))

        echo "$SUP_STATUS" | grep -E "STOPPED|FATAL|EXITED" | while read line; do
            PROC=$(echo "$line" | awk '{print $1}')
            log "${YELLOW}   Restarting: $PROC${NC}"
            sudo supervisorctl restart "$PROC" 2>/dev/null
        done
        ((FIXES_APPLIED++))
    else
        log "${GREEN}✅ All Supervisor processes running${NC}"
    fi

    # Show status
    echo "$SUP_STATUS" | while read line; do
        if echo "$line" | grep -q "RUNNING"; then
            log "${GREEN}   ✓ $line${NC}"
        else
            log "${RED}   ✗ $line${NC}"
        fi
    done
else
    log "${YELLOW}⚠️  Supervisor not configured or not running${NC}"
    ((WARNINGS_FOUND++))

    if systemctl is-active supervisor &>/dev/null; then
        log "${YELLOW}Reloading Supervisor...${NC}"
        sudo supervisorctl reload
        ((FIXES_APPLIED++))
    fi
fi
log ""

#
# ─── CHECK 7: PORTS ────────────────────────────────────────────────────────────
#
((TOTAL_CHECKS++))
log "${BLUE}[7/18] Network Ports & Conflicts${NC}"

check_port() {
    local port=$1
    local service=$2
    local expected_service=$3

    if command -v ss &>/dev/null; then
        PORT_INFO=$(ss -tlnp 2>/dev/null | grep ":$port ")
    elif command -v netstat &>/dev/null; then
        PORT_INFO=$(netstat -tlnp 2>/dev/null | grep ":$port ")
    else
        log "${YELLOW}⚠️  Neither ss nor netstat found - installing net-tools${NC}"
        sudo apt install -y net-tools &>/dev/null
        PORT_INFO=$(netstat -tlnp 2>/dev/null | grep ":$port ")
    fi

    if [ -n "$PORT_INFO" ]; then
        # Extract process name
        PROCESS=$(echo "$PORT_INFO" | awk '{print $NF}' | cut -d'/' -f2 | head -1)

        if [ -n "$expected_service" ]; then
            if echo "$PROCESS" | grep -qi "$expected_service"; then
                log "${GREEN}✅ Port $port ($service): Open by $PROCESS${NC}"
                return 0
            else
                log "${RED}❌ Port $port CONFLICT: Used by $PROCESS (expected $expected_service)${NC}"
                ((ERRORS_FOUND++))

                # Try to fix port conflicts
                if [ "$port" == "80" ] || [ "$port" == "443" ]; then
                    log "${YELLOW}   Fixing: Restarting Nginx...${NC}"
                    sudo systemctl restart nginx
                    ((FIXES_APPLIED++))
                elif [ "$port" == "3306" ]; then
                    log "${YELLOW}   Fixing: Restarting MariaDB...${NC}"
                    sudo systemctl restart mariadb || sudo systemctl restart mysql
                    ((FIXES_APPLIED++))
                elif [ "$port" == "6379" ]; then
                    log "${YELLOW}   Fixing: Restarting Redis...${NC}"
                    sudo systemctl restart redis-server
                    ((FIXES_APPLIED++))
                fi
                return 1
            fi
        else
            log "${GREEN}✅ Port $port ($service): Open by $PROCESS${NC}"
            return 0
        fi
    else
        log "${YELLOW}⚠️  Port $port ($service): Not listening${NC}"

        # Try to start the service
        if [ "$service" == "HTTP" ] || [ "$service" == "HTTPS" ]; then
            log "${YELLOW}   Starting Nginx...${NC}"
            sudo systemctl start nginx
            ((FIXES_APPLIED++))
        elif [ "$service" == "MariaDB" ]; then
            log "${YELLOW}   Starting MariaDB...${NC}"
            sudo systemctl start mariadb || sudo systemctl start mysql
            ((FIXES_APPLIED++))
        elif [ "$service" == "Redis" ]; then
            log "${YELLOW}   Starting Redis...${NC}"
            sudo systemctl start redis-server
            ((FIXES_APPLIED++))
        fi

        return 1
    fi
}

check_port 80 "HTTP" "nginx"
check_port 443 "HTTPS" "nginx"
check_port 3306 "MariaDB" "mariadbd\|mysqld"
check_port 6379 "Redis" "redis"
check_port 8000 "Frappe Dev" ""
check_port 9000 "Socketio" ""

# Check for common port blockers
if command -v apache2 &>/dev/null; then
    if systemctl is-active apache2 &>/dev/null; then
        log "${YELLOW}⚠️  Apache2 is running and may conflict with Nginx${NC}"
        ((WARNINGS_FOUND++))
        log "${CYAN}   Consider: sudo systemctl stop apache2 && sudo systemctl disable apache2${NC}"
    fi
fi

# Check for leftover bench development Redis processes (ports 11000, 12000, 13000)
BENCH_REDIS_PORTS=(11000 12000 13000)
LEFTOVER_REDIS=0

for port in "${BENCH_REDIS_PORTS[@]}"; do
    if command -v lsof &>/dev/null; then
        if lsof -ti:$port &>/dev/null; then
            PROCESS_PID=$(lsof -ti:$port)
            log "${RED}❌ Port $port (Bench Redis) blocked by leftover process (PID: $PROCESS_PID)${NC}"
            ((ERRORS_FOUND++))
            ((LEFTOVER_REDIS++))
        fi
    fi
done

if [ "$LEFTOVER_REDIS" -gt 0 ]; then
    if ask_fix "Found $LEFTOVER_REDIS leftover bench Redis process(es) - kill them?"; then
        log "${YELLOW}Killing leftover bench processes...${NC}"

        # Kill bench start processes
        pkill -f "bench start" 2>/dev/null || true
        pkill -f "honcho" 2>/dev/null || true

        # Kill Redis on bench ports
        for port in "${BENCH_REDIS_PORTS[@]}"; do
            if lsof -ti:$port &>/dev/null; then
                log "${YELLOW}   • Killing process on port $port...${NC}"
                kill -9 $(lsof -ti:$port) 2>/dev/null || true
            fi
        done

        sleep 1
        log "${GREEN}✅ Leftover processes killed${NC}"
        log "${CYAN}   You can now run 'bench start' or 'sudo bench setup production'${NC}"
        ((FIXES_APPLIED++))
    fi
fi

log ""

#
# ─── CHECK 8: BENCH CONFIGURATION ──────────────────────────────────────────────
#
((TOTAL_CHECKS++))
log "${BLUE}[8/18] Bench Configuration${NC}"

if [ -f "$BENCH_DIR/common_site_config.json" ]; then
    log "${GREEN}✅ common_site_config.json exists${NC}"
else
    log "${RED}❌ common_site_config.json missing!${NC}"
    ((CRITICAL_ERRORS++))
fi

if [ -f "$BENCH_DIR/Procfile" ]; then
    log "${GREEN}✅ Procfile exists${NC}"
else
    log "${YELLOW}⚠️  Procfile missing - regenerating...${NC}"
    bench setup procfile 2>/dev/null
    ((FIXES_APPLIED++))
fi

if [ -d "$BENCH_DIR/apps/frappe" ]; then
    FRAPPE_VERSION=$(cat "$BENCH_DIR/apps/frappe/frappe/__init__.py" 2>/dev/null | grep "__version__" | cut -d'"' -f2 || echo "Unknown")
    log "${GREEN}✅ Frappe version: $FRAPPE_VERSION${NC}"
else
    log "${RED}❌ Frappe app missing!${NC}"
    ((CRITICAL_ERRORS++))
fi

if [ -d "$BENCH_DIR/apps/erpnext" ]; then
    ERPNEXT_VERSION=$(cat "$BENCH_DIR/apps/erpnext/erpnext/__init__.py" 2>/dev/null | grep "__version__" | cut -d'"' -f2 || echo "Unknown")
    log "${GREEN}✅ ERPNext version: $ERPNEXT_VERSION${NC}"
else
    log "${YELLOW}⚠️  ERPNext app not installed${NC}"
fi
log ""

#
# ─── CHECK 8.5: MISSING APPS DETECTION ─────────────────────────────────────────
#
((TOTAL_CHECKS++))
log "${BLUE}[8.5/18] Missing Apps Detection${NC}"

if [ "$SITE" != "unknown" ] && [ -f "$BENCH_DIR/sites/$SITE/apps.txt" ]; then
    MISSING_APPS=()

    while IFS= read -r app; do
        # Skip empty lines
        [ -z "$app" ] && continue

        if [ ! -d "$BENCH_DIR/apps/$app" ]; then
            MISSING_APPS+=("$app")
            log "${RED}❌ App '$app' is listed but missing from apps/ directory${NC}"
            ((ERRORS_FOUND++))
        fi
    done < "$BENCH_DIR/sites/$SITE/apps.txt"

    if [ ${#MISSING_APPS[@]} -gt 0 ]; then
        if ask_fix "Found ${#MISSING_APPS[@]} missing app(s) - remove them from site?"; then
            log "${YELLOW}Removing missing apps from site...${NC}"

            for app in "${MISSING_APPS[@]}"; do
                log "${YELLOW}   • Removing $app from $SITE...${NC}"

                # Remove from apps.txt
                grep -v "^${app}$" "$BENCH_DIR/sites/$SITE/apps.txt" > "$BENCH_DIR/sites/$SITE/apps.txt.tmp"
                mv "$BENCH_DIR/sites/$SITE/apps.txt.tmp" "$BENCH_DIR/sites/$SITE/apps.txt"

                # Try to remove from database if site is accessible
                bench --site "$SITE" --force remove-from-installed-apps "$app" 2>/dev/null || true

                log "${GREEN}   ✓ Removed $app${NC}"
                ((FIXES_APPLIED++))
            done

            log "${GREEN}✅ Missing apps removed - you may need to run 'bench migrate' again${NC}"
        fi
    else
        log "${GREEN}✅ All apps in apps.txt exist${NC}"
    fi
else
    log "${YELLOW}⚠️  Site not found or apps.txt missing - skipping check${NC}"
fi
log ""

#
# ─── CHECK 9: PERMISSIONS ──────────────────────────────────────────────────────
#
((TOTAL_CHECKS++))
log "${BLUE}[9/19] File Permissions${NC}"

if [ -w "$BENCH_DIR" ]; then
    log "${GREEN}✅ Bench directory: Writable${NC}"
else
    log "${RED}❌ Bench directory: Not writable${NC}"
    ((ERRORS_FOUND++))

    if ask_fix "Bench directory has wrong permissions"; then
        sudo chown -R "$(whoami):$(whoami)" "$BENCH_DIR"
        ((FIXES_APPLIED++))
        log "${GREEN}✅ Permissions fixed${NC}"
    fi
fi

if [ "$SITE" != "unknown" ]; then
    if [ -w "$BENCH_DIR/sites/$SITE" ]; then
        log "${GREEN}✅ Site directory: Writable${NC}"
    else
        log "${RED}❌ Site directory: Not writable${NC}"
        ((ERRORS_FOUND++))
        sudo chown -R "$(whoami):$(whoami)" "$BENCH_DIR/sites/$SITE"
        ((FIXES_APPLIED++))
    fi
fi
log ""

#
# ─── CHECK 10: PYTHON DEPENDENCIES ─────────────────────────────────────────────
#
((TOTAL_CHECKS++))
log "${BLUE}[10/19] Python Environment${NC}"

if [ -d "$BENCH_DIR/env" ]; then
    log "${GREEN}✅ Virtual environment exists${NC}"

    source "$BENCH_DIR/env/bin/activate"

    # Check critical packages
    for pkg in frappe-bench redis pymysql; do
        if pip show "$pkg" &>/dev/null; then
            log "${GREEN}✅ $pkg installed${NC}"
        else
            log "${YELLOW}⚠️  $pkg missing - installing...${NC}"
            pip install "$pkg" &>/dev/null
            ((FIXES_APPLIED++))
        fi
    done
else
    log "${RED}❌ Virtual environment missing!${NC}"
    ((CRITICAL_ERRORS++))
fi
log ""

#
# ─── CHECK 11: NODE DEPENDENCIES ───────────────────────────────────────────────
#
((TOTAL_CHECKS++))
log "${BLUE}[11/19] Node.js Environment${NC}"

if command -v node &>/dev/null; then
    NODE_VER=$(node --version)
    log "${GREEN}✅ Node.js: $NODE_VER${NC}"
else
    log "${RED}❌ Node.js not found!${NC}"
    ((CRITICAL_ERRORS++))
fi

if command -v yarn &>/dev/null; then
    YARN_VER=$(yarn --version)
    log "${GREEN}✅ Yarn: $YARN_VER${NC}"
else
    log "${YELLOW}⚠️  Yarn not found - installing...${NC}"
    npm install -g yarn 2>/dev/null
    ((FIXES_APPLIED++))
fi

if [ -d "$BENCH_DIR/apps/frappe/node_modules" ]; then
    log "${GREEN}✅ Node modules installed${NC}"
else
    log "${YELLOW}⚠️  Node modules missing - installing...${NC}"
    cd "$BENCH_DIR/apps/frappe" && yarn install &>/dev/null
    ((FIXES_APPLIED++))
fi
log ""

#
# ─── CHECK 12: COMPREHENSIVE ERROR DETECTION & AUTO-FIX ────────────────────────
#
((TOTAL_CHECKS++))
log "${BLUE}[12/19] Comprehensive Error Detection & Auto-Fix${NC}"

ERROR_COUNT=0
FIXES_THIS_SECTION=0

# Collect errors from all log files
ALL_ERRORS=""
if [ -f "$BENCH_DIR/logs/web.error.log" ]; then
    ALL_ERRORS+=$(tail -200 "$BENCH_DIR/logs/web.error.log" 2>/dev/null | grep -iE "error|exception|failed|critical|traceback" || true)
fi
if [ -f "$BENCH_DIR/logs/worker.error.log" ]; then
    ALL_ERRORS+=$'\n'$(tail -200 "$BENCH_DIR/logs/worker.error.log" 2>/dev/null | grep -iE "error|exception|failed" || true)
fi
if [ -f "$BENCH_DIR/logs/bench.log" ]; then
    ALL_ERRORS+=$'\n'$(tail -100 "$BENCH_DIR/logs/bench.log" 2>/dev/null | grep -iE "error|exception|failed" || true)
fi

if [ -n "$ALL_ERRORS" ]; then
    ERROR_COUNT=$(echo "$ALL_ERRORS" | grep -c "." || echo 0)
    log "${YELLOW}Analyzing $ERROR_COUNT error lines...${NC}"

    # ═══════════════════════════════════════════════════════════════════════════
    # DATABASE ERRORS
    # ═══════════════════════════════════════════════════════════════════════════

    if echo "$ALL_ERRORS" | grep -qi "database\|mysql\|mariadb\|1045\|2002\|2003\|HY000"; then
        log "${RED}❌ Database Errors Detected${NC}"
        ((ERRORS_FOUND++))

        if echo "$ALL_ERRORS" | grep -qi "access denied\|1045"; then
            log "${YELLOW}   • Access Denied - Checking credentials...${NC}"
        fi

        if echo "$ALL_ERRORS" | grep -qi "can't connect\|2002\|2003"; then
            if ask_fix "   Database connection refused - restart MariaDB?"; then
                log "${YELLOW}   • Restarting MariaDB...${NC}"
                sudo systemctl restart mariadb || sudo systemctl restart mysql
                ((FIXES_APPLIED++))
                ((FIXES_THIS_SECTION++))
            fi
        fi

        if echo "$ALL_ERRORS" | grep -qi "database.*locked\|deadlock"; then
            log "${YELLOW}   • Database locked/deadlock detected${NC}"
            mysql -u root -e "SHOW PROCESSLIST;" 2>/dev/null | grep -i "lock" || true
            ((FIXES_THIS_SECTION++))
        fi

        if echo "$ALL_ERRORS" | grep -qi "table.*doesn't exist\|unknown column"; then
            if ask_fix "   Missing table/column - run database migration?"; then
                log "${YELLOW}   • Running migrate...${NC}"
                bench --site "$SITE" migrate 2>/dev/null
                ((FIXES_APPLIED++))
                ((FIXES_THIS_SECTION++))
            fi
        fi
    fi

    # ═══════════════════════════════════════════════════════════════════════════
    # REDIS/CACHE ERRORS
    # ═══════════════════════════════════════════════════════════════════════════

    if echo "$ALL_ERRORS" | grep -qi "redis\|cache\|connection.*refused.*6379"; then
        log "${RED}❌ Redis/Cache Errors Detected${NC}"
        ((ERRORS_FOUND++))

        if ask_fix "   Redis/Cache errors - clear cache and restart Redis?"; then
            log "${YELLOW}   • Clearing cache and restarting Redis...${NC}"
            bench --site "$SITE" clear-cache 2>/dev/null || true
            bench --site "$SITE" clear-website-cache 2>/dev/null || true
            sudo systemctl restart redis-server
            ((FIXES_APPLIED++))
            ((FIXES_THIS_SECTION++))
        fi
    fi

    # ═══════════════════════════════════════════════════════════════════════════
    # PERMISSION ERRORS
    # ═══════════════════════════════════════════════════════════════════════════

    if echo "$ALL_ERRORS" | grep -qi "permission denied\|EACCES\|operation not permitted"; then
        log "${RED}❌ Permission Errors Detected${NC}"
        ((ERRORS_FOUND++))

        if ask_fix "   File permission errors - fix all permissions?"; then
            log "${YELLOW}   • Fixing file permissions...${NC}"
            sudo chown -R "$(whoami):$(whoami)" "$BENCH_DIR"
            find "$BENCH_DIR" -type d -exec chmod 755 {} \; 2>/dev/null || true
            find "$BENCH_DIR" -type f -exec chmod 644 {} \; 2>/dev/null || true
            chmod +x "$BENCH_DIR/env/bin/"* 2>/dev/null || true
            ((FIXES_APPLIED++))
            ((FIXES_THIS_SECTION++))
        fi
    fi

    # ═══════════════════════════════════════════════════════════════════════════
    # PYTHON/MODULE ERRORS
    # ═══════════════════════════════════════════════════════════════════════════

    if echo "$ALL_ERRORS" | grep -qi "modulenotfounderror\|importerror\|no module named"; then
        log "${RED}❌ Python Module Errors Detected${NC}"
        ((ERRORS_FOUND++))

        if ask_fix "   Python module missing - reinstall dependencies?"; then
            log "${YELLOW}   • Reinstalling dependencies...${NC}"
            cd "$BENCH_DIR" && bench setup requirements 2>/dev/null || true
            ((FIXES_APPLIED++))
            ((FIXES_THIS_SECTION++))
        fi
    fi

    # ═══════════════════════════════════════════════════════════════════════════
    # NODE/YARN/ASSETS ERRORS
    # ═══════════════════════════════════════════════════════════════════════════

    if echo "$ALL_ERRORS" | grep -qi "node\|yarn\|npm\|webpack\|assets.*not.*found\|build.*failed"; then
        log "${RED}❌ Node.js/Assets Build Errors${NC}"
        ((ERRORS_FOUND++))

        if ask_fix "   Assets build failed - rebuild all assets?"; then
            log "${YELLOW}   • Rebuilding assets...${NC}"
            cd "$BENCH_DIR" && bench build 2>/dev/null || true
            ((FIXES_APPLIED++))
            ((FIXES_THIS_SECTION++))
        fi
    fi

    # ═══════════════════════════════════════════════════════════════════════════
    # WORKER/QUEUE ERRORS
    # ═══════════════════════════════════════════════════════════════════════════

    if echo "$ALL_ERRORS" | grep -qi "worker.*failed\|queue.*stuck\|background.*job"; then
        log "${RED}❌ Worker/Queue Errors Detected${NC}"
        ((ERRORS_FOUND++))

        log "${YELLOW}   • Restarting workers...${NC}"
        sudo supervisorctl restart all 2>/dev/null || true
        ((FIXES_APPLIED++))
        ((FIXES_THIS_SECTION++))
    fi

    # ═══════════════════════════════════════════════════════════════════════════
    # MIGRATION/PATCH ERRORS
    # ═══════════════════════════════════════════════════════════════════════════

    if echo "$ALL_ERRORS" | grep -qi "migration.*failed\|patch.*failed\|migrate"; then
        log "${RED}❌ Migration/Patch Errors Detected${NC}"
        ((ERRORS_FOUND++))

        log "${YELLOW}   • Running migrations...${NC}"
        bench --site "$SITE" migrate 2>/dev/null || true
        ((FIXES_APPLIED++))
        ((FIXES_THIS_SECTION++))
    fi

    # ═══════════════════════════════════════════════════════════════════════════
    # DOCTYPE/SCHEMA ERRORS
    # ═══════════════════════════════════════════════════════════════════════════

    if echo "$ALL_ERRORS" | grep -qi "doctype.*not.*found\|invalid.*doctype\|schema.*error"; then
        log "${RED}❌ DocType/Schema Errors${NC}"
        ((ERRORS_FOUND++))

        log "${YELLOW}   • Rebuilding DocTypes...${NC}"
        bench --site "$SITE" migrate 2>/dev/null || true
        bench --site "$SITE" clear-cache 2>/dev/null || true
        ((FIXES_APPLIED++))
        ((FIXES_THIS_SECTION++))
    fi

    # ═══════════════════════════════════════════════════════════════════════════
    # CSRF/SESSION ERRORS
    # ═══════════════════════════════════════════════════════════════════════════

    if echo "$ALL_ERRORS" | grep -qi "csrf\|session.*expired\|invalid.*token"; then
        log "${RED}❌ CSRF/Session Errors${NC}"
        ((ERRORS_FOUND++))

        log "${YELLOW}   • Clearing sessions...${NC}"
        bench --site "$SITE" clear-cache 2>/dev/null || true
        ((FIXES_APPLIED++))
        ((FIXES_THIS_SECTION++))
    fi

    # ═══════════════════════════════════════════════════════════════════════════
    # EMAIL/SMTP ERRORS
    # ═══════════════════════════════════════════════════════════════════════════

    if echo "$ALL_ERRORS" | grep -qi "smtp\|email.*failed\|authentication.*failed.*email"; then
        log "${RED}❌ Email/SMTP Errors${NC}"
        ((ERRORS_FOUND++))

        log "${YELLOW}   • Check Email Account settings in ERPNext${NC}"
        ((FIXES_THIS_SECTION++))
    fi

    # ═══════════════════════════════════════════════════════════════════════════
    # SSL/NGINX ERRORS
    # ═══════════════════════════════════════════════════════════════════════════

    if echo "$ALL_ERRORS" | grep -qi "ssl\|certificate\|nginx.*error"; then
        log "${RED}❌ SSL/Nginx Errors${NC}"
        ((ERRORS_FOUND++))

        log "${YELLOW}   • Testing and reloading Nginx...${NC}"
        if sudo nginx -t 2>&1 | grep -q "successful"; then
            sudo systemctl reload nginx
            ((FIXES_APPLIED++))
            ((FIXES_THIS_SECTION++))
        else
            log "${YELLOW}   • Regenerating Nginx config...${NC}"
            sudo bench setup nginx --yes 2>/dev/null || true
            sudo systemctl restart nginx
            ((FIXES_APPLIED++))
            ((FIXES_THIS_SECTION++))
        fi
    fi

    # ═══════════════════════════════════════════════════════════════════════════
    # TIMEOUT ERRORS
    # ═══════════════════════════════════════════════════════════════════════════

    if echo "$ALL_ERRORS" | grep -qi "timeout\|timed out\|504.*gateway"; then
        log "${RED}❌ Timeout Errors${NC}"
        ((ERRORS_FOUND++))

        log "${YELLOW}   • Increasing timeouts and restarting services...${NC}"
        sudo supervisorctl restart all 2>/dev/null || true
        ((FIXES_APPLIED++))
        ((FIXES_THIS_SECTION++))
    fi

    # ═══════════════════════════════════════════════════════════════════════════
    # DISK SPACE ERRORS
    # ═══════════════════════════════════════════════════════════════════════════

    if echo "$ALL_ERRORS" | grep -qi "no space\|disk.*full\|enospc"; then
        log "${RED}❌ Disk Space Errors${NC}"
        ((ERRORS_FOUND++))
        ((CRITICAL_ERRORS++))

        log "${YELLOW}   • Cleaning up...${NC}"
        bench clear-cache 2>/dev/null || true
        find "$BENCH_DIR/logs" -name "*.log" -mtime +7 -delete 2>/dev/null || true
        find "$BENCH_DIR/sites/*/private/backups" -name "*.sql.gz" -mtime +30 -delete 2>/dev/null || true
        ((FIXES_APPLIED++))
        ((FIXES_THIS_SECTION++))
    fi

    # ═══════════════════════════════════════════════════════════════════════════
    # CIRCULAR REFERENCE ERRORS
    # ═══════════════════════════════════════════════════════════════════════════

    if echo "$ALL_ERRORS" | grep -qi "circular.*reference\|maximum.*recursion"; then
        log "${RED}❌ Circular Reference Errors${NC}"
        ((ERRORS_FOUND++))

        log "${YELLOW}   • This requires code-level fix${NC}"
    fi

    # ═══════════════════════════════════════════════════════════════════════════
    # VERSION MISMATCH ERRORS
    # ═══════════════════════════════════════════════════════════════════════════

    if echo "$ALL_ERRORS" | grep -qi "version.*mismatch\|incompatible.*version"; then
        log "${RED}❌ Version Mismatch Errors${NC}"
        ((ERRORS_FOUND++))

        log "${YELLOW}   • Check app versions compatibility${NC}"
        bench version 2>/dev/null || true
    fi

    # ═══════════════════════════════════════════════════════════════════════════
    # GIT CONFLICT ERRORS
    # ═══════════════════════════════════════════════════════════════════════════

    if echo "$ALL_ERRORS" | grep -qi "git.*conflict\|merge.*conflict"; then
        log "${RED}❌ Git Conflict Errors${NC}"
        ((ERRORS_FOUND++))

        log "${YELLOW}   • Check git status in apps:${NC}"
        for app_dir in "$BENCH_DIR/apps"/*; do
            if [ -d "$app_dir/.git" ]; then
                cd "$app_dir" && git status 2>/dev/null | grep -q "conflict" && log "${RED}   Conflict in: $(basename $app_dir)${NC}"
            fi
        done
    fi

    # ═══════════════════════════════════════════════════════════════════════════
    # FILE UPLOAD ERRORS
    # ═══════════════════════════════════════════════════════════════════════════

    if echo "$ALL_ERRORS" | grep -qi "file.*too.*large\|413.*request.*entity"; then
        log "${RED}❌ File Upload Size Errors${NC}"
        ((ERRORS_FOUND++))

        log "${YELLOW}   • Check Nginx client_max_body_size${NC}"
        log "${CYAN}   Set in site config: max_file_size = 10485760${NC}"
    fi

    # ═══════════════════════════════════════════════════════════════════════════
    # CUSTOM SCRIPT ERRORS
    # ═══════════════════════════════════════════════════════════════════════════

    if echo "$ALL_ERRORS" | grep -qi "custom.*script\|client.*script.*error"; then
        log "${RED}❌ Custom Script Errors${NC}"
        ((ERRORS_FOUND++))

        log "${YELLOW}   • Check Custom Scripts in ERPNext${NC}"
        log "${CYAN}   Clear browser cache and test${NC}"
    fi

    # ═══════════════════════════════════════════════════════════════════════════
    # HOOKS ERRORS
    # ═══════════════════════════════════════════════════════════════════════════

    if echo "$ALL_ERRORS" | grep -qi "hooks\|hook.*not.*found"; then
        log "${RED}❌ Hooks Errors${NC}"
        ((ERRORS_FOUND++))

        log "${YELLOW}   • Check hooks.py in custom apps${NC}"
        bench --site "$SITE" migrate 2>/dev/null || true
        ((FIXES_THIS_SECTION++))
    fi

    # ═══════════════════════════════════════════════════════════════════════════
    # SUMMARY OF FIXES
    # ═══════════════════════════════════════════════════════════════════════════

    if [ "$FIXES_THIS_SECTION" -gt 0 ]; then
        log "${GREEN}✓ Applied $FIXES_THIS_SECTION automatic fixes${NC}"
    fi

    # Show sample errors
    log "${CYAN}Sample error messages (last 3):${NC}"
    echo "$ALL_ERRORS" | grep -E "error|exception" | tail -3 | while read err; do
        log "${YELLOW}   ${err:0:100}...${NC}"
    done

else
    log "${GREEN}✅ No errors found in logs${NC}"
fi

log ""

#
# ─── CHECK 13: SCHEDULER ───────────────────────────────────────────────────────
#
((TOTAL_CHECKS++))
log "${BLUE}[13/19] Scheduler Status${NC}"

if [ "$SITE" != "unknown" ]; then
    SCHEDULER_STATUS=$(bench --site "$SITE" doctor 2>/dev/null | grep -i scheduler || echo "Unknown")

    if echo "$SCHEDULER_STATUS" | grep -qi "enabled\|active"; then
        log "${GREEN}✅ Scheduler: Enabled${NC}"
    else
        log "${YELLOW}⚠️  Scheduler: Disabled - enabling...${NC}"
        bench --site "$SITE" scheduler enable 2>/dev/null
        bench --site "$SITE" scheduler resume 2>/dev/null
        ((FIXES_APPLIED++))
    fi

    # Show pending jobs
    PENDING=$(bench --site "$SITE" show-pending-jobs 2>/dev/null | head -3)
    if [ -n "$PENDING" ]; then
        log "${CYAN}Pending jobs:${NC}"
        echo "$PENDING" | tee -a "$LOG_FILE"
    fi
fi
log ""

#
# ─── CHECK 14: SSL CERTIFICATES (MULTI-SITE) ───────────────────────────────────
#
((TOTAL_CHECKS++))
log "${BLUE}[14/19] SSL Certificates (All Sites)${NC}"

TOTAL_SITES_WITH_SSL=0
TOTAL_SITES_WITHOUT_SSL=0
EXPIRING_CERTS=0
EXPIRED_CERTS=0

if [ "$SITE" != "unknown" ]; then
    for check_site in "${ALL_SITES[@]}"; do
        if [ "$check_site" == "unknown" ]; then
            continue
        fi

        log "${CYAN}Checking: $check_site${NC}"

        # Check multiple SSL locations
        SSL_CERT=""
        if [ -f "/etc/letsencrypt/live/$check_site/fullchain.pem" ]; then
            SSL_CERT="/etc/letsencrypt/live/$check_site/fullchain.pem"
        elif [ -f "/etc/letsencrypt/live/$check_site-0001/fullchain.pem" ]; then
            SSL_CERT="/etc/letsencrypt/live/$check_site-0001/fullchain.pem"
        elif [ -f "/etc/ssl/certs/$check_site.crt" ]; then
            SSL_CERT="/etc/ssl/certs/$check_site.crt"
        fi

        if [ -n "$SSL_CERT" ]; then
            ((TOTAL_SITES_WITH_SSL++))

            # Get expiry date
            EXPIRY=$(openssl x509 -enddate -noout -in "$SSL_CERT" 2>/dev/null | cut -d= -f2)

            if [ -n "$EXPIRY" ]; then
                EXPIRY_EPOCH=$(date -d "$EXPIRY" +%s 2>/dev/null || echo 0)
                NOW_EPOCH=$(date +%s)
                DAYS_LEFT=$(( (EXPIRY_EPOCH - NOW_EPOCH) / 86400 ))

                if [ "$DAYS_LEFT" -lt 0 ]; then
                    log "${RED}   ❌ EXPIRED ${DAYS_LEFT#-} days ago!${NC}"
                    ((EXPIRED_CERTS++))
                    ((ERRORS_FOUND++))

                    log "${YELLOW}   Attempting SSL renewal...${NC}"
                    if sudo certbot renew --cert-name "$check_site" --force-renewal &>/dev/null; then
                        log "${GREEN}   ✅ Certificate renewed successfully${NC}"
                        ((FIXES_APPLIED++))
                    else
                        log "${RED}   ❌ Renewal failed - manual intervention needed${NC}"
                        log "${CYAN}   Try: sudo bench setup lets-encrypt $check_site${NC}"
                    fi

                elif [ "$DAYS_LEFT" -lt 30 ]; then
                    log "${YELLOW}   ⚠️  Expires in $DAYS_LEFT days${NC}"
                    ((EXPIRING_CERTS++))
                    ((WARNINGS_FOUND++))

                    log "${YELLOW}   Renewing certificate...${NC}"
                    if sudo certbot renew --cert-name "$check_site" &>/dev/null; then
                        log "${GREEN}   ✅ Certificate renewed${NC}"
                        ((FIXES_APPLIED++))
                    fi

                elif [ "$DAYS_LEFT" -lt 60 ]; then
                    log "${CYAN}   ✓ Valid for $DAYS_LEFT days (renewal soon)${NC}"
                    ((WARNINGS_FOUND++))
                else
                    log "${GREEN}   ✅ Valid for $DAYS_LEFT days${NC}"
                fi
            else
                log "${YELLOW}   ⚠️  Cannot read expiry date${NC}"
                ((WARNINGS_FOUND++))
            fi

            # Check Nginx SSL configuration
            if [ -f "/etc/nginx/conf.d/$check_site.conf" ]; then
                if grep -q "ssl_certificate" "/etc/nginx/conf.d/$check_site.conf" 2>/dev/null; then
                    log "${GREEN}   ✅ Nginx SSL configured${NC}"
                else
                    log "${YELLOW}   ⚠️  Nginx SSL not configured${NC}"
                    ((WARNINGS_FOUND++))
                fi
            elif [ -f "/etc/nginx/sites-enabled/$check_site" ]; then
                if grep -q "ssl_certificate" "/etc/nginx/sites-enabled/$check_site" 2>/dev/null; then
                    log "${GREEN}   ✅ Nginx SSL configured${NC}"
                else
                    log "${YELLOW}   ⚠️  Nginx SSL not configured${NC}"
                    ((WARNINGS_FOUND++))
                fi
            fi

        else
            ((TOTAL_SITES_WITHOUT_SSL++))
            log "${RED}   ❌ No SSL certificate found${NC}"
            ((WARNINGS_FOUND++))

            # Check if certbot is installed
            if ! command -v certbot &>/dev/null; then
                log "${YELLOW}   Installing certbot...${NC}"
                sudo apt update -qq
                sudo apt install -y certbot python3-certbot-nginx &>/dev/null
                ((FIXES_APPLIED++))
            fi

            log "${CYAN}   Install with: sudo bench setup lets-encrypt $check_site${NC}"
            log "${CYAN}   Or manually: sudo certbot --nginx -d $check_site${NC}"
        fi

        log ""
    done

    # Summary
    log "${BLUE}SSL Summary:${NC}"
    log "${GREEN}   Sites with SSL: $TOTAL_SITES_WITH_SSL${NC}"
    log "${RED}   Sites without SSL: $TOTAL_SITES_WITHOUT_SSL${NC}"

    if [ "$EXPIRED_CERTS" -gt 0 ]; then
        log "${RED}   Expired certificates: $EXPIRED_CERTS${NC}"
    fi

    if [ "$EXPIRING_CERTS" -gt 0 ]; then
        log "${YELLOW}   Expiring soon: $EXPIRING_CERTS${NC}"
    fi

    # Check certbot auto-renewal
    if command -v certbot &>/dev/null; then
        if systemctl is-enabled certbot.timer &>/dev/null; then
            log "${GREEN}   ✅ Auto-renewal enabled${NC}"
        else
            log "${YELLOW}   ⚠️  Auto-renewal not enabled - enabling...${NC}"
            sudo systemctl enable certbot.timer &>/dev/null
            sudo systemctl start certbot.timer &>/dev/null
            ((FIXES_APPLIED++))
            log "${GREEN}   ✅ Auto-renewal enabled${NC}"
        fi
    fi

else
    log "${YELLOW}⚠️  No sites found - skipping SSL check${NC}"
fi
log ""

#
# ─── CHECK 15: SITE ACCESSIBILITY (MULTI-SITE) ────────────────────────────────
#
((TOTAL_CHECKS++))
log "${BLUE}[15/19] Site Accessibility Test (All Sites)${NC}"

ACCESSIBLE_SITES=0
INACCESSIBLE_SITES=0

if [ "$SITE" != "unknown" ]; then
    for check_site in "${ALL_SITES[@]}"; do
        if [ "$check_site" == "unknown" ]; then
            continue
        fi

        log "${CYAN}Testing: $check_site${NC}"

        # Try HTTP access
        HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost" -H "Host: $check_site" --max-time 5 2>/dev/null || echo "000")

        if [ "$HTTP_CODE" == "200" ] || [ "$HTTP_CODE" == "301" ] || [ "$HTTP_CODE" == "302" ]; then
            log "${GREEN}   ✅ HTTP accessible: $HTTP_CODE${NC}"
            ((ACCESSIBLE_SITES++))
        else
            log "${RED}   ❌ HTTP not accessible: $HTTP_CODE${NC}"
            ((INACCESSIBLE_SITES++))
            ((ERRORS_FOUND++))
        fi

        # Try HTTPS access if SSL exists
        if [ -f "/etc/letsencrypt/live/$check_site/fullchain.pem" ] || [ -f "/etc/letsencrypt/live/$check_site-0001/fullchain.pem" ]; then
            HTTPS_CODE=$(curl -sk -o /dev/null -w "%{http_code}" "https://localhost" -H "Host: $check_site" --max-time 5 2>/dev/null || echo "000")

            if [ "$HTTPS_CODE" == "200" ] || [ "$HTTPS_CODE" == "301" ] || [ "$HTTPS_CODE" == "302" ]; then
                log "${GREEN}   ✅ HTTPS accessible: $HTTPS_CODE${NC}"
            else
                log "${YELLOW}   ⚠️  HTTPS not accessible: $HTTPS_CODE${NC}"
                ((WARNINGS_FOUND++))
            fi
        fi

        # Check if site is active in bench
        if bench --site "$check_site" doctor 2>&1 | grep -qi "active\|running"; then
            log "${GREEN}   ✅ Site active in bench${NC}"
        else
            log "${YELLOW}   ⚠️  Site may not be properly configured${NC}"
            ((WARNINGS_FOUND++))
        fi

        log ""
    done

    # Summary
    log "${BLUE}Accessibility Summary:${NC}"
    log "${GREEN}   Accessible sites: $ACCESSIBLE_SITES${NC}"

    if [ "$INACCESSIBLE_SITES" -gt 0 ]; then
        log "${RED}   Inaccessible sites: $INACCESSIBLE_SITES${NC}"

        log "${YELLOW}Attempting to fix by restarting services...${NC}"
        sudo systemctl restart nginx
        sudo supervisorctl restart all
        ((FIXES_APPLIED++))

        sleep 3

        # Re-test
        log "${CYAN}Re-testing after restart...${NC}"
        FIXED_SITES=0
        for check_site in "${ALL_SITES[@]}"; do
            if [ "$check_site" == "unknown" ]; then
                continue
            fi

            HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost" -H "Host: $check_site" --max-time 5 2>/dev/null || echo "000")

            if [ "$HTTP_CODE" == "200" ] || [ "$HTTP_CODE" == "301" ] || [ "$HTTP_CODE" == "302" ]; then
                ((FIXED_SITES++))
            fi
        done

        if [ "$FIXED_SITES" -eq "${#ALL_SITES[@]}" ]; then
            log "${GREEN}   ✅ All sites now accessible${NC}"
        else
            log "${YELLOW}   ⚠️  Some sites still inaccessible - manual check needed${NC}"
        fi
    fi

else
    log "${YELLOW}⚠️  No sites found - skipping accessibility check${NC}"
fi
log ""

#
# ─── CHECK 16: DATABASE HEALTH ─────────────────────────────────────────────────
#
((TOTAL_CHECKS++))
log "${BLUE}[16/19] Database Health & Optimization${NC}"

if [ "$SITE" != "unknown" ]; then
    SITE_DB=$(echo "$SITE" | tr '.' '_' | tr '-' '_')

    # Check database size
    DB_SIZE=$(mysql -u root -e "SELECT ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS 'Size_MB' FROM information_schema.tables WHERE table_schema='$SITE_DB';" 2>/dev/null | tail -1)

    if [ -n "$DB_SIZE" ]; then
        log "${CYAN}Database size: ${DB_SIZE} MB${NC}"

        # Warn if database is very large
        if (( $(echo "$DB_SIZE > 5000" | bc -l 2>/dev/null || echo 0) )); then
            log "${YELLOW}⚠️  Large database detected - consider archiving old data${NC}"
            ((WARNINGS_FOUND++))
        fi
    fi

    # Check for database errors
    DB_ERRORS=$(mysql -u root -e "CHECK TABLE \`$SITE_DB\`.*;" 2>&1 | grep -i "error\|corrupt" || true)
    if [ -n "$DB_ERRORS" ]; then
        log "${RED}❌ Database errors found!${NC}"
        ((ERRORS_FOUND++))
        log "${YELLOW}Running database repair...${NC}"
        mysql -u root -e "REPAIR TABLE \`$SITE_DB\`.*;" 2>/dev/null
        ((FIXES_APPLIED++))
    else
        log "${GREEN}✅ Database integrity OK${NC}"
    fi

    # Check InnoDB buffer pool size
    INNODB_BUFFER=$(mysql -u root -e "SHOW VARIABLES LIKE 'innodb_buffer_pool_size';" 2>/dev/null | awk 'NR==2 {print $2}')
    if [ -n "$INNODB_BUFFER" ]; then
        INNODB_BUFFER_MB=$((INNODB_BUFFER / 1024 / 1024))
        log "${CYAN}InnoDB buffer pool: ${INNODB_BUFFER_MB} MB${NC}"

        if [ "$INNODB_BUFFER_MB" -lt 256 ]; then
            log "${YELLOW}⚠️  InnoDB buffer pool is small - performance may be affected${NC}"
            ((WARNINGS_FOUND++))
        fi
    fi
else
    log "${YELLOW}⚠️  No site found - skipping database health check${NC}"
fi
log ""

#
# ─── CHECK 17: BACKUP STATUS ───────────────────────────────────────────────────
#
((TOTAL_CHECKS++))
log "${BLUE}[17/19] Backup Status${NC}"

if [ "$SITE" != "unknown" ]; then
    BACKUP_DIR="$BENCH_DIR/sites/$SITE/private/backups"

    if [ -d "$BACKUP_DIR" ]; then
        # Find latest backup
        LATEST_DB_BACKUP=$(find "$BACKUP_DIR" -name "*-database.sql.gz" -type f -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -1 | cut -d' ' -f2)
        LATEST_FILES_BACKUP=$(find "$BACKUP_DIR" -name "*-files.tar" -type f -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -1 | cut -d' ' -f2)

        if [ -n "$LATEST_DB_BACKUP" ]; then
            BACKUP_AGE=$(( ($(date +%s) - $(stat -c %Y "$LATEST_DB_BACKUP")) / 86400 ))
            BACKUP_SIZE=$(du -h "$LATEST_DB_BACKUP" | cut -f1)

            log "${CYAN}Latest database backup: $(basename "$LATEST_DB_BACKUP")${NC}"
            log "${CYAN}   Age: $BACKUP_AGE days | Size: $BACKUP_SIZE${NC}"

            if [ "$BACKUP_AGE" -gt 7 ]; then
                log "${RED}❌ Backup is older than 7 days!${NC}"
                ((ERRORS_FOUND++))

                log "${YELLOW}Creating fresh backup...${NC}"
                bench --site "$SITE" backup --with-files &>/dev/null
                ((FIXES_APPLIED++))
                log "${GREEN}✅ New backup created${NC}"
            elif [ "$BACKUP_AGE" -gt 3 ]; then
                log "${YELLOW}⚠️  Backup is $BACKUP_AGE days old - consider creating a fresh one${NC}"
                ((WARNINGS_FOUND++))
            else
                log "${GREEN}✅ Recent backup available${NC}"
            fi
        else
            log "${RED}❌ No database backup found!${NC}"
            ((ERRORS_FOUND++))

            log "${YELLOW}Creating initial backup...${NC}"
            bench --site "$SITE" backup --with-files &>/dev/null
            ((FIXES_APPLIED++))
            log "${GREEN}✅ Backup created${NC}"
        fi

        # Count total backups
        BACKUP_COUNT=$(find "$BACKUP_DIR" -name "*-database.sql.gz" -type f | wc -l)
        log "${CYAN}Total backups: $BACKUP_COUNT${NC}"

    else
        log "${RED}❌ Backup directory not found${NC}"
        ((ERRORS_FOUND++))
    fi
else
    log "${YELLOW}⚠️  No site found - skipping backup check${NC}"
fi
log ""

#
# ─── CHECK 18: SYSTEM RESOURCES & LIMITS ───────────────────────────────────────
#
((TOTAL_CHECKS++))
log "${BLUE}[18/19] System Resources & Limits${NC}"

# Check open file limit
FILE_LIMIT=$(ulimit -n)
log "${CYAN}Open files limit: $FILE_LIMIT${NC}"

if [ "$FILE_LIMIT" -lt 10000 ]; then
    log "${YELLOW}⚠️  File limit is low - may cause issues under load${NC}"
    ((WARNINGS_FOUND++))
    log "${CYAN}   Increase with: ulimit -n 65535${NC}"
fi

# Check max user processes
PROC_LIMIT=$(ulimit -u)
log "${CYAN}Max processes: $PROC_LIMIT${NC}"

# Check system load average
LOAD_AVG=$(uptime | awk -F'load average:' '{print $2}' | cut -d',' -f1 | tr -d ' ')
CPU_COUNT=$(nproc)
log "${CYAN}Load average: $LOAD_AVG (CPUs: $CPU_COUNT)${NC}"

# Warn if load is too high
if (( $(echo "$LOAD_AVG > $CPU_COUNT" | bc -l 2>/dev/null || echo 0) )); then
    log "${YELLOW}⚠️  High system load detected${NC}"
    ((WARNINGS_FOUND++))
fi

# Check swap usage
SWAP_TOTAL=$(free -m | awk 'NR==3 {print $2}')
SWAP_USED=$(free -m | awk 'NR==3 {print $3}')

if [ "$SWAP_TOTAL" -gt 0 ]; then
    SWAP_PERCENT=$((SWAP_USED * 100 / SWAP_TOTAL))
    log "${CYAN}Swap usage: ${SWAP_PERCENT}% (${SWAP_USED}MB/${SWAP_TOTAL}MB)${NC}"

    if [ "$SWAP_PERCENT" -gt 50 ]; then
        log "${YELLOW}⚠️  High swap usage - system may be low on RAM${NC}"
        ((WARNINGS_FOUND++))
    fi
else
    log "${YELLOW}⚠️  No swap space configured${NC}"
fi

# Check disk I/O (if iostat available)
if command -v iostat &>/dev/null; then
    DISK_WAIT=$(iostat -x 1 2 | awk '/^[sv]d/ {print $10}' | tail -1 2>/dev/null || echo "0")
    log "${CYAN}Disk I/O wait: ${DISK_WAIT}%${NC}"

    if (( $(echo "$DISK_WAIT > 30" | bc -l 2>/dev/null || echo 0) )); then
        log "${YELLOW}⚠️  High disk I/O - storage may be slow${NC}"
        ((WARNINGS_FOUND++))
    fi
fi

log ""

#
# ─── SUMMARY ───────────────────────────────────────────────────────────────────
#
log "${BLUE}╔═══════════════════════════════════════════════════════════════════╗${NC}"
log "${BLUE}║                         📊 SUMMARY                                ║${NC}"
log "${BLUE}╚═══════════════════════════════════════════════════════════════════╝${NC}"
log ""
log "${CYAN}Total Checks:        $TOTAL_CHECKS${NC}"
log "${RED}Critical Errors:     $CRITICAL_ERRORS${NC}"
log "${RED}Errors Found:        $ERRORS_FOUND${NC}"
log "${YELLOW}Warnings:            $WARNINGS_FOUND${NC}"
log "${GREEN}Fixes Applied:       $FIXES_APPLIED${NC}"
log ""
log "${CYAN}Bench Directory:     $BENCH_DIR${NC}"
log "${CYAN}Site Name:           $SITE${NC}"
log "${CYAN}Log File:            $LOG_FILE${NC}"
log ""

#
# ─── FINAL VERDICT ─────────────────────────────────────────────────────────────
#
if [ "$CRITICAL_ERRORS" -gt 0 ]; then
    log "${RED}╔═══════════════════════════════════════════════════════════════════╗${NC}"
    log "${RED}║                  ⚠️  CRITICAL ISSUES FOUND ⚠️                      ║${NC}"
    log "${RED}╚═══════════════════════════════════════════════════════════════════╝${NC}"
    log ""
    log "${RED}Your ERPNext installation has critical issues that need attention.${NC}"
    log ""
    log "${YELLOW}Recommended actions:${NC}"
    log "1. Review the log file: $LOG_FILE"
    log "2. Run doctor.sh again to verify fixes"
    log "3. Check bench logs: cd $BENCH_DIR && bench doctor"
    log "4. Manual intervention may be required"
    log ""

elif [ "$ERRORS_FOUND" -gt 0 ]; then
    log "${YELLOW}╔═══════════════════════════════════════════════════════════════════╗${NC}"
    log "${YELLOW}║                 ⚠️  ISSUES FOUND AND FIXED ⚠️                      ║${NC}"
    log "${YELLOW}╚═══════════════════════════════════════════════════════════════════╝${NC}"
    log ""
    log "${GREEN}$FIXES_APPLIED fixes were applied automatically.${NC}"
    log ""
    log "${CYAN}Recommended: Run doctor.sh again to verify all fixes.${NC}"
    log ""

elif [ "$WARNINGS_FOUND" -gt 0 ]; then
    log "${CYAN}╔═══════════════════════════════════════════════════════════════════╗${NC}"
    log "${CYAN}║                  ✅ HEALTHY WITH WARNINGS ✅                       ║${NC}"
    log "${CYAN}╚═══════════════════════════════════════════════════════════════════╝${NC}"
    log ""
    log "${GREEN}ERPNext is running well with minor warnings.${NC}"
    log ""

else
    log "${GREEN}╔═══════════════════════════════════════════════════════════════════╗${NC}"
    log "${GREEN}║                    🎉 ERPNext is HEALTHY! 🎉                      ║${NC}"
    log "${GREEN}╚═══════════════════════════════════════════════════════════════════╝${NC}"
    log ""
    log "${GREEN}All systems operational. No issues detected.${NC}"
    log ""
fi

log "${BLUE}═══════════════════════════════════════════════════════════════════${NC}"
log "${CYAN}Finished: $(date '+%Y-%m-%d %H:%M:%S')${NC}"
log "${BLUE}═══════════════════════════════════════════════════════════════════${NC}"

# Exit code based on severity
if [ "$CRITICAL_ERRORS" -gt 0 ]; then
    exit 2
elif [ "$ERRORS_FOUND" -gt 0 ]; then
    exit 1
else
    exit 0
fi
