#!/usr/bin/env bash

#═══════════════════════════════════════════════════════════════════════════════
# ERPNext Complete Uninstaller
# Removes everything installed by install-hybrid.sh
# Version: 1.0
#═══════════════════════════════════════════════════════════════════════════════

#
# ─── COLORS ────────────────────────────────────────────────────────────────────
#
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

#
# ─── HEADER ────────────────────────────────────────────────────────────────────
#
clear
echo -e "${RED}╔═══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║                                                                   ║${NC}"
echo -e "${RED}║              🗑️  ERPNext COMPLETE UNINSTALLER  🗑️                 ║${NC}"
echo -e "${RED}║                                                                   ║${NC}"
echo -e "${RED}║         This will remove EVERYTHING installed by                 ║${NC}"
echo -e "${RED}║         install-hybrid.sh including all data!                    ║${NC}"
echo -e "${RED}║                                                                   ║${NC}"
echo -e "${RED}╚═══════════════════════════════════════════════════════════════════╝${NC}"
echo ""

#
# ─── WARNING ───────────────────────────────────────────────────────────────────
#
echo -e "${RED}⚠️  WARNING: This will permanently delete:${NC}"
echo -e "${YELLOW}   • All ERPNext/Frappe bench directories${NC}"
echo -e "${YELLOW}   • All databases and data${NC}"
echo -e "${YELLOW}   • Nginx configurations${NC}"
echo -e "${YELLOW}   • Supervisor configurations${NC}"
echo -e "${YELLOW}   • MariaDB/MySQL${NC}"
echo -e "${YELLOW}   • Redis${NC}"
echo -e "${YELLOW}   • Node.js (NVM installation)${NC}"
echo -e "${YELLOW}   • All system packages installed for ERPNext${NC}"
echo ""

read -p "$(echo -e ${RED}Are you ABSOLUTELY SURE you want to continue? Type 'YES' to confirm: ${NC})" CONFIRM

if [ "$CONFIRM" != "YES" ]; then
    echo -e "${GREEN}Uninstall cancelled. No changes made.${NC}"
    exit 0
fi

echo ""
echo -e "${YELLOW}Starting complete uninstallation...${NC}"
echo ""
sleep 2

#
# ─── FIND BENCH DIRECTORIES ────────────────────────────────────────────────────
#
echo -e "${BLUE}[1/12] Finding ERPNext installations...${NC}"

BENCH_DIRS=()

# Search common locations
if [ -d "$HOME/frappe-bench" ]; then
    BENCH_DIRS+=("$HOME/frappe-bench")
fi

if [ -d "/home/frappe/frappe-bench" ]; then
    BENCH_DIRS+=("/home/frappe/frappe-bench")
fi

# Search for other bench installations
while IFS= read -r dir; do
    if [ -n "$dir" ] && [ -d "$dir" ]; then
        BENCH_DIRS+=("$dir")
    fi
done < <(find /opt /home -maxdepth 3 -name "frappe-bench" -type d 2>/dev/null | grep -v "$HOME/frappe-bench" | grep -v "/home/frappe/frappe-bench")

if [ ${#BENCH_DIRS[@]} -eq 0 ]; then
    echo -e "${YELLOW}⊘ No bench installations found${NC}"
else
    echo -e "${CYAN}Found ${#BENCH_DIRS[@]} bench installation(s):${NC}"
    for dir in "${BENCH_DIRS[@]}"; do
        echo -e "${CYAN}   • $dir${NC}"
    done
fi
echo ""

#
# ─── STOP ALL SERVICES ─────────────────────────────────────────────────────────
#
echo -e "${BLUE}[2/12] Stopping all services...${NC}"

# Stop bench processes
pkill -f "bench start" 2>/dev/null || true
pkill -f "honcho" 2>/dev/null || true

# Kill Redis on bench ports
for port in 11000 12000 13000; do
    if command -v lsof &>/dev/null && lsof -ti:$port &>/dev/null; then
        echo -e "${YELLOW}   • Killing process on port $port${NC}"
        kill -9 $(lsof -ti:$port) 2>/dev/null || true
    fi
done

# Stop system services
sudo systemctl stop supervisor 2>/dev/null || true
sudo systemctl stop nginx 2>/dev/null || true
sudo systemctl stop redis-server 2>/dev/null || true
sudo systemctl stop mariadb 2>/dev/null || true
sudo systemctl stop mysql 2>/dev/null || true

echo -e "${GREEN}✓ Services stopped${NC}"
echo ""

#
# ─── REMOVE BENCH DIRECTORIES ──────────────────────────────────────────────────
#
echo -e "${BLUE}[3/12] Removing bench directories...${NC}"

for dir in "${BENCH_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        echo -e "${YELLOW}   • Removing: $dir${NC}"
        rm -rf "$dir"
    fi
done

echo -e "${GREEN}✓ Bench directories removed${NC}"
echo ""

#
# ─── REMOVE DATABASES ──────────────────────────────────────────────────────────
#
echo -e "${BLUE}[4/12] Removing all ERPNext databases...${NC}"

if command -v mysql &>/dev/null; then
    # Get all databases starting with common ERPNext patterns
    DATABASES=$(mysql -u root -e "SHOW DATABASES;" 2>/dev/null | grep -E "^_|erpnext|frappe" | grep -v "Database\|information_schema\|mysql\|performance_schema" || true)

    if [ -n "$DATABASES" ]; then
        echo "$DATABASES" | while read db; do
            echo -e "${YELLOW}   • Dropping database: $db${NC}"
            mysql -u root -e "DROP DATABASE IF EXISTS \`$db\`;" 2>/dev/null || true
        done
        echo -e "${GREEN}✓ Databases removed${NC}"
    else
        echo -e "${YELLOW}⊘ No ERPNext databases found${NC}"
    fi
else
    echo -e "${YELLOW}⊘ MySQL not accessible${NC}"
fi
echo ""

#
# ─── REMOVE NGINX CONFIGURATIONS ───────────────────────────────────────────────
#
echo -e "${BLUE}[5/12] Removing Nginx configurations...${NC}"

# Remove site configs
sudo rm -f /etc/nginx/conf.d/*erpnext* 2>/dev/null || true
sudo rm -f /etc/nginx/conf.d/*frappe* 2>/dev/null || true
sudo rm -f /etc/nginx/sites-enabled/*erpnext* 2>/dev/null || true
sudo rm -f /etc/nginx/sites-enabled/*frappe* 2>/dev/null || true
sudo rm -f /etc/nginx/sites-available/*erpnext* 2>/dev/null || true
sudo rm -f /etc/nginx/sites-available/*frappe* 2>/dev/null || true

# Remove any site-specific configs (scan for bench-related configs)
find /etc/nginx/conf.d/ -name "*.conf" -exec grep -l "frappe\|bench" {} \; 2>/dev/null | while read conf; do
    echo -e "${YELLOW}   • Removing: $conf${NC}"
    sudo rm -f "$conf"
done

find /etc/nginx/sites-enabled/ -type f -exec grep -l "frappe\|bench" {} \; 2>/dev/null | while read conf; do
    echo -e "${YELLOW}   • Removing: $conf${NC}"
    sudo rm -f "$conf"
done

echo -e "${GREEN}✓ Nginx configurations removed${NC}"
echo ""

#
# ─── REMOVE SUPERVISOR CONFIGURATIONS ──────────────────────────────────────────
#
echo -e "${BLUE}[6/12] Removing Supervisor configurations...${NC}"

sudo rm -f /etc/supervisor/conf.d/*bench* 2>/dev/null || true
sudo rm -f /etc/supervisor/conf.d/*frappe* 2>/dev/null || true
sudo rm -f /etc/supervisor/conf.d/*erpnext* 2>/dev/null || true

# Restore original supervisor config (remove custom chown line)
if [ -f /etc/supervisor/supervisord.conf ]; then
    sudo sed -i '/chown=/d' /etc/supervisor/supervisord.conf 2>/dev/null || true
fi

echo -e "${GREEN}✓ Supervisor configurations removed${NC}"
echo ""

#
# ─── REMOVE NVM & NODE.JS ──────────────────────────────────────────────────────
#
echo -e "${BLUE}[7/12] Removing NVM & Node.js...${NC}"

if [ -d "$HOME/.nvm" ]; then
    echo -e "${YELLOW}   • Removing NVM directory${NC}"
    rm -rf "$HOME/.nvm"

    # Remove NVM from bashrc
    if [ -f "$HOME/.bashrc" ]; then
        echo -e "${YELLOW}   • Cleaning .bashrc${NC}"
        sed -i '/NVM_DIR/d' "$HOME/.bashrc" 2>/dev/null || true
        sed -i '/nvm\.sh/d' "$HOME/.bashrc" 2>/dev/null || true
        sed -i '/Load NVM/d' "$HOME/.bashrc" 2>/dev/null || true
    fi

    echo -e "${GREEN}✓ NVM removed${NC}"
else
    echo -e "${YELLOW}⊘ NVM not found${NC}"
fi
echo ""

#
# ─── REMOVE PYTHON PACKAGES ────────────────────────────────────────────────────
#
echo -e "${BLUE}[8/12] Removing Python packages...${NC}"

if command -v pip3 &>/dev/null; then
    echo -e "${YELLOW}   • Removing frappe-bench${NC}"
    sudo pip3 uninstall -y frappe-bench 2>/dev/null || true

    echo -e "${YELLOW}   • Removing frappe-related packages${NC}"
    sudo pip3 uninstall -y frappe 2>/dev/null || true

    echo -e "${GREEN}✓ Python packages removed${NC}"
else
    echo -e "${YELLOW}⊘ pip3 not found${NC}"
fi
echo ""

#
# ─── DISABLE SERVICES ──────────────────────────────────────────────────────────
#
echo -e "${BLUE}[9/12] Disabling services...${NC}"

sudo systemctl disable supervisor 2>/dev/null || true
sudo systemctl disable nginx 2>/dev/null || true
sudo systemctl disable redis-server 2>/dev/null || true

echo -e "${GREEN}✓ Services disabled${NC}"
echo ""

#
# ─── REMOVE SYSTEM PACKAGES (OPTIONAL) ─────────────────────────────────────────
#
echo -e "${BLUE}[10/12] System packages removal...${NC}"
echo ""
read -p "$(echo -e ${YELLOW}Do you want to remove system packages too? \(MariaDB, Redis, Nginx, etc.\)? [y/N]: ${NC})" REMOVE_PACKAGES

if [[ "$REMOVE_PACKAGES" =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Removing system packages...${NC}"

    sudo apt remove --purge -y \
        mariadb-server mariadb-client \
        redis-server \
        nginx \
        supervisor \
        wkhtmltopdf \
        2>/dev/null || true

    sudo apt autoremove -y 2>/dev/null || true

    echo -e "${GREEN}✓ System packages removed${NC}"
else
    echo -e "${CYAN}⊘ Keeping system packages (MariaDB, Redis, Nginx)${NC}"
fi
echo ""

#
# ─── REMOVE WKHTMLTOPDF ────────────────────────────────────────────────────────
#
echo -e "${BLUE}[11/12] Removing wkhtmltopdf...${NC}"

sudo rm -f /usr/bin/wkhtmltopdf 2>/dev/null || true
sudo rm -f /usr/bin/wkhtmltoimage 2>/dev/null || true
sudo rm -f /usr/local/bin/wkhtmltopdf 2>/dev/null || true
sudo rm -f /usr/local/bin/wkhtmltoimage 2>/dev/null || true

echo -e "${GREEN}✓ wkhtmltopdf removed${NC}"
echo ""

#
# ─── CLEAN UP残留 FILES ───────────────────────────────────────────────────────
#
echo -e "${BLUE}[12/12] Cleaning up residual files...${NC}"

# Remove SSL certificates (if user confirms)
if [ -d "/etc/letsencrypt/live" ]; then
    CERT_COUNT=$(ls -1 /etc/letsencrypt/live | wc -l)
    if [ "$CERT_COUNT" -gt 0 ]; then
        read -p "$(echo -e ${YELLOW}Remove SSL certificates? [y/N]: ${NC})" REMOVE_SSL
        if [[ "$REMOVE_SSL" =~ ^[Yy]$ ]]; then
            echo -e "${YELLOW}   • Removing SSL certificates${NC}"
            sudo rm -rf /etc/letsencrypt/* 2>/dev/null || true
        fi
    fi
fi

# Remove log files
sudo rm -rf /var/log/nginx/*bench* 2>/dev/null || true
sudo rm -rf /var/log/nginx/*frappe* 2>/dev/null || true
sudo rm -rf /var/log/nginx/*erpnext* 2>/dev/null || true

# Remove temp files
rm -rf /tmp/erpnext-* 2>/dev/null || true

echo -e "${GREEN}✓ Cleanup complete${NC}"
echo ""

#
# ─── SUMMARY ───────────────────────────────────────────────────────────────────
#
echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                                   ║${NC}"
echo -e "${GREEN}║              ✅ UNINSTALLATION COMPLETE! ✅                        ║${NC}"
echo -e "${GREEN}║                                                                   ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}═══ What was removed: ═══${NC}"
echo -e "${GREEN}✓${NC} All bench directories"
echo -e "${GREEN}✓${NC} All ERPNext databases"
echo -e "${GREEN}✓${NC} Nginx configurations"
echo -e "${GREEN}✓${NC} Supervisor configurations"
echo -e "${GREEN}✓${NC} NVM & Node.js"
echo -e "${GREEN}✓${NC} Python packages (frappe-bench)"
echo -e "${GREEN}✓${NC} Temporary files"

if [[ "$REMOVE_PACKAGES" =~ ^[Yy]$ ]]; then
    echo -e "${GREEN}✓${NC} System packages (MariaDB, Redis, Nginx, etc.)"
fi

echo ""
echo -e "${BLUE}═══ Next Steps: ═══${NC}"
echo ""
echo -e "1. Reboot your system: ${YELLOW}sudo reboot${NC}"
echo -e "2. (Optional) Clean remaining config files: ${YELLOW}sudo apt autoclean${NC}"
echo -e "3. To reinstall ERPNext: ${YELLOW}./install-hybrid.sh${NC}"
echo ""
echo -e "${CYAN}Thank you for using ERPNext!${NC}"
echo ""
