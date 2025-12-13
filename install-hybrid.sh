#!/usr/bin/env bash

#â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
# ERPNext Complete Installer v2.0
# All-in-one installation script with user input
#â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

# Check if running with sudo
if [ "$EUID" -ne 0 ]; then
    echo "Error: This script must be run with sudo"
    echo "Usage: sudo bash $0"
    exit 1
fi

#
# â”€â”€â”€ COLORS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
#
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
LIGHT_BLUE='\033[1;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

#
# â”€â”€â”€ LOGGING & DEBUGGING â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
#
INSTALL_LOG="/tmp/erpnext_install_$(date +%Y%m%d_%H%M%S).log"
INSTALL_DIR="$HOME/.erpnext_install"
mkdir -p "$INSTALL_DIR"

exec 1> >(tee -a "$INSTALL_LOG")
exec 2>&1

log_info() {
    echo -e "${BLUE}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_success() {
    echo -e "${GREEN}[âœ“ SUCCESS]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_warn() {
    echo -e "${YELLOW}[âš  WARNING]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo -e "${RED}[âœ— ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

#
# â”€â”€â”€ ERROR HANDLING & ROLLBACK â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
#
handle_error() {
    local line=$1
    local exit_code=$?
    log_error "Error on line $line with exit status $exit_code"
    log_warn "Installation failed. Check log: $INSTALL_LOG"
    log_info "To rollback, manual intervention may be needed. Contact support."
    exit $exit_code
}

trap 'handle_error $LINENO' ERR
set -e
set -u

#
# â”€â”€â”€ CONSTANTS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
#
SUPPORTED_DISTRIBUTIONS=("Ubuntu" "Debian")
SUPPORTED_UBUNTU_VERSIONS=("24.04" "22.04" "20.04")
SUPPORTED_DEBIAN_VERSIONS=("12" "11")
RECOMMENDED_DISK_SPACE=50
MINIMUM_DISK_SPACE=20
MIN_MEMORY=4

# Set TERM if not set
export TERM=${TERM:-linux}

clear 2>/dev/null || echo -e "\n\n"

echo -e "${BLUE}â•”â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•—${NC}"
echo -e "${BLUE}â•‘                                                                        â•‘${NC}"
echo -e "${BLUE}â•‘         ðŸš€ ERPNext INSTALLER v2.0 - PRODUCTION READY ðŸš€              â•‘${NC}"
echo -e "${BLUE}â•‘                                                                        â•‘${NC}"
echo -e "${BLUE}â•‘         Enterprise-Grade with Security, Backups & Monitoring          â•‘${NC}"
echo -e "${BLUE}â•‘                                                                        â•‘${NC}"
echo -e "${BLUE}â•šâ•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•${NC}"
echo ""

log_info "Installation started. Log file: $INSTALL_LOG"

#
# â”€â”€â”€ HELPER FUNCTIONS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
#

# Password input with confirmation
ask_password() {
    local prompt="$1"
    local val1 val2

    while true; do
        read -rsp "${prompt}: " val1
        echo >&2
        read -rsp "Confirm password: " val2
        echo >&2

        if [ "$val1" = "$val2" ]; then
            log_success "Password confirmed" >&2
            echo "$val1"
            break
        else
            log_error "Passwords do not match. Please try again." >&2
        fi
    done
}

# Yes/No confirmation
confirm() {
    local prompt="$1"
    local response
    read -p "$prompt (y/N): " response
    response=$(echo "$response" | tr '[:upper:]' '[:lower:]')
    [[ "$response" == "y" || "$response" == "yes" ]]
}

# Get Node.js version
get_node_version() {
    local erp_version="$1"
    local os_name=$(lsb_release -is)
    local os_version=$(lsb_release -rs)

    if [[ "$os_name" == "Ubuntu" && "$os_version" == "24.04" ]]; then
        echo "20"
    elif [[ "$erp_version" == "15" || "$erp_version" == "develop" ]]; then
        echo "18"
    else
        echo "16"
    fi
}

#
# â”€â”€â”€ PRE-FLIGHT CHECKS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
#

echo -e "\n${BLUE}â•â•â• Pre-flight Checks â•â•â•${NC}\n"

log_info "Checking system requirements..."

# Disk space
available_disk=$(df / | awk 'NR==2 {print int($4/1024/1024)}')
if [ "$available_disk" -lt "$MINIMUM_DISK_SPACE" ]; then
    log_error "WARNING: Very low disk space! Required: ${MINIMUM_DISK_SPACE}GB, Available: ${available_disk}GB"
    if ! confirm "Continue anyway (Not recommended)"; then
        exit 1
    fi
elif [ "$available_disk" -lt "$RECOMMENDED_DISK_SPACE" ]; then
    log_warn "Disk space below recommended (Recommended: ${RECOMMENDED_DISK_SPACE}GB, Available: ${available_disk}GB)"
else
    log_success "Disk space: ${available_disk}GB"
fi

# RAM
available_memory=$(free -g | awk 'NR==2 {print $7}')
if [ "$available_memory" -lt "$MIN_MEMORY" ]; then
    log_warn "Low memory: ${available_memory}GB (Recommended: ${MIN_MEMORY}GB)"
else
    log_success "Memory: ${available_memory}GB"
fi

# Internet
if ! ping -c 1 8.8.8.8 &> /dev/null; then
    log_error "No internet connectivity detected"
    exit 1
fi
log_success "Internet connectivity verified"

# OS Check
if ! command -v lsb_release &> /dev/null; then
    sudo apt update && sudo apt install -y lsb-release
fi

os_name=$(lsb_release -is)
os_version=$(lsb_release -rs)
log_info "Detected OS: $os_name $os_version"

# Check existing installations
if [ -d "$HOME/frappe-bench" ] || [ -d "/home/*/frappe-bench" ]; then
    log_warn "Found existing frappe-bench installation"
    if ! confirm "Continue anyway? This may cause conflicts"; then
        exit 0
    fi
fi

log_success "Pre-flight checks completed"

#
# â”€â”€â”€ USER INPUT COLLECTION â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
#

echo -e "\n${BLUE}â•â•â• Installation Configuration â•â•â•${NC}\n"

# Username
while true; do
    read -p "Enter ERPNext username (e.g., frappe): " ERP_USER
    if [ -z "$ERP_USER" ]; then
        log_error "Username cannot be empty"
    else
        break
    fi
done
log_success "ERP User: $ERP_USER"

# Site name
while true; do
    read -p "Enter site name (e.g., site.local): " SITE_NAME
    if [ -z "$SITE_NAME" ]; then
        log_error "Site name cannot be empty"
    else
        break
    fi
done
log_success "Site: $SITE_NAME"

# Version
echo -e "\nSelect ERPNext Version:"
echo "  13 - Version 13 (LTS)"
echo "  14 - Version 14 (Stable)"
echo "  15 - Version 15 (Latest Stable) [RECOMMENDED]"
echo "  develop - Development Branch (âš ï¸  Unstable)"

while true; do
    read -p "Version (13/14/15/develop) [15]: " ERP_VERSION
    ERP_VERSION=${ERP_VERSION:-15}

    if [[ "$ERP_VERSION" =~ ^(13|14|15|develop)$ ]]; then
        break
    else
        log_error "Invalid version"
    fi
done

case "$ERP_VERSION" in
    13|14|15)
        BENCH_VERSION="version-$ERP_VERSION"
        ;;
    develop)
        BENCH_VERSION="develop"
        log_warn "Develop branch is unstable!"
        ;;
esac
log_success "Version: $ERP_VERSION"

# Production mode
echo ""
read -p "Install in Production mode? (Nginx + Supervisor) [Y/n]: " PROD_MODE
PROD_MODE=${PROD_MODE:-y}
PRODUCTION=$([[ "$PROD_MODE" =~ ^[Yy]$ ]] && echo "yes" || echo "no")

# Install ERPNext
read -p "Install ERPNext application? [Y/n]: " INSTALL_ERP
INSTALL_ERP=${INSTALL_ERP:-y}
INSTALL_ERPNEXT=$([[ "$INSTALL_ERP" =~ ^[Yy]$ ]] && echo "yes" || echo "no")

# Passwords
echo -e "\n${LIGHT_BLUE}â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•${NC}"
echo -e "${YELLOW}ðŸ”‘ SET PASSWORDS FOR INSTALLATION${NC}"
echo -e "${LIGHT_BLUE}â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•${NC}"

echo -e "\n${CYAN}ERPNext System User Password${NC}"
ERP_USER_PASS=$(ask_password "Enter password for '$ERP_USER'")

echo -e "\n${CYAN}MySQL Root Password${NC}"
MYSQL_PASS=$(ask_password "MySQL Root Password")

echo -e "\n${CYAN}ERPNext Administrator Password${NC}"
ADMIN_PASS=$(ask_password "Administrator Password")

# Summary
echo -e "\n${BLUE}â•â•â• Installation Summary â•â•â•${NC}"
echo -e "Site Name:        ${GREEN}$SITE_NAME${NC}"
echo -e "ERP User:         ${GREEN}$ERP_USER${NC}"
echo -e "ERPNext Version:  ${GREEN}$ERP_VERSION${NC}"
echo -e "Install ERPNext:  ${GREEN}$INSTALL_ERPNEXT${NC}"
echo -e "Production Mode:  ${GREEN}$PRODUCTION${NC}"
echo -e "Log File:         ${GREEN}$INSTALL_LOG${NC}"
echo ""

if ! confirm "Proceed with installation"; then
    log_info "Installation cancelled by user"
    exit 0
fi

#
# â”€â”€â”€ CREATE ERP USER â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
#

if id -u "$ERP_USER" >/dev/null 2>&1; then
    log_success "ERP user exists: $ERP_USER"
else
    log_info "Creating ERP user: $ERP_USER"
    sudo adduser --gecos "ERPNext System User" --disabled-password "$ERP_USER" 2>&1 | grep -v "Warning:" || true
    echo "$ERP_USER:$ERP_USER_PASS" | sudo chpasswd
    sudo usermod -aG sudo "$ERP_USER" || true
    echo "$ERP_USER ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/$ERP_USER > /dev/null
    sudo chmod 0440 /etc/sudoers.d/$ERP_USER
    log_success "âœ“ ERP user '$ERP_USER' created"
fi

ERP_HOME=$(getent passwd "$ERP_USER" | cut -d: -f6)
log_success "ERP Home: $ERP_HOME"

echo ""
log_info "Starting installation... This will take 15-45 minutes"
sleep 2

#
# â”€â”€â”€ INSTALLATION STEPS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
#

echo -e "\n${BLUE}â•â•â• [1/13] Updating System Packages â•â•â•${NC}"
sudo apt update
sudo apt upgrade -y
log_success "System updated"

echo -e "\n${BLUE}â•â•â• [2/13] Installing Base Packages â•â•â•${NC}"
sudo apt install -y \
    git curl wget \
    python3-dev python3-pip python3-venv python3-setuptools \
    redis-server \
    mariadb-server mariadb-client default-libmysqlclient-dev \
    software-properties-common \
    pkg-config \
    fontconfig libxrender1 xfonts-75dpi xfonts-base \
    certbot python3-certbot-nginx

if [[ "$PRODUCTION" == "yes" ]]; then
    sudo apt install -y nginx supervisor fail2ban
fi
log_success "Base packages installed"

echo -e "\n${BLUE}â•â•â• [3/13] Installing wkhtmltopdf â•â•â•${NC}"
arch=$(uname -m)
case $arch in
    x86_64) arch="amd64" ;;
    aarch64) arch="arm64" ;;
esac
WKHTMLTOX_URL="https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-2/wkhtmltox_0.12.6.1-2.jammy_${arch}.deb"
wget -q "$WKHTMLTOX_URL" -O wkhtmltox.deb
sudo dpkg -i wkhtmltox.deb || sudo apt --fix-broken install -y
sudo cp /usr/local/bin/wkhtmlto* /usr/bin/ || true
rm wkhtmltox.deb
log_success "wkhtmltopdf installed"

echo -e "\n${BLUE}â•â•â• [4/13] Configuring MariaDB â•â•â•${NC}"

# Create missing MySQL directories FIRST (required by mysql_install_db)
sudo mkdir -p /etc/mysql/conf.d
sudo mkdir -p /etc/mysql/mariadb.conf.d

# Stop MariaDB if running
sudo systemctl stop mariadb 2>/dev/null || true

# Remove corrupted data directory
sudo rm -rf /var/lib/mysql/*

# Reinitialize MariaDB system tables
sudo mysql_install_db --user=mysql --datadir=/var/lib/mysql

# Start MariaDB with fresh installation
sudo systemctl start mariadb
sleep 5

# Verify MariaDB started successfully
if ! sudo systemctl is-active --quiet mariadb; then
    log_error "MariaDB failed to start. Check: sudo journalctl -xeu mariadb"
    exit 1
fi

# Configure MariaDB root password
sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '$MYSQL_PASS';" || true
sudo mysql -u root -p"$MYSQL_PASS" -e "FLUSH PRIVILEGES;" || true

# Configure character set for UTF8MB4
if ! grep -q "character-set-server = utf8mb4" /etc/mysql/my.cnf 2>/dev/null; then
    sudo bash -c 'cat >> /etc/mysql/my.cnf << EOF

[mysqld]
character-set-client-handshake = FALSE
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci

[mysql]
default-character-set = utf8mb4
EOF'
    sudo systemctl restart mariadb
    sleep 2
fi
log_success "MariaDB configured"

echo -e "\n${BLUE}â•â•â• [5/13] Installing Node.js via NVM â•â•â•${NC}"
NODE_VERSION=$(get_node_version "$ERP_VERSION")
sudo -u "$ERP_USER" -H bash -lc '
if [ ! -d "$HOME/.nvm" ]; then
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
fi
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
nvm install '"$NODE_VERSION"'
nvm alias default '"$NODE_VERSION"'
nvm use default
npm install -g yarn@1.22.19
'
log_success "Node.js v$NODE_VERSION and Yarn installed"

echo -e "\n${BLUE}â•â•â• [6/13] Installing Frappe Bench â•â•â•${NC}"
if find /usr/lib/python3.*/EXTERNALLY-MANAGED 2>/dev/null | grep -q .; then
    sudo python3 -m pip config --global set global.break-system-packages true 2>/dev/null || true
fi
sudo pip3 install frappe-bench
log_success "Frappe Bench installed"

echo -e "\n${BLUE}â•â•â• [7/13] Initializing Bench â•â•â•${NC}"
sudo -u "$ERP_USER" -H bash -lc '
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
nvm use default
cd "$HOME"
bench init frappe-bench --frappe-branch '"$BENCH_VERSION"' --verbose
'
log_success "Bench initialized"

echo -e "\n${BLUE}â•â•â• [8/13] Creating Site â•â•â•${NC}"

# Ensure MariaDB is running before creating site
sudo systemctl start mariadb
sleep 5

# Verify MariaDB is accepting connections
until sudo mysqladmin ping -u root -p"$MYSQL_PASS" --silent 2>/dev/null; do
    echo "Waiting for MariaDB to be ready..."
    sleep 3
done

sudo -u "$ERP_USER" -H bash -lc '
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
nvm use default
cd "$HOME/frappe-bench"
bench new-site '"$SITE_NAME"' --db-root-username root --db-root-password '"$MYSQL_PASS"' --admin-password '"$ADMIN_PASS"'
'
log_success "Site created: $SITE_NAME"

if [[ "$INSTALL_ERPNEXT" == "yes" ]]; then
    echo -e "\n${BLUE}â•â•â• [9/13] Installing ERPNext â•â•â•${NC}"
    sudo -u "$ERP_USER" -H bash -lc '
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
    nvm use default
    cd "$HOME/frappe-bench"
    bench get-app erpnext --branch '"$BENCH_VERSION"'
    bench --site '"$SITE_NAME"' install-app erpnext
    '
    log_success "ERPNext installed"
else
    log_warn "Skipping ERPNext installation"
fi

if [[ "$PRODUCTION" == "yes" ]]; then
    echo -e "\n${BLUE}â•â•â• [10/13] Production Setup â•â•â•${NC}"

    pkill -f "bench start" 2>/dev/null || true
    pkill -f "honcho" 2>/dev/null || true
    for port in 11000 12000 13000; do
        lsof -ti:$port 2>/dev/null | xargs kill -9 2>/dev/null || true
    done

    python_version=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
    playbook_file="/usr/local/lib/python${python_version}/dist-packages/bench/playbooks/roles/mariadb/tasks/main.yml"
    if [ -f "$playbook_file" ]; then
        sudo sed -i 's/- include: /- include_tasks: /g' "$playbook_file" 2>/dev/null || true
    fi

    # Run production setup from bench directory
    cd "$ERP_HOME/frappe-bench"
    yes | sudo bench setup production "$ERP_USER"

    if ! grep -q "chown=$ERP_USER:$ERP_USER" /etc/supervisor/supervisord.conf 2>/dev/null; then
        sudo sed -i "5a chown=$ERP_USER:$ERP_USER" /etc/supervisor/supervisord.conf
    fi

    sudo systemctl restart supervisor

    sudo -u "$ERP_USER" -H bash -lc '
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
    nvm use default
    cd "$HOME/frappe-bench"
    bench --site '"$SITE_NAME"' scheduler enable
    bench --site '"$SITE_NAME"' scheduler resume
    '

    if [[ "$ERP_VERSION" == "15" || "$ERP_VERSION" == "develop" ]]; then
        sudo -u "$ERP_USER" -H bash -lc '
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
        nvm use default
        cd "$HOME/frappe-bench"
        bench setup socketio
        yes | bench setup supervisor
        bench setup redis
        '
        sudo supervisorctl reload
    fi

    sudo chmod 755 "$ERP_HOME"
    sudo supervisorctl restart all

    log_success "Production setup complete"
else
    log_warn "Skipping production setup"
fi

echo -e "\n${BLUE}â•â•â• [11/13] Performance Optimization â•â•â•${NC}"
sudo mysql -e "SET GLOBAL innodb_buffer_pool_size = $(free | awk 'NR==2{printf "%.0f", $2 * 1024 * 0.5}');" 2>/dev/null || true
sudo sysctl -w net.core.somaxconn=65535 2>/dev/null || true
sudo sysctl -w vm.overcommit_memory=1 2>/dev/null || true
log_success "Performance optimizations applied"

echo -e "\n${BLUE}â•â•â• [12/13] Security Hardening â•â•â•${NC}"
if command -v ufw &> /dev/null; then
    sudo ufw allow 22/tcp
    sudo ufw allow 80/tcp
    sudo ufw allow 443/tcp
    sudo ufw --force enable
    log_success "Firewall configured"
fi

if ! command -v fail2ban-client &> /dev/null; then
    sudo apt install -y fail2ban
fi
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
log_success "Fail2ban enabled"

echo -e "\n${BLUE}â•â•â• [13/13] Post-Installation Setup â•â•â•${NC}"
log_success "Installation completed"

#
# â”€â”€â”€ INSTALLATION COMPLETE â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
#

echo ""
echo -e "${GREEN}â•”â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•—${NC}"
echo -e "${GREEN}â•‘                                                                        â•‘${NC}"
echo -e "${GREEN}â•‘              âœ… INSTALLATION COMPLETED SUCCESSFULLY! âœ…               â•‘${NC}"
echo -e "${GREEN}â•‘                                                                        â•‘${NC}"
echo -e "${GREEN}â•šâ•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•${NC}"
echo ""

log_success "Installation completed successfully!"
log_info "Installation Log: $INSTALL_LOG"

echo -e "${GREEN}â•â•â• Access Information â•â•â•${NC}"
echo ""

if [[ "$PRODUCTION" == "yes" ]]; then
    echo -e "${CYAN}URL:${NC}              http://$(hostname -I | awk '{print $1}')"
    echo -e "${CYAN}                      or http://$SITE_NAME${NC}"
else
    echo -e "${CYAN}Development:${NC}      cd $ERP_HOME/frappe-bench && bench start"
    echo -e "${CYAN}Then visit:${NC}       http://localhost:8000"
fi

echo -e "${CYAN}Username:${NC}         Administrator"
echo -e "${CYAN}Password:${NC}         ${GREEN}[The admin password you set]${NC}"
echo -e "${CYAN}System User:${NC}      $ERP_USER"
echo -e "${CYAN}Home Directory:${NC}   $ERP_HOME"
echo ""

echo -e "${GREEN}â•â•â• Important Commands â•â•â•${NC}"
echo ""
echo "Check services:"
echo -e "   ${YELLOW}sudo supervisorctl status${NC}"
echo ""
echo "Restart services:"
echo -e "   ${YELLOW}sudo supervisorctl restart all${NC}"
echo ""
echo "View logs:"
echo -e "   ${YELLOW}tail -f $INSTALL_LOG${NC}"
echo ""

echo -e "${BLUE}â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•${NC}"
echo -e "${GREEN}Thank you for using ERPNext Installer v2.0!${NC}"
echo -e "${BLUE}â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•${NC}"
echo ""

echo -e "${CYAN}â•â•â• Support & Contact â•â•â•${NC}"
echo -e "${YELLOW}Developer:${NC}  Umair Wali"
echo -e "${YELLOW}Mobile:${NC}     +92 308 2614004"
echo -e "${YELLOW}Log File:${NC}   $INSTALL_LOG"
echo ""

log_success "All done! Your ERPNext installation is ready."
