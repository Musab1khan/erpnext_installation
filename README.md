# erpnext_installation

A collection of installation, setup, diagnostic and uninstall scripts for ERPNext deployments.

Repository contents
- doctor.sh — Diagnostic / health-check script (large script with many checks).
- install-hybrid.sh — Main installer for a hybrid installation (installer script).
- setup.sh — Initial setup / preparation script (prerequisites, user setup, dependencies).
- uninstall.sh — Uninstaller / cleanup script.

Overview
This repository bundles shell scripts intended to automate installation, setup and maintenance tasks for ERPNext environments. Use these scripts to prepare a server, run the installer, verify the installation, or fully remove it.

Prerequisites
- A supported Linux server (these scripts are typically written for Debian/Ubuntu-like systems). Check the scripts for explicit OS/version assumptions before running.
- Root or sudo access.
- Network access to required package repositories and ERPNext resources.
- At least a minimal familiarity with running shell scripts and reading script output/logs.

Quick start
1. Clone the repository:
   git clone https://github.com/Musab1khan/erpnext_installation.git
   cd erpnext_installation

2. Make scripts executable:
   chmod +x setup.sh install-hybrid.sh doctor.sh uninstall.sh

3. Run initial setup (prepares system, dependencies, users, etc.):
   sudo ./setup.sh

4. Run the installer:
   sudo ./install-hybrid.sh
   - The installer may prompt for input or require environment configuration; follow on-screen instructions.
   - If you need a non-interactive install, inspect the script for environment variables or flags that can be set.

5. Verify the installation:
   sudo ./doctor.sh
   - doctor.sh contains many checks — use it to diagnose common issues and confirm services are running.

6. Uninstall / cleanup:
   sudo ./uninstall.sh
   - Review the script before running to understand what it will remove. Backup data if needed.

Configuration and customization
- Each script contains configuration variables and comments near the top — open them in an editor and review before running.
- For production, make sure to:
  - Backup existing databases and files.
  - Review network/firewall requirements.
  - Configure proper DNS, SSL, and system limits as required by ERPNext.

Safety notes
- Always review scripts before execution, especially when running with sudo/root privileges.
- Test on a non-production system first.
- Back up important data (sites, databases, config) before installing or uninstalling.

Troubleshooting
- Use doctor.sh to gather diagnostic data.
- Check system journals (journalctl), webserver logs, and ERPNext logs (usually in sites/*/logs) for errors.
- If a step fails, copy the relevant error output and consult ERPNext community resources or open an issue with detailed logs.

Contributing
- If you improve scripts or add new helpers, please open a PR with a clear description and testing notes.
- Add tests or reproducible instructions for any new automation.

Where to look in this repo
- setup.sh — bootstrap tasks and prerequisites
- install-hybrid.sh — main installation workflow
- doctor.sh — verification and diagnostic helpers
- uninstall.sh — teardown and cleanup

License
- No license file included in the repository. Add a LICENSE file if you want to define reuse and contribution terms.
```
