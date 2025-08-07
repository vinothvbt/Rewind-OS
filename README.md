# 🌀 Rewind OS - The Git of Operating Systems

Rewind OS is a next-generation Linux-based operating system designed for complete time manipulation of your system. Inspired by the concepts of version control (like Git) and powered by the robustness of NixOS, Rewind OS enables you to travel back and forth through time — capturing, auditing, and restoring system states as easily as browsing a video timeline.

---

## 🔥 Key Features

### 🔁 Time Travel (Back & Forth)

* Instantly rewind to any system state with second-level precision.
* Move forward in time if a new branch is restored from an old state.
* Inspired by Marvel's Time Stone — but in real Linux.

### 🧠 Intelligent Snapshot System

* Powered by Btrfs/ZFS with delta compression.
* Snapshots taken automatically based on user actions, updates, or on demand.
* Each snapshot is hashed (SHA-256) and linked to a timeline.

### 📼 Video-based GUI Rollback

* See the system as it was at each point in time.
* Click on any second of the timeline video to restore that exact state.
* Interactive branch map allows navigating between forks of system history.

### 🔐 Security & Privacy First

* Selective exclusions for private activity (e.g., incognito sessions, media viewing).
* Encrypted snapshots with biometric/pin unlock.
* Auditable logs for trusted rollback.

### 📦 NixOS-Powered Configuration Engine

* Declarative, reproducible system config using Nix.
* Changes in GUI generate Nix code under-the-hood.
* No need to learn Nix — the system learns your changes.

### 🧬 Git-Like Branching Engine

* Every change creates a new timeline branch.
* Switch between system states like switching Git branches.
* Merge branches or discard experiments without fear.

---

## 📁 Project Structure

```
rewind-os/
├── gui/                  # Rewind Timeline GUI
├── timestone/            # CLI snapshot + rollback engine
├── system-config-gen/    # Nix config generator from GUI actions
├── branch-manager/       # Git-like branch engine
├── recorder/             # Background video + state recorder
└── iso/                  # ISO build pipeline
```

---

## 💻 Installation & Build (Dev Preview)

### Prerequisites:

* Linux distro (NixOS recommended)
* Python 3.11+
* Btrfs or ZFS enabled
* Git, systemd

### Step 1: Install Nix

```bash
curl -L https://nixos.org/nix/install | sh
```

### Step 2: Clone Repo

```bash
git clone https://github.com/rewind-os/rewind-os.git
cd rewind-os
```

### Step 3: Launch Time Stone CLI

```bash
cd timestone
sudo python3 main.py --init
```

### Step 4: Launch GUI (Experimental)

```bash
cd gui
npm install && npm start
```

---

## 🔧 Usage

### Create Snapshot:

```bash
rewindctl snapshot "Installed VSCode"
```

### List Snapshots:

```bash
rewindctl list
```

### Rewind to Snapshot:

```bash
rewindctl rewind <snapshot-id>
```

### Launch Video Rollback:

```bash
rewind-gui
```

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
