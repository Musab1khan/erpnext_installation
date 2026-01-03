#!/usr/bin/env python3
"""
ERPNext Web-Based Installer v4.1
Complete installation toolkit with Doctor, Uninstall, and Remote Access
Developer: Umair Wali | +92 308 2614004
"""

from flask import Flask, render_template_string, request, jsonify, Response
import subprocess
import threading
import queue
import os
import time
import socket

app = Flask(__name__)

# Global state
status = {
    'install_running': False,
    'doctor_running': False,
    'uninstall_running': False
}

log_queue = queue.Queue()

def get_server_ip():
    """Get server IP address"""
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except:
        return "localhost"

HTML_TEMPLATE = '''
<!DOCTYPE html>
<html>
<head>
    <title>ERPNext Installer v4.1</title>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Segoe UI', Arial, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 20px;
        }
        .container {
            max-width: 1400px;
            margin: 0 auto;
            background: white;
            border-radius: 10px;
            box-shadow: 0 10px 40px rgba(0,0,0,0.3);
            overflow: hidden;
        }
        .header {
            background: #2c3e50;
            color: white;
            padding: 20px;
            text-align: center;
        }
        .header h1 { font-size: 26px; margin-bottom: 5px; }
        .header p { color: #bdc3c7; font-size: 13px; }
        .server-info {
            background: #34495e;
            color: #ecf0f1;
            padding: 10px 20px;
            display: flex;
            justify-content: space-between;
            font-size: 13px;
        }
        .tabs {
            display: flex;
            background: #ecf0f1;
            border-bottom: 2px solid #bdc3c7;
        }
        .tab {
            padding: 15px 30px;
            cursor: pointer;
            border: none;
            background: transparent;
            font-size: 15px;
            font-weight: 600;
            color: #7f8c8d;
            transition: all 0.3s;
        }
        .tab:hover { background: #d5dbdb; }
        .tab.active {
            background: white;
            color: #2c3e50;
            border-bottom: 3px solid #667eea;
        }
        .tab-content { display: none; }
        .tab-content.active { display: block; }

        /* Install Tab */
        .install-grid {
            display: grid;
            grid-template-columns: 450px 1fr;
            min-height: 600px;
        }
        .sidebar {
            background: #f8f9fa;
            padding: 25px;
            border-right: 1px solid #dee2e6;
        }
        .content { padding: 25px; }

        .form-group { margin-bottom: 15px; }
        .form-group label {
            display: block;
            margin-bottom: 5px;
            font-weight: 600;
            color: #2c3e50;
            font-size: 14px;
        }
        .form-group input, .form-group select {
            width: 100%;
            padding: 10px;
            border: 2px solid #e0e0e0;
            border-radius: 5px;
            font-size: 14px;
        }
        .form-group input:focus, .form-group select:focus {
            outline: none;
            border-color: #667eea;
        }
        .form-group input[type="checkbox"] {
            width: auto;
            margin-right: 8px;
        }
        .checkbox-label {
            display: flex;
            align-items: center;
            cursor: pointer;
        }
        .info-box {
            background: #e3f2fd;
            border-left: 4px solid #2196f3;
            padding: 12px;
            margin: 15px 0;
            font-size: 13px;
            border-radius: 4px;
        }
        .btn {
            padding: 12px 25px;
            border: none;
            border-radius: 5px;
            font-size: 14px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.3s;
            margin-right: 10px;
        }
        .btn-primary { background: #4CAF50; color: white; }
        .btn-primary:hover { background: #45a049; }
        .btn-danger { background: #f44336; color: white; }
        .btn-danger:hover { background: #da190b; }
        .btn-info { background: #2196F3; color: white; }
        .btn-info:hover { background: #0b7dda; }
        .btn-warning { background: #ff9800; color: white; }
        .btn-warning:hover { background: #e68900; }
        .btn:disabled {
            background: #ccc;
            cursor: not-allowed;
        }

        .package-list {
            background: white;
            border: 1px solid #e0e0e0;
            border-radius: 5px;
            max-height: 300px;
            overflow-y: auto;
            margin-bottom: 20px;
        }
        .package-item {
            padding: 10px 15px;
            border-bottom: 1px solid #f0f0f0;
            font-size: 13px;
            display: flex;
            align-items: center;
        }
        .package-item:last-child { border-bottom: none; }
        .package-icon {
            font-size: 18px;
            margin-right: 10px;
            min-width: 25px;
        }
        .console {
            background: #1e1e1e;
            color: #00ff00;
            padding: 15px;
            border-radius: 5px;
            height: 350px;
            overflow-y: auto;
            font-family: 'Courier New', monospace;
            font-size: 13px;
            line-height: 1.5;
        }
        .progress-container { margin: 20px 0; }
        .progress-bar {
            background: #e0e0e0;
            height: 30px;
            border-radius: 15px;
            overflow: hidden;
            position: relative;
        }
        .progress-fill {
            background: linear-gradient(90deg, #4CAF50, #8BC34A);
            height: 100%;
            width: 0%;
            transition: width 0.5s;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-weight: 600;
            font-size: 14px;
        }
        .section-title {
            font-size: 18px;
            font-weight: 600;
            color: #2c3e50;
            margin-bottom: 15px;
            padding-bottom: 10px;
            border-bottom: 2px solid #667eea;
        }
        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }
        .spinning { animation: spin 1s linear infinite; }

        /* Doctor Tab */
        .doctor-container {
            padding: 30px;
            max-width: 1000px;
            margin: 0 auto;
        }
        .doctor-options {
            background: #f8f9fa;
            padding: 20px;
            border-radius: 5px;
            margin-bottom: 20px;
        }

        /* Uninstall Tab */
        .uninstall-container {
            padding: 30px;
            max-width: 800px;
            margin: 0 auto;
        }
        .warning-box {
            background: #fff3cd;
            border: 2px solid #ffc107;
            border-radius: 5px;
            padding: 20px;
            margin: 20px 0;
        }
        .warning-box h3 {
            color: #856404;
            margin-bottom: 10px;
        }
        .warning-list {
            color: #721c24;
            margin-left: 20px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🚀 ERPNext Complete Installer</h1>
            <p>Web-Based Installation Toolkit v4.1 | Developer: Umair Wali</p>
        </div>

        <div class="server-info">
            <span>📍 Server IP: <strong>{{ server_ip }}</strong></span>
            <span>🌐 Access: <strong>http://{{ server_ip }}:5000</strong></span>
            <span>💻 Local: <strong>http://localhost:5000</strong></span>
        </div>

        <div class="tabs">
            <button class="tab active" onclick="switchTab('install')">⚙️ Installer</button>
            <button class="tab" onclick="switchTab('doctor')">🏥 Doctor</button>
            <button class="tab" onclick="switchTab('uninstall')">🗑️ Uninstall</button>
        </div>

        <!-- INSTALL TAB -->
        <div id="install-tab" class="tab-content active">
            <div class="install-grid">
                <div class="sidebar">
                    <div class="section-title">⚙️ Configuration</div>

                    <div class="form-group">
                        <label>Username</label>
                        <input type="text" id="username" value="frappe">
                    </div>

                    <div class="form-group">
                        <label>Site Name</label>
                        <input type="text" id="sitename" value="site.local">
                    </div>

                    <div class="form-group">
                        <label>ERPNext Version</label>
                        <select id="version">
                            <option value="13">Version 13 (LTS)</option>
                            <option value="14">Version 14 (Stable)</option>
                            <option value="15" selected>Version 15 (Latest)</option>
                            <option value="develop">Develop (Unstable)</option>
                        </select>
                    </div>

                    <div class="form-group">
                        <label>MySQL Password</label>
                        <input type="password" id="mysql_pass" placeholder="Min 6 characters">
                    </div>

                    <div class="form-group">
                        <label>Admin Password</label>
                        <input type="password" id="admin_pass" placeholder="Min 6 characters">
                    </div>

                    <div class="form-group">
                        <label class="checkbox-label">
                            <input type="checkbox" id="prod_mode" checked>
                            Production Mode (Nginx + Supervisor)
                        </label>
                    </div>

                    <div class="form-group">
                        <label class="checkbox-label">
                            <input type="checkbox" id="install_erpnext" checked>
                            Install ERPNext Application
                        </label>
                    </div>

                    <div class="info-box">
                        <strong>📋 Requirements:</strong><br>
                        • Min: 2GB RAM, 15GB Disk<br>
                        • Recommended: 4GB RAM, 25GB Disk<br>
                        • Time: 15-45 minutes
                    </div>

                    <div style="margin-top: 20px;">
                        <button class="btn btn-primary" id="startBtn" onclick="startInstallation()">
                            🚀 Start Installation
                        </button>
                        <button class="btn btn-danger" id="stopBtn" onclick="stopInstallation()" disabled>
                            ⏹ Stop
                        </button>
                    </div>
                </div>

                <div class="content">
                    <div class="section-title">📊 Installation Progress</div>

                    <div class="progress-container">
                        <div class="progress-bar">
                            <div class="progress-fill" id="progressBar">0%</div>
                        </div>
                    </div>

                    <div class="package-list" id="packageList">
                        <div class="package-item"><span class="package-icon">⏳</span> Step 1: System Update</div>
                        <div class="package-item"><span class="package-icon">⏳</span> Step 2: Python & Dependencies</div>
                        <div class="package-item"><span class="package-icon">⏳</span> Step 3: MariaDB Database</div>
                        <div class="package-item"><span class="package-icon">⏳</span> Step 4: Redis Cache</div>
                        <div class="package-item"><span class="package-icon">⏳</span> Step 5: Nginx Web Server</div>
                        <div class="package-item"><span class="package-icon">⏳</span> Step 6: wkhtmltopdf</div>
                        <div class="package-item"><span class="package-icon">⏳</span> Step 7: Node.js & Yarn</div>
                        <div class="package-item"><span class="package-icon">⏳</span> Step 8: Frappe Bench</div>
                        <div class="package-item"><span class="package-icon">⏳</span> Step 9: Bench Initialization</div>
                        <div class="package-item"><span class="package-icon">⏳</span> Step 10: MariaDB Config</div>
                        <div class="package-item"><span class="package-icon">⏳</span> Step 11: Create Site</div>
                        <div class="package-item"><span class="package-icon">⏳</span> Step 12: Install ERPNext</div>
                        <div class="package-item"><span class="package-icon">⏳</span> Step 13: Production Setup</div>
                        <div class="package-item"><span class="package-icon">⏳</span> Step 14: Security Setup</div>
                        <div class="package-item"><span class="package-icon">⏳</span> Step 15: Optimization</div>
                    </div>

                    <div class="section-title">📋 Console Output</div>
                    <div class="console" id="console">
                        <div>Ready to install ERPNext...</div>
                        <div>Configure settings and click "Start Installation"</div>
                    </div>
                </div>
            </div>
        </div>

        <!-- DOCTOR TAB -->
        <div id="doctor-tab" class="tab-content">
            <div class="doctor-container">
                <div class="section-title">🏥 ERPNext Doctor - Diagnostic Tool</div>

                <div class="doctor-options">
                    <h3>Diagnostic Options</h3>
                    <label class="checkbox-label" style="margin: 10px 0;">
                        <input type="checkbox" id="auto_fix" checked>
                        Automatically fix detected issues
                    </label>
                </div>

                <div style="margin-bottom: 20px;">
                    <button class="btn btn-info" id="doctorBtn" onclick="runDoctor()">
                        🔍 Run Diagnostics
                    </button>
                    <button class="btn btn-warning" onclick="clearDoctorOutput()">
                        🧹 Clear Output
                    </button>
                </div>

                <div class="section-title">📋 Diagnostic Results</div>
                <div class="console" id="doctorConsole">
                    <div>Click "Run Diagnostics" to start health check...</div>
                </div>
            </div>
        </div>

        <!-- UNINSTALL TAB -->
        <div id="uninstall-tab" class="tab-content">
            <div class="uninstall-container">
                <div class="section-title">🗑️ Uninstall ERPNext</div>

                <div class="warning-box">
                    <h3>⚠️ WARNING: Permanent Deletion</h3>
                    <p>This will <strong>PERMANENTLY DELETE</strong>:</p>
                    <ul class="warning-list">
                        <li>All ERPNext/Frappe bench directories</li>
                        <li>All databases and data</li>
                        <li>Nginx configurations</li>
                        <li>Supervisor configurations</li>
                        <li>Optional: System packages (MariaDB, Redis, Node.js)</li>
                    </ul>
                    <p style="margin-top: 10px;"><strong>Make sure you have backups!</strong></p>
                </div>

                <div class="doctor-options">
                    <h3>Uninstall Options</h3>
                    <label class="checkbox-label" style="margin: 10px 0;">
                        <input type="checkbox" id="remove_packages">
                        Also remove system packages (MariaDB, Redis, Nginx)
                    </label>
                    <br>
                    <label class="checkbox-label" style="margin: 10px 0;">
                        <input type="checkbox" id="backup_before" checked>
                        Create backup before uninstalling
                    </label>
                </div>

                <div style="margin: 20px 0;">
                    <button class="btn btn-danger" onclick="confirmUninstall()">
                        🗑️ Uninstall ERPNext
                    </button>
                </div>

                <div class="section-title">📋 Uninstall Output</div>
                <div class="console" id="uninstallConsole" style="height: 300px;">
                    <div>Uninstallation output will appear here...</div>
                </div>
            </div>
        </div>
    </div>

    <script>
        let eventSource = null;

        function switchTab(tabName) {
            // Hide all tabs
            document.querySelectorAll('.tab-content').forEach(t => t.classList.remove('active'));
            document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));

            // Show selected tab
            document.getElementById(tabName + '-tab').classList.add('active');
            event.target.classList.add('active');
        }

        // INSTALL FUNCTIONS
        function startInstallation() {
            const username = document.getElementById('username').value;
            const sitename = document.getElementById('sitename').value;
            const mysql_pass = document.getElementById('mysql_pass').value;
            const admin_pass = document.getElementById('admin_pass').value;

            if (!username || !sitename) {
                alert('Username and Site Name are required!');
                return;
            }

            if (mysql_pass.length < 6 || admin_pass.length < 6) {
                alert('Passwords must be at least 6 characters!');
                return;
            }

            if (!confirm('Start ERPNext installation?\\n\\n⏱ This will take 15-45 minutes.')) {
                return;
            }

            const data = {
                username: username,
                sitename: sitename,
                version: document.getElementById('version').value,
                mysql_pass: mysql_pass,
                admin_pass: admin_pass,
                prod_mode: document.getElementById('prod_mode').checked,
                install_erpnext: document.getElementById('install_erpnext').checked
            };

            fetch('/start', {
                method: 'POST',
                headers: {'Content-Type': 'application/json'},
                body: JSON.stringify(data)
            })
            .then(res => res.json())
            .then(data => {
                if (data.success) {
                    document.getElementById('startBtn').disabled = true;
                    document.getElementById('stopBtn').disabled = false;
                    connectEventStream('/stream');
                }
            });
        }

        function stopInstallation() {
            if (confirm('Stop installation?')) {
                fetch('/stop', {method: 'POST'});
                if (eventSource) eventSource.close();
                document.getElementById('startBtn').disabled = false;
                document.getElementById('stopBtn').disabled = true;
            }
        }

        // DOCTOR FUNCTIONS
        function runDoctor() {
            document.getElementById('doctorBtn').disabled = true;
            document.getElementById('doctorConsole').innerHTML = '<div>Running diagnostics...</div>';

            const data = {
                auto_fix: document.getElementById('auto_fix').checked
            };

            fetch('/doctor/start', {
                method: 'POST',
                headers: {'Content-Type': 'application/json'},
                body: JSON.stringify(data)
            })
            .then(res => res.json())
            .then(data => {
                if (data.success) {
                    connectEventStream('/doctor/stream');
                }
            });
        }

        function clearDoctorOutput() {
            document.getElementById('doctorConsole').innerHTML = '<div>Output cleared. Ready for next diagnostic run...</div>';
        }

        // UNINSTALL FUNCTIONS
        function confirmUninstall() {
            const confirmed = prompt('Type "YES" to confirm uninstallation (all caps):');
            if (confirmed !== 'YES') {
                alert('Uninstallation cancelled.');
                return;
            }

            const data = {
                remove_packages: document.getElementById('remove_packages').checked,
                backup_before: document.getElementById('backup_before').checked
            };

            document.getElementById('uninstallConsole').innerHTML = '<div>Starting uninstallation...</div>';

            fetch('/uninstall/start', {
                method: 'POST',
                headers: {'Content-Type': 'application/json'},
                body: JSON.stringify(data)
            })
            .then(res => res.json())
            .then(data => {
                if (data.success) {
                    connectEventStream('/uninstall/stream');
                }
            });
        }

        // EVENT STREAM
        function connectEventStream(url) {
            if (eventSource) eventSource.close();
            eventSource = new EventSource(url);

            eventSource.addEventListener('log', function(e) {
                const consoles = {
                    '/stream': 'console',
                    '/doctor/stream': 'doctorConsole',
                    '/uninstall/stream': 'uninstallConsole'
                };
                const consoleId = consoles[url] || 'console';
                const console = document.getElementById(consoleId);
                console.innerHTML += '<div>' + e.data + '</div>';
                console.scrollTop = console.scrollHeight;
            });

            eventSource.addEventListener('progress', function(e) {
                const data = JSON.parse(e.data);
                const percent = Math.round((data.step / data.total) * 100);
                const progressBar = document.getElementById('progressBar');
                progressBar.style.width = percent + '%';
                progressBar.textContent = percent + '% - Step ' + data.step + '/' + data.total;
            });

            eventSource.addEventListener('package', function(e) {
                const data = JSON.parse(e.data);
                const items = document.querySelectorAll('#packageList .package-item');
                if (items[data.step]) {
                    const icon = items[data.step].querySelector('.package-icon');
                    if (data.status === 'running') {
                        icon.textContent = '🔄';
                        icon.classList.add('spinning');
                    } else if (data.status === 'success') {
                        icon.textContent = '✅';
                        icon.classList.remove('spinning');
                    } else if (data.status === 'error') {
                        icon.textContent = '❌';
                        icon.classList.remove('spinning');
                    }
                }
            });

            eventSource.addEventListener('complete', function(e) {
                const data = JSON.parse(e.data);
                alert(data.message);
                document.getElementById('startBtn').disabled = false;
                document.getElementById('stopBtn').disabled = true;
                document.getElementById('doctorBtn').disabled = false;
                eventSource.close();
            });
        }
    </script>
</body>
</html>
'''

@app.route('/')
def index():
    server_ip = get_server_ip()
    return render_template_string(HTML_TEMPLATE, server_ip=server_ip)

# INSTALL ROUTES
@app.route('/start', methods=['POST'])
def start_install():
    if status['install_running']:
        return jsonify({'success': False, 'message': 'Installation already running'})

    config = request.json
    status['install_running'] = True

    thread = threading.Thread(target=run_installation, args=(config,))
    thread.daemon = True
    thread.start()

    return jsonify({'success': True})

@app.route('/stop', methods=['POST'])
def stop_install():
    status['install_running'] = False
    subprocess.run(['sudo', 'pkill', '-f', 'erpnext_web_install'])
    return jsonify({'success': True})

@app.route('/stream')
def stream():
    def generate():
        while status['install_running'] or not log_queue.empty():
            try:
                msg = log_queue.get(timeout=1)
                yield f"{msg}\n\n"
            except queue.Empty:
                yield f"data: heartbeat\n\n"
    return Response(generate(), mimetype='text/event-stream')

# DOCTOR ROUTES
@app.route('/doctor/start', methods=['POST'])
def start_doctor():
    if status['doctor_running']:
        return jsonify({'success': False, 'message': 'Doctor already running'})

    config = request.json
    status['doctor_running'] = True

    thread = threading.Thread(target=run_doctor, args=(config,))
    thread.daemon = True
    thread.start()

    return jsonify({'success': True})

@app.route('/doctor/stream')
def doctor_stream():
    def generate():
        while status['doctor_running'] or not log_queue.empty():
            try:
                msg = log_queue.get(timeout=1)
                yield f"{msg}\n\n"
            except queue.Empty:
                yield f"data: heartbeat\n\n"
    return Response(generate(), mimetype='text/event-stream')

# UNINSTALL ROUTES
@app.route('/uninstall/start', methods=['POST'])
def start_uninstall():
    if status['uninstall_running']:
        return jsonify({'success': False, 'message': 'Uninstall already running'})

    config = request.json
    status['uninstall_running'] = True

    thread = threading.Thread(target=run_uninstall, args=(config,))
    thread.daemon = True
    thread.start()

    return jsonify({'success': True})

@app.route('/uninstall/stream')
def uninstall_stream():
    def generate():
        while status['uninstall_running'] or not log_queue.empty():
            try:
                msg = log_queue.get(timeout=1)
                yield f"{msg}\n\n"
            except queue.Empty:
                yield f"data: heartbeat\n\n"
    return Response(generate(), mimetype='text/event-stream')

# WORKER FUNCTIONS
def run_installation(config):
    try:
        script = generate_install_script(config)
        script_path = "/tmp/erpnext_web_install.sh"

        with open(script_path, 'w') as f:
            f.write(script)
        os.chmod(script_path, 0o755)

        log_queue.put('event: log\ndata: ═══════════════════════════════════════')
        log_queue.put('event: log\ndata: 🚀 ERPNext Installation Started')
        log_queue.put('event: log\ndata: ═══════════════════════════════════════')

        process = subprocess.Popen(
            ['sudo', 'bash', script_path],
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            bufsize=1
        )

        step = 0
        for line in process.stdout:
            if not status['install_running']:
                process.terminate()
                break

            line = line.rstrip()
            log_queue.put(f'event: log\ndata: {line}')

            if 'Step' in line:
                for i in range(1, 16):
                    if f'Step {i}' in line:
                        if step < i:
                            if step > 0:
                                log_queue.put(f'event: package\ndata: {{"step": {step-1}, "status": "success"}}')
                            step = i
                            log_queue.put(f'event: package\ndata: {{"step": {step-1}, "status": "running"}}')
                            log_queue.put(f'event: progress\ndata: {{"step": {step}, "total": 15}}')
                        break

        process.wait()

        if process.returncode == 0:
            for i in range(15):
                log_queue.put(f'event: package\ndata: {{"step": {i}, "status": "success"}}')
            log_queue.put('event: log\ndata: ✅ INSTALLATION COMPLETED!')
            log_queue.put(f'event: log\ndata: URL: http://{config["sitename"]}')
            log_queue.put('event: complete\ndata: {"message": "✅ Installation completed!"}')
        else:
            log_queue.put('event: log\ndata: ❌ Installation failed!')
            log_queue.put('event: complete\ndata: {"message": "❌ Installation failed!"}')

    except Exception as e:
        log_queue.put(f'event: log\ndata: ERROR: {str(e)}')
    finally:
        status['install_running'] = False

def run_doctor(config):
    try:
        log_queue.put('event: log\ndata: 🏥 Starting ERPNext Doctor...')
        log_queue.put('event: log\ndata: ═══════════════════════════════════════')

        script_dir = os.path.dirname(os.path.abspath(__file__))
        doctor_script = os.path.join(script_dir, 'doctor.sh')

        if not os.path.exists(doctor_script):
            log_queue.put('event: log\ndata: ❌ ERROR: doctor.sh not found!')
            log_queue.put('event: complete\ndata: {"message": "doctor.sh not found!"}')
            status['doctor_running'] = False
            return

        process = subprocess.Popen(
            ['sudo', 'bash', doctor_script],
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            bufsize=1
        )

        for line in process.stdout:
            if not status['doctor_running']:
                process.terminate()
                break
            line = line.rstrip()
            log_queue.put(f'event: log\ndata: {line}')

        process.wait()

        if process.returncode == 0:
            log_queue.put('event: log\ndata: ✅ Diagnostics completed!')
            log_queue.put('event: complete\ndata: {"message": "✅ Diagnostics completed!"}')
        else:
            log_queue.put('event: log\ndata: ⚠️ Diagnostics finished with warnings')
            log_queue.put('event: complete\ndata: {"message": "⚠️ Finished with warnings"}')

    except Exception as e:
        log_queue.put(f'event: log\ndata: ERROR: {str(e)}')
    finally:
        status['doctor_running'] = False

def run_uninstall(config):
    try:
        log_queue.put('event: log\ndata: 🗑️ Starting Uninstallation...')
        log_queue.put('event: log\ndata: ═══════════════════════════════════════')

        script_dir = os.path.dirname(os.path.abspath(__file__))
        uninstall_script = os.path.join(script_dir, 'uninstall.sh')

        if not os.path.exists(uninstall_script):
            log_queue.put('event: log\ndata: ❌ ERROR: uninstall.sh not found!')
            log_queue.put('event: complete\ndata: {"message": "uninstall.sh not found!"}')
            status['uninstall_running'] = False
            return

        # Prepare inputs for uninstall script
        inputs = "YES\n"
        if config.get('remove_packages'):
            inputs += "y\n"
        else:
            inputs += "n\n"

        process = subprocess.Popen(
            ['sudo', 'bash', uninstall_script],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True
        )

        output, _ = process.communicate(input=inputs)
        for line in output.split('\n'):
            log_queue.put(f'event: log\ndata: {line}')

        if process.returncode == 0:
            log_queue.put('event: log\ndata: ✅ Uninstallation completed!')
            log_queue.put('event: complete\ndata: {"message": "✅ Uninstallation completed!"}')
        else:
            log_queue.put('event: log\ndata: ❌ Uninstallation failed!')
            log_queue.put('event: complete\ndata: {"message": "❌ Uninstallation failed!"}')

    except Exception as e:
        log_queue.put(f'event: log\ndata: ERROR: {str(e)}')
    finally:
        status['uninstall_running'] = False

def generate_install_script(config):
    user = config['username']
    site = config['sitename']
    ver = config['version']
    mysql = config['mysql_pass']
    admin = config['admin_pass']
    prod = "yes" if config['prod_mode'] else "no"
    inst = "yes" if config['install_erpnext'] else "no"

    bench_ver = f"version-{ver}" if ver in ["13","14","15"] else "develop"
    node_ver = "18" if ver in ["15","develop"] else "16"

    return f'''#!/bin/bash
set -e

echo "Step 1: System update..."
apt update && apt upgrade -y

echo "Step 2: Python & dependencies..."
apt install -y git curl wget python3-dev python3-pip python3-venv python3-setuptools software-properties-common pkg-config

echo "Step 3: MariaDB..."
apt install -y mariadb-server mariadb-client default-libmysqlclient-dev

echo "Step 4: Redis..."
apt install -y redis-server

echo "Step 5: Nginx..."
[[ "{prod}" == "yes" ]] && apt install -y nginx supervisor fail2ban certbot python3-certbot-nginx

echo "Step 6: wkhtmltopdf..."
arch=$(uname -m); [[ "$arch" == "x86_64" ]] && arch="amd64"; [[ "$arch" == "aarch64" ]] && arch="arm64"
wget -q "https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-2/wkhtmltox_0.12.6.1-2.jammy_${{arch}}.deb" -O /tmp/w.deb
dpkg -i /tmp/w.deb || apt --fix-broken install -y
rm /tmp/w.deb

echo "Step 7: Node.js & Yarn..."
if ! id "{user}" &>/dev/null; then
    adduser --gecos "" --disabled-password "{user}"
    echo "{user}:$(openssl rand -base64 12)" | chpasswd
    usermod -aG sudo "{user}"
    echo "{user} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/{user}
    chmod 0440 /etc/sudoers.d/{user}
fi

sudo -u "{user}" -H bash -lc '
if [ ! -d "$HOME/.nvm" ]; then
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
fi
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
nvm install {node_ver}
npm install -g yarn@1.22.19
'

echo "Step 8: Frappe Bench..."
find /usr/lib/python3.*/EXTERNALLY-MANAGED 2>/dev/null | xargs rm -f || true
pip3 install frappe-bench

echo "Step 9: Bench initialization..."
sudo -u "{user}" -H bash -lc '
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
cd "$HOME"
bench init frappe-bench --frappe-branch {bench_ver}
'

echo "Step 10: MariaDB configuration..."
systemctl stop mariadb || true
mkdir -p /etc/mysql/conf.d /etc/mysql/mariadb.conf.d
[ ! -f /var/lib/mysql/ibdata1 ] && rm -rf /var/lib/mysql/* && mysql_install_db --user=mysql
systemctl start mariadb
sleep 5
mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '{mysql}';" || true
cat >> /etc/mysql/my.cnf << 'EOF'

[mysqld]
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci
EOF
systemctl restart mariadb
sleep 3

echo "Step 11: Creating site..."
until mysqladmin ping -u root -p"{mysql}" --silent 2>/dev/null; do sleep 2; done
sudo -u "{user}" -H bash -lc '
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
cd "$HOME/frappe-bench"
bench new-site {site} --db-root-password {mysql} --admin-password {admin}
'

[[ "{inst}" == "yes" ]] && {{
echo "Step 12: Installing ERPNext..."
sudo -u "{user}" -H bash -lc '
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
cd "$HOME/frappe-bench"
bench get-app erpnext --branch {bench_ver}
bench --site {site} install-app erpnext
'
}}

[[ "{prod}" == "yes" ]] && {{
echo "Step 13: Production setup..."
pkill -f "bench start" 2>/dev/null || true
cd /home/{user}/frappe-bench
yes | bench setup production {user}
sudo -u "{user}" -H bash -lc '
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
cd "$HOME/frappe-bench"
bench --site {site} scheduler enable
'
supervisorctl restart all
}}

echo "Step 14: Security setup..."
command -v ufw && ufw allow 22,80,443/tcp && ufw --force enable || true

echo "Step 15: Optimization..."
sysctl -w net.core.somaxconn=65535 2>/dev/null || true

echo "✅ Installation complete!"
exit 0
'''

if __name__ == '__main__':
    server_ip = get_server_ip()
    print("\n" + "="*70)
    print("🚀 ERPNext Web Installer v4.1")
    print("="*70)
    print(f"\n📱 Local Access:  http://localhost:5000")
    print(f"🌐 Remote Access: http://{server_ip}:5000")
    print(f"\n💡 Share this URL with others: http://{server_ip}:5000")
    print("\n⚠️  Run with sudo for installation")
    print("⏹️  Press Ctrl+C to stop the server\n")

    app.run(host='0.0.0.0', port=5000, debug=False, threaded=True)
