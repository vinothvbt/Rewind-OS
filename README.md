# 🌀 Rewind OS - The Git of Operating Systems

Rewind OS is a next-generation Linux-based operating system designed for complete time manipulation of your system. Inspired by the concepts of version control (like Git) and powered by the robustness of NixOS, Rewind OS enables you to travel back and forth through time — capturing, auditing, and restoring system states as easily as browsing a video timeline.

**Current Status**: Phase 1 Implementation - Foundational CLI and NixOS integration

---

## 🔥 Key Features

### 🔁 Time Travel (Back & Forth)

* Instantly rewind to any system state with timeline precision.
* Move forward in time if a new branch is restored from an old state.
* Inspired by Marvel's Time Stone — but in real Linux.

### 🧠 Intelligent Snapshot System

* Timeline-based snapshot management with git-like branching.
* Snapshots taken automatically based on user actions, updates, or on demand.
* Each snapshot is tracked and linked to a timeline branch.

### 🧬 Git-Like Branching Engine

* Every change creates a new timeline branch.
* Switch between system states like switching Git branches.
* Merge branches or discard experiments without fear.

### 📦 NixOS-Powered Configuration Engine

* Declarative, reproducible system config using Nix.
* Integrated with NixOS rebuild process.
* Automatic snapshots before system changes.

### 🔐 Desktop Integration

* XFCE desktop environment integration.
* Automatic desktop reload after state changes.
* Configuration backup and restore.

---

## 📁 Project Structure

```
rewind-os/
├── rewind/                 # Core Python package
│   ├── __init__.py        # Package initialization
│   ├── cli.py             # Command-line interface
│   └── timeline.py        # Timeline operations
├── scripts/               # System integration scripts
│   └── hook-xfce-reload.sh # XFCE reload script
├── nix/                   # NixOS configuration
│   ├── rewind.nix         # Main NixOS module
│   └── example.nix        # Example configuration
├── README.md              # This file
└── PHASES.md              # Development roadmap
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

**Restore to a snapshot**:
```bash
python3 -m rewind.cli restore snap_1234567890
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

**View help for any command**:
```bash
python3 -m rewind.cli --help
python3 -m rewind.cli snapshot --help
```

### XFCE Integration

**Manual desktop reload**:
```bash
./scripts/hook-xfce-reload.sh full
```

**Lightweight refresh**:
```bash
./scripts/hook-xfce-reload.sh light
```

**Backup XFCE configuration**:
```bash
./scripts/hook-xfce-reload.sh backup
```

---

## ⚙️ Configuration

### NixOS Module Options

```nix
services.rewind-os = {
  enable = true;
  configDir = "/var/lib/rewind-os";  # Storage location
  
  autoSnapshot = {
    enable = true;
    interval = "hourly";             # Automatic snapshot frequency
    beforeRebuild = true;            # Snapshot before nixos-rebuild
  };
  
  xfce = {
    enable = true;                   # XFCE integration
    reloadOnRestore = true;          # Auto-reload after restore
  };
  
  storage = {
    backend = "simple";              # Storage backend type
    retentionDays = 30;              # Snapshot retention period
  };
};
```

### Environment Variables

- `REWIND_CONFIG_DIR`: Override default config directory (`~/.rewind`)

---

## 🧪 Development Status

### Phase 1: ✅ Complete
- [x] Core CLI functionality
- [x] Timeline operations (list, branch, switch, restore)
- [x] NixOS module integration
- [x] XFCE desktop hooks
- [x] Basic documentation

### Coming Soon (Phase 2):
- [ ] Actual filesystem snapshot backends (Btrfs/ZFS)
- [ ] Enhanced timeline management
- [ ] Automated testing suite
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
