# 🚀 ERPNext Complete Installer v4.1

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Python Version](https://img.shields.io/badge/python-3.6+-blue.svg)](https://www.python.org/downloads/)
[![Flask](https://img.shields.io/badge/flask-2.0+-green.svg)](https://flask.palletsprojects.com/)
[![ERPNext](https://img.shields.io/badge/ERPNext-v13%20|%20v14%20|%20v15-orange.svg)](https://erpnext.com/)

**Web-Based GUI Installation Toolkit with Cloud Support**

Developer: **Umair Wali** | Contact: **+92 308 2614004**

---

## 📖 Table of Contents
- [Features](#-features)
- [System Requirements](#-system-requirements)
- [Installation](#-installation)
- [Cloud Deployment](#️-cloudremote-installation)
- [Troubleshooting](#️-troubleshooting)
- [Support](#-support)

---

## ✨ Features

### 🎯 Main Features
- ✅ **Web-Based GUI** - No crashes, runs in browser!
- ✅ **3 Tabs** - Installer, Doctor, Uninstall all in one
- ✅ **Live Package Tracking** - Real-time checkmarks ✅ as packages install
- ✅ **Visual Progress Bar** - See installation progress live
- ✅ **Live Console** - Watch all installation logs in real-time
- ✅ **Remote Access** - Install from anywhere (Cloud/Local)
- ✅ **Beautiful UI** - Modern, professional interface

### 📦 What Gets Installed
- ERPNext (v13, v14, v15, or develop)
- MariaDB database + optimization
- Redis cache server
- Nginx web server (production)
- Supervisor process manager
- SSL support (certbot)
- Security (UFW + Fail2ban)
- wkhtmltopdf for PDF generation

---

## 💻 System Requirements

| Requirement | Minimum | Recommended |
|-------------|---------|-------------|
| **OS** | Ubuntu 20.04/22.04/24.04 | Ubuntu 22.04/24.04 |
| **RAM** | 2GB | 4GB |
| **Disk** | 15GB free | 25GB free |
| **CPU** | 2 cores | 4 cores |
| **Internet** | Required | Required |

---

## 📁 Files

```
erpnext_installation/
├── start_web_gui.sh              # Web GUI launcher (START HERE!)
├── web_installer.py              # Web-based installer (v4.1)
├── CLOUD_DEPLOYMENT.md           # Cloud deployment guide
├── install-hybrid.sh             # CLI installer (alternative)
├── doctor.sh                     # Diagnostic tool
├── uninstall.sh                  # Uninstaller
└── README.md                     # This file
```

---

## 🚀 Installation

### 🖥️ Local Installation (3 Steps)

#### Step 1: Clone Repository
```bash
git clone https://github.com/Musab1khan/erpnext_installation.git
cd erpnext_installation
chmod +x start_web_gui.sh
```

#### Step 2: Start Web Server
```bash
./start_web_gui.sh
```

#### Step 3: Open Browser
```
http://localhost:5000
```

#### Step 4: Use GUI Tabs
- **⚙️ Installer Tab**: Install ERPNext
- **🏥 Doctor Tab**: Run diagnostics
- **🗑️ Uninstall Tab**: Remove ERPNext

---

### ☁️ Cloud/Remote Installation

#### For Your Client's Cloud Server:

**Quick Steps:**
```bash
# 1. SSH to client's server:
ssh root@CLIENT_SERVER_IP

# 2. Clone installer:
git clone https://github.com/Musab1khan/erpnext_installation.git
cd erpnext_installation

# 3. Install Flask:
pip3 install flask

# 4. Start web GUI:
./start_web_gui.sh

# 5. Access from anywhere:
# http://CLIENT_SERVER_IP:5000
```

**📖 Detailed Guide**: See [CLOUD_DEPLOYMENT.md](CLOUD_DEPLOYMENT.md)

**Supported Providers:**
- ✅ DigitalOcean ($6/month)
- ✅ AWS EC2 ($5-10/month)
- ✅ Google Cloud (Free tier)
- ✅ Vultr, Linode, Azure

---

## 📊 Installation Progress

Installation mein ye 15 steps hain (live tracking):

1. ✅ **Step 1**: System Update
2. ✅ **Step 2**: Python & Dependencies
3. ✅ **Step 3**: MariaDB Database
4. ✅ **Step 4**: Redis Cache
5. ✅ **Step 5**: Nginx Web Server
6. ✅ **Step 6**: wkhtmltopdf
7. ✅ **Step 7**: Node.js & Yarn
8. ✅ **Step 8**: Frappe Bench
9. ✅ **Step 9**: Bench Initialization
10. ✅ **Step 10**: MariaDB Configuration
11. ✅ **Step 11**: Create Site
12. ✅ **Step 12**: Install ERPNext App
13. ✅ **Step 13**: Production Setup
14. ✅ **Step 14**: Security Setup
15. ✅ **Step 15**: Optimization

**Time**: 15-45 minutes

---

## 🌐 Access ERPNext

Installation complete hone ke baad:

### Production Mode
```
URL: http://YOUR_SERVER_IP
or:  http://YOUR_SITE_NAME

Username: Administrator
Password: [Your admin password]
```

### Development Mode
```bash
cd /home/frappe/frappe-bench
bench start

# Browser: http://localhost:8000
```

---

## 🛠️ Troubleshooting

### Web GUI Nahi Khul Raha?
```bash
# Flask install karein
sudo pip3 install flask

# Phir run karein
./start_web_gui.sh

# Browser mein open karein
# http://localhost:5000
```

### Port 5000 Already in Use?
```bash
# Port change karein web_installer.py mein
# Line 550: app.run(host='0.0.0.0', port=8080)
```

### Installation Fail?
1. Browser console output check karein
2. Internet check karein
3. Disk space: `df -h`
4. Memory: `free -h`

---

## 📝 Useful Commands

### Service Management
```bash
# Status check
sudo supervisorctl status

# Restart services
sudo supervisorctl restart all

# View logs
sudo supervisorctl tail -f frappe-bench-web:
```

### Bench Commands
```bash
# Bench directory
cd /home/frappe/frappe-bench

# Update ERPNext
bench update

# Backup
bench --site SITE_NAME backup

# List sites
bench --site all list

# Console
bench --site SITE_NAME console
```

### Diagnostic & Uninstall
```bash
# Run doctor
sudo bash doctor.sh

# Uninstall
sudo bash uninstall.sh
```

---

## 🔐 Security Tips

### Strong Passwords
- Minimum 8 characters
- Mix: Uppercase + lowercase + numbers + symbols
- Example: `MyErp@2024!Secure`

### Post-Installation
```bash
# Firewall
sudo ufw enable
sudo ufw allow 22,80,443/tcp

# SSL (production)
sudo bench setup lets-encrypt YOUR_SITE_NAME
```

---

## 📞 Support

### Developer
- **Name**: Umair Wali
- **Mobile**: +92 308 2614004

### Help
Contact with:
1. Error screenshot
2. Console output
3. System info (OS, RAM, disk)

---

## ⚡ Quick Reference

| Task | Command |
|------|---------|
| **Start GUI** | `./start_web_gui.sh` |
| **Check Services** | `sudo supervisorctl status` |
| **Restart** | `sudo supervisorctl restart all` |
| **Update** | `bench update` |
| **Backup** | `bench --site SITE backup` |
| **Diagnose** | `sudo bash doctor.sh` |
| **Uninstall** | `sudo bash uninstall.sh` |

---

**Made with ❤️ by Umair Wali | +92 308 2614004**
