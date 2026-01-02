# ERPNext Installation Toolkit

A comprehensive suite of installation, diagnostic, and management tools for ERPNext deployments with both **CLI** and **GUI** interfaces.

## 🎯 Features

### ✨ Graphical Interface (NEW!)
- 🖥️ **Modern GUI** - User-friendly graphical interface
- 📊 **Dashboard** - System overview and quick actions
- ⚙️ **Installation Wizard** - Step-by-step guided setup
- 🏥 **Doctor Tool** - Visual diagnostics with auto-fix
- 🗑️ **Uninstaller** - Safe removal with warnings
- 📋 **Log Viewer** - Real-time log monitoring

### 🛠️ Command-Line Tools
- 🔧 **Automated Installation** - One-command ERPNext setup
- 🏥 **Comprehensive Diagnostics** - 18+ system checks
- 🔄 **Auto-Fix** - Automatic problem resolution
- 🗑️ **Clean Uninstall** - Complete removal option

## 📦 Repository Contents

### Graphical Interface (GUI)
```
erpnext_gui.py      - Complete GUI application (Python/Tkinter)
launch_gui.sh       - GUI launcher with dependency checks
```

### Command-Line Tools (CLI)
```
doctor.sh           - Diagnostic & health-check script
install-hybrid.sh   - Main ERPNext installer
setup.sh            - Initial setup script
uninstall.sh        - Complete uninstaller
```

## 🚀 Quick Start

### Option 1: Graphical Interface (Recommended for Beginners)

```bash
# Clone repository
git clone https://github.com/Musab1khan/erpnext_installation.git
cd erpnext_installation

# Make launcher executable
chmod +x launch_gui.sh

# Launch GUI
sudo ./launch_gui.sh
```

The GUI will:
- ✅ Auto-install dependencies (Python3, Tkinter)
- ✅ Provide visual installation wizard
- ✅ Show real-time progress
- ✅ Display colored diagnostic results

### Option 2: Command-Line Interface

```bash
# Clone repository
git clone https://github.com/Musab1khan/erpnext_installation.git
cd erpnext_installation

# Make scripts executable
chmod +x setup.sh install-hybrid.sh doctor.sh uninstall.sh

# Run setup
./setup.sh

# Install ERPNext
sudo ./install-hybrid.sh

# Run diagnostics
./doctor.sh

# Uninstall (if needed)
./uninstall.sh
```

## 📖 Usage Guide

### 🖥️ GUI Mode

#### Launch the GUI
```bash
sudo ./launch_gui.sh
```

#### GUI Features

**1. Dashboard Tab**
- View system information
- Quick access buttons for all tools
- Installation status overview

**2. Installer Tab**
- Configure installation settings:
  - ERPNext username
  - Site name
  - Version (13/14/15/develop)
  - Production mode option
- Set passwords securely
- Real-time installation output
- Progress monitoring

**3. Doctor Tab**
- Run comprehensive diagnostics
- View color-coded results:
  - ❌ Red = Errors
  - ⚠️ Yellow = Warnings
  - ✅ Green = Success
- Auto-fix detected issues
- Save diagnostic reports

**4. Uninstaller Tab**
- Safe uninstallation with warnings
- Option to keep/remove system packages
- Backup before uninstall
- Progress tracking

**5. Logs Tab**
- View installation logs
- Browse log files
- Real-time log updates

### 🖥️ CLI Mode

#### Install ERPNext
```bash
sudo ./install-hybrid.sh
```

Follow prompts for:
- Username (default: frappe)
- Site name (default: site.local)
- Version (13/14/15/develop)
- Passwords (user, MySQL, admin)
- Production mode (yes/no)

#### Run Diagnostics
```bash
./doctor.sh
```

Automatically checks and fixes:
- ✅ System packages
- ✅ Disk space
- ✅ Memory usage
- ✅ MariaDB status
- ✅ Redis cache
- ✅ Nginx configuration
- ✅ Supervisor processes
- ✅ Network ports
- ✅ File permissions
- ✅ SSL certificates
- ✅ Site accessibility
- ✅ Database health
- ✅ Backups
- ✅ And 18+ more checks!

#### Uninstall
```bash
./uninstall.sh
```

Removes:
- All bench directories
- All databases
- Nginx configs
- Supervisor configs
- Optional: System packages

## 🔧 Prerequisites

### For GUI Mode
- **Python 3.6+** (auto-installed if missing)
- **python3-tk** (auto-installed if missing)
- **Linux with GUI** (Ubuntu/Debian Desktop)

### For CLI Mode
- **Supported OS:**
  - Ubuntu 24.04, 22.04, 20.04
  - Debian 12, 11
- **Minimum Requirements:**
  - 4GB RAM (8GB recommended)
  - 20GB disk space (50GB recommended)
  - Internet connection
  - Root/sudo access

## 📸 GUI Screenshots

### Dashboard
```
┌─────────────────────────────────────────┐
│  🚀 ERPNext Installation Toolkit        │
├─────────────────────────────────────────┤
│                                         │
│  [🔍 System Check]  [⚙️ Install]       │
│                                         │
│  [🏥 Run Doctor]    [🗑️ Uninstall]     │
│                                         │
│  System Information:                    │
│  OS: Ubuntu 24.04                       │
│  Disk: 45GB / 100GB                     │
│  Memory: 6GB / 16GB                     │
└─────────────────────────────────────────┘
```

### Installation Wizard
```
┌─────────────────────────────────────────┐
│  ERPNext Installation Wizard            │
├─────────────────────────────────────────┤
│  Username:     [frappe            ]     │
│  Site Name:    [site.local        ]     │
│  Version:      [15 ▼]                   │
│  □ Production Mode                      │
│  ☑ Install ERPNext                      │
│                                         │
│  Passwords:                             │
│  User:         [••••••••••]             │
│  MySQL:        [••••••••••]             │
│  Admin:        [••••••••••]             │
│                                         │
│  [🚀 Start Installation]                │
└─────────────────────────────────────────┘
```

## 🛡️ Safety Features

### GUI Safety
- ✅ Password confirmation dialogs
- ✅ Double confirmation for destructive actions
- ✅ Visual warnings for critical operations
- ✅ Progress indicators
- ✅ Error handling with user-friendly messages

### CLI Safety
- ✅ Pre-flight system checks
- ✅ Confirmation prompts
- ✅ Automatic backups
- ✅ Rollback capability
- ✅ Detailed logging

## 📊 Doctor Tool Features

### Automated Checks (18+)
1. System packages & dependencies
2. Disk space usage
3. Memory usage
4. MariaDB/MySQL status
5. Redis cache server
6. Nginx web server
7. Supervisor process manager
8. Network ports & conflicts
9. Bench configuration
10. File permissions
11. Python environment
12. Node.js environment
13. Comprehensive error detection
14. Scheduler status
15. SSL certificates (multi-site)
16. Site accessibility (multi-site)
17. Database health
18. Backup status
19. System resources & limits

### Auto-Fix Capabilities
- 🔧 Restart failed services
- 🔧 Fix file permissions
- 🔧 Clear caches
- 🔧 Rebuild assets
- 🔧 Run migrations
- 🔧 Renew SSL certificates
- 🔧 Kill leftover processes
- 🔧 Clean disk space

## 🎨 GUI vs CLI Comparison

| Feature | GUI | CLI |
|---------|-----|-----|
| **Ease of Use** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |
| **Visual Feedback** | ✅ Real-time | ✅ Text-based |
| **Error Messages** | ✅ User-friendly | ✅ Detailed |
| **Progress Tracking** | ✅ Visual bars | ✅ Text output |
| **Log Viewing** | ✅ Built-in viewer | ⚠️ External tools |
| **Automation** | ⚠️ Manual clicks | ✅ Scriptable |
| **Remote Access** | ⚠️ Requires X11 | ✅ SSH-friendly |
| **Beginner-Friendly** | ✅ Very | ⚠️ Moderate |

## 🔍 Troubleshooting

### GUI Issues

**GUI won't launch:**
```bash
# Install dependencies manually
sudo apt update
sudo apt install -y python3 python3-tk

# Check Python version
python3 --version  # Should be 3.6+

# Run directly
sudo python3 erpnext_gui.py
```

**"Display not found" error (SSH):**
```bash
# Enable X11 forwarding
ssh -X user@server
sudo ./launch_gui.sh

# OR use CLI mode instead
sudo ./install-hybrid.sh
```

### CLI Issues

**Installation fails:**
```bash
# Check logs
cat /tmp/erpnext_install_*.log

# Run doctor
./doctor.sh

# Check system requirements
df -h    # Disk space
free -h  # Memory
```

**Services not starting:**
```bash
# Run doctor with auto-fix
./doctor.sh

# Manual restart
sudo supervisorctl restart all
sudo systemctl restart nginx
```

## 📝 Configuration Examples

### Development Setup
```bash
# In GUI: Uncheck "Production Mode"
# OR in CLI:
Username: frappe
Site: dev.local
Version: develop
Production: no
```

### Production Setup
```bash
# In GUI: Check "Production Mode"
# OR in CLI:
Username: frappe
Site: erp.yourcompany.com
Version: 15
Production: yes
Install ERPNext: yes
```

## 🔐 Security Best Practices

1. **Use strong passwords** - Minimum 12 characters
2. **Enable firewall** - Only open required ports
3. **Regular backups** - Automated daily backups
4. **SSL certificates** - Use Let's Encrypt
5. **Keep updated** - Regular system updates
6. **Monitor logs** - Review logs regularly

## 📞 Support & Contact

### Developer Information
- **Name:** Umair Wali
- **Mobile:** +92 308 2614004
- **GitHub:** [Musab1khan](https://github.com/Musab1khan)

### Getting Help

**GUI Issues:**
1. Check the Logs tab in GUI
2. Use Help → Documentation
3. Contact developer

**CLI Issues:**
1. Review installation logs: `/tmp/erpnext_install_*.log`
2. Run `./doctor.sh` for diagnostics
3. Check `sites/*/logs/` for app logs

## 🎯 Common Use Cases

### First-time Installation (GUI)
1. Launch GUI: `sudo ./launch_gui.sh`
2. Go to Installer tab
3. Fill in configuration
4. Click "Start Installation"
5. Wait 15-45 minutes
6. Access ERPNext at shown URL

### Diagnosing Issues (GUI)
1. Launch GUI
2. Go to Doctor tab
3. Check "Automatically fix issues"
4. Click "Run Diagnostics"
5. Review color-coded results
6. Save report if needed

### Complete Removal (GUI)
1. Launch GUI
2. Go to Uninstaller tab
3. Read warnings
4. Check backup option
5. Confirm uninstall
6. Review output

## 🌟 Advantages of GUI Version

✅ **No command memorization** - Click and configure  
✅ **Visual progress** - See what's happening  
✅ **Error prevention** - Input validation  
✅ **Beginner-friendly** - No Linux expertise needed  
✅ **Log viewer** - Built-in log analysis  
✅ **Color-coded results** - Easy to understand  
✅ **Save reports** - Export diagnostics  
✅ **Multi-tasking** - Monitor while working  

## 📚 Additional Resources

- [ERPNext Documentation](https://docs.erpnext.com)
- [Frappe Framework Guide](https://frappeframework.com/docs)
- [ERPNext Forum](https://discuss.erpnext.com)

## 📄 License

This toolkit is provided as-is for ERPNext installation purposes. Use at your own risk.

## 🙏 Acknowledgments

Built for the ERPNext community to simplify installation and maintenance.

---

**Made with ❤️ by Umair Wali**  
*Empowering businesses with easy ERPNext deployment*
