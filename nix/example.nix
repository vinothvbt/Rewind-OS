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

  # Enable Rewind-OS with recommended settings
  services.rewind-os = {
    enable = true;
    
    # Configuration directory (default: /var/lib/rewind-os)
    configDir = "/var/lib/rewind-os";
    
    # Automatic snapshot configuration
    autoSnapshot = {
      enable = true;
      interval = "hourly";           # Create snapshots every hour
      beforeRebuild = true;          # Snapshot before nixos-rebuild
    };
    
    # XFCE desktop integration
    xfce = {
      enable = true;                 # Enable if using XFCE
      reloadOnRestore = true;        # Auto-reload XFCE after restore
    };
    
    # Storage configuration
    storage = {
      backend = "simple";            # Options: btrfs, zfs, simple
      retentionDays = 30;            # Keep snapshots for 30 days
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
  
  # For Btrfs backend:
  # fileSystems."/" = {
  #   device = "/dev/disk/by-label/nixos";
  #   fsType = "btrfs";
  #   options = [ "subvol=root" "compress=zstd" ];
  # };
  
  # For ZFS backend:
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
}