# Example NixOS Configuration with Rewind-OS Integration
#
# This is an example of how to integrate Rewind-OS into your NixOS configuration.
# Copy relevant sections to your /etc/nixos/configuration.nix file.

{ config, pkgs, ... }:

{
  imports = [
    # Include the Rewind-OS module
    ./rewind.nix
  ];

  # Enable Rewind-OS with comprehensive Phase 2 features
  services.rewind-os = {
    enable = true;
    
    # Configuration directory (default: /var/lib/rewind-os)
    configDir = "/var/lib/rewind-os";
    
    # Enhanced automatic snapshot configuration
    autoSnapshot = {
      enable = true;
      interval = "hourly";           # Create snapshots every hour
      beforeRebuild = true;          # Snapshot before nixos-rebuild
      onUserLogin = true;            # Snapshot on user login
      
      # Retention policy for automatic cleanup
      retentionPolicy = {
        enable = true;
        maxSnapshots = 50;           # Keep max 50 snapshots per branch
        maxAge = "30d";              # Remove snapshots older than 30 days
      };
    };
    
    # Live configuration management (Phase 2 feature)
    configManagement = {
      enable = true;                 # Enable live config changes
      snapshotBeforeChange = true;   # Safety snapshot before changes
      reloadUserServices = true;     # Reload user systemd services
      customReloadCommand = ''
        # Custom reload commands go here
        echo "Custom configuration reload completed"
      '';
    };
    
    # Safe rollback functionality (Phase 2 feature)
    rollback = {
      enable = true;
      safetyChecks = true;           # Enable safety checks
      maxRollbackDepth = 10;         # Maximum rollback depth
    };
    
    # Enhanced XFCE desktop integration
    xfce = {
      enable = true;                 # Enable if using XFCE
      reloadOnRestore = true;        # Auto-reload XFCE after restore
      reloadOnChange = true;         # Auto-reload XFCE after config changes
      backupConfig = true;           # Backup XFCE config before changes
    };
    
    # Advanced storage configuration
    storage = {
      backend = "simple";            # Options: btrfs, zfs, simple
      retentionDays = 30;            # Keep snapshots for 30 days
      compressionLevel = 6;          # Compression level (0-9)
    };
    
    # Optional web interface (Phase 2 feature)
    webInterface = {
      enable = false;                # Enable web-based timeline GUI
      port = 8080;                   # Web interface port
      bindAddress = "127.0.0.1";     # Bind to localhost only
    };
    
    # Phase 3: Security, Audit, and Investigation Tools
    security = {
      enable = true;                 # Enable security features
      
      # Security audit tools configuration
      auditTools = {
        enable = true;               # Enable security audit tools
        systemIntegrity = true;      # Enable system integrity monitoring (rkhunter, aide, etc.)
        logAnalysis = true;          # Enable log analysis tools (fail2ban, logwatch)
        forensics = false;           # Enable forensics tools (sleuthkit, volatility - advanced users)
      };
      
      # System hardening configuration
      hardening = {
        enable = true;               # Enable system hardening
        apparmor = true;             # Enable AppArmor mandatory access control
        firewall = true;             # Enhanced firewall configuration with iptables rules
        kernelHardening = true;      # Kernel security hardening parameters
        userspace = true;            # Userspace security hardening
        networkSecurity = true;      # Network security hardening (TCP syncookies, etc.)
        auditd = true;               # Enable audit daemon with enhanced rules
      };
      
      # Security monitoring and alerting
      monitoring = {
        enable = true;               # Enable security monitoring
        realTimeAlerts = false;      # Real-time security alerts (requires setup)
        logRetention = 90;           # Keep security logs for 90 days
        automaticSnapshots = true;   # Create snapshots on security events
        checklistVerification = true; # Enable automated security checklist verification
      };
    };
  };

  # Example system configuration that works well with Rewind-OS
  system.stateVersion = "23.11";
  
  # Boot configuration
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  
  # Networking
  networking.hostName = "rewind-nixos";
  networking.networkmanager.enable = true;
  
  # Desktop Environment (XFCE example)
  services.xserver = {
    enable = true;
    displayManager.lightdm.enable = true;
    desktopManager.xfce.enable = true;
  };
  
  # User configuration
  users.users.user = {
    isNormalUser = true;
    description = "Rewind User";
    extraGroups = [ 
      "networkmanager" 
      "wheel" 
      "rewind-os"  # Add user to rewind-os group for CLI access
    ];
  };
  
  # System packages that work well with Rewind-OS
  environment.systemPackages = with pkgs; [
    # Basic tools
    vim
    git
    wget
    curl
    
    # File system tools for snapshot backends
    btrfs-progs     # If using btrfs backend
    zfs             # If using zfs backend
    
    # Desktop tools
    firefox
    thunderbird
    libreoffice
    
    # Development tools
    vscode
    python3
    nodejs
    
    # System monitoring
    htop
    iotop
    nethogs
  ];
  
  # Services that integrate well with timeline management
  services.openssh.enable = true;
  services.printing.enable = true;
  
  # Automatic garbage collection (works with Rewind-OS retention)
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };
  
  # Firewall configuration
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ];  # SSH
  };
  
  # Audio
  sound.enable = true;
  hardware.pulseaudio.enable = true;
  
  # Example of environment variables for Rewind-OS
  environment.variables = {
    REWIND_CONFIG_DIR = "/var/lib/rewind-os";
  };
  
  # Additional systemd services that can trigger snapshots
  systemd.services.custom-app-snapshot = {
    description = "Create snapshot before important app changes";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.systemd}/bin/systemctl start rewind-auto-snapshot.service";
    };
    # This service can be called before deploying applications
  };
  
  # Example of file system configuration for snapshot backends
  # Uncomment the relevant section based on your choice:
  
  # For Btrfs backend (recommended for Phase 2):
  # fileSystems."/" = {
  #   device = "/dev/disk/by-label/nixos";
  #   fsType = "btrfs";
  #   options = [ "subvol=root" "compress=zstd" ];
  # };
  
  # For ZFS backend (advanced users):
  # boot.supportedFilesystems = [ "zfs" ];
  # networking.hostId = "12345678";  # Required for ZFS
  
  # Security settings that work well with timeline management
  security.sudo.enable = true;
  security.polkit.enable = true;
  
  # Example of how to create custom timeline triggers
  # This could be adapted for application-specific snapshots
  systemd.services.example-app-deploy = {
    description = "Example application deployment with snapshot";
    serviceConfig = {
      Type = "oneshot";
      ExecStartPre = "/run/current-system/sw/bin/rewind snapshot 'Before app deployment'";
      ExecStart = "/usr/bin/echo 'Deploy application here'";
      ExecStartPost = "/run/current-system/sw/bin/rewind snapshot 'After app deployment'";
    };
  };
  
  # Phase 2: Advanced configuration examples
  
  # Custom systemd service that integrates with Rewind-OS
  systemd.services.my-custom-service = {
    description = "Custom service with Rewind-OS integration";
    before = [ "rewind-auto-snapshot.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStartPre = "/run/current-system/sw/bin/rewind stash 'Before custom service'";
      ExecStart = "/usr/bin/echo 'Custom service logic here'";
      ExecStartPost = "/run/current-system/sw/bin/rewind snapshot 'After custom service'";
    };
  };
  
  # Example of integrating with application updates
  systemd.services.app-update-with-timeline = {
    description = "Application update with timeline integration";
    serviceConfig = {
      Type = "oneshot";
      ExecStartPre = [
        "/run/current-system/sw/bin/rewind snapshot 'Pre-app-update checkpoint'"
        "/run/current-system/sw/bin/rewind stash 'Stashing before update'"
      ];
      ExecStart = "/usr/bin/echo 'Update applications here'";
      ExecStartPost = [
        "/run/current-system/sw/bin/rewind snapshot 'Post-app-update checkpoint'"
        "/usr/bin/systemctl --user restart rewind-config-reload.service"
      ];
    };
  };
  
  # Environment configuration for better Rewind-OS integration
  environment.etc."rewind-os/config.json" = {
    text = builtins.toJSON {
      version = "0.2.0";
      features = {
        stash = true;
        safeRollback = true;
        liveConfigReload = true;
        webInterface = config.services.rewind-os.webInterface.enable;
      };
      integrations = {
        xfce = config.services.rewind-os.xfce.enable;
        systemd = true;
        nixos = true;
      };
    };
  };
}