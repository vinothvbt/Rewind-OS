# Phase 3: Security, Audit, and Investigation Tools - Complete Documentation

## Overview

Phase 3 of Rewind-OS introduces comprehensive security, audit, and investigation tools that integrate seamlessly with the timeline-based system state management. All security tools are pre-configured and work "out of the box" with intelligent defaults.

## Features Implemented

### 1. Integrated Security Audit Tools

#### System Integrity Monitoring
- **RKHunter**: Rootkit detection with pre-configured settings
- **ChkRootkit**: Secondary rootkit detection
- **AIDE**: Advanced Intrusion Detection Environment for file integrity
- **Lynis**: Comprehensive security auditing
- **ClamAV**: Antivirus scanning with automatic updates

#### Log Analysis and Monitoring
- **Fail2Ban**: Intrusion prevention system with custom Rewind-OS jail
- **Logwatch**: Automated log analysis and reporting
- **Rsyslog**: Enhanced logging with security event forwarding

#### Forensics Tools (Optional)
- **Sleuthkit**: Digital forensics toolkit
- **Autopsy**: Digital forensics platform
- **Volatility**: Memory forensics framework
- **Binwalk**: Binary analysis tool

### 2. Enhanced NixOS Hardening

#### AppArmor Integration
- Mandatory Access Control (MAC) system
- Pre-configured profiles for common applications
- Automatic profile enforcement

#### Kernel Hardening
- Memory protection (SLAB debugging, page poisoning)
- Control flow integrity
- Disable dangerous syscalls and debugging interfaces
- Module signature enforcement

#### Network Security
- Enhanced firewall rules with rate limiting
- TCP SYN cookies and timestamps disabled
- IPv6 hardening
- Network packet logging

#### File System Security
- Protected symlinks and hardlinks
- SUID dump restrictions
- Core dump security

#### Audit Daemon (auditd)
- Comprehensive audit rules for security events
- File access monitoring
- Privilege escalation detection
- Rewind-OS specific event monitoring

### 3. Real-time Security Monitoring

#### Automated Monitoring Services
- **Hourly Security Checks**: Automated integrity and log analysis
- **Daily Security Checklist**: Compliance verification
- **Real-time Alerts**: Optional continuous monitoring
- **Security Event Snapshots**: Automatic timeline snapshots on security events

#### Security Checklist Verification
- Firewall configuration validation
- SSH security settings verification
- System update status checking
- Audit logging verification
- File permission validation
- Security tool availability checking

### 4. Security Tools Integration

#### Enhanced Security Script (`scripts/security-tools.sh`)

**Available Commands:**
```bash
# Basic operations
./scripts/security-tools.sh init              # Initialize security infrastructure
./scripts/security-tools.sh help              # Show all available commands

# Basic security checks
./scripts/security-tools.sh integrity         # Basic integrity check
./scripts/security-tools.sh logs              # Basic log analysis
./scripts/security-tools.sh network           # Network security assessment
./scripts/security-tools.sh forensics         # Forensics environment preparation

# Enhanced security checks (when tools are available)
./scripts/security-tools.sh integrity-enhanced # Enhanced integrity with RKHunter/AIDE
./scripts/security-tools.sh logs-enhanced      # Enhanced log analysis with Fail2Ban

# Monitoring and reporting
./scripts/security-tools.sh monitor           # Comprehensive security monitoring
./scripts/security-tools.sh realtime          # Real-time monitoring (60 seconds)
./scripts/security-tools.sh checklist         # Security checklist verification
./scripts/security-tools.sh report            # Generate comprehensive security report
```

#### CLI Security Commands (`rewind security`)

```bash
# Security status and monitoring
rewind security --status                       # Show security status
rewind security --scan                         # Run security scan with snapshots
rewind security --audit                        # Show security audit trail
rewind security --report                       # Generate security report
```

### 5. Pre-configured Security Tool Configurations

All security tools come with optimized default configurations:

- **RKHunter** (`configs/rkhunter.conf`): Tuned for NixOS environment
- **AIDE** (`configs/aide.conf`): Monitors critical system files and Rewind-OS directory
- **Fail2Ban** (`configs/fail2ban-jail.local`): SSH protection and custom Rewind-OS jail
- **Logwatch** (`configs/logwatch.conf`): Comprehensive log monitoring

### 6. Security Compliance and Verification

#### Automated Security Checklist
The system automatically verifies:
1. Firewall configuration and status
2. SSH security settings (root login, password auth)
3. System update status
4. Audit logging functionality
5. Critical file permissions
6. Security tool availability

#### Security Scoring
- Provides percentage-based security score
- Identifies areas needing improvement
- Generates actionable recommendations

## NixOS Configuration

### Basic Security Configuration

```nix
services.rewind-os = {
  enable = true;
  
  security = {
    enable = true;
    
    # Enable security audit tools
    auditTools = {
      enable = true;
      systemIntegrity = true;    # RKHunter, AIDE, ChkRootkit, Lynis
      logAnalysis = true;        # Fail2Ban, Logwatch, Rsyslog
      forensics = false;         # Sleuthkit, Volatility (advanced users)
    };
    
    # Enable system hardening
    hardening = {
      enable = true;
      apparmor = true;           # Enable AppArmor MAC
      firewall = true;           # Enhanced firewall rules
      kernelHardening = true;    # Kernel security parameters
      auditd = true;             # Audit daemon with enhanced rules
    };
    
    # Enable security monitoring
    monitoring = {
      enable = true;
      realTimeAlerts = false;    # Enable for continuous monitoring
      automaticSnapshots = true; # Snapshots on security events
      checklistVerification = true; # Daily security checklist
    };
  };
};
```

### Advanced Security Configuration

```nix
services.rewind-os = {
  security = {
    enable = true;
    
    auditTools = {
      enable = true;
      systemIntegrity = true;
      logAnalysis = true;
      forensics = true;          # Enable full forensics toolkit
    };
    
    hardening = {
      enable = true;
      apparmor = true;
      firewall = true;
      kernelHardening = true;
      userspace = true;
      networkSecurity = true;
      auditd = true;
    };
    
    monitoring = {
      enable = true;
      realTimeAlerts = true;     # Enable real-time monitoring
      logRetention = 180;        # Keep logs for 6 months
      automaticSnapshots = true;
      checklistVerification = true;
    };
  };
};
```

## Usage Examples

### Daily Security Operations

```bash
# Morning security check
rewind security --status

# Run comprehensive security scan
./scripts/security-tools.sh monitor

# Check compliance
./scripts/security-tools.sh checklist

# Generate security report
rewind security --report
```

### Incident Response

```bash
# Create forensics environment
./scripts/security-tools.sh forensics

# Run enhanced integrity check
./scripts/security-tools.sh integrity-enhanced

# Check recent security events
rewind security --audit

# Create incident snapshot
rewind snapshot "Security incident - $(date)"
```

### Real-time Monitoring

```bash
# Start 60-second real-time monitoring
./scripts/security-tools.sh realtime

# Enable continuous real-time monitoring (NixOS config)
services.rewind-os.security.monitoring.realTimeAlerts = true;
```

## Security Log Locations

All security logs are organized under the Rewind-OS configuration directory:

```
/var/lib/rewind-os/
├── security-logs/
│   ├── security.log              # General security events
│   ├── monitoring.log            # Monitoring cycle logs
│   ├── realtime-monitoring.log   # Real-time monitoring alerts
│   ├── auth.log                  # Authentication events
│   └── kernel.log                # Kernel security events
├── security-reports/
│   ├── integrity-*.log           # Integrity check reports
│   ├── log-analysis-*.log        # Log analysis reports
│   ├── network-*.log             # Network security reports
│   ├── security-checklist-*.log  # Checklist verification reports
│   └── comprehensive-report-*.txt # Full security reports
└── audit-trails/
    └── forensics-*/              # Forensics workspaces
```

## Security Systemd Services

The following systemd services are automatically configured:

- `rewind-security-monitor.timer`: Hourly security monitoring
- `rewind-security-checklist.timer`: Daily security checklist verification
- `rewind-security-realtime.service`: Continuous real-time monitoring (optional)
- `rewind-security-log-cleanup.timer`: Security log rotation

## Troubleshooting

### Common Issues

1. **Security tools not found**: Ensure `auditTools.enable = true` in NixOS config
2. **Permission denied**: Add user to `rewind-os` group
3. **Real-time monitoring alerts**: Check `/var/lib/rewind-os/security-logs/realtime-monitoring.log`
4. **AppArmor profiles**: Use `aa-status` to check profile status

### Verification Commands

```bash
# Check security services status
systemctl status rewind-security-monitor.timer
systemctl status rewind-security-checklist.timer

# Verify security tool installation
which rkhunter aide fail2ban-client

# Check AppArmor status
sudo aa-status

# Verify audit rules
sudo auditctl -l
```

## Security Best Practices

1. **Enable all security features** in production environments
2. **Review security reports** regularly
3. **Investigate timeline anomalies** using security audit trail
4. **Keep security tools updated** through NixOS updates
5. **Monitor real-time alerts** in critical environments
6. **Create security snapshots** before major changes
7. **Use forensics tools** for incident investigation

## Integration with Rewind-OS Timeline

- **Automatic snapshots** created before and after security events
- **Security audit trail** shows security-related timeline entries
- **Compliance verification** tracked in timeline metadata
- **Security reports** include timeline context
- **Incident response** can use timeline rollback for recovery

## Compliance and Standards

The security configuration helps meet various compliance requirements:

- **CIS Controls**: System hardening and monitoring
- **NIST Cybersecurity Framework**: Comprehensive security controls
- **ISO 27001**: Information security management
- **SOX/PCI DSS**: Audit logging and access controls

This implementation provides enterprise-grade security while maintaining the flexibility and ease of use that Rewind-OS is known for.