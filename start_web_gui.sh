#!/bin/bash

clear
echo "╔═══════════════════════════════════════════════╗"
echo "║   ERPNext Web Installer v4.1 - Launcher       ║"
echo "╚═══════════════════════════════════════════════╝"
echo ""

# Install Flask if not available
if ! python3 -c "import flask" 2>/dev/null; then
    echo "📦 Installing Flask (web framework)..."
    pip3 install flask || sudo pip3 install flask
    echo "✅ Flask installed!"
    echo ""
fi

echo "🚀 Starting web server..."
echo ""

# Run web installer
cd "$(dirname "$0")"
python3 web_installer.py
