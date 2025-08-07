# Rewind-OS Troubleshooting Guide

This guide covers common issues and solutions for Rewind-OS Phase 2.

## Table of Contents

- [Installation Issues](#installation-issues)
- [CLI Problems](#cli-problems)
- [Timeline Operations](#timeline-operations)
- [Stash Management](#stash-management)
- [NixOS Integration](#nixos-integration)
- [XFCE Desktop Issues](#xfce-desktop-issues)
- [Configuration Problems](#configuration-problems)
- [Performance Issues](#performance-issues)
- [Emergency Recovery](#emergency-recovery)

---

## Installation Issues

### Problem: Module import errors
```
ModuleNotFoundError: No module named 'rewind'
```

**Solution:**
1. Ensure you're running from the correct directory:
   ```bash
   cd /path/to/Rewind-OS
   python3 -m rewind.cli --help
   ```

2. Check Python path:
   ```bash
   export PYTHONPATH="/path/to/Rewind-OS:$PYTHONPATH"
   ```

### Problem: Permission denied errors
```
PermissionError: [Errno 13] Permission denied: '/var/lib/rewind-os'
```

**Solution:**
1. Check if you're in the `rewind-os` group:
   ```bash
   groups $USER | grep rewind-os
   ```

2. Add yourself to the group:
   ```bash
   sudo usermod -a -G rewind-os $USER
   ```

3. Set custom config directory:
   ```bash
   export REWIND_CONFIG_DIR="$HOME/.rewind"
   ```

---

## CLI Problems

### Problem: Command not found
```
bash: rewind: command not found
```

**Solution:**
1. Use the full Python module path:
   ```bash
   python3 -m rewind.cli [command]
   ```

2. Create an alias in your shell:
   ```bash
   alias rewind='python3 -m rewind.cli'
   ```

3. For NixOS systems, ensure the module is properly installed.

### Problem: CLI hangs or freezes

**Solution:**
1. Check for background processes:
   ```bash
   ps aux | grep rewind
   ```

2. Force kill if necessary:
   ```bash
   pkill -f rewind
   ```

3. Enable debug mode:
   ```bash
   REWIND_DEBUG=1 python3 -m rewind.cli [command]
   ```

---

## Timeline Operations

### Problem: Snapshot creation fails
```
Error: Failed to create snapshot
```

**Solution:**
1. Check disk space:
   ```bash
   df -h ~/.rewind
   ```

2. Verify permissions:
   ```bash
   ls -la ~/.rewind
   ```

3. Check configuration:
   ```bash
   python3 -m rewind.cli info
   ```

### Problem: Cannot restore snapshot
```
Failed to restore snapshot 'snap_xxx' (doesn't exist?)
```

**Solution:**
1. List available snapshots:
   ```bash
   python3 -m rewind.cli list --snapshots
   ```

2. Check snapshot details:
   ```bash
   python3 -m rewind.cli info snap_xxx
   ```

3. Verify branch context:
   ```bash
   python3 -m rewind.cli list
   ```

### Problem: Branch switching fails
```
Failed to switch to branch 'xxx' (doesn't exist?)
```

**Solution:**
1. List available branches:
   ```bash
   python3 -m rewind.cli list
   ```

2. Create the branch if it doesn't exist:
   ```bash
   python3 -m rewind.cli branch xxx "Description"
   ```

---

## Stash Management

### Problem: Stash apply fails
```
Failed to apply stash (no stashes available?)
```

**Solution:**
1. Check available stashes:
   ```bash
   python3 -m rewind.cli list --stashes
   ```

2. Create a stash first:
   ```bash
   python3 -m rewind.cli stash "Test stash"
   ```

### Problem: Cannot drop stash
```
Failed to drop stash (no stashes available?)
```

**Solution:**
1. Verify stash exists:
   ```bash
   python3 -m rewind.cli list --stashes
   ```

2. Use specific stash ID:
   ```bash
   python3 -m rewind.cli stash --drop stash_xxx
   ```

---

## NixOS Integration

### Problem: Systemd services not starting
```
Failed to start rewind-auto-snapshot.service
```

**Solution:**
1. Check service status:
   ```bash
   systemctl status rewind-auto-snapshot.service
   ```

2. View logs:
   ```bash
   journalctl -u rewind-auto-snapshot.service
   ```

3. Restart service:
   ```bash
   sudo systemctl restart rewind-auto-snapshot.service
   ```

### Problem: Pre-rebuild snapshots not created

**Solution:**
1. Verify configuration:
   ```nix
   services.rewind-os.autoSnapshot.beforeRebuild = true;
   ```

2. Check service dependency:
   ```bash
   systemctl list-dependencies nixos-rebuild.service
   ```

3. Manual pre-rebuild snapshot:
   ```bash
   sudo systemctl start rewind-pre-rebuild.service
   ```

---

## XFCE Desktop Issues

### Problem: Desktop reload fails
```
ERROR: Failed to start XFCE panel
```

**Solution:**
1. Check XFCE processes:
   ```bash
   ./scripts/hook-xfce-reload.sh status
   ```

2. Try smart reload:
   ```bash
   ./scripts/hook-xfce-reload.sh smart
   ```

3. Manual component restart:
   ```bash
   ./scripts/hook-xfce-reload.sh panel
   ./scripts/hook-xfce-reload.sh desktop
   ```

### Problem: XFCE configuration corruption

**Solution:**
1. Check for backups:
   ```bash
   ls ~/.rewind/xfce-backups/
   ```

2. Use recovery mode:
   ```bash
   ./scripts/hook-xfce-reload.sh recovery
   ```

3. Validate configuration:
   ```bash
   ./scripts/hook-xfce-reload.sh validate
   ```

### Problem: Display connection issues
```
Cannot connect to X11 display
```

**Solution:**
1. Check DISPLAY variable:
   ```bash
   echo $DISPLAY
   ```

2. Test X11 connection:
   ```bash
   xset q
   ```

3. Restart X11 session if necessary.

---

## Configuration Problems

### Problem: Live config reload fails

**Solution:**
1. Check configuration service:
   ```bash
   systemctl status rewind-config-reload.service
   ```

2. Manual config reload:
   ```bash
   sudo systemctl start rewind-config-reload.service
   ```

3. Check for syntax errors in NixOS config:
   ```bash
   sudo nixos-rebuild dry-build
   ```

### Problem: Retention policy not working

**Solution:**
1. Check cleanup service:
   ```bash
   systemctl status rewind-cleanup.service
   ```

2. Manual cleanup:
   ```bash
   sudo systemctl start rewind-cleanup.service
   ```

3. Verify configuration:
   ```nix
   services.rewind-os.autoSnapshot.retentionPolicy.enable = true;
   ```

---

## Performance Issues

### Problem: Slow snapshot operations

**Solution:**
1. Check disk I/O:
   ```bash
   iotop
   ```

2. Monitor disk space:
   ```bash
   du -sh ~/.rewind
   ```

3. Enable compression:
   ```nix
   services.rewind-os.storage.compressionLevel = 6;
   ```

### Problem: High memory usage

**Solution:**
1. Check running processes:
   ```bash
   ps aux | grep rewind | sort -k4 -nr
   ```

2. Reduce retention:
   ```nix
   services.rewind-os.autoSnapshot.retentionPolicy.maxSnapshots = 25;
   ```

---

## Emergency Recovery

### Problem: System becomes unbootable after restore

**Solution:**
1. Boot from NixOS installer or rescue media.

2. Mount the system:
   ```bash
   sudo mount /dev/sdaX /mnt
   ```

3. Access Rewind-OS data:
   ```bash
   ls /mnt/var/lib/rewind-os/
   ```

4. Use previous NixOS generation:
   ```bash
   sudo nixos-rebuild boot --rollback
   ```

### Problem: Complete timeline corruption

**Solution:**
1. Backup current data:
   ```bash
   cp -r ~/.rewind ~/.rewind.backup
   ```

2. Reset timeline:
   ```bash
   rm ~/.rewind/timeline.json
   python3 -m rewind.cli list  # This will recreate the timeline
   ```

3. Restore from system backup if available.

### Problem: Cannot access CLI at all

**Solution:**
1. Check Python installation:
   ```bash
   python3 --version
   ```

2. Try alternative Python:
   ```bash
   python -m rewind.cli --help
   ```

3. Direct execution:
   ```bash
   cd /path/to/Rewind-OS
   python3 rewind/cli.py --help
   ```

---

## Getting Help

### Debug Information Collection

When reporting issues, please provide:

1. **System Information:**
   ```bash
   uname -a
   python3 --version
   nixos-version  # If on NixOS
   ```

2. **Rewind-OS Status:**
   ```bash
   python3 -m rewind.cli info
   ```

3. **Log Files:**
   ```bash
   cat ~/.rewind/xfce-reload.log
   cat ~/.rewind/xfce-errors.log
   journalctl -u rewind-auto-snapshot.service
   ```

4. **Configuration:**
   ```bash
   cat /etc/nixos/configuration.nix | grep -A 20 rewind-os
   ```

### Enable Verbose Logging

For debugging, enable verbose output:

```bash
export REWIND_DEBUG=1
export REWIND_CONFIG_DIR="$HOME/.rewind"
python3 -m rewind.cli [command] 2>&1 | tee debug.log
```

### Community Support

- **GitHub Issues**: Report bugs and feature requests
- **Documentation**: Check README.md and PHASES.md
- **Examples**: Review nix/example.nix for configuration templates

---

## Known Issues

### Phase 2 Limitations

1. **Filesystem Snapshots**: Currently only metadata snapshots are supported. Actual filesystem snapshots (Btrfs/ZFS) are planned for Phase 3.

2. **Web Interface**: The web interface option is present but not yet implemented.

3. **Cross-Platform**: Currently optimized for NixOS with XFCE. Other distributions and desktop environments have limited support.

### Workarounds

1. **Non-NixOS Systems**: Use manual CLI operations instead of systemd integration.

2. **Non-XFCE Desktops**: Disable XFCE integration and implement custom reload scripts.

3. **Limited Storage**: Use retention policies and compression to manage disk usage.

---

*This troubleshooting guide is continuously updated. If you encounter issues not covered here, please report them on the project repository.*