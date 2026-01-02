#!/usr/bin/env python3
"""
ERPNext Installation Toolkit - GUI Version
A comprehensive graphical interface for ERPNext installation, diagnostics, and management
"""

import tkinter as tk
from tkinter import ttk, scrolledtext, messagebox, filedialog
import subprocess
import threading
import os
import sys
from datetime import datetime
import json
import re

class ERPNextGUI:
    def __init__(self, root):
        self.root = root
        self.root.title("ERPNext Installation Toolkit - GUI")
        self.root.geometry("1000x700")
        self.root.configure(bg='#f0f0f0')
        
        # Variables
        self.install_running = False
        self.doctor_running = False
        self.script_dir = os.path.dirname(os.path.abspath(__file__))
        
        # Setup UI
        self.setup_styles()
        self.create_menu()
        self.create_main_layout()
        
    def setup_styles(self):
        """Configure custom styles"""
        style = ttk.Style()
        style.theme_use('clam')
        
        # Custom button styles
        style.configure('Primary.TButton', 
                       background='#007bff', 
                       foreground='white',
                       font=('Arial', 10, 'bold'),
                       padding=10)
        
        style.configure('Success.TButton',
                       background='#28a745',
                       foreground='white',
                       font=('Arial', 10, 'bold'),
                       padding=10)
        
        style.configure('Danger.TButton',
                       background='#dc3545',
                       foreground='white',
                       font=('Arial', 10, 'bold'),
                       padding=10)
        
        style.configure('Warning.TButton',
                       background='#ffc107',
                       foreground='black',
                       font=('Arial', 10, 'bold'),
                       padding=10)
        
    def create_menu(self):
        """Create menu bar"""
        menubar = tk.Menu(self.root)
        self.root.config(menu=menubar)
        
        # File menu
        file_menu = tk.Menu(menubar, tearoff=0)
        menubar.add_cascade(label="File", menu=file_menu)
        file_menu.add_command(label="View Logs", command=self.show_logs)
        file_menu.add_command(label="Export Report", command=self.export_report)
        file_menu.add_separator()
        file_menu.add_command(label="Exit", command=self.root.quit)
        
        # Tools menu
        tools_menu = tk.Menu(menubar, tearoff=0)
        menubar.add_cascade(label="Tools", menu=tools_menu)
        tools_menu.add_command(label="System Check", command=self.show_system_check)
        tools_menu.add_command(label="Run Doctor", command=self.show_doctor)
        tools_menu.add_command(label="Installation Wizard", command=self.show_installer)
        
        # Help menu
        help_menu = tk.Menu(menubar, tearoff=0)
        menubar.add_cascade(label="Help", menu=help_menu)
        help_menu.add_command(label="Documentation", command=self.show_help)
        help_menu.add_command(label="About", command=self.show_about)
        
    def create_main_layout(self):
        """Create main application layout"""
        # Header
        header_frame = tk.Frame(self.root, bg='#007bff', height=80)
        header_frame.pack(fill=tk.X, side=tk.TOP)
        header_frame.pack_propagate(False)
        
        title_label = tk.Label(header_frame, 
                              text="🚀 ERPNext Installation Toolkit",
                              font=('Arial', 20, 'bold'),
                              bg='#007bff',
                              fg='white')
        title_label.pack(pady=20)
        
        # Main content area with notebook (tabs)
        self.notebook = ttk.Notebook(self.root)
        self.notebook.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        
        # Create tabs
        self.create_dashboard_tab()
        self.create_installer_tab()
        self.create_doctor_tab()
        self.create_uninstaller_tab()
        self.create_logs_tab()
        
        # Status bar
        self.status_bar = tk.Label(self.root, text="Ready", 
                                   bd=1, relief=tk.SUNKEN, anchor=tk.W)
        self.status_bar.pack(side=tk.BOTTOM, fill=tk.X)
        
    def create_dashboard_tab(self):
        """Create dashboard overview tab"""
        dashboard = ttk.Frame(self.notebook)
        self.notebook.add(dashboard, text="📊 Dashboard")
        
        # Title
        title = tk.Label(dashboard, text="Welcome to ERPNext Toolkit",
                        font=('Arial', 16, 'bold'))
        title.pack(pady=20)
        
        # Quick actions frame
        actions_frame = tk.LabelFrame(dashboard, text="Quick Actions",
                                     font=('Arial', 12, 'bold'),
                                     padx=20, pady=20)
        actions_frame.pack(fill=tk.BOTH, expand=True, padx=20, pady=10)
        
        # Grid layout for action buttons
        btn_frame = tk.Frame(actions_frame)
        btn_frame.pack(expand=True)
        
        # Row 1
        tk.Button(btn_frame, text="🔍 System Check",
                 command=self.show_system_check,
                 bg='#17a2b8', fg='white',
                 font=('Arial', 12, 'bold'),
                 width=20, height=3).grid(row=0, column=0, padx=10, pady=10)
        
        tk.Button(btn_frame, text="⚙️ Install ERPNext",
                 command=self.show_installer,
                 bg='#28a745', fg='white',
                 font=('Arial', 12, 'bold'),
                 width=20, height=3).grid(row=0, column=1, padx=10, pady=10)
        
        # Row 2
        tk.Button(btn_frame, text="🏥 Run Doctor",
                 command=self.show_doctor,
                 bg='#007bff', fg='white',
                 font=('Arial', 12, 'bold'),
                 width=20, height=3).grid(row=1, column=0, padx=10, pady=10)
        
        tk.Button(btn_frame, text="🗑️ Uninstall",
                 command=self.show_uninstaller,
                 bg='#dc3545', fg='white',
                 font=('Arial', 12, 'bold'),
                 width=20, height=3).grid(row=1, column=1, padx=10, pady=10)
        
        # System info
        info_frame = tk.LabelFrame(dashboard, text="System Information",
                                  font=('Arial', 11, 'bold'),
                                  padx=10, pady=10)
        info_frame.pack(fill=tk.X, padx=20, pady=10)
        
        self.sys_info_text = scrolledtext.ScrolledText(info_frame, height=8,
                                                       font=('Courier', 10))
        self.sys_info_text.pack(fill=tk.BOTH, expand=True)
        
        # Load system info
        self.load_system_info()
        
    def create_installer_tab(self):
        """Create installation wizard tab"""
        installer = ttk.Frame(self.notebook)
        self.notebook.add(installer, text="⚙️ Installer")
        
        # Scrollable frame
        canvas = tk.Canvas(installer)
        scrollbar = ttk.Scrollbar(installer, orient="vertical", command=canvas.yview)
        scrollable_frame = ttk.Frame(canvas)
        
        scrollable_frame.bind(
            "<Configure>",
            lambda e: canvas.configure(scrollregion=canvas.bbox("all"))
        )
        
        canvas.create_window((0, 0), window=scrollable_frame, anchor="nw")
        canvas.configure(yscrollcommand=scrollbar.set)
        
        # Title
        title = tk.Label(scrollable_frame, text="ERPNext Installation Wizard",
                        font=('Arial', 14, 'bold'))
        title.pack(pady=10)
        
        # Configuration frame
        config_frame = tk.LabelFrame(scrollable_frame, text="Installation Configuration",
                                    font=('Arial', 11, 'bold'), padx=20, pady=15)
        config_frame.pack(fill=tk.X, padx=20, pady=10)
        
        # ERP User
        tk.Label(config_frame, text="ERPNext Username:", font=('Arial', 10)).grid(row=0, column=0, sticky='w', pady=5)
        self.erp_user_var = tk.StringVar(value="frappe")
        tk.Entry(config_frame, textvariable=self.erp_user_var, width=30).grid(row=0, column=1, pady=5)
        
        # Site Name
        tk.Label(config_frame, text="Site Name:", font=('Arial', 10)).grid(row=1, column=0, sticky='w', pady=5)
        self.site_name_var = tk.StringVar(value="site.local")
        tk.Entry(config_frame, textvariable=self.site_name_var, width=30).grid(row=1, column=1, pady=5)
        
        # Version
        tk.Label(config_frame, text="ERPNext Version:", font=('Arial', 10)).grid(row=2, column=0, sticky='w', pady=5)
        self.version_var = tk.StringVar(value="15")
        version_combo = ttk.Combobox(config_frame, textvariable=self.version_var, 
                                     values=["13", "14", "15", "develop"], width=28)
        version_combo.grid(row=2, column=1, pady=5)
        
        # Production Mode
        self.prod_mode_var = tk.BooleanVar(value=True)
        tk.Checkbutton(config_frame, text="Install in Production Mode (Nginx + Supervisor)",
                      variable=self.prod_mode_var, font=('Arial', 10)).grid(row=3, column=0, columnspan=2, sticky='w', pady=5)
        
        # Install ERPNext
        self.install_erpnext_var = tk.BooleanVar(value=True)
        tk.Checkbutton(config_frame, text="Install ERPNext Application",
                      variable=self.install_erpnext_var, font=('Arial', 10)).grid(row=4, column=0, columnspan=2, sticky='w', pady=5)
        
        # Passwords frame
        pass_frame = tk.LabelFrame(scrollable_frame, text="Passwords",
                                  font=('Arial', 11, 'bold'), padx=20, pady=15)
        pass_frame.pack(fill=tk.X, padx=20, pady=10)
        
        # User Password
        tk.Label(pass_frame, text="System User Password:", font=('Arial', 10)).grid(row=0, column=0, sticky='w', pady=5)
        self.user_pass_var = tk.StringVar()
        tk.Entry(pass_frame, textvariable=self.user_pass_var, show='*', width=30).grid(row=0, column=1, pady=5)
        
        # MySQL Password
        tk.Label(pass_frame, text="MySQL Root Password:", font=('Arial', 10)).grid(row=1, column=0, sticky='w', pady=5)
        self.mysql_pass_var = tk.StringVar()
        tk.Entry(pass_frame, textvariable=self.mysql_pass_var, show='*', width=30).grid(row=1, column=1, pady=5)
        
        # Admin Password
        tk.Label(pass_frame, text="Administrator Password:", font=('Arial', 10)).grid(row=2, column=0, sticky='w', pady=5)
        self.admin_pass_var = tk.StringVar()
        tk.Entry(pass_frame, textvariable=self.admin_pass_var, show='*', width=30).grid(row=2, column=1, pady=5)
        
        # Output frame
        output_frame = tk.LabelFrame(scrollable_frame, text="Installation Output",
                                    font=('Arial', 11, 'bold'), padx=10, pady=10)
        output_frame.pack(fill=tk.BOTH, expand=True, padx=20, pady=10)
        
        self.install_output = scrolledtext.ScrolledText(output_frame, height=15,
                                                       font=('Courier', 9))
        self.install_output.pack(fill=tk.BOTH, expand=True)
        
        # Control buttons
        btn_frame = tk.Frame(scrollable_frame)
        btn_frame.pack(pady=10)
        
        self.install_btn = tk.Button(btn_frame, text="🚀 Start Installation",
                                     command=self.start_installation,
                                     bg='#28a745', fg='white',
                                     font=('Arial', 11, 'bold'),
                                     width=20, height=2)
        self.install_btn.pack(side=tk.LEFT, padx=5)
        
        tk.Button(btn_frame, text="⏹️ Stop",
                 command=self.stop_installation,
                 bg='#dc3545', fg='white',
                 font=('Arial', 11, 'bold'),
                 width=15, height=2).pack(side=tk.LEFT, padx=5)
        
        canvas.pack(side="left", fill="both", expand=True)
        scrollbar.pack(side="right", fill="y")
        
    def create_doctor_tab(self):
        """Create diagnostic tool tab"""
        doctor = ttk.Frame(self.notebook)
        self.notebook.add(doctor, text="🏥 Doctor")
        
        # Title
        title = tk.Label(doctor, text="ERPNext Doctor - Diagnostic Tool",
                        font=('Arial', 14, 'bold'))
        title.pack(pady=10)
        
        # Options frame
        options_frame = tk.LabelFrame(doctor, text="Diagnostic Options",
                                     font=('Arial', 11, 'bold'), padx=20, pady=15)
        options_frame.pack(fill=tk.X, padx=20, pady=10)
        
        self.auto_fix_var = tk.BooleanVar(value=True)
        tk.Checkbutton(options_frame, text="Automatically fix detected issues",
                      variable=self.auto_fix_var, font=('Arial', 10)).pack(anchor='w')
        
        self.detailed_check_var = tk.BooleanVar(value=True)
        tk.Checkbutton(options_frame, text="Perform detailed system checks",
                      variable=self.detailed_check_var, font=('Arial', 10)).pack(anchor='w')
        
        # Results frame
        results_frame = tk.LabelFrame(doctor, text="Diagnostic Results",
                                     font=('Arial', 11, 'bold'), padx=10, pady=10)
        results_frame.pack(fill=tk.BOTH, expand=True, padx=20, pady=10)
        
        self.doctor_output = scrolledtext.ScrolledText(results_frame, height=20,
                                                       font=('Courier', 9))
        self.doctor_output.pack(fill=tk.BOTH, expand=True)
        
        # Configure text tags for colored output
        self.doctor_output.tag_config("error", foreground="red")
        self.doctor_output.tag_config("warning", foreground="orange")
        self.doctor_output.tag_config("success", foreground="green")
        self.doctor_output.tag_config("info", foreground="blue")
        
        # Control buttons
        btn_frame = tk.Frame(doctor)
        btn_frame.pack(pady=10)
        
        self.doctor_btn = tk.Button(btn_frame, text="🔍 Run Diagnostics",
                                    command=self.run_doctor,
                                    bg='#007bff', fg='white',
                                    font=('Arial', 11, 'bold'),
                                    width=20, height=2)
        self.doctor_btn.pack(side=tk.LEFT, padx=5)
        
        tk.Button(btn_frame, text="💾 Save Report",
                 command=self.save_doctor_report,
                 bg='#17a2b8', fg='white',
                 font=('Arial', 11, 'bold'),
                 width=15, height=2).pack(side=tk.LEFT, padx=5)
        
    def create_uninstaller_tab(self):
        """Create uninstaller tab"""
        uninstaller = ttk.Frame(self.notebook)
        self.notebook.add(uninstaller, text="🗑️ Uninstaller")
        
        # Warning frame
        warning_frame = tk.Frame(uninstaller, bg='#fff3cd', bd=2, relief=tk.RAISED)
        warning_frame.pack(fill=tk.X, padx=20, pady=20)
        
        warning_label = tk.Label(warning_frame,
                                text="⚠️ WARNING: This will permanently delete ALL ERPNext data!\n"
                                     "Make sure you have backups before proceeding.",
                                bg='#fff3cd', fg='#856404',
                                font=('Arial', 11, 'bold'),
                                justify=tk.LEFT, padx=20, pady=15)
        warning_label.pack()
        
        # What will be removed
        info_frame = tk.LabelFrame(uninstaller, text="What Will Be Removed",
                                  font=('Arial', 11, 'bold'), padx=20, pady=15)
        info_frame.pack(fill=tk.X, padx=20, pady=10)
        
        items = [
            "✗ All ERPNext/Frappe bench directories",
            "✗ All databases and data",
            "✗ Nginx configurations",
            "✗ Supervisor configurations",
            "✗ Optional: MariaDB, Redis, Node.js"
        ]
        
        for item in items:
            tk.Label(info_frame, text=item, font=('Arial', 10),
                    fg='red', justify=tk.LEFT).pack(anchor='w', pady=2)
        
        # Options
        options_frame = tk.LabelFrame(uninstaller, text="Uninstall Options",
                                     font=('Arial', 11, 'bold'), padx=20, pady=15)
        options_frame.pack(fill=tk.X, padx=20, pady=10)
        
        self.remove_packages_var = tk.BooleanVar(value=False)
        tk.Checkbutton(options_frame, 
                      text="Also remove system packages (MariaDB, Redis, Nginx)",
                      variable=self.remove_packages_var,
                      font=('Arial', 10)).pack(anchor='w')
        
        self.backup_before_var = tk.BooleanVar(value=True)
        tk.Checkbutton(options_frame,
                      text="Create backup before uninstalling",
                      variable=self.backup_before_var,
                      font=('Arial', 10)).pack(anchor='w')
        
        # Output
        output_frame = tk.LabelFrame(uninstaller, text="Uninstall Output",
                                    font=('Arial', 11, 'bold'), padx=10, pady=10)
        output_frame.pack(fill=tk.BOTH, expand=True, padx=20, pady=10)
        
        self.uninstall_output = scrolledtext.ScrolledText(output_frame, height=12,
                                                         font=('Courier', 9))
        self.uninstall_output.pack(fill=tk.BOTH, expand=True)
        
        # Buttons
        btn_frame = tk.Frame(uninstaller)
        btn_frame.pack(pady=10)
        
        tk.Button(btn_frame, text="🗑️ Uninstall ERPNext",
                 command=self.confirm_uninstall,
                 bg='#dc3545', fg='white',
                 font=('Arial', 11, 'bold'),
                 width=20, height=2).pack()
        
    def create_logs_tab(self):
        """Create logs viewer tab"""
        logs = ttk.Frame(self.notebook)
        self.notebook.add(logs, text="📋 Logs")
        
        # Controls frame
        controls = tk.Frame(logs)
        controls.pack(fill=tk.X, padx=10, pady=10)
        
        tk.Label(controls, text="Log File:", font=('Arial', 10, 'bold')).pack(side=tk.LEFT, padx=5)
        
        self.log_file_var = tk.StringVar()
        log_entry = tk.Entry(controls, textvariable=self.log_file_var, width=60)
        log_entry.pack(side=tk.LEFT, padx=5)
        
        tk.Button(controls, text="Browse",
                 command=self.browse_log_file).pack(side=tk.LEFT, padx=5)
        
        tk.Button(controls, text="Reload",
                 command=self.load_log_file,
                 bg='#17a2b8', fg='white').pack(side=tk.LEFT, padx=5)
        
        # Log viewer
        log_frame = tk.LabelFrame(logs, text="Log Content",
                                 font=('Arial', 11, 'bold'), padx=10, pady=10)
        log_frame.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        
        self.log_text = scrolledtext.ScrolledText(log_frame, height=25,
                                                  font=('Courier', 9))
        self.log_text.pack(fill=tk.BOTH, expand=True)
        
        # Auto-load latest installation log
        self.find_latest_log()
        
    # ==========================
    # FUNCTIONALITY METHODS
    # ==========================
    
    def load_system_info(self):
        """Load and display system information"""
        try:
            info = []
            
            # OS Info
            os_info = subprocess.check_output(['lsb_release', '-ds'], 
                                            text=True).strip()
            info.append(f"Operating System: {os_info}")
            
            # Kernel
            kernel = subprocess.check_output(['uname', '-r'], text=True).strip()
            info.append(f"Kernel: {kernel}")
            
            # Python
            python_ver = subprocess.check_output([sys.executable, '--version'],
                                                text=True).strip()
            info.append(f"Python: {python_ver}")
            
            # Disk space
            df_output = subprocess.check_output(['df', '-h', '/'],
                                               text=True).strip().split('\n')[1]
            disk_info = ' '.join(df_output.split())
            info.append(f"Disk: {disk_info}")
            
            # Memory
            mem_output = subprocess.check_output(['free', '-h'],
                                                text=True).strip().split('\n')[1]
            mem_info = ' '.join(mem_output.split())
            info.append(f"Memory: {mem_info}")
            
            # Check if ERPNext is installed
            bench_dirs = self.find_bench_directories()
            if bench_dirs:
                info.append(f"\nERPNext Installed: Yes")
                info.append(f"Bench Directories: {len(bench_dirs)}")
                for bench_dir in bench_dirs:
                    info.append(f"  • {bench_dir}")
            else:
                info.append(f"\nERPNext Installed: No")
            
            self.sys_info_text.delete(1.0, tk.END)
            self.sys_info_text.insert(1.0, '\n'.join(info))
            
        except Exception as e:
            self.sys_info_text.insert(1.0, f"Error loading system info: {e}")
    
    def find_bench_directories(self):
        """Find all ERPNext bench installations"""
        bench_dirs = []
        
        common_paths = [
            os.path.expanduser("~/frappe-bench"),
            "/home/frappe/frappe-bench"
        ]
        
        for path in common_paths:
            if os.path.isdir(path):
                bench_dirs.append(path)
        
        return bench_dirs
    
    def start_installation(self):
        """Start ERPNext installation"""
        # Validate inputs
        if not self.erp_user_var.get():
            messagebox.showerror("Error", "ERPNext username is required")
            return
        
        if not self.site_name_var.get():
            messagebox.showerror("Error", "Site name is required")
            return
        
        if not all([self.user_pass_var.get(), self.mysql_pass_var.get(), 
                   self.admin_pass_var.get()]):
            messagebox.showerror("Error", "All passwords are required")
            return
        
        # Confirm installation
        if not messagebox.askyesno("Confirm Installation",
                                   "Start ERPNext installation?\n\n"
                                   "This will take 15-45 minutes."):
            return
        
        self.install_running = True
        self.install_btn.config(state='disabled')
        self.install_output.delete(1.0, tk.END)
        self.update_status("Installing ERPNext...")
        
        # Run installation in thread
        thread = threading.Thread(target=self.run_installation)
        thread.daemon = True
        thread.start()
    
    def run_installation(self):
        """Execute installation script"""
        try:
            script_path = os.path.join(self.script_dir, 'install-hybrid.sh')
            
            if not os.path.exists(script_path):
                self.append_output("ERROR: install-hybrid.sh not found!\n", "error")
                return
            
            # Prepare environment variables
            env = os.environ.copy()
            env['ERP_USER'] = self.erp_user_var.get()
            env['SITE_NAME'] = self.site_name_var.get()
            env['ERP_VERSION'] = self.version_var.get()
            env['ERP_USER_PASS'] = self.user_pass_var.get()
            env['MYSQL_PASS'] = self.mysql_pass_var.get()
            env['ADMIN_PASS'] = self.admin_pass_var.get()
            env['PRODUCTION'] = 'yes' if self.prod_mode_var.get() else 'no'
            env['INSTALL_ERPNEXT'] = 'yes' if self.install_erpnext_var.get() else 'no'
            
            # Run script
            process = subprocess.Popen(
                ['sudo', 'bash', script_path],
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
                env=env,
                bufsize=1
            )
            
            # Read output line by line
            for line in process.stdout:
                self.append_install_output(line)
            
            process.wait()
            
            if process.returncode == 0:
                self.append_install_output("\n✅ Installation completed successfully!\n", "success")
                self.update_status("Installation completed")
                messagebox.showinfo("Success", "ERPNext installed successfully!")
            else:
                self.append_install_output(f"\n❌ Installation failed with code {process.returncode}\n", "error")
                self.update_status("Installation failed")
                
        except Exception as e:
            self.append_install_output(f"\nERROR: {e}\n", "error")
        finally:
            self.install_running = False
            self.root.after(0, lambda: self.install_btn.config(state='normal'))
    
    def stop_installation(self):
        """Stop installation process"""
        if self.install_running:
            if messagebox.askyesno("Confirm", "Stop installation?"):
                # Kill installation processes
                subprocess.run(['sudo', 'pkill', '-f', 'install-hybrid.sh'])
                self.install_running = False
                self.install_btn.config(state='normal')
                self.update_status("Installation stopped")
    
    def run_doctor(self):
        """Run ERPNext doctor diagnostic tool"""
        self.doctor_running = True
        self.doctor_btn.config(state='disabled')
        self.doctor_output.delete(1.0, tk.END)
        self.update_status("Running diagnostics...")
        
        # Run in thread
        thread = threading.Thread(target=self.execute_doctor)
        thread.daemon = True
        thread.start()
    
    def execute_doctor(self):
        """Execute doctor script"""
        try:
            script_path = os.path.join(self.script_dir, 'doctor.sh')
            
            if not os.path.exists(script_path):
                self.append_doctor_output("ERROR: doctor.sh not found!\n", "error")
                return
            
            # Run script
            process = subprocess.Popen(
                ['sudo', 'bash', script_path],
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
                bufsize=1
            )
            
            # Read output
            for line in process.stdout:
                self.append_doctor_output(line)
            
            process.wait()
            
            if process.returncode == 0:
                self.append_doctor_output("\n✅ Diagnostics completed\n", "success")
                self.update_status("Diagnostics completed")
            else:
                self.append_doctor_output(f"\n⚠️ Diagnostics finished with warnings\n", "warning")
                
        except Exception as e:
            self.append_doctor_output(f"\nERROR: {e}\n", "error")
        finally:
            self.doctor_running = False
            self.root.after(0, lambda: self.doctor_btn.config(state='normal'))
    
    def confirm_uninstall(self):
        """Confirm and start uninstallation"""
        result = messagebox.askquestion(
            "⚠️ CONFIRM UNINSTALL",
            "This will PERMANENTLY DELETE all ERPNext data!\n\n"
            "Are you ABSOLUTELY SURE?\n\n"
            "Type YES in the next dialog to confirm.",
            icon='warning'
        )
        
        if result != 'yes':
            return
        
        # Second confirmation
        confirm_text = tk.simpledialog.askstring(
            "Final Confirmation",
            "Type 'YES' to confirm uninstallation:"
        )
        
        if confirm_text != 'YES':
            messagebox.showinfo("Cancelled", "Uninstallation cancelled")
            return
        
        # Start uninstallation
        self.run_uninstall()
    
    def run_uninstall(self):
        """Execute uninstall script"""
        self.uninstall_output.delete(1.0, tk.END)
        self.update_status("Uninstalling...")
        
        thread = threading.Thread(target=self.execute_uninstall)
        thread.daemon = True
        thread.start()
    
    def execute_uninstall(self):
        """Execute uninstall script"""
        try:
            script_path = os.path.join(self.script_dir, 'uninstall.sh')
            
            if not os.path.exists(script_path):
                self.append_uninstall_output("ERROR: uninstall.sh not found!\n")
                return
            
            # Prepare input
            inputs = "YES\n"
            if self.remove_packages_var.get():
                inputs += "y\n"
            else:
                inputs += "n\n"
            
            # Run script
            process = subprocess.Popen(
                ['sudo', 'bash', script_path],
                stdin=subprocess.PIPE,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True
            )
            
            output, _ = process.communicate(input=inputs)
            self.append_uninstall_output(output)
            
            if process.returncode == 0:
                self.update_status("Uninstallation completed")
                messagebox.showinfo("Complete", "ERPNext uninstalled successfully")
            else:
                self.update_status("Uninstallation failed")
                
        except Exception as e:
            self.append_uninstall_output(f"ERROR: {e}\n")
    
    # ==========================
    # OUTPUT METHODS
    # ==========================
    
    def append_install_output(self, text):
        """Append text to installation output"""
        def append():
            self.install_output.insert(tk.END, text)
            self.install_output.see(tk.END)
        self.root.after(0, append)
    
    def append_doctor_output(self, text, tag=None):
        """Append text to doctor output with optional tag"""
        def append():
            if tag:
                self.doctor_output.insert(tk.END, text, tag)
            else:
                # Auto-detect type based on content
                if '❌' in text or 'ERROR' in text:
                    self.doctor_output.insert(tk.END, text, "error")
                elif '⚠️' in text or 'WARNING' in text:
                    self.doctor_output.insert(tk.END, text, "warning")
                elif '✅' in text or 'SUCCESS' in text:
                    self.doctor_output.insert(tk.END, text, "success")
                else:
                    self.doctor_output.insert(tk.END, text)
            self.doctor_output.see(tk.END)
        self.root.after(0, append)
    
    def append_uninstall_output(self, text):
        """Append text to uninstall output"""
        def append():
            self.uninstall_output.insert(tk.END, text)
            self.uninstall_output.see(tk.END)
        self.root.after(0, append)
    
    def update_status(self, message):
        """Update status bar"""
        def update():
            self.status_bar.config(text=f"{datetime.now().strftime('%H:%M:%S')} - {message}")
        self.root.after(0, update)
    
    # ==========================
    # UTILITY METHODS
    # ==========================
    
    def show_system_check(self):
        """Show system check dialog"""
        self.notebook.select(0)  # Go to dashboard
        messagebox.showinfo("System Check", "System check functionality - Coming soon!")
    
    def show_installer(self):
        """Switch to installer tab"""
        self.notebook.select(1)
    
    def show_doctor(self):
        """Switch to doctor tab"""
        self.notebook.select(2)
    
    def show_uninstaller(self):
        """Switch to uninstaller tab"""
        self.notebook.select(3)
    
    def show_logs(self):
        """Switch to logs tab"""
        self.notebook.select(4)
    
    def browse_log_file(self):
        """Browse for log file"""
        filename = filedialog.askopenfilename(
            title="Select Log File",
            initialdir="/tmp",
            filetypes=[("Log files", "*.log"), ("All files", "*.*")]
        )
        if filename:
            self.log_file_var.set(filename)
            self.load_log_file()
    
    def find_latest_log(self):
        """Find and load latest installation log"""
        try:
            log_files = []
            for file in os.listdir('/tmp'):
                if file.startswith('erpnext_install_') and file.endswith('.log'):
                    log_files.append(os.path.join('/tmp', file))
            
            if log_files:
                latest = max(log_files, key=os.path.getmtime)
                self.log_file_var.set(latest)
                self.load_log_file()
        except Exception as e:
            pass
    
    def load_log_file(self):
        """Load log file content"""
        log_file = self.log_file_var.get()
        if not log_file or not os.path.exists(log_file):
            return
        
        try:
            with open(log_file, 'r') as f:
                content = f.read()
            self.log_text.delete(1.0, tk.END)
            self.log_text.insert(1.0, content)
            self.update_status(f"Loaded log: {os.path.basename(log_file)}")
        except Exception as e:
            messagebox.showerror("Error", f"Cannot load log file: {e}")
    
    def save_doctor_report(self):
        """Save doctor report to file"""
        content = self.doctor_output.get(1.0, tk.END)
        if not content.strip():
            messagebox.showwarning("Warning", "No report to save")
            return
        
        filename = filedialog.asksaveasfilename(
            defaultextension=".txt",
            filetypes=[("Text files", "*.txt"), ("All files", "*.*")],
            initialfile=f"doctor_report_{datetime.now().strftime('%Y%m%d_%H%M%S')}.txt"
        )
        
        if filename:
            try:
                with open(filename, 'w') as f:
                    f.write(content)
                messagebox.showinfo("Success", f"Report saved to:\n{filename}")
            except Exception as e:
                messagebox.showerror("Error", f"Cannot save report: {e}")
    
    def export_report(self):
        """Export comprehensive system report"""
        messagebox.showinfo("Export", "Export report functionality - Coming soon!")
    
    def show_help(self):
        """Show help documentation"""
        help_text = """
ERPNext Installation Toolkit - Help

DASHBOARD:
• Quick access to all tools
• System information overview

INSTALLER:
• Configure ERPNext installation
• Set passwords and options
• Monitor installation progress

DOCTOR:
• Diagnose ERPNext issues
• Auto-fix detected problems
• Generate diagnostic reports

UNINSTALLER:
• Safely remove ERPNext
• Option to keep/remove packages
• Backup before uninstall

LOGS:
• View installation logs
• Monitor system logs
• Export log files

For support:
Developer: Umair Wali
Mobile: +92 308 2614004
        """
        
        help_window = tk.Toplevel(self.root)
        help_window.title("Help")
        help_window.geometry("600x500")
        
        text = scrolledtext.ScrolledText(help_window, font=('Arial', 10))
        text.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        text.insert(1.0, help_text)
        text.config(state='disabled')
    
    def show_about(self):
        """Show about dialog"""
        about_text = """
ERPNext Installation Toolkit GUI
Version 2.0

A comprehensive graphical interface for ERPNext 
installation, diagnostics, and management.

Features:
✓ One-click installation wizard
✓ Automated diagnostics and fixes
✓ System health monitoring
✓ Safe uninstallation
✓ Log viewer and reporting

Developer: Umair Wali
Contact: +92 308 2614004

© 2024 ERPNext Installation Toolkit
        """
        messagebox.showinfo("About", about_text)


def main():
    """Main entry point"""
    # Check if running as root
    if os.geteuid() != 0:
        print("⚠️  Warning: Some features require root privileges")
        print("Run with: sudo python3 erpnext_gui.py")
    
    root = tk.Tk()
    app = ERPNextGUI(root)
    root.mainloop()


if __name__ == "__main__":
    main()
