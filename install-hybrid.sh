#!/usr/bin/env bash

#═══════════════════════════════════════════════════════════════════════════════
# ERPNext Hybrid Installer - Best of Both Worlds
# Combines simplicity of basic installer with robustness of full installer
# Version: 1.0
#═══════════════════════════════════════════════════════════════════════════════

#
# ─── ERROR HANDLING ────────────────────────────────────────────────────────────
#
handle_error() {
    local line=$1
    local exit_code=$?
    echo -e "\n${RED}❌ Error on line $line with exit status $exit_code${NC}"
    echo -e "${YELLOW}Installation failed. Please check the error above.${NC}"
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
CYAN='\033[0;36m'
NC='\033[0m' # No Color

#
# ─── CONSTANTS ─────────────────────────────────────────────────────────────────
#
SUPPORTED_DISTRIBUTIONS=("Ubuntu" "Debian")
SUPPORTED_UBUNTU_VERSIONS=("24.04" "22.04" "20.04")
SUPPORTED_DEBIAN_VERSIONS=("12" "11")

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
            echo -e "${GREEN}✓ Password confirmed${NC}" >&2
            echo "$val1"
            break
        else
            echo -e "${RED}✗ Passwords do not match. Please try again.${NC}\n" >&2
        fi
    done
}

# Check OS compatibility
check_os_compatibility() {
    if ! command -v lsb_release &> /dev/null; then
        echo -e "${RED}✗ lsb_release not found. Installing lsb-release...${NC}"
        sudo apt update && sudo apt install -y lsb-release
    fi

    local os_name=$(lsb_release -is)
    local os_version=$(lsb_release -rs)

    echo -e "${CYAN}Detected OS: $os_name $os_version${NC}"

    local os_supported=false
    local version_supported=false

    # Check distribution
    for dist in "${SUPPORTED_DISTRIBUTIONS[@]}"; do
        if [[ "$dist" = "$os_name" ]]; then
            os_supported=true
            break
        fi
    done

    # Check version
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
        echo -e "${RED}✗ Unsupported OS: $os_name $os_version${NC}"
        echo -e "${YELLOW}Supported: Ubuntu (20.04, 22.04, 24.04), Debian (11, 12)${NC}"
        exit 1
    fi

    echo -e "${GREEN}✓ OS compatibility verified${NC}\n"
}

# Check for existing installations
check_existing_installations() {
    echo -e "${CYAN}Checking for existing ERPNext installations...${NC}"

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
        echo -e "${YELLOW}⚠  Found existing installation(s):${NC}"
        for install_path in "${found_installations[@]}"; do
            echo -e "${YELLOW}   • $install_path${NC}"
        done
        echo ""
        read -p "Continue anyway? This may cause conflicts (y/N): " continue_confirm
        continue_confirm=$(echo "$continue_confirm" | tr '[:upper:]' '[:lower:]')

        if [[ "$continue_confirm" != "y" && "$continue_confirm" != "yes" ]]; then
            echo -e "${RED}Installation cancelled.${NC}"
            exit 0
        fi
    else
        echo -e "${GREEN}✓ No existing installations found${NC}\n"
    fi
}

# Validate version compatibility
validate_version() {
    local version="$1"
    local os_name=$(lsb_release -is)
    local os_version=$(lsb_release -rs)

    # v13/v14 not compatible with Ubuntu 24.04 or Debian 12
    if [[ "$version" == "13" || "$version" == "14" ]]; then
        if [[ "$os_name" == "Ubuntu" && "$os_version" == "24.04" ]]; then
            echo -e "${RED}✗ ERPNext v$version is not compatible with Ubuntu 24.04${NC}"
            echo -e "${YELLOW}  Please use ERPNext v15 or downgrade to Ubuntu 22.04${NC}"
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

#
# ─── MAIN INSTALLATION ─────────────────────────────────────────────────────────
#

clear
echo "╔═══════════════════════════════════════════════════════════════════╗"
echo "║                                                                   ║"
echo "║         🚀 ERPNext HYBRID INSTALLER v1.0 🚀                       ║"
echo "║                                                                   ║"
echo "║         Robust + Simple = Production Ready                        ║"
echo "║                                                                   ║"
echo "╚═══════════════════════════════════════════════════════════════════╝"
echo ""

#
# ─── PRE-FLIGHT CHECKS ─────────────────────────────────────────────────────────
#

echo -e "${BLUE}═══ Pre-flight Checks ═══${NC}\n"

check_os_compatibility
check_existing_installations

#
# ─── USER INPUT COLLECTION ────────────────────────────────────────────────────
#

echo -e "${BLUE}═══ Installation Configuration ═══${NC}\n"

# Site name
read -p "Site Name (e.g., erp.company.com): " SITE_NAME
while [[ -z "$SITE_NAME" ]]; do
    echo -e "${RED}✗ Site name cannot be empty${NC}"
    read -p "Site Name (e.g., erp.company.com): " SITE_NAME
done
echo -e "${GREEN}✓ Site: $SITE_NAME${NC}\n"

# ERPNext version
echo "Select ERPNext Version:"
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
        echo -e "${YELLOW}⚠️  WARNING: Develop branch is unstable and not for production!${NC}"
        read -p "Continue? (yes/no): " dev_confirm
        if [[ "$dev_confirm" != "yes" ]]; then
            echo -e "${RED}Installation cancelled.${NC}"
            exit 0
        fi
        BENCH_VERSION="develop"
        ;;
    *)
        echo -e "${RED}✗ Invalid version. Use 13, 14, 15, or develop${NC}"
        exit 1
        ;;
esac
echo -e "${GREEN}✓ Version: $ERP_VERSION${NC}\n"

# Passwords
echo -e "${CYAN}MySQL Root Password${NC}"
MYSQL_PASS=$(ask_password "MySQL Root Password")
echo ""

echo -e "${CYAN}ERPNext Administrator Password${NC}"
ADMIN_PASS=$(ask_password "Administrator Password")
echo ""

# Production setup
read -p "Install Production Setup (Nginx + Supervisor)? (y/N): " PRODUCTION
PRODUCTION=$(echo "$PRODUCTION" | tr '[:upper:]' '[:lower:]')
echo ""

# Additional apps
read -p "Install ERPNext? (Y/n): " INSTALL_ERPNEXT
INSTALL_ERPNEXT=$(echo "$INSTALL_ERPNEXT" | tr '[:upper:]' '[:lower:]')
if [[ "$INSTALL_ERPNEXT" != "n" && "$INSTALL_ERPNEXT" != "no" ]]; then
    INSTALL_ERPNEXT="yes"
fi
echo ""

# Summary
echo -e "${BLUE}═══ Installation Summary ═══${NC}"
echo -e "Site Name:        ${GREEN}$SITE_NAME${NC}"
echo -e "ERPNext Version:  ${GREEN}$ERP_VERSION${NC}"
echo -e "Install ERPNext:  ${GREEN}$INSTALL_ERPNEXT${NC}"
echo -e "Production Mode:  ${GREEN}$PRODUCTION${NC}"
echo ""
read -p "Proceed with installation? (Y/n): " CONFIRM
CONFIRM=$(echo "$CONFIRM" | tr '[:upper:]' '[:lower:]')

if [[ "$CONFIRM" == "n" || "$CONFIRM" == "no" ]]; then
    echo -e "${RED}Installation cancelled.${NC}"
    exit 0
fi

echo ""
echo -e "${GREEN}Starting installation... This will take 15-45 minutes.${NC}"
echo -e "${CYAN}You can safely leave this running.${NC}\n"
sleep 2

#
# ─── SYSTEM UPDATE ────────────────────────────────────────────────────────────
#

echo -e "${BLUE}═══ [1/10] Updating System Packages ═══${NC}"
sudo apt update
sudo apt upgrade -y
echo -e "${GREEN}✓ System updated${NC}\n"

#
# ─── INSTALL BASE PACKAGES ────────────────────────────────────────────────────
#

echo -e "${BLUE}═══ [2/10] Installing Base Packages ═══${NC}"
sudo apt install -y \
    git curl wget \
    python3-dev python3-pip python3-venv python3-setuptools \
    redis-server \
    mariadb-server mariadb-client default-libmysqlclient-dev \
    software-properties-common \
    pkg-config \
    fontconfig libxrender1 xfonts-75dpi xfonts-base

if [[ "$PRODUCTION" == "y" || "$PRODUCTION" == "yes" ]]; then
    sudo apt install -y nginx supervisor
fi

echo -e "${GREEN}✓ Base packages installed${NC}\n"

#
# ─── INSTALL WKHTMLTOPDF ──────────────────────────────────────────────────────
#

echo -e "${BLUE}═══ [3/10] Installing wkhtmltopdf ═══${NC}"
arch=$(uname -m)
case $arch in
    x86_64) arch="amd64" ;;
    aarch64) arch="arm64" ;;
    *) echo -e "${RED}Unsupported architecture: $arch${NC}"; exit 1 ;;
esac

WKHTMLTOX_URL="https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-2/wkhtmltox_0.12.6.1-2.jammy_${arch}.deb"

wget -q "$WKHTMLTOX_URL" -O wkhtmltox.deb
sudo dpkg -i wkhtmltox.deb || sudo apt --fix-broken install -y
sudo cp /usr/local/bin/wkhtmlto* /usr/bin/ || true
sudo chmod a+x /usr/bin/wk* || true
rm wkhtmltox.deb

echo -e "${GREEN}✓ wkhtmltopdf installed${NC}\n"

#
# ─── CONFIGURE MARIADB ────────────────────────────────────────────────────────
#

echo -e "${BLUE}═══ [4/10] Configuring MariaDB ═══${NC}"

# Set root password
sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '$MYSQL_PASS';" || true
sudo mysql -u root -p"$MYSQL_PASS" -e "DELETE FROM mysql.user WHERE User='';" || true
sudo mysql -u root -p"$MYSQL_PASS" -e "DROP DATABASE IF EXISTS test;" || true
sudo mysql -u root -p"$MYSQL_PASS" -e "FLUSH PRIVILEGES;" || true

# Configure UTF8MB4
if ! grep -q "character-set-server = utf8mb4" /etc/mysql/my.cnf; then
    sudo bash -c 'cat >> /etc/mysql/my.cnf << EOF

[mysqld]
character-set-client-handshake = FALSE
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci

[mysql]
default-character-set = utf8mb4
EOF'
    sudo systemctl restart mariadb
fi

echo -e "${GREEN}✓ MariaDB configured${NC}\n"

#
# ─── INSTALL NODE.JS VIA NVM ──────────────────────────────────────────────────
#

echo -e "${BLUE}═══ [5/10] Installing Node.js via NVM ═══${NC}"

# Install NVM
if [ ! -d "$HOME/.nvm" ]; then
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
fi

# Load NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Install appropriate Node version
NODE_VERSION=$(get_node_version "$ERP_VERSION")
nvm install "$NODE_VERSION"
nvm alias default "$NODE_VERSION"
nvm use default

# Install Yarn
npm install -g yarn@1.22.19

echo -e "${GREEN}✓ Node.js v$NODE_VERSION and Yarn installed${NC}\n"

#
# ─── INSTALL BENCH ────────────────────────────────────────────────────────────
#

echo -e "${BLUE}═══ [6/10] Installing Frappe Bench ═══${NC}"

# Handle externally-managed Python environments (PEP 668)
if find /usr/lib/python3.*/EXTERNALLY-MANAGED 2>/dev/null | grep -q .; then
    sudo python3 -m pip config --global set global.break-system-packages true 2>/dev/null || true
fi

sudo pip3 install frappe-bench

echo -e "${GREEN}✓ Frappe Bench installed${NC}\n"

#
# ─── INITIALIZE BENCH ─────────────────────────────────────────────────────────
#

echo -e "${BLUE}═══ [7/10] Initializing Bench ═══${NC}"

cd "$HOME"

# Ensure NVM is loaded
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm use default

bench init frappe-bench --frappe-branch "$BENCH_VERSION" --verbose

echo -e "${GREEN}✓ Bench initialized${NC}\n"

#
# ─── CREATE SITE ──────────────────────────────────────────────────────────────
#

echo -e "${BLUE}═══ [8/10] Creating Site ═══${NC}"

cd "$HOME/frappe-bench"

bench new-site "$SITE_NAME" \
    --db-root-username root \
    --db-root-password "$MYSQL_PASS" \
    --admin-password "$ADMIN_PASS"

echo -e "${GREEN}✓ Site created: $SITE_NAME${NC}\n"

#
# ─── INSTALL ERPNEXT ──────────────────────────────────────────────────────────
#

if [[ "$INSTALL_ERPNEXT" == "yes" ]]; then
    echo -e "${BLUE}═══ [9/10] Installing ERPNext ═══${NC}"

    bench get-app erpnext --branch "$BENCH_VERSION"
    bench --site "$SITE_NAME" install-app erpnext

    echo -e "${GREEN}✓ ERPNext installed${NC}\n"
else
    echo -e "${YELLOW}⊘ Skipping ERPNext installation${NC}\n"
fi

#
# ─── PRODUCTION SETUP ─────────────────────────────────────────────────────────
#

if [[ "$PRODUCTION" == "y" || "$PRODUCTION" == "yes" ]]; then
    echo -e "${BLUE}═══ [10/10] Production Setup ═══${NC}"

    # Kill any leftover bench processes before production setup
    echo -e "${YELLOW}Cleaning up any running bench processes...${NC}"

    # Stop bench gracefully if running
    pkill -f "bench start" 2>/dev/null || true
    pkill -f "honcho" 2>/dev/null || true

    # Kill leftover Redis processes from bench (ports 11000, 13000, 12000)
    for port in 11000 12000 13000; do
        if lsof -ti:$port &>/dev/null; then
            echo -e "${YELLOW}  • Killing process on port $port...${NC}"
            kill -9 $(lsof -ti:$port) 2>/dev/null || true
        fi
    done

    # Kill leftover Node.js processes
    pkill -f "node.*socketio" 2>/dev/null || true
    pkill -f "node.*frappe" 2>/dev/null || true

    # Wait for processes to die
    sleep 2

    echo -e "${GREEN}✓ Cleanup complete${NC}"

    # Fix Ansible playbook include syntax
    python_version=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
    playbook_file="/usr/local/lib/python${python_version}/dist-packages/bench/playbooks/roles/mariadb/tasks/main.yml"
    if [ -f "$playbook_file" ]; then
        sudo sed -i 's/- include: /- include_tasks: /g' "$playbook_file" 2>/dev/null || true
    fi

    # Setup production
    yes | sudo bench setup production "$(whoami)"

    # Fix supervisor permissions
    if ! grep -q "chown=$(whoami):$(whoami)" /etc/supervisor/supervisord.conf 2>/dev/null; then
        sudo sed -i "5a chown=$(whoami):$(whoami)" /etc/supervisor/supervisord.conf
    fi

    sudo systemctl restart supervisor

    # Enable scheduler
    bench --site "$SITE_NAME" scheduler enable
    bench --site "$SITE_NAME" scheduler resume

    # Version-specific configurations
    if [[ "$ERP_VERSION" == "15" || "$ERP_VERSION" == "develop" ]]; then
        bench setup socketio
        yes | bench setup supervisor
        bench setup redis
        sudo supervisorctl reload
    fi

    # Fix permissions
    sudo chmod 755 "$HOME"
    sudo supervisorctl restart all

    echo -e "${GREEN}✓ Production setup complete${NC}\n"
else
    echo -e "${YELLOW}⊘ Skipping production setup${NC}"
    echo -e "${CYAN}  To start development server: cd ~/frappe-bench && bench start${NC}\n"
fi

#
# ─── INSTALLATION COMPLETE ────────────────────────────────────────────────────
#

echo ""
echo "╔═══════════════════════════════════════════════════════════════════╗"
echo "║                                                                   ║"
echo "║              ✅ INSTALLATION COMPLETE! ✅                         ║"
echo "║                                                                   ║"
echo "╚═══════════════════════════════════════════════════════════════════╝"
echo ""
echo -e "${GREEN}═══ Access Information ═══${NC}"
echo ""

if [[ "$PRODUCTION" == "y" || "$PRODUCTION" == "yes" ]]; then
    echo -e "${CYAN}URL:${NC}              http://$SITE_NAME"
else
    echo -e "${CYAN}Development:${NC}      cd ~/frappe-bench && bench start"
    echo -e "${CYAN}Then visit:${NC}       http://localhost:8000"
fi

echo -e "${CYAN}Username:${NC}         Administrator"
echo -e "${CYAN}Password:${NC}         ${GREEN}[The admin password you set]${NC}"
echo ""
echo -e "${GREEN}═══ Next Steps ═══${NC}"
echo ""

if [[ "$PRODUCTION" != "y" && "$PRODUCTION" != "yes" ]]; then
    echo "1. Start the development server:"
    echo -e "   ${YELLOW}cd ~/frappe-bench${NC}"
    echo -e "   ${YELLOW}bench start${NC}"
    echo ""
fi

echo "2. Access your ERPNext instance and complete the setup wizard"
echo ""
echo "3. (Optional) Install additional apps:"
echo -e "   ${YELLOW}cd ~/frappe-bench${NC}"
echo -e "   ${YELLOW}bench get-app [app-name]${NC}"
echo -e "   ${YELLOW}bench --site $SITE_NAME install-app [app-name]${NC}"
echo ""
echo "4. (Optional) Enable SSL:"
echo -e "   ${YELLOW}sudo bench setup lets-encrypt $SITE_NAME${NC}"
echo ""

echo -e "${BLUE}═══════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Thank you for using ERPNext Hybrid Installer!${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${CYAN}═══ Need Help? Contact Support ═══${NC}"
echo -e "${YELLOW}Developer:${NC}  Umair Wali"
echo -e "${YELLOW}Mobile:${NC}     +92 308 2614004"
echo -e "${CYAN}If you face any issues, feel free to reach out!${NC}"
echo ""
