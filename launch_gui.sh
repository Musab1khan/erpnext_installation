#!/usr/bin/env bash

#═══════════════════════════════════════════════════════════════════════════════
# ERPNext GUI Launcher
# Simple script to launch the graphical interface
#═══════════════════════════════════════════════════════════════════════════════

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                                                                   ║${NC}"
echo -e "${BLUE}║         🚀 ERPNext Installation Toolkit - GUI Launcher 🚀        ║${NC}"
echo -e "${BLUE}║                                                                   ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if Python 3 is installed
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}❌ Python 3 is not installed!${NC}"
    echo -e "${YELLOW}Installing Python 3...${NC}"
    sudo apt update
    sudo apt install -y python3 python3-tk
fi

# Check if tkinter is available
python3 -c "import tkinter" 2>/dev/null
if [ $? -ne 0 ]; then
    echo -e "${YELLOW}⚠️  Tkinter not found. Installing...${NC}"
    sudo apt install -y python3-tk
fi

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if GUI script exists
if [ ! -f "$SCRIPT_DIR/erpnext_gui.py" ]; then
    echo -e "${RED}❌ erpnext_gui.py not found!${NC}"
    echo -e "${YELLOW}Please ensure erpnext_gui.py is in the same directory${NC}"
    exit 1
fi

# Make sure script is executable
chmod +x "$SCRIPT_DIR/erpnext_gui.py"

# Launch GUI
echo -e "${GREEN}✅ Launching GUI...${NC}"
echo ""

cd "$SCRIPT_DIR"

# Check if running with sudo (needed for installation features)
if [ "$EUID" -ne 0 ]; then
    echo -e "${YELLOW}⚠️  Note: Some features require root privileges${NC}"
    echo -e "${YELLOW}   Run with: sudo ./launch_gui.sh${NC}"
    echo ""
    echo -e "${BLUE}Starting GUI in limited mode...${NC}"
    python3 erpnext_gui.py
else
    python3 erpnext_gui.py
fi
