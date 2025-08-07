# Rewind-OS NixOS Module
# 
# This module provides the core functionality for Rewind-OS timeline-based
# system state management integrated with NixOS configuration.

{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.rewind-os;
  
  rewindPackage = pkgs.python3Packages.buildPythonApplication {
    pname = "rewind-os";
    version = "0.1.0";
    
    src = ./.;
    
    propagatedBuildInputs = with pkgs.python3Packages; [
      # Add any Python dependencies here
    ];
    
    # Install the CLI script
    postInstall = ''
      mkdir -p $out/bin
      cp -r ${./rewind} $out/lib/python*/site-packages/
      
      # Create rewind CLI wrapper
      cat > $out/bin/rewind << EOF
#!/usr/bin/env python3
import sys
sys.path.insert(0, '$out/lib/python*/site-packages')
from rewind.cli import main
if __name__ == "__main__":
    main()
EOF
      chmod +x $out/bin/rewind
      
      # Install XFCE reload script
      mkdir -p $out/share/rewind-os/scripts
      cp ${./scripts/hook-xfce-reload.sh} $out/share/rewind-os/scripts/
      chmod +x $out/share/rewind-os/scripts/hook-xfce-reload.sh
      
      # Install systemd integration scripts
      mkdir -p $out/share/rewind-os/systemd
      
      # Pre-rebuild hook script
      cat > $out/share/rewind-os/systemd/pre-rebuild.sh << 'EOF'
#!/bin/bash
export REWIND_CONFIG_DIR="${cfg.configDir}"
echo "Creating pre-rebuild snapshot..."
${rewindPackage}/bin/rewind snapshot "Pre-rebuild snapshot ($(date))"
EOF
      chmod +x $out/share/rewind-os/systemd/pre-rebuild.sh
      
      # Config reload script
      cat > $out/share/rewind-os/systemd/config-reload.sh << 'EOF'
#!/bin/bash
export REWIND_CONFIG_DIR="${cfg.configDir}"
echo "Reloading configuration..."
if [ "${toString cfg.xfce.enable}" = "1" ]; then
    ${rewindPackage}/share/rewind-os/scripts/hook-xfce-reload.sh light
fi
# Add other desktop environment reloads here
systemctl --user reload-or-restart user.slice || true
EOF
      chmod +x $out/share/rewind-os/systemd/config-reload.sh
    '';
    
    meta = with lib; {
      description = "Timeline-based system state management for NixOS";
      homepage = "https://github.com/vinothvbt/Rewind-OS";
      license = licenses.mit;
      maintainers = [ "vinoth" ];
    };
  };

  # Configuration management script
  configReloadScript = pkgs.writeShellScript "rewind-config-reload" ''
    set -euo pipefail
    
    export REWIND_CONFIG_DIR="${cfg.configDir}"
    
    # Create snapshot before config change
    if [ "${toString cfg.configManagement.snapshotBeforeChange}" = "1" ]; then
        echo "Creating snapshot before configuration change..."
        ${rewindPackage}/bin/rewind snapshot "Pre-config change ($(date))"
    fi
    
    # Apply configuration changes
    echo "Applying configuration changes..."
    
    # Reload desktop environment if enabled
    if [ "${toString cfg.xfce.enable}" = "1" ] && [ "${toString cfg.xfce.reloadOnChange}" = "1" ]; then
        echo "Reloading XFCE environment..."
        ${rewindPackage}/share/rewind-os/scripts/hook-xfce-reload.sh light
    fi
    
    # Reload systemd user services
    if [ "${toString cfg.configManagement.reloadUserServices}" = "1" ]; then
        echo "Reloading user services..."
        systemctl --user daemon-reload || true
        systemctl --user restart user.slice || true
    fi
    
    # Custom config reload command
    ${cfg.configManagement.customReloadCommand}
    
    echo "Configuration reload completed."
  '';

in {
  options.services.rewind-os = {
    enable = mkEnableOption "Rewind-OS timeline-based system management";
    
    configDir = mkOption {
      type = types.str;
      default = "/var/lib/rewind-os";
      description = "Directory to store Rewind-OS configuration and timeline data";
    };
    
    autoSnapshot = {
      enable = mkEnableOption "Automatic snapshot creation";
      
      interval = mkOption {
        type = types.str;
        default = "hourly";
        description = "Interval for automatic snapshots (systemd timer format)";
      };
      
      beforeRebuild = mkOption {
        type = types.bool;
        default = true;
        description = "Create snapshot before nixos-rebuild operations";
      };
      
      onUserLogin = mkOption {
        type = types.bool;
        default = false;
        description = "Create snapshot on user login";
      };
      
      retentionPolicy = {
        enable = mkEnableOption "Automatic snapshot cleanup";
        
        maxSnapshots = mkOption {
          type = types.int;
          default = 50;
          description = "Maximum number of snapshots to keep per branch";
        };
        
        maxAge = mkOption {
          type = types.str;
          default = "30d";
          description = "Maximum age of snapshots to keep";
        };
      };
    };
    
    configManagement = {
      enable = mkEnableOption "Live configuration management without reboot";
      
      snapshotBeforeChange = mkOption {
        type = types.bool;
        default = true;
        description = "Create snapshot before applying configuration changes";
      };
      
      reloadUserServices = mkOption {
        type = types.bool;
        default = true;
        description = "Reload user systemd services after config changes";
      };
      
      customReloadCommand = mkOption {
        type = types.str;
        default = "";
        description = "Custom command to run after configuration changes";
      };
    };
    
    rollback = {
      enable = mkEnableOption "Safe rollback functionality";
      
      safetyChecks = mkOption {
        type = types.bool;
        default = true;
        description = "Enable safety checks before rollback operations";
      };
      
      maxRollbackDepth = mkOption {
        type = types.int;
        default = 10;
        description = "Maximum number of rollback operations to allow";
      };
    };
    
    xfce = {
      enable = mkEnableOption "XFCE integration for desktop reload";
      
      reloadOnRestore = mkOption {
        type = types.bool;
        default = true;
        description = "Automatically reload XFCE when restoring snapshots";
      };
      
      reloadOnChange = mkOption {
        type = types.bool;
        default = true;
        description = "Automatically reload XFCE when configuration changes";
      };
      
      backupConfig = mkOption {
        type = types.bool;
        default = true;
        description = "Backup XFCE configuration before changes";
      };
    };
    
    storage = {
      backend = mkOption {
        type = types.enum [ "btrfs" "zfs" "simple" ];
        default = "simple";
        description = "Storage backend for snapshots";
      };
      
      retentionDays = mkOption {
        type = types.int;
        default = 30;
        description = "Number of days to retain automatic snapshots";
      };
      
      compressionLevel = mkOption {
        type = types.int;
        default = 6;
        description = "Compression level for snapshots (0-9)";
      };
    };
    
    webInterface = {
      enable = mkEnableOption "Web-based timeline interface";
      
      port = mkOption {
        type = types.port;
        default = 8080;
        description = "Port for web interface";
      };
      
      bindAddress = mkOption {
        type = types.str;
        default = "127.0.0.1";
        description = "Bind address for web interface";
      };
    };
    
    # Phase 3: Security, Audit, and Investigation Tools
    security = {
      enable = mkEnableOption "Security, audit, and investigation tools";
      
      auditTools = {
        enable = mkEnableOption "Security audit tools integration";
        
        systemIntegrity = mkOption {
          type = types.bool;
          default = true;
          description = "Enable system integrity monitoring tools";
        };
        
        logAnalysis = mkOption {
          type = types.bool;
          default = true;
          description = "Enable log analysis and monitoring tools";
        };
        
        forensics = mkOption {
          type = types.bool;
          default = false;
          description = "Enable forensics and investigation tools";
        };
      };
      
      hardening = {
        enable = mkEnableOption "System hardening configuration";
        
        firewall = mkOption {
          type = types.bool;
          default = true;
          description = "Enable enhanced firewall configuration";
        };
        
        kernelHardening = mkOption {
          type = types.bool;
          default = true;
          description = "Enable kernel security hardening";
        };
        
        userspace = mkOption {
          type = types.bool;
          default = true;
          description = "Enable userspace security hardening";
        };
        
        networkSecurity = mkOption {
          type = types.bool;
          default = true;
          description = "Enable network security hardening";
        };
      };
      
      monitoring = {
        enable = mkEnableOption "Security monitoring and alerting";
        
        realTimeAlerts = mkOption {
          type = types.bool;
          default = false;
          description = "Enable real-time security alerts";
        };
        
        logRetention = mkOption {
          type = types.int;
          default = 90;
          description = "Number of days to retain security logs";
        };
        
        automaticSnapshots = mkOption {
          type = types.bool;
          default = true;
          description = "Create automatic snapshots on security events";
        };
      };
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ rewindPackage ];
    
    # Create system user for rewind-os
    users.users.rewind-os = {
      isSystemUser = true;
      group = "rewind-os";
      home = cfg.configDir;
      createHome = true;
      description = "Rewind-OS system user";
    };
    
    users.groups.rewind-os = {};
    
    # Ensure config directory exists with proper permissions
    systemd.tmpfiles.rules = [
      "d ${cfg.configDir} 0755 rewind-os rewind-os -"
      "d ${cfg.configDir}/snapshots 0755 rewind-os rewind-os -"
      "d ${cfg.configDir}/branches 0755 rewind-os rewind-os -"
      "d ${cfg.configDir}/stashes 0755 rewind-os rewind-os -"
      "d ${cfg.configDir}/backups 0755 rewind-os rewind-os -"
    ] ++ lib.optionals cfg.security.enable [
      "d ${cfg.configDir}/security-logs 0755 rewind-os rewind-os -"
      "d ${cfg.configDir}/security-reports 0755 rewind-os rewind-os -"
      "d ${cfg.configDir}/audit-trails 0755 rewind-os rewind-os -"
    ];
    
    # Auto-snapshot service
    systemd.services.rewind-auto-snapshot = mkIf cfg.autoSnapshot.enable {
      description = "Rewind-OS automatic snapshot creation";
      serviceConfig = {
        Type = "oneshot";
        User = "rewind-os";
        Group = "rewind-os";
        Environment = "REWIND_CONFIG_DIR=${cfg.configDir}";
        ExecStart = "${rewindPackage}/bin/rewind snapshot 'Automatic snapshot ($(date))'";
        WorkingDirectory = cfg.configDir;
      };
    };
    
    # Auto-snapshot timer
    systemd.timers.rewind-auto-snapshot = mkIf cfg.autoSnapshot.enable {
      description = "Timer for Rewind-OS automatic snapshots";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = cfg.autoSnapshot.interval;
        Persistent = true;
      };
    };
    
    # Cleanup service for old snapshots
    systemd.services.rewind-cleanup = mkIf cfg.autoSnapshot.retentionPolicy.enable {
      description = "Cleanup old Rewind-OS snapshots";
      serviceConfig = {
        Type = "oneshot";
        User = "rewind-os";
        Group = "rewind-os";
        Environment = "REWIND_CONFIG_DIR=${cfg.configDir}";
        ExecStart = pkgs.writeShellScript "rewind-cleanup" ''
          # This would implement cleanup logic based on retention policy
          echo "Cleaning up old snapshots (max: ${toString cfg.autoSnapshot.retentionPolicy.maxSnapshots}, age: ${cfg.autoSnapshot.retentionPolicy.maxAge})"
          # TODO: Implement actual cleanup logic
        '';
        WorkingDirectory = cfg.configDir;
      };
    };
    
    # Cleanup timer
    systemd.timers.rewind-cleanup = mkIf cfg.autoSnapshot.retentionPolicy.enable {
      description = "Timer for Rewind-OS snapshot cleanup";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
      };
    };
    
    # Pre-rebuild snapshot service
    systemd.services.rewind-pre-rebuild = mkIf cfg.autoSnapshot.beforeRebuild {
      description = "Create Rewind-OS snapshot before nixos-rebuild";
      serviceConfig = {
        Type = "oneshot";
        User = "rewind-os";
        Group = "rewind-os";
        Environment = "REWIND_CONFIG_DIR=${cfg.configDir}";
        ExecStart = "${rewindPackage}/share/rewind-os/systemd/pre-rebuild.sh";
        WorkingDirectory = cfg.configDir;
      };
      before = [ "nixos-rebuild.service" ];
      wantedBy = [ "nixos-rebuild.service" ];
    };
    
    # Configuration reload service
    systemd.services.rewind-config-reload = mkIf cfg.configManagement.enable {
      description = "Rewind-OS configuration reload service";
      serviceConfig = {
        Type = "oneshot";
        User = "root";
        Environment = "REWIND_CONFIG_DIR=${cfg.configDir}";
        ExecStart = "${configReloadScript}";
        WorkingDirectory = cfg.configDir;
      };
    };
    
    # User login snapshot service
    systemd.services.rewind-user-login = mkIf cfg.autoSnapshot.onUserLogin {
      description = "Create snapshot on user login";
      serviceConfig = {
        Type = "oneshot";
        User = "rewind-os";
        Group = "rewind-os";
        Environment = "REWIND_CONFIG_DIR=${cfg.configDir}";
        ExecStart = "${rewindPackage}/bin/rewind snapshot 'User login snapshot ($(date))'";
        WorkingDirectory = cfg.configDir;
      };
    };
    
    # XFCE integration
    environment.etc."rewind-os/xfce-reload" = mkIf cfg.xfce.enable {
      source = "${rewindPackage}/share/rewind-os/scripts/hook-xfce-reload.sh";
      mode = "0755";
    };
    
    # Add rewind command to system PATH and create useful aliases
    environment.shellAliases = {
      "rewind-status" = "${rewindPackage}/bin/rewind info";
      "rewind-snap" = "${rewindPackage}/bin/rewind snapshot";
      "rewind-list" = "${rewindPackage}/bin/rewind list";
      "rewind-stash" = "${rewindPackage}/bin/rewind stash";
    };
    
    # Environment variables
    environment.variables = {
      REWIND_CONFIG_DIR = cfg.configDir;
    };
    
    # Security: Add rewind-os group to necessary system groups for snapshot functionality
    users.users.rewind-os.extraGroups = [ "disk" ];
    
    # Polkit rules for rewind operations
    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
          if (action.id.indexOf("org.freedesktop.systemd1.manage-units") == 0 &&
              action.lookup("unit").indexOf("rewind-") == 0 &&
              subject.user == "rewind-os") {
              return polkit.Result.YES;
          }
      });
      
      // Allow rewind-os user to reload configuration
      polkit.addRule(function(action, subject) {
          if (action.id == "org.freedesktop.systemd1.reload-daemon" &&
              subject.user == "rewind-os") {
              return polkit.Result.YES;
          }
      });
    '';
    
    # Systemd path units for watching configuration changes
    systemd.paths.rewind-config-watch = mkIf cfg.configManagement.enable {
      description = "Watch for NixOS configuration changes";
      pathConfig = {
        PathModified = "/etc/nixos/configuration.nix";
        Unit = "rewind-config-reload.service";
      };
      wantedBy = [ "multi-user.target" ];
    };
    
    # Web interface service (optional)
    systemd.services.rewind-web = mkIf cfg.webInterface.enable {
      description = "Rewind-OS web interface";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "simple";
        User = "rewind-os";
        Group = "rewind-os";
        Environment = [
          "REWIND_CONFIG_DIR=${cfg.configDir}"
          "REWIND_WEB_PORT=${toString cfg.webInterface.port}"
          "REWIND_WEB_BIND=${cfg.webInterface.bindAddress}"
        ];
        ExecStart = "${rewindPackage}/bin/rewind-web";
        Restart = "always";
        RestartSec = 5;
        WorkingDirectory = cfg.configDir;
      };
    };
    
    # Firewall rule for web interface
    networking.firewall.allowedTCPPorts = mkIf cfg.webInterface.enable [ cfg.webInterface.port ];
    
    # Phase 3: Security, Audit, and Investigation Tools Configuration
    
    # Security audit tools packages
    environment.systemPackages = mkIf cfg.security.enable (with pkgs;
      lib.optionals cfg.security.auditTools.systemIntegrity [
        aide                    # Advanced Intrusion Detection Environment
        chkrootkit             # Rootkit detection
        rkhunter               # Rootkit Hunter
        lynis                  # Security auditing tool
        clamav                 # Antivirus scanner
        
      ] ++ lib.optionals cfg.security.auditTools.logAnalysis [
        logwatch               # Log analysis and reporting
        fail2ban               # Intrusion prevention system
        rsyslog                # Enhanced syslog
        
      ] ++ lib.optionals cfg.security.auditTools.forensics [
        sleuthkit              # Digital forensics toolkit
        autopsy                # Digital forensics platform
        volatility3            # Memory forensics framework
        binwalk                # Binary analysis tool
    ]);
    
    # Security hardening configuration
    boot.kernelParams = mkIf (cfg.security.enable && cfg.security.hardening.kernelHardening) [
      # Kernel hardening parameters
      "slab_nomerge"           # Prevent slab merging
      "slub_debug=FZP"         # Enable SLUB debugging
      "page_poison=1"          # Enable page poisoning
      "vsyscall=none"          # Disable vsyscalls
      "debugfs=off"            # Disable debugfs
      "oops=panic"             # Panic on oops
      "module.sig_enforce=1"   # Enforce module signatures
    ];
    
    # Enhanced firewall configuration
    networking.firewall = mkIf (cfg.security.enable && cfg.security.hardening.firewall) {
      enable = true;
      allowPing = false;
      logReversePathDrops = true;
      logRefusedConnections = true;
      logRefusedPackets = false;
      logRefusedUnicastsOnly = false;
    };
    
    # System hardening via sysctl
    boot.kernel.sysctl = mkIf (cfg.security.enable && cfg.security.hardening.kernelHardening) {
      # Network security
      "net.ipv4.ip_forward" = 0;
      "net.ipv4.conf.all.accept_redirects" = 0;
      "net.ipv4.conf.default.accept_redirects" = 0;
      "net.ipv4.conf.all.secure_redirects" = 0;
      "net.ipv4.conf.default.secure_redirects" = 0;
      "net.ipv4.conf.all.send_redirects" = 0;
      "net.ipv4.conf.default.send_redirects" = 0;
      "net.ipv4.conf.all.accept_source_route" = 0;
      "net.ipv4.conf.default.accept_source_route" = 0;
      "net.ipv4.conf.all.log_martians" = 1;
      "net.ipv4.conf.default.log_martians" = 1;
      "net.ipv4.icmp_echo_ignore_broadcasts" = 1;
      "net.ipv4.icmp_ignore_bogus_error_responses" = 1;
      "net.ipv4.tcp_syncookies" = 1;
      
      # Memory protection
      "kernel.dmesg_restrict" = 1;
      "kernel.kptr_restrict" = 2;
      "kernel.yama.ptrace_scope" = 2;
      "vm.mmap_min_addr" = 65536;
      
      # File system security
      "fs.protected_hardlinks" = 1;
      "fs.protected_symlinks" = 1;
      "fs.suid_dumpable" = 0;
    };
    
    # Security monitoring services
    systemd.services.rewind-security-monitor = mkIf (cfg.security.enable && cfg.security.monitoring.enable) {
      description = "Rewind-OS security monitoring service";
      serviceConfig = {
        Type = "oneshot";
        User = "rewind-os";
        Group = "rewind-os";
        Environment = "REWIND_CONFIG_DIR=${cfg.configDir}";
        ExecStart = pkgs.writeShellScript "security-monitor" ''
          # Security monitoring script
          echo "Running security monitoring checks..."
          
          # Check for security events and create snapshots if needed
          if [ "${toString cfg.security.monitoring.automaticSnapshots}" = "1" ]; then
            # Create security event snapshot
            ${rewindPackage}/bin/rewind snapshot "Security check ($(date))"
          fi
          
          # Log security status
          mkdir -p ${cfg.configDir}/security-logs
          echo "$(date): Security monitoring completed" >> ${cfg.configDir}/security-logs/security.log
          
          # TODO: Implement actual security monitoring logic
          # - Check system integrity
          # - Analyze logs for suspicious activity
          # - Monitor file system changes
          # - Check for unauthorized access attempts
        '';
        WorkingDirectory = cfg.configDir;
      };
    };
    
    # Security monitoring timer
    systemd.timers.rewind-security-monitor = mkIf (cfg.security.enable && cfg.security.monitoring.enable) {
      description = "Timer for Rewind-OS security monitoring";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "hourly";
        Persistent = true;
      };
    };
    
    # Security log rotation service
    systemd.services.rewind-security-log-cleanup = mkIf (cfg.security.enable && cfg.security.monitoring.enable) {
      description = "Cleanup old Rewind-OS security logs";
      serviceConfig = {
        Type = "oneshot";
        User = "rewind-os";
        Group = "rewind-os";
        Environment = "REWIND_CONFIG_DIR=${cfg.configDir}";
        ExecStart = pkgs.writeShellScript "security-log-cleanup" ''
          # Clean up security logs older than retention period
          find ${cfg.configDir}/security-logs -name "*.log" -mtime +${toString cfg.security.monitoring.logRetention} -delete || true
          echo "$(date): Security log cleanup completed" >> ${cfg.configDir}/security-logs/cleanup.log
        '';
        WorkingDirectory = cfg.configDir;
      };
    };
    
    # Security log cleanup timer
    systemd.timers.rewind-security-log-cleanup = mkIf (cfg.security.enable && cfg.security.monitoring.enable) {
      description = "Timer for security log cleanup";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
      };
    };
    
    # Enhanced polkit rules for security tools
    security.polkit.extraConfig = mkIf cfg.security.enable ''
      // Allow rewind-os user to run security monitoring tools
      polkit.addRule(function(action, subject) {
          if (action.id.indexOf("org.freedesktop.systemd1.manage-units") == 0 &&
              action.lookup("unit").indexOf("rewind-security") == 0 &&
              subject.user == "rewind-os") {
              return polkit.Result.YES;
          }
      });
      
      // Allow security audit tools access
      polkit.addRule(function(action, subject) {
          if (action.id == "org.freedesktop.systemd1.start-unit" &&
              subject.user == "rewind-os" &&
              (action.lookup("unit") == "rewind-security-monitor.service" ||
               action.lookup("unit") == "rewind-security-log-cleanup.service")) {
              return polkit.Result.YES;
          }
      });
    '';
    
    # Fail2ban configuration for intrusion prevention
    services.fail2ban = mkIf (cfg.security.enable && cfg.security.auditTools.logAnalysis) {
      enable = true;
      maxretry = 3;
      bantime = "1h";
      
      # Create custom jail for Rewind-OS security events
      jails.rewind-security = ''
        enabled = true
        filter = rewind-security
        logpath = ${cfg.configDir}/security-logs/security.log
        bantime = 3600
        findtime = 600
        maxretry = 5
      '';
    };
    
    # Rsyslog configuration for enhanced logging
    services.rsyslog = mkIf (cfg.security.enable && cfg.security.auditTools.logAnalysis) {
      enable = true;
      extraConfig = ''
        # Forward security events to Rewind-OS security log
        if $programname startswith 'rewind' then {
          action(type="omfile" file="${cfg.configDir}/security-logs/rewind-system.log")
          stop
        }
        
        # Log authentication events
        auth,authpriv.*                 ${cfg.configDir}/security-logs/auth.log
        
        # Log kernel messages
        kern.*                          ${cfg.configDir}/security-logs/kernel.log
      '';
    };
    
    # ClamAV antivirus configuration
    services.clamav = mkIf (cfg.security.enable && cfg.security.auditTools.systemIntegrity) {
      daemon.enable = true;
      updater.enable = true;
      updater.frequency = 12; # Update twice daily
    };
  };
}