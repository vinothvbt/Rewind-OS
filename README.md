# 🌀 Rewind OS - The Git of Operating Systems

Rewind OS is a next-generation Linux-based operating system designed for complete time manipulation of your system. Inspired by the concepts of version control (like Git) and powered by the robustness of NixOS, Rewind OS enables you to travel back and forth through time — capturing, auditing, and restoring system states as easily as browsing a video timeline.

**Current Status**: Phase 3 Implementation - Security, Audit, and Investigation Tools

---

## 🔥 Key Features

### 🔁 Time Travel (Back & Forth)

* Instantly rewind to any system state with timeline precision.
* Move forward in time if a new branch is restored from an old state.
* **NEW**: Safe rollback with automatic safety snapshots and confirmation prompts.
* **NEW**: Stash/unstash functionality for temporary state management.
* Inspired by Marvel's Time Stone — but in real Linux.

### 🧠 Intelligent Snapshot System

* Timeline-based snapshot management with git-like branching.
* Snapshots taken automatically based on user actions, updates, or on demand.
* Each snapshot is tracked and linked to a timeline branch.
* **NEW**: Automatic retention policies with configurable cleanup.
* **NEW**: Enhanced snapshot metadata and cross-reference tracking.

### 🧬 Git-Like Branching Engine

* Every change creates a new timeline branch.
* Switch between system states like switching Git branches.
* Merge branches or discard experiments without fear.
* **NEW**: Stash management for work-in-progress states.
* **NEW**: Enhanced branch operations with detailed tracking.

### 📦 NixOS-Powered Configuration Engine

* Declarative, reproducible system config using Nix.
* Integrated with NixOS rebuild process.
* Automatic snapshots before system changes.
* **NEW**: Live configuration management without reboot.
* **NEW**: Advanced systemd service integration for auto-save and rollback.
* **NEW**: Configuration change monitoring and automatic reload.

### 🔐 Desktop Integration

* XFCE desktop environment integration with enhanced reload mechanisms.
* Automatic desktop reload after state changes with error recovery.
* Configuration backup and restore with validation.
* **NEW**: Smart reload strategies (full, light, recovery modes).
* **NEW**: Real-time configuration validation and rollback on failure.

---

## 📁 Project Structure

```
rewind-os/
├── rewind/                 # Core Python package
│   ├── __init__.py        # Package initialization
│   ├── cli.py             # Command-line interface with security commands
│   └── timeline.py        # Timeline operations
├── scripts/               # System integration scripts
│   ├── hook-xfce-reload.sh # XFCE reload script
│   └── security-tools.sh  # Comprehensive security tools and monitoring
├── configs/               # Security tool configurations (Phase 3)
│   ├── rkhunter.conf      # RKHunter rootkit detection config
│   ├── aide.conf          # AIDE file integrity monitoring config
│   ├── fail2ban-jail.local # Fail2Ban intrusion prevention config
│   ├── fail2ban-filter-rewind-security.conf # Custom Rewind-OS filter
│   └── logwatch.conf      # Logwatch log analysis config
├── nix/                   # NixOS configuration
│   ├── rewind.nix         # Main NixOS module with security features
│   └── example.nix        # Example configuration with Phase 3 security
├── README.md              # This file
├── SECURITY.md            # Comprehensive Phase 3 security documentation
└── PHASES_Version5.md     # Development roadmap
```

---

## 💻 Installation & Setup

### Prerequisites:

* NixOS system (recommended)
* Python 3.8+ 
* Git
* XFCE (optional, for desktop integration)

### Quick Start

1. **Clone Repository**:
   ```bash
   git clone https://github.com/vinothvbt/Rewind-OS.git
   cd Rewind-OS
   ```

2. **Test CLI Directly** (Development):
   ```bash
   # Initialize timeline
   python3 -m rewind.cli list
   
   # Create a snapshot
   python3 -m rewind.cli snapshot "Initial setup"
   
   # List all branches
   python3 -m rewind.cli list
   ```

3. **NixOS Integration** (Production):
   ```nix
   # Add to your /etc/nixos/configuration.nix
   imports = [ ./path/to/rewind-os/nix/rewind.nix ];
   
   services.rewind-os = {
     enable = true;
     autoSnapshot.enable = true;
     xfce.enable = true;  # If using XFCE
   };
   ```

4. **Rebuild NixOS**:
   ```bash
   sudo nixos-rebuild switch
   ```

---

## 🔧 Usage

### Basic Timeline Operations

**Create a snapshot**:
```bash
python3 -m rewind.cli snapshot "Installed new packages"
```

**List all branches**:
```bash
python3 -m rewind.cli list
```

**List snapshots in current branch**:
```bash
python3 -m rewind.cli list --snapshots
```

**Create a new branch**:
```bash
python3 -m rewind.cli branch experimental "Testing new configuration"
```

**Switch to a branch**:
```bash
python3 -m rewind.cli switch experimental
```

**Restore to a snapshot (with confirmation)**:
```bash
python3 -m rewind.cli restore snap_1234567890
```

**Force restore without confirmation**:
```bash
python3 -m rewind.cli restore snap_1234567890 --force
```

### Stash Management (Phase 2)

**Create a stash**:
```bash
python3 -m rewind.cli stash "Work in progress"
```

**List all stashes**:
```bash
python3 -m rewind.cli list --stashes
```

**Apply most recent stash**:
```bash
python3 -m rewind.cli stash --apply
```

**Apply and remove most recent stash**:
```bash
python3 -m rewind.cli stash --pop
```

**Drop most recent stash**:
```bash
python3 -m rewind.cli stash --drop
```

### Information and Status

**Show timeline status**:
```bash
python3 -m rewind.cli info
```

**Show snapshot details**:
```bash
python3 -m rewind.cli info snap_1234567890
```

### Security Tools (Phase 3)

**Show security status**:
```bash
python3 -m rewind.cli security --status
```

**Run security scan with snapshots**:
```bash
python3 -m rewind.cli security --scan
```

**Show security audit trail**:
```bash
python3 -m rewind.cli security --audit
```

**Generate security report**:
```bash
python3 -m rewind.cli security --report
```

**Advanced security tools**:
```bash
# Initialize security infrastructure
./scripts/security-tools.sh init

# Run complete security monitoring
./scripts/security-tools.sh monitor

# Generate comprehensive security report
./scripts/security-tools.sh report

# Run specific security checks
./scripts/security-tools.sh integrity
./scripts/security-tools.sh network
./scripts/security-tools.sh forensics
```

### Advanced Operations

**Create branch and switch to it**:
```bash
python3 -m rewind.cli branch testing "New feature testing" --switch
```

**List snapshots from specific branch**:
```bash
python3 -m rewind.cli list --snapshots --branch main
```

**Unsafe restore (skip safety snapshot)**:
```bash
python3 -m rewind.cli restore snap_1234567890 --unsafe --force
```

**View help for any command**:
```bash
python3 -m rewind.cli --help
python3 -m rewind.cli snapshot --help
```

### XFCE Integration (Phase 2 Enhanced)

**Smart desktop reload with error recovery**:
```bash
./scripts/hook-xfce-reload.sh smart
```

**Full desktop reload**:
```bash
./scripts/hook-xfce-reload.sh full
```

**Lightweight refresh**:
```bash
./scripts/hook-xfce-reload.sh light
```

**Check component status**:
```bash
./scripts/hook-xfce-reload.sh status
```

**Backup XFCE configuration**:
```bash
./scripts/hook-xfce-reload.sh backup
```

**Recovery mode (restore from backup)**:
```bash
./scripts/hook-xfce-reload.sh recovery
```

---

## ⚙️ Configuration

### NixOS Module Options (Phase 2)

```nix
services.rewind-os = {
  enable = true;
  configDir = "/var/lib/rewind-os";  # Storage location
  
  # Enhanced automatic snapshot system
  autoSnapshot = {
    enable = true;
    interval = "hourly";             # Automatic snapshot frequency
    beforeRebuild = true;            # Snapshot before nixos-rebuild
    onUserLogin = true;              # Snapshot on user login
    
    # Automatic cleanup policies
    retentionPolicy = {
      enable = true;
      maxSnapshots = 50;             # Keep max 50 snapshots per branch
      maxAge = "30d";                # Remove snapshots older than 30 days
    };
  };
  
  # Live configuration management (NEW in Phase 2)
  configManagement = {
    enable = true;                   # Enable live config changes
    snapshotBeforeChange = true;     # Safety snapshot before changes
    reloadUserServices = true;       # Reload user systemd services
    customReloadCommand = "";        # Custom reload commands
  };
  
  # Safe rollback functionality (NEW in Phase 2)
  rollback = {
    enable = true;
    safetyChecks = true;             # Enable safety checks
    maxRollbackDepth = 10;           # Maximum rollback depth
  };
  
  # Enhanced XFCE integration
  xfce = {
    enable = true;                   # XFCE integration
    reloadOnRestore = true;          # Auto-reload after restore
    reloadOnChange = true;           # Auto-reload after config changes
    backupConfig = true;             # Backup XFCE config before changes
  };
  
  # Advanced storage configuration
  storage = {
    backend = "simple";              # Storage backend type
    retentionDays = 30;              # Snapshot retention period
    compressionLevel = 6;            # Compression level (0-9)
  };
  
  # Web interface (NEW in Phase 2)
  webInterface = {
    enable = false;                  # Enable web-based timeline GUI
    port = 8080;                     # Web interface port
    bindAddress = "127.0.0.1";       # Bind address
  };
  
  # Phase 3: Security, Audit, and Investigation Tools (NEW)
  security = {
    enable = true;                   # Enable security features
    
    # Security audit tools configuration
    auditTools = {
      enable = true;                 # Enable security audit tools
      systemIntegrity = true;        # System integrity monitoring tools
      logAnalysis = true;            # Log analysis and monitoring tools
      forensics = false;             # Forensics and investigation tools
    };
    
    # System hardening configuration
    hardening = {
      enable = true;                 # Enable system hardening
      firewall = true;               # Enhanced firewall configuration
      kernelHardening = true;        # Kernel security hardening
      userspace = true;              # Userspace security hardening
      networkSecurity = true;        # Network security hardening
    };
    
    # Security monitoring and alerting
    monitoring = {
      enable = true;                 # Enable security monitoring
      realTimeAlerts = false;        # Real-time security alerts
      logRetention = 90;             # Security log retention (days)
      automaticSnapshots = true;     # Create snapshots on security events
    };
  };
};
```

### Environment Variables

- `REWIND_CONFIG_DIR`: Override default config directory (`~/.rewind`)
- `REWIND_FORCE`: Skip confirmations (`1`, `true`, `yes`)
- `REWIND_DEBUG`: Enable debug output (`1`, `true`, `yes`)

---

## 🧪 Development Status

### Phase 1: ✅ Complete
- [x] Core CLI functionality
- [x] Timeline operations (list, branch, switch, restore)
- [x] NixOS module integration
- [x] XFCE desktop hooks
- [x] Basic documentation

### Phase 2: ✅ Complete
- [x] Enhanced CLI with stash/unstash functionality
- [x] Safe rollback with confirmation prompts and safety snapshots
- [x] Live configuration management without reboot
- [x] Advanced NixOS integration with systemd services
- [x] Enhanced XFCE integration with error recovery
- [x] Improved documentation and troubleshooting guides
- [x] End-to-end testing capabilities

### Phase 3: 🔐 Security, Audit, and Investigation Tools

**Complete security hardening and monitoring infrastructure:**

**Enhanced Security Tools:**
```bash
# Comprehensive security monitoring
./scripts/security-tools.sh monitor

# Real-time security monitoring (60s)
./scripts/security-tools.sh realtime

# Security compliance checklist
./scripts/security-tools.sh checklist

# Enhanced integrity checking (RKHunter, AIDE, ChkRootkit)
./scripts/security-tools.sh integrity-enhanced

# Advanced log analysis (Fail2Ban integration)
./scripts/security-tools.sh logs-enhanced

# Forensics environment preparation
./scripts/security-tools.sh forensics

# Generate comprehensive security report
./scripts/security-tools.sh report
```

**Security CLI Commands:**
```bash
# Security status and monitoring
rewind security --status

# Run security scan with automatic snapshots
rewind security --scan

# Show security audit trail
rewind security --audit

# Generate security report with timeline context
rewind security --report
```

**Pre-configured Security Tools (out-of-the-box):**
- **System Integrity**: RKHunter, ChkRootkit, AIDE, Lynis, ClamAV
- **Log Analysis**: Fail2Ban, Logwatch, Rsyslog with security forwarding
- **Access Control**: AppArmor with pre-configured profiles
- **Audit System**: Enhanced auditd with comprehensive rules
- **Forensics**: Sleuthkit, Autopsy, Volatility, Binwalk (optional)

**Automated Security Features:**
- **Real-time Monitoring**: Continuous security event detection
- **Security Checklist**: Automated compliance verification
- **Automatic Snapshots**: Timeline snapshots on security events  
- **Intrusion Prevention**: Fail2Ban with custom Rewind-OS rules
- **System Hardening**: Kernel parameters, firewall rules, sysctl tuning

### Coming Soon (Phase 4):
- [ ] Actual filesystem snapshot backends (Btrfs/ZFS)
- [ ] Web-based timeline GUI
- [ ] Enhanced timeline management
- [ ] Performance optimizations

See [PHASES.md](PHASES.md) for complete development roadmap.

---

## 🛠️ Development

### Running Tests

```bash
# Test CLI operations
python3 -m rewind.cli list
python3 -m rewind.cli snapshot "Test snapshot"
python3 -m rewind.cli list --snapshots
```

### Project Structure Overview

- **`rewind/`**: Core Python package with CLI and timeline logic
- **`scripts/`**: System integration scripts
- **`nix/`**: NixOS configuration and examples
- **Timeline Data**: Stored in `~/.rewind/` (development) or `/var/lib/rewind-os/` (production)

### Contributing

1. Test CLI functionality
2. Report issues and bugs
3. Improve documentation
4. Add support for other desktop environments
5. Optimize performance

---

## ⚠️ Disclaimer

Rewind OS is currently in Phase 1 development (foundational structure). The current implementation provides a working CLI for timeline management but does not yet perform actual system-level snapshots. Use in development environments for testing the interface and workflow.

---

## 🧙‍♂️ Future Goals

* Support for actual filesystem snapshots (Btrfs/ZFS)
* Web-based timeline GUI with visual interface
* Support for all major Linux distros (not just NixOS)
* Remote snapshot sync across machines
* AI-predicted rollback suggestions
* Complete ISO distribution

---

## 🧑‍💻 Lead Developer

**Vinoth** — Designer, Developer, Time Lord (≧▽≦)

**Assignee for Future Development**: @copilot - For automation and continuous improvements

---

## 📜 License

MIT License. Do whatever you want — but don't build a TVA clone.

---

## 🧪 Tech Stack

* **Base OS**: NixOS
* **File System**: Btrfs / ZFS
* **Snapshot Engine**: Time Stone (Python)
* **Video Timeline UI**: React + ffmpeg
* **Config Engine**: Nix Flakes
* **Security**: SHA-256, Encrypted Partitions, Audit Logs

---

## 📦 ISO Build (Coming Soon)

The full Rewind OS ISO will bundle:

* Preconfigured NixOS base
* Time Stone CLI + GUI
* All necessary systemd, snapshot hooks

### To Build ISO:

```bash
cd iso
./build.sh
```

---

## ⚠️ Disclaimer

Rewind OS is in early-stage development and not production ready. Use in virtual environments or test machines only. Privacy settings must be configured manually in current builds.

---

## 🧙‍♂️ Future Goals

* Support all major Linux distros (not just NixOS)
* Remote snapshot sync across machines
* Merge & diff system branches
* AI-predicted rollback suggestions
* CLI + GUI parity

---

## 🧑‍💻 Lead Developer

**Vinoth** — Designer, Developer, Time Lord (≧▽≦)

---

## 📜 License

MIT License. Do whatever you want — but don’t build a TVA clone.
