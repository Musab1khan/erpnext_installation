# ☁️ Cloud Deployment Guide

**ERPNext Web Installer ko Cloud Server pe Deploy karna**

Developer: **Umair Wali** | Contact: **+92 308 2614004**

---

## 🌐 Cloud Server Types

### Popular Cloud Providers
- ✅ **DigitalOcean** - $6/month (Recommended)
- ✅ **AWS EC2** - $5-10/month
- ✅ **Google Cloud** - Free tier available
- ✅ **Vultr** - $6/month
- ✅ **Linode** - $5/month
- ✅ **Azure** - Free tier available

---

## 📋 Server Requirements

| Resource | Minimum | Recommended |
|----------|---------|-------------|
| **RAM** | 2GB | 4GB |
| **CPU** | 1 vCore | 2 vCores |
| **Disk** | 25GB | 50GB SSD |
| **OS** | Ubuntu 20.04/22.04 | Ubuntu 22.04 |
| **Network** | 1TB transfer | 2TB transfer |

---

## 🚀 Quick Deployment Steps

### Step 1: Create Cloud Server

**DigitalOcean Example:**
```bash
1. DigitalOcean.com pe account banao
2. Create → Droplets
3. Choose: Ubuntu 22.04 LTS
4. Plan: Basic ($6/month - 1GB RAM)
5. Region: Singapore/India (nearest)
6. SSH Key add karo (ya password)
7. Create Droplet
8. IP address note karo (e.g., 167.99.123.45)
```

### Step 2: Connect to Server

**Windows (PuTTY):**
```
1. PuTTY download karo
2. Host Name: YOUR_SERVER_IP
3. Port: 22
4. Connection Type: SSH
5. Open
6. Login: root
7. Password: (email mein aaya hoga)
```

**Mac/Linux Terminal:**
```bash
ssh root@YOUR_SERVER_IP
# Password enter karein
```

### Step 3: Upload Files to Server

**Method 1: Git Clone (Recommended)**
```bash
# Server pe run karein:
cd /root
git clone https://github.com/Musab1khan/erpnext_installation.git
cd erpnext_installation
chmod +x start_web_gui.sh
```

**Method 2: SCP (Direct Upload)**
```bash
# Local computer se:
scp -r /home/jtq/erpnext_installation root@YOUR_SERVER_IP:/root/
```

**Method 3: WinSCP (Windows)**
```
1. WinSCP download karo
2. Host: YOUR_SERVER_IP
3. Username: root
4. Password: YOUR_PASSWORD
5. Files drag & drop karo
```

### Step 4: Run Installer on Server

```bash
# Server pe SSH karke:
cd /root/erpnext_installation

# Web GUI start karo:
./start_web_gui.sh
```

### Step 5: Access from Anywhere

```bash
# Browser mein (kisi bhi computer/mobile se):
http://YOUR_SERVER_IP:5000

# Example:
http://167.99.123.45:5000
```

---

## 🔐 Security Setup (Important!)

### 1. Firewall Configuration

```bash
# Server pe run karein:
sudo ufw allow 22        # SSH
sudo ufw allow 80        # HTTP
sudo ufw allow 443       # HTTPS
sudo ufw allow 5000      # Web Installer
sudo ufw enable

# Check status:
sudo ufw status
```

### 2. Change Default Port (Optional)

```bash
# web_installer.py edit karo:
nano web_installer.py

# Line 1024 dhundo:
app.run(host='0.0.0.0', port=5000, debug=False, threaded=True)

# Change to:
app.run(host='0.0.0.0', port=8080, debug=False, threaded=True)

# Firewall mein bhi change karo:
sudo ufw allow 8080
sudo ufw delete allow 5000
```

### 3. Setup Domain (Optional)

```bash
# DNS settings (Cloudflare/Namecheap):
A Record: installer.yourdomain.com → YOUR_SERVER_IP

# Access karo:
http://installer.yourdomain.com:5000
```

---

## 🌍 Complete Cloud Deployment Example

### DigitalOcean Full Setup

```bash
# 1. Create Droplet (Ubuntu 22.04, 2GB RAM, $12/month)
# 2. SSH connect:
ssh root@167.99.123.45

# 3. Update system:
apt update && apt upgrade -y

# 4. Clone repository:
cd /root
git clone https://github.com/Musab1khan/erpnext_installation.git
cd erpnext_installation

# 5. Install Flask:
pip3 install flask

# 6. Setup firewall:
ufw allow 22,80,443,5000/tcp
ufw enable

# 7. Start web installer:
chmod +x start_web_gui.sh
./start_web_gui.sh

# Output:
# ======================================================================
# 🚀 ERPNext Web Installer v4.1
# ======================================================================
#
# 📱 Local Access:  http://localhost:5000
# 🌐 Remote Access: http://167.99.123.45:5000
#
# 💡 Share this URL with others: http://167.99.123.45:5000

# 8. Open in browser:
# http://167.99.123.45:5000

# 9. Install ERPNext!
```

---

## 📱 Client Access Scenarios

### Scenario 1: Your Client (Different Location)

```
Client Location: Karachi
Server Location: Singapore (DigitalOcean)

Steps:
1. Share URL: http://167.99.123.45:5000
2. Client opens in browser
3. Client fills form and installs
4. ERPNext installs on server
5. Client accesses ERPNext at: http://167.99.123.45

✅ Works from anywhere!
```

### Scenario 2: Multiple Clients

```
Server: 167.99.123.45

Client 1 (Lahore):     http://167.99.123.45:5000
Client 2 (Islamabad):  http://167.99.123.45:5000
Client 3 (Dubai):      http://167.99.123.45:5000

⚠️ Only one installation at a time!
```

### Scenario 3: Client's Own Server

```
Client has: AWS server (54.123.45.67)

Steps:
1. SSH into client's server: ssh ubuntu@54.123.45.67
2. Upload installer files
3. Run: ./start_web_gui.sh
4. Client accesses: http://54.123.45.67:5000
5. ERPNext installs on their server
```

---

## 🔒 Production Deployment (After ERPNext Install)

### 1. Stop Web Installer
```bash
# Press Ctrl+C to stop web installer
# Or:
pkill -f web_installer.py
```

### 2. Block Port 5000
```bash
sudo ufw delete allow 5000
```

### 3. Setup Nginx Reverse Proxy (Optional)
```bash
# Create nginx config:
sudo nano /etc/nginx/sites-available/installer

# Add:
server {
    listen 80;
    server_name installer.yourdomain.com;

    location / {
        proxy_pass http://localhost:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}

# Enable:
sudo ln -s /etc/nginx/sites-available/installer /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx

# Access:
http://installer.yourdomain.com (no port needed!)
```

---

## 🛠️ Troubleshooting Cloud Issues

### Port 5000 Blocked?
```bash
# Check firewall:
sudo ufw status

# Check if port is open:
sudo netstat -tulpn | grep 5000

# Test from outside:
telnet YOUR_SERVER_IP 5000
```

### Can't Connect from Outside?
```bash
# Check cloud provider firewall:
# DigitalOcean: Networking → Firewalls
# AWS: Security Groups
# Google Cloud: VPC Firewall

# Add rule:
Protocol: TCP
Port: 5000
Source: 0.0.0.0/0 (anywhere)
```

### Web Installer Not Starting?
```bash
# Check Flask:
python3 -c "import flask; print(flask.__version__)"

# Check Python:
python3 --version

# Reinstall Flask:
pip3 install --upgrade flask
```

### Server IP Not Detected?
```bash
# Manual check:
hostname -I
ip addr show

# Edit web_installer.py if needed:
# Line 27-36: get_server_ip() function
```

---

## 💰 Cost Estimation

### Option 1: DigitalOcean Droplet
```
Server: $6-12/month (1-2GB RAM)
Domain: $12/year (optional)
Total: ~$84/year
```

### Option 2: AWS EC2
```
Server: $5-10/month (t2.micro/t2.small)
Data Transfer: $1-5/month
Total: ~$96/year
```

### Option 3: Client's Existing Server
```
Cost: FREE (if they already have server)
Just install our tool!
```

---

## 📞 Support

### Need Help with Cloud Setup?

**Developer: Umair Wali**
- **Mobile**: +92 308 2614004
- **Services**:
  - Cloud server setup
  - Domain configuration
  - SSL certificate setup
  - Custom deployment

---

## ⚡ Quick Commands Reference

```bash
# Start installer:
./start_web_gui.sh

# Stop installer:
Ctrl+C
# or
pkill -f web_installer.py

# Check if running:
ps aux | grep web_installer

# View logs:
tail -f /tmp/erpnext*.log

# Restart after changes:
pkill -f web_installer && ./start_web_gui.sh
```

---

## 🎯 Best Practices

1. ✅ **Use 2GB+ RAM** - ERPNext needs memory
2. ✅ **Enable Firewall** - Security first
3. ✅ **Use SSH Keys** - More secure than passwords
4. ✅ **Regular Backups** - Cloud provider snapshots
5. ✅ **Monitor Resources** - Check RAM/CPU usage
6. ✅ **Update System** - `apt update && apt upgrade`
7. ✅ **Use Domain** - Better than IP address
8. ✅ **Setup SSL** - HTTPS for security

---

**Made with ❤️ by Umair Wali | +92 308 2614004**

**Happy Cloud Deployment! ☁️🚀**
