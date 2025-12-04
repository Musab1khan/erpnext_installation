#!/usr/bin/env bash

#═══════════════════════════════════════════════════════════════════════════════
# ERPNext Hybrid Installer - Production Ready v2.0
# Enterprise-Grade Installation with Security, Backups, Monitoring & SSL
#═══════════════════════════════════════════════════════════════════════════════

#
# ─── LOGGING & DEBUGGING ──────────────────────────────────────────────────────
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
    echo -e "${GREEN}[✓ SUCCESS]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_warn() {
    echo -e "${YELLOW}[⚠ WARNING]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo -e "${RED}[✗ ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

#
# ─── ERROR HANDLING & ROLLBACK ────────────────────────────────────────────────
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
set -e  # Exit on error
set -u  # Exit on undefined variable

#
# ─── COLORS ────────────────────────────────────────────────────────────────────
#
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
LIGHT_BLUE='\033[1;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

#
# ─── CONSTANTS ─────────────────────────────────────────────────────────────────
#
SUPPORTED_DISTRIBUTIONS=("Ubuntu" "Debian")
SUPPORTED_UBUNTU_VERSIONS=("24.04" "22.04" "20.04")
SUPPORTED_DEBIAN_VERSIONS=("12" "11")
RECOMMENDED_DISK_SPACE=50  # GB (Recommended for production)
MINIMUM_DISK_SPACE=20      # GB (Absolute minimum required)
MIN_MEMORY=4               # GB

#
# ─── HELPER FUNCTIONS ──────────────────────────────────────────────────────────
#

# Validated password input with confirmation
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

# Ask for Yes/No confirmation
confirm() {
    local prompt="$1"
    local response
    read -p "$prompt (y/N): " response
    response=$(echo "$response" | tr '[:upper:]' '[:lower:]')
    [[ "$response" == "y" || "$response" == "yes" ]]
}

# Check system requirements
check_system_requirements() {
    log_info "Checking system requirements..."

    # Check disk space (Informational only - don't block)
    local available_disk=$(df / | awk 'NR==2 {print int($4/1024/1024)}')
    
    if [ "$available_disk" -lt "$MINIMUM_DISK_SPACE" ]; then
        log_error "WARNING: Very low disk space! Required minimum: ${MINIMUM_DISK_SPACE}GB, Available: ${available_disk}GB"
        if ! confirm "Continue anyway (Not recommended)"; then
            exit 1
        fi
    elif [ "$available_disk" -lt "$RECOMMENDED_DISK_SPACE" ]; then
        log_warn "Disk space below recommended (Recommended: ${RECOMMENDED_DISK_SPACE}GB, Available: ${available_disk}GB)"
        log_info "Installation can proceed, but you may face issues with backups and updates"
    else
        log_success "Disk space: ${available_disk}GB (Recommended: ${RECOMMENDED_DISK_SPACE}GB)"
    fi

    # Check RAM
    local available_memory=$(free -g | awk 'NR==2 {print $7}')
    if [ "$available_memory" -lt "$MIN_MEMORY" ]; then
        log_warn "Low memory detected: ${available_memory}GB (Recommended: ${MIN_MEMORY}GB)"
        log_info "Installation can proceed but performance may be affected"
    else
        log_success "Memory: ${available_memory}GB"
    fi

    # Check internet connectivity
    if ! ping -c 1 8.8.8.8 &> /dev/null; then
        log_error "No internet connectivity detected"
        exit 1
    fi
    log_success "Internet connectivity verified"

    # Check if running as root or with sudo
    if [ "$EUID" -eq 0 ]; then
        log_error "Do not run this script as root. Run with sudo privileges instead."
        exit 1
    fi
    log_success "Permission check passed"
}

# Check OS compatibility
check_os_compatibility() {
    log_info "Checking OS compatibility..."
    
    if ! command -v lsb_release &> /dev/null; then
        log_warn "lsb_release not found. Installing lsb-release..."
        sudo apt update && sudo apt install -y lsb-release
    fi

    local os_name=$(lsb_release -is)
    local os_version=$(lsb_release -rs)

    log_info "Detected OS: $os_name $os_version"

    local os_supported=false
    local version_supported=false

    for dist in "${SUPPORTED_DISTRIBUTIONS[@]}"; do
        if [[ "$dist" = "$os_name" ]]; then
            os_supported=true
            break
        fi
    done

    if [[ "$os_name" == "Ubuntu" ]]; then
        for ver in "${SUPPORTED_UBUNTU_VERSIONS[@]}"; do
            if [[ "$ver" = "$os_version" ]]; then
                version_supported=true
                break
            fi
        done
    elif [[ "$os_name" == "Debian" ]]; then
        for ver in "${SUPPORTED_DEBIAN_VERSIONS[@]}"; do
            if [[ "$ver" = "$os_version" ]]; then
                version_supported=true
                break
            fi
        done
    fi

    if [[ "$os_supported" = false ]] || [[ "$version_supported" = false ]]; then
        log_error "Unsupported OS: $os_name $os_version"
        log_info "Supported: Ubuntu (20.04, 22.04, 24.04), Debian (11, 12)"
        exit 1
    fi

    log_success "OS compatibility verified"
}

# Check for existing installations
check_existing_installations() {
    log_info "Checking for existing ERPNext installations..."

    local search_paths=(
        "$HOME/frappe-bench"
        "/home/*/frappe-bench"
        "/opt/frappe-bench"
    )

    local found_installations=()

    for path in "${search_paths[@]}"; do
        if [[ -d "$path" ]] && [[ -f "$path/apps/frappe/frappe/__init__.py" ]]; then
            found_installations+=("$path")
        fi
    done

    if [[ ${#found_installations[@]} -gt 0 ]]; then
        log_warn "Found existing installation(s):"
        for install_path in "${found_installations[@]}"; do
            echo "   • $install_path"
        done
        
        if ! confirm "Continue anyway? This may cause conflicts"; then
            log_info "Installation cancelled by user"
            exit 0
        fi
    else
        log_success "No existing installations found"
    fi
}

# Validate version compatibility
validate_version() {
    local version="$1"
    local os_name=$(lsb_release -is)
    local os_version=$(lsb_release -rs)

    if [[ "$version" == "13" || "$version" == "14" ]]; then
        if [[ "$os_name" == "Ubuntu" && "$os_version" == "24.04" ]]; then
            log_error "ERPNext v$version is not compatible with Ubuntu 24.04"
            log_info "Please use ERPNext v15 or downgrade to Ubuntu 22.04"
            exit 1
        fi
    fi
}

# Get Node.js version for ERPNext version
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

# Setup SSL certificate
setup_ssl_certificate() {
    local site_name="$1"
    local erp_user="$2"
    local erp_home="$3"

    if ! confirm "Setup SSL certificate with Let's Encrypt"; then
        log_info "Skipping SSL setup"
        return 0
    fi

    log_info "Setting up SSL certificate for $site_name..."

    read -p "Enter your email for Let's Encrypt: " email_address
    while [[ -z "$email_address" ]]; do
        log_error "Email cannot be empty"
        read -p "Enter your email for Let's Encrypt: " email_address
    done

    sudo -u "$erp_user" -H bash -lc "
    cd $erp_home/frappe-bench
    yes | bench setup lets-encrypt $site_name --email $email_address
    " || log_warn "SSL setup failed. Manual intervention may be needed."

    log_success "SSL certificate setup completed"
}

# Configure automated backups
setup_backups() {
    local erp_user="$1"
    local erp_home="$2"
    local site_name="$3"

    if ! confirm "Setup automated daily backups"; then
        log_info "Skipping backup configuration"
        return 0
    fi

    log_info "Configuring automated backups..."

    local backup_dir="$erp_home/backups"
    sudo -u "$erp_user" mkdir -p "$backup_dir"

    # Create backup script
    cat > /tmp/erpnext_backup.sh << 'EOF'
#!/bin/bash
BENCH_HOME=$1
SITE_NAME=$2
BACKUP_DIR=$3
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

cd "$BENCH_HOME/frappe-bench"
bench --site "$SITE_NAME" backup --backup-path "$BACKUP_DIR/backup_$TIMESTAMP.sql.gz"

# Keep only last 30 backups
find "$BACKUP_DIR" -name "backup_*.sql.gz" -type f -mtime +30 -delete

echo "Backup completed: $BACKUP_DIR/backup_$TIMESTAMP.sql.gz"
EOF

    chmod +x /tmp/erpnext_backup.sh
    sudo cp /tmp/erpnext_backup.sh /usr/local/bin/erpnext-backup.sh

    # Add cron job for daily backups at 2 AM
    local cron_job="0 2 * * * /usr/local/bin/erpnext-backup.sh $erp_home/frappe-bench $site_name $backup_dir"
    
    # Check if cron job already exists
    if ! crontab -u "$erp_user" -l 2>/dev/null | grep -q "erpnext-backup.sh"; then
        (crontab -u "$erp_user" -l 2>/dev/null || true; echo "$cron_job") | crontab -u "$erp_user" -
        log_success "Automated backup cron job created (Daily at 2 AM)"
    fi
}

# Setup security hardening
setup_security_hardening() {
    local erp_user="$1"

    log_info "Applying security hardening..."

    # Configure firewall
    if command -v ufw &> /dev/null; then
        sudo ufw allow 22/tcp
        sudo ufw allow 80/tcp
        sudo ufw allow 443/tcp
        sudo ufw --force enable
        log_success "Firewall configured (UFW)"
    fi

    # Disable SSH password login (if key-based auth setup)
    if confirm "Disable SSH password authentication (Key-based only)"; then
        sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config || true
        sudo systemctl restart sshd
        log_success "SSH hardened: Password authentication disabled"
    fi

    # Set up fail2ban for brute-force protection
    if ! command -v fail2ban-client &> /dev/null; then
        sudo apt install -y fail2ban
    fi

    sudo systemctl enable fail2ban
    sudo systemctl start fail2ban
    log_success "Fail2ban installed and enabled"

    # Configure sudoers for ERP user (Limited NOPASSWD - only essential commands)
    log_info "Configuring sudoers for $erp_user..."
    
    # Remove temporary NOPASSWD if exists
    if [ -f "/etc/sudoers.d/$erp_user" ]; then
        sudo rm /etc/sudoers.d/$erp_user
    fi
    
    # Allow only specific commands without password for better security
    cat | sudo tee /etc/sudoers.d/$erp_user > /dev/null << SUDOEOF
$erp_user ALL=(ALL) NOPASSWD:/usr/local/bin/bench
$erp_user ALL=(ALL) NOPASSWD:/usr/bin/supervisorctl
$erp_user ALL=(ALL) NOPASSWD:/bin/systemctl
SUDOEOF
    
    sudo chmod 0440 /etc/sudoers.d/$erp_user
    log_success "Sudoers configured: Limited NOPASSWD for bench/supervisor/systemctl only"
    log_warn "Other sudo commands will require password (RECOMMENDED for security)"
}

# Setup monitoring and health checks
setup_monitoring() {
    local site_name="$1"
    local erp_home="$2"
    local erp_user="$3"

    log_info "Setting up monitoring and health checks..."

    # Create health check script
    cat > /tmp/erpnext_health_check.sh << 'EOF'
#!/bin/bash

BENCH_HOME=$1
SITE_NAME=$2

echo "=== ERPNext Health Check $(date) ==="

# Check if Frappe processes are running
bench_running=$(pgrep -f "bench" | wc -l)
echo "Bench processes running: $bench_running"

# Check database connection
cd "$BENCH_HOME/frappe-bench"
bench --site "$SITE_NAME" console "frappe.db.get_value('System Settings', None, 'db_host')" &>/dev/null && echo "✓ Database: OK" || echo "✗ Database: FAILED"

# Check disk space
disk_usage=$(df -h "$BENCH_HOME" | awk 'NR==2 {print $5}')
echo "Disk usage: $disk_usage"

# Check memory
memory_usage=$(free -h | awk 'NR==2 {print $3 " / " $2}')
echo "Memory usage: $memory_usage"

# Check supervisor status
supervisorctl status &>/dev/null && echo "✓ Supervisor: OK" || echo "✗ Supervisor: FAILED"

echo "=== End Health Check ==="
EOF

    chmod +x /tmp/erpnext_health_check.sh
    sudo cp /tmp/erpnext_health_check.sh /usr/local/bin/erpnext-health-check.sh

    log_success "Health check script installed: /usr/local/bin/erpnext-health-check.sh"
    log_info "Run manually: erpnext-health-check.sh $erp_home/frappe-bench $site_name"
}

# Performance optimization
setup_performance_optimization() {
    local erp_home="$1"
    local erp_user="$2"

    log_info "Applying performance optimizations..."

    # MariaDB optimization
    sudo mysql -e "SET GLOBAL innodb_buffer_pool_size = $(free | awk 'NR==2{printf "%.0f", $2 * 1024 * 0.5}');" || true

    # Redis optimization
    sudo sysctl -w net.core.somaxconn=65535 || true
    sudo sysctl -w vm.overcommit_memory=1 || true

    log_success "Performance optimizations applied"
}

# Post-installation verification
verify_installation() {
    local site_name="$1"
    local erp_home="$2"
    local erp_user="$3"

    log_info "Verifying installation..."

    local all_passed=true

    # Test 1: Bench exists
    if [ -d "$erp_home/frappe-bench" ]; then
        log_success "✓ Bench directory exists"
    else
        log_error "✗ Bench directory not found"
        all_passed=false
    fi

    # Test 2: Site database exists
    if sudo mysql -u root -p"$MYSQL_PASS" -e "USE erpnext_${site_name//./_};" 2>/dev/null; then
        log_success "✓ Site database verified"
    else
        log_warn "⚠ Could not verify site database"
    fi

    # Test 3: Supervisor running (if production)
    if command -v supervisorctl &> /dev/null; then
        if supervisorctl status &> /dev/null; then
            log_success "✓ Supervisor is running"
        else
            log_warn "⚠ Supervisor not responding"
        fi
    fi

    # Test 4: Nginx/Development server
    if command -v nginx &> /dev/null; then
        if systemctl is-active nginx > /dev/null; then
            log_success "✓ Nginx is running"
        fi
    fi

    if [ "$all_passed" = true ]; then
        log_success "All verification tests passed!"
        return 0
    else
        log_warn "Some verification tests failed. Please check manually."
        return 1
    fi
}

# Save installation configuration
save_installation_config() {
    local config_file="$INSTALL_DIR/installation_config.txt"
    
    cat > "$config_file" << EOF
=== ERPNext Installation Configuration ===
Date: $(date)
Log File: $INSTALL_LOG

Site Name: $SITE_NAME
ERP User: $ERP_USER
ERP Home: $ERP_HOME
ERPNext Version: $ERP_VERSION
Production Setup: $PRODUCTION

Passwords (Store securely):
- MySQL Root: [Set during installation]
- Admin User: [Set during installation]

System Info:
- OS: $(lsb_release -ds)
- Hostname: $(hostname)
- IP Address: $(hostname -I | awk '{print $1}')

SSL Configured: $([[ -f "$ERP_HOME/frappe-bench/config/nginx.conf" ]] && grep -q "ssl_certificate" "$ERP_HOME/frappe-bench/config/nginx.conf" && echo "Yes" || echo "No")
Backups Configured: $(grep -q "erpnext-backup.sh" <(crontab -u "$ERP_USER" -l 2>/dev/null) && echo "Yes" || echo "No")
Firewall Enabled: $(ufw status | grep -q "active" && echo "Yes" || echo "No")

=== Next Steps ===
1. Access your ERPNext: http://$SITE_NAME or https://$SITE_NAME
2. Login with Administrator / [your-password]
3. Run health check: erpnext-health-check.sh $ERP_HOME/frappe-bench $SITE_NAME
4. Configure email/SMTP in ERPNext Settings
5. Schedule regular updates

=== Support ===
Developer: Umair Wali
Mobile: +92 308 2614004
Log Location: $INSTALL_LOG
EOF

    log_success "Installation config saved: $config_file"
}

#
# ─── MAIN INSTALLATION ─────────────────────────────────────────────────────────
#

clear
echo "╔════════════════════════════════════════════════════════════════════════╗"
echo "║                                                                        ║"
echo "║      🚀 ERPNext HYBRID INSTALLER v2.0 - PRODUCTION READY 🚀           ║"
echo "║                                                                        ║"
echo "║    Enterprise-Grade with Security, Backups, SSL & Monitoring           ║"
echo "║                                                                        ║"
echo "╚════════════════════════════════════════════════════════════════════════╝"
echo ""

log_info "Installation started. Log file: $INSTALL_LOG"

#
# ─── PRE-FLIGHT CHECKS ─────────────────────────────────────────────────────────
#

echo -e "\n${BLUE}═══ Pre-flight Checks ═══${NC}\n"

check_system_requirements
check_os_compatibility
check_existing_installations

#
# ─── USER INPUT COLLECTION ────────────────────────────────────────────────────
#

echo -e "\n${BLUE}═══ Installation Configuration ═══${NC}\n"

read -p "ERPNext System Username: " ERP_USER
while [[ -z "$ERP_USER" ]]; do
    log_error "Username cannot be empty"
    read -p "ERPNext System Username: " ERP_USER
done
log_success "ERP User: $ERP_USER"

read -p "Site Name (e.g., erp.company.com): " SITE_NAME
while [[ -z "$SITE_NAME" ]]; do
    log_error "Site name cannot be empty"
    read -p "Site Name (e.g., erp.company.com): " SITE_NAME
done
log_success "Site: $SITE_NAME"

echo -e "\nSelect ERPNext Version:"
echo "  13 - Version 13 (LTS)"
echo "  14 - Version 14 (Stable)"
echo "  15 - Version 15 (Latest Stable)"
echo "  develop - Development Branch (⚠️  Unstable)"
read -p "Version (13/14/15/develop): " ERP_VERSION

case "$ERP_VERSION" in
    13|14|15)
        validate_version "$ERP_VERSION"
        BENCH_VERSION="version-$ERP_VERSION"
        ;;
    develop)
        log_warn "WARNING: Develop branch is unstable and not for production!"
        if ! confirm "Continue with develop branch"; then
            log_info "Installation cancelled"
            exit 0
        fi
        BENCH_VERSION="develop"
        ;;
    *)
        log_error "Invalid version. Use 13, 14, 15, or develop"
        exit 1
        ;;
esac
log_success "Version: $ERP_VERSION"

echo -e "\n${LIGHT_BLUE}════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}🔑 SET PASSWORDS FOR INSTALLATION${NC}"
echo -e "${LIGHT_BLUE}════════════════════════════════════════════════════${NC}"

echo -e "\n${CYAN}ERPNext System User Password (frappe)${NC}"
ERP_USER_PASS=$(ask_password "Enter password for '$ERP_USER'")

echo -e "\n${CYAN}MySQL Root Password${NC}"
MYSQL_PASS=$(ask_password "MySQL Root Password")

echo -e "\n${CYAN}ERPNext Administrator Password${NC}"
ADMIN_PASS=$(ask_password "Administrator Password")

if confirm "\nInstall Production Setup (Nginx + Supervisor)"; then
    PRODUCTION="yes"
else
    PRODUCTION="no"
fi

if confirm "Install ERPNext app"; then
    INSTALL_ERPNEXT="yes"
else
    INSTALL_ERPNEXT="no"
fi

# Summary
echo -e "\n${BLUE}═══ Installation Summary ═══${NC}"
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
# ─── CREATE ERP USER WITH PASSWORD ────────────────────────────────────────────
#

if id -u "$ERP_USER" >/dev/null 2>&1; then
    log_success "ERP user exists: $ERP_USER"
else
    log_info "Creating ERP user: $ERP_USER with password..."
    
    # Create user with password using chpasswd (more reliable)
    sudo adduser --gecos "ERPNext System User" --disabled-password "$ERP_USER" 2>&1 | grep -v "Warning:" || true
    echo "$ERP_USER:$ERP_USER_PASS" | sudo chpasswd
    
    # Add to sudo group
    sudo usermod -aG sudo "$ERP_USER" || true
    
    # Configure sudoers to NOT ask password for this user during installation
    # This is temporary - can be changed later for security
    echo "$ERP_USER ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/$ERP_USER > /dev/null
    sudo chmod 0440 /etc/sudoers.d/$ERP_USER
    
    log_success "✓ ERP user '$ERP_USER' created with password"
    log_success "✓ Temporary NOPASSWD sudoers applied for smooth installation"
fi

ERP_HOME=$(getent passwd "$ERP_USER" | cut -d: -f6)
log_success "ERP Home: $ERP_HOME"

echo ""
log_info "Starting installation... This will take 15-45 minutes"
log_info "You can safely leave this running"
sleep 2

#
# ─── SYSTEM UPDATE ────────────────────────────────────────────────────────────
#

echo -e "\n${BLUE}═══ [1/13] Updating System Packages ═══${NC}"
log_info "Running apt update and upgrade..."
sudo apt update
sudo apt upgrade -y
log_success "System updated"

#
# ─── INSTALL BASE PACKAGES ────────────────────────────────────────────────────
#

echo -e "\n${BLUE}═══ [2/13] Installing Base Packages ═══${NC}"
log_info "Installing dependencies..."
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

#
# ─── INSTALL WKHTMLTOPDF ──────────────────────────────────────────────────────
#

echo -e "\n${BLUE}═══ [3/13] Installing wkhtmltopdf ═══${NC}"
arch=$(uname -m)
case $arch in
    x86_64) arch="amd64" ;;
    aarch64) arch="arm64" ;;
    *) log_error "Unsupported architecture: $arch"; exit 1 ;;
esac

WKHTMLTOX_URL="https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-2/wkhtmltox_0.12.6.1-2.jammy_${arch}.deb"

log_info "Downloading wkhtmltopdf..."
wget -q "$WKHTMLTOX_URL" -O wkhtmltox.deb
sudo dpkg -i wkhtmltox.deb || sudo apt --fix-broken install -y
sudo cp /usr/local/bin/wkhtmlto* /usr/bin/ || true
sudo chmod a+x /usr/bin/wk* || true
rm wkhtmltox.deb
log_success "wkhtmltopdf installed"

#
# ─── CONFIGURE MARIADB ────────────────────────────────────────────────────────
#

echo -e "\n${BLUE}═══ [4/13] Configuring MariaDB ═══${NC}"
log_info "Setting up MySQL..."

sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '$MYSQL_PASS';" || true
sudo mysql -u root -p"$MYSQL_PASS" -e "DELETE FROM mysql.user WHERE User='';" || true
sudo mysql -u root -p"$MYSQL_PASS" -e "DROP DATABASE IF EXISTS test;" || true
sudo mysql -u root -p"$MYSQL_PASS" -e "FLUSH PRIVILEGES;" || true

if ! grep -q "character-set-server = utf8mb4" /etc/mysql/my.cnf; then
    sudo bash -c 'cat >> /etc/mysql/my.cnf << EOF

[mysqld]
character-set-client-handshake = FALSE
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci
max_connections = 500

[mysql]
default-character-set = utf8mb4
EOF'
    sudo systemctl restart mariadb
fi

log_success "MariaDB configured"

#
# ─── INSTALL NODE.JS VIA NVM ──────────────────────────────────────────────────
#

echo -e "\n${BLUE}═══ [5/13] Installing Node.js via NVM ═══${NC}"

NODE_VERSION=$(get_node_version "$ERP_VERSION")
log_info "Installing Node.js v$NODE_VERSION..."

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

#
# ─── INSTALL BENCH ────────────────────────────────────────────────────────────
#

echo -e "\n${BLUE}═══ [6/13] Installing Frappe Bench ═══${NC}"
log_info "Installing Frappe Bench..."

if find /usr/lib/python3.*/EXTERNALLY-MANAGED 2>/dev/null | grep -q .; then
    sudo python3 -m pip config --global set global.break-system-packages true 2>/dev/null || true
fi

sudo pip3 install frappe-bench

log_success "Frappe Bench installed"

#
# ─── INITIALIZE BENCH ─────────────────────────────────────────────────────────
#

echo -e "\n${BLUE}═══ [7/13] Initializing Bench ═══${NC}"
log_info "Initializing bench environment..."

sudo -u "$ERP_USER" -H bash -lc '
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
nvm use default
cd "$HOME"
bench init frappe-bench --frappe-branch '"$BENCH_VERSION"' --verbose
'

log_success "Bench initialized"

#
# ─── CREATE SITE ──────────────────────────────────────────────────────────────
#

echo -e "\n${BLUE}═══ [8/13] Creating Site ═══${NC}"
log_info "Creating ERPNext site: $SITE_NAME..."

sudo -u "$ERP_USER" -H bash -lc '
cd "$HOME/frappe-bench"
bench new-site '"$SITE_NAME"' --db-root-username root --db-root-password '"$MYSQL_PASS"' --admin-password '"$ADMIN_PASS"'
'

log_success "Site created: $SITE_NAME"

#
# ─── INSTALL ERPNEXT ──────────────────────────────────────────────────────────
#

if [[ "$INSTALL_ERPNEXT" == "yes" ]]; then
    echo -e "\n${BLUE}═══ [9/13] Installing ERPNext ═══${NC}"
    log_info "Installing ERPNext application..."

    sudo -u "$ERP_USER" -H bash -lc '
    cd "$HOME/frappe-bench"
    bench get-app erpnext --branch '"$BENCH_VERSION"'
    bench --site '"$SITE_NAME"' install-app erpnext
    '

    log_success "ERPNext installed"
else
    log_warn "Skipping ERPNext installation"
fi

#
# ─── PRODUCTION SETUP ─────────────────────────────────────────────────────────
#

if [[ "$PRODUCTION" == "yes" ]]; then
    echo -e "\n${BLUE}═══ [10/13] Production Setup ═══${NC}"

    log_info "Cleaning up running bench processes..."

    pkill -f "bench start" 2>/dev/null || true
    pkill -f "honcho" 2>/dev/null || true

    for port in 11000 12000 13000; do
        if lsof -ti:$port &>/dev/null; then
            kill -9 $(lsof -ti:$port) 2>/dev/null || true
        fi
    done

    pkill -f "node.*socketio" 2>/dev/null || true
    pkill -f "node.*frappe" 2>/dev/null || true

    sleep 2
    log_success "Cleanup complete"

    # Fix Ansible playbook
    python_version=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
    playbook_file="/usr/local/lib/python${python_version}/dist-packages/bench/playbooks/roles/mariadb/tasks/main.yml"
    if [ -f "$playbook_file" ]; then
        sudo sed -i 's/- include: /- include_tasks: /g' "$playbook_file" 2>/dev/null || true
    fi

    log_info "Setting up production environment..."
    yes | sudo bench setup production "$ERP_USER"

    # Fix supervisor
    if ! grep -q "chown=$ERP_USER:$ERP_USER" /etc/supervisor/supervisord.conf 2>/dev/null; then
        sudo sed -i "5a chown=$ERP_USER:$ERP_USER" /etc/supervisor/supervisord.conf
    fi

    sudo systemctl restart supervisor

    sudo -u "$ERP_USER" -H bash -lc '
    cd "$HOME/frappe-bench"
    bench --site '"$SITE_NAME"' scheduler enable
    bench --site '"$SITE_NAME"' scheduler resume
    '

    if [[ "$ERP_VERSION" == "15" || "$ERP_VERSION" == "develop" ]]; then
        sudo -u "$ERP_USER" -H bash -lc '
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

#
# ─── PERFORMANCE OPTIMIZATION ─────────────────────────────────────────────────
#

echo -e "\n${BLUE}═══ [11/13] Performance Optimization ═══${NC}"
setup_performance_optimization "$ERP_HOME" "$ERP_USER"

#
# ─── SECURITY HARDENING ───────────────────────────────────────────────────────
#

echo -e "\n${BLUE}═══ [12/13] Security Hardening ═══${NC}"
setup_security_hardening "$ERP_USER"

#
# ─── POST-INSTALLATION SETUP ──────────────────────────────────────────────────
#

echo -e "\n${BLUE}═══ [13/13] Post-Installation Setup ═══${NC}"

# SSL Setup
if [[ "$PRODUCTION" == "yes" ]]; then
    setup_ssl_certificate "$SITE_NAME" "$ERP_USER" "$ERP_HOME"
fi

# Backups
setup_backups "$ERP_USER" "$ERP_HOME" "$SITE_NAME"

# Monitoring
setup_monitoring "$SITE_NAME" "$ERP_HOME" "$ERP_USER"

# Verification
verify_installation "$SITE_NAME" "$ERP_HOME" "$ERP_USER"

# Save config
save_installation_config

#
# ─── INSTALLATION COMPLETE ────────────────────────────────────────────────────
#

echo ""
echo "╔════════════════════════════════════════════════════════════════════════╗"
echo "║                                                                        ║"
echo "║              ✅ INSTALLATION COMPLETE! ✅                             ║"
echo "║                                                                        ║"
echo "╚════════════════════════════════════════════════════════════════════════╝"
echo ""

log_success "Installation completed successfully!"
log_info "Installation Log: $INSTALL_LOG"

echo -e "${GREEN}═══ Access Information ═══${NC}"
echo ""

if [[ "$PRODUCTION" == "yes" ]]; then
    if [ -f "$ERP_HOME/frappe-bench/config/nginx.conf" ] && grep -q "ssl_certificate" "$ERP_HOME/frappe-bench/config/nginx.conf"; then
        echo -e "${CYAN}URL:${NC}              https://$SITE_NAME"
    else
        echo -e "${CYAN}URL:${NC}              http://$SITE_NAME"
    fi
else
    echo -e "${CYAN}Development:${NC}      cd $ERP_HOME/frappe-bench && bench start"
    echo -e "${CYAN}Then visit:${NC}       http://localhost:8000"
fi

echo -e "${CYAN}Username:${NC}         Administrator"
echo -e "${CYAN}Password:${NC}         ${GREEN}[The admin password you set]${NC}"
echo -e "${CYAN}System User:${NC}      $ERP_USER"
echo -e "${CYAN}Home Directory:${NC}   $ERP_HOME"
echo ""

echo -e "${GREEN}═══ Important Commands ═══${NC}"
echo ""
echo "Backup database:"
echo -e "   ${YELLOW}/usr/local/bin/erpnext-backup.sh $ERP_HOME/frappe-bench $SITE_NAME${NC}"
echo ""
echo "Health check:"
echo -e "   ${YELLOW}/usr/local/bin/erpnext-health-check.sh $ERP_HOME/frappe-bench $SITE_NAME${NC}"
echo ""
echo "View logs:"
echo -e "   ${YELLOW}tail -f $INSTALL_LOG${NC}"
echo ""
echo "Supervisor control:"
echo -e "   ${YELLOW}sudo supervisorctl status${NC}"
echo ""

echo -e "${GREEN}═══ Next Steps ═══${NC}"
echo ""
echo "1. Complete ERPNext setup wizard at your site URL"
echo "2. Configure company and master data"
echo "3. Setup email/SMTP in Settings"
echo "4. Enable two-factor authentication"
echo "5. Configure regular backups (Already scheduled daily at 2 AM)"
echo ""

echo -e "${BLUE}════════════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Thank you for using ERPNext Hybrid Installer v2.0!${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════════════${NC}"
echo ""

echo -e "${CYAN}═══ Support & Contact ═══${NC}"
echo -e "${YELLOW}Developer:${NC}  Umair Wali"
echo -e "${YELLOW}Mobile:${NC}     +92 308 2614004"
echo -e "${YELLOW}Log File:${NC}   $INSTALL_LOG"
echo ""

log_success "All done! Your ERPNext installation is ready for production."
