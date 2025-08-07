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
    '';
    
    meta = with lib; {
      description = "Timeline-based system state management for NixOS";
      homepage = "https://github.com/vinothvbt/Rewind-OS";
      license = licenses.mit;
      maintainers = [ "vinoth" ];
    };
  };

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
    };
    
    xfce = {
      enable = mkEnableOption "XFCE integration for desktop reload";
      
      reloadOnRestore = mkOption {
        type = types.bool;
        default = true;
        description = "Automatically reload XFCE when restoring snapshots";
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
    ];
    
    # Auto-snapshot service
    systemd.services.rewind-auto-snapshot = mkIf cfg.autoSnapshot.enable {
      description = "Rewind-OS automatic snapshot creation";
      serviceConfig = {
        Type = "oneshot";
        User = "rewind-os";
        Group = "rewind-os";
        ExecStart = "${rewindPackage}/bin/rewind snapshot 'Automatic snapshot'";
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
    
    # Pre-rebuild snapshot service
    systemd.services.rewind-pre-rebuild = mkIf cfg.autoSnapshot.beforeRebuild {
      description = "Create Rewind-OS snapshot before nixos-rebuild";
      serviceConfig = {
        Type = "oneshot";
        User = "rewind-os";
        Group = "rewind-os";
        ExecStart = "${rewindPackage}/bin/rewind snapshot 'Pre-rebuild snapshot'";
        WorkingDirectory = cfg.configDir;
      };
      before = [ "nixos-rebuild.service" ];
      wantedBy = [ "nixos-rebuild.service" ];
    };
    
    # XFCE integration
    environment.etc."rewind-os/xfce-reload" = mkIf cfg.xfce.enable {
      source = "${rewindPackage}/share/rewind-os/scripts/hook-xfce-reload.sh";
      mode = "0755";
    };
    
    # Add rewind command to system PATH
    environment.shellAliases = {
      "rewind-status" = "${rewindPackage}/bin/rewind list";
      "rewind-snap" = "${rewindPackage}/bin/rewind snapshot";
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
    '';
  };
}