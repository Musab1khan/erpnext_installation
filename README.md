# ERPNext Installation Scripts

A collection of installation, setup, diagnostic, and uninstall scripts for ERPNext deployments.

## Repository Contents

* **doctor.sh** — Diagnostic / health-check script with extensive checks
* **install-hybrid.sh** — Main installer for a hybrid ERPNext setup
* **setup.sh** — Initial setup and prerequisites script
* **uninstall.sh** — Cleanup and uninstaller script

## Overview

This repository contains automated shell scripts to prepare servers, install ERPNext, verify system health, and perform full uninstallation. These scripts streamline deployment and maintenance for ERPNext environments.

## Prerequisites

* Supported Linux server (Debian/Ubuntu recommended)
* Root or sudo access
* Working internet connection for package repositories
* Basic familiarity with shell scripts and logs

## Quick Start

1. Clone the repository:

   ```bash
   git clone https://github.com/Musab1khan/erpnext_installation.git
   cd erpnext_installation
   ```

2. Make scripts executable:

   ```bash
   chmod +x setup.sh install-hybrid.sh doctor.sh uninstall.sh
   ```

3. Run initial setup:

   ```bash
   sudo ./setup.sh
   ```

4. Run the installer:

   ```bash
   sudo ./install-hybrid.sh
   ```

   * Follow on-screen instructions for any prompts.
   * For non-interactive installation, check script variables.

5. Verify the installation:

   ```bash
   sudo ./doctor.sh
   ```

6. Uninstall ERPNext:

   ```bash
   sudo ./uninstall.sh
   ```

   * Always take backups before uninstalling.

## Configuration & Customization

* Each script includes configuration variables at the top.
* Review scripts before running, especially for production environments.
* Ensure DNS, SSL, and firewall settings are properly configured.
* Backup databases and files before installation or removal.

## Safety Notes

* Always inspect scripts before executing with root privileges.
* Test on non‑production servers first.
* Backup important data (sites, databases, logs).

## Troubleshooting

* Use **doctor.sh** for diagnostics.
* Check system logs using `journalctl`.
* Review ERPNext logs inside `sites/*/logs`.
* For failures, share logs and error outputs when reporting issues.

## Contributing

* Submit PRs for improvements or additional scripts.
* Include clear descriptions and test notes.
* Add reproducible instructions for new automation features.

## File Guide

* **setup.sh** — System preparation
* **install-hybrid.sh** — Main installation workflow
* **doctor.sh** — Health-check utilities
* **uninstall.sh** — ERPNext removal and cleanup

## License

No license included. Add a LICENSE file to define reuse and contribution terms.
