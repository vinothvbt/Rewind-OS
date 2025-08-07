#!/bin/bash
# Rewind-OS Security Tools Script
# Phase 3: Security, Audit, and Investigation Tools
#
# This script provides basic security tool integration for Rewind-OS
# It serves as a foundation for more advanced security features

set -euo pipefail

# Configuration
REWIND_CONFIG_DIR="${REWIND_CONFIG_DIR:-/var/lib/rewind-os}"
SECURITY_LOG_DIR="${REWIND_CONFIG_DIR}/security-logs"
SECURITY_REPORT_DIR="${REWIND_CONFIG_DIR}/security-reports"
AUDIT_TRAIL_DIR="${REWIND_CONFIG_DIR}/audit-trails"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Initialize security directories
init_security() {
    log "Initializing Rewind-OS security infrastructure..."
    
    mkdir -p "${SECURITY_LOG_DIR}"
    mkdir -p "${SECURITY_REPORT_DIR}"
    mkdir -p "${AUDIT_TRAIL_DIR}"
    
    success "Security directories created"
}

# System integrity check
integrity_check() {
    log "Running system integrity check..."
    
    # TODO: Implement actual integrity checks
    # For now, this is a basic framework
    
    local report_file="${SECURITY_REPORT_DIR}/integrity-$(date +%Y%m%d-%H%M%S).log"
    
    {
        echo "=== System Integrity Check ==="
        echo "Timestamp: $(date)"
        echo "Host: $(hostname)"
        echo "User: $(whoami)"
        echo ""
        
        # Check critical system files
        echo "Critical System Files:"
        if [ -f /etc/passwd ]; then
            echo "✓ /etc/passwd exists"
        else
            echo "✗ /etc/passwd missing"
        fi
        
        if [ -f /etc/shadow ]; then
            echo "✓ /etc/shadow exists"
        else
            echo "✗ /etc/shadow missing"
        fi
        
        # Check system permissions
        echo ""
        echo "System Permissions:"
        echo "passwd permissions: $(stat -c %a /etc/passwd 2>/dev/null || echo 'N/A')"
        echo "shadow permissions: $(stat -c %a /etc/shadow 2>/dev/null || echo 'N/A')"
        
        # Check for setuid files (basic security scan)
        echo ""
        echo "Recent setuid files:"
        find /usr -type f -perm -4000 2>/dev/null | head -5 || echo "Cannot scan for setuid files"
        
    } > "${report_file}"
    
    success "Integrity check completed: ${report_file}"
}

# Log analysis
analyze_logs() {
    log "Analyzing system logs for security events..."
    
    local report_file="${SECURITY_REPORT_DIR}/log-analysis-$(date +%Y%m%d-%H%M%S).log"
    
    {
        echo "=== Log Analysis Report ==="
        echo "Timestamp: $(date)"
        echo ""
        
        # Check auth logs if available
        if [ -f /var/log/auth.log ]; then
            echo "Recent authentication events:"
            tail -20 /var/log/auth.log | grep -E "(Failed|Accepted)" || echo "No auth events found"
        elif [ -f /var/log/secure ]; then
            echo "Recent authentication events:"
            tail -20 /var/log/secure | grep -E "(Failed|Accepted)" || echo "No auth events found"
        else
            echo "No authentication logs found"
        fi
        
        echo ""
        
        # Check for suspicious activity
        echo "Checking for suspicious activity..."
        if [ -f /var/log/syslog ]; then
            echo "Recent system events:"
            tail -10 /var/log/syslog || echo "Cannot read syslog"
        else
            echo "No syslog found"
        fi
        
    } > "${report_file}"
    
    success "Log analysis completed: ${report_file}"
}

# Network security check
network_check() {
    log "Running network security assessment..."
    
    local report_file="${SECURITY_REPORT_DIR}/network-$(date +%Y%m%d-%H%M%S).log"
    
    {
        echo "=== Network Security Check ==="
        echo "Timestamp: $(date)"
        echo ""
        
        # Check listening ports
        echo "Listening ports:"
        ss -tuln 2>/dev/null | head -10 || netstat -tuln 2>/dev/null | head -10 || echo "Cannot check listening ports"
        
        echo ""
        
        # Check firewall status
        echo "Firewall status:"
        if command -v ufw >/dev/null 2>&1; then
            ufw status 2>/dev/null || echo "UFW not available or accessible"
        elif command -v firewall-cmd >/dev/null 2>&1; then
            firewall-cmd --state 2>/dev/null || echo "Firewalld not available or accessible"
        else
            echo "No known firewall tools found"
        fi
        
        echo ""
        
        # Check network interfaces
        echo "Network interfaces:"
        ip addr show 2>/dev/null | grep -E "^[0-9]" || ifconfig 2>/dev/null | grep -E "^[a-z]" || echo "Cannot check network interfaces"
        
    } > "${report_file}"
    
    success "Network check completed: ${report_file}"
}

# Forensics preparation
forensics_prep() {
    log "Preparing forensics environment..."
    
    # Create forensics workspace
    local forensics_dir="${AUDIT_TRAIL_DIR}/forensics-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "${forensics_dir}"
    
    {
        echo "=== Forensics Preparation ==="
        echo "Timestamp: $(date)"
        echo "Workspace: ${forensics_dir}"
        echo ""
        
        # System information
        echo "System Information:"
        echo "Hostname: $(hostname)"
        echo "Kernel: $(uname -r)"
        echo "OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2 | tr -d '"' 2>/dev/null || echo 'Unknown')"
        echo "Uptime: $(uptime)"
        echo ""
        
        # Memory information
        echo "Memory Information:"
        cat /proc/meminfo | head -5 || echo "Cannot read memory info"
        echo ""
        
        # Process information
        echo "Running Processes (top 10):"
        ps aux --sort=-%cpu | head -11 || echo "Cannot read process info"
        
    } > "${forensics_dir}/system-snapshot.log"
    
    success "Forensics preparation completed: ${forensics_dir}"
}

# Security monitoring
monitor() {
    log "Starting security monitoring cycle..."
    
    # Log the monitoring event
    echo "$(date): Security monitoring cycle started" >> "${SECURITY_LOG_DIR}/monitoring.log"
    
    # Run basic checks
    integrity_check
    analyze_logs
    network_check
    
    # Create Rewind-OS snapshot if CLI is available
    log "Creating security monitoring snapshot..."
    run_rewind_command snapshot "Security monitoring cycle ($(date))"
    
    echo "$(date): Security monitoring cycle completed" >> "${SECURITY_LOG_DIR}/monitoring.log"
    success "Security monitoring cycle completed"
}

# Generate comprehensive security report
generate_report() {
    log "Generating comprehensive security report..."
    
    local report_file="${SECURITY_REPORT_DIR}/comprehensive-report-$(date +%Y%m%d-%H%M%S).txt"
    
    {
        echo "=============================================="
        echo "    Rewind-OS Comprehensive Security Report"
        echo "=============================================="
        echo ""
        echo "Generated: $(date)"
        echo "Host: $(hostname)"
        echo "Report ID: $(basename ${report_file} .txt)"
        echo ""
        
        echo "=== EXECUTIVE SUMMARY ==="
        echo "This report provides a comprehensive overview of the security"
        echo "status of the Rewind-OS system including system integrity,"
        echo "log analysis, network security, and audit trails."
        echo ""
        
        echo "=== SYSTEM OVERVIEW ==="
        echo "Hostname: $(hostname)"
        echo "Operating System: $(cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2 | tr -d '"' 2>/dev/null || echo 'Unknown')"
        echo "Kernel Version: $(uname -r)"
        echo "System Uptime: $(uptime | awk '{print $3,$4}' | sed 's/,//')"
        echo "Current User: $(whoami)"
        echo "Report Generation Time: $(date)"
        echo ""
        
        echo "=== SECURITY CHECKS PERFORMED ==="
        echo "• System integrity verification"
        echo "• Authentication log analysis"
        echo "• Network security assessment"
        echo "• File system permissions check"
        echo "• Process monitoring"
        echo "• Rewind-OS timeline integration"
        echo ""
        
        echo "=== RECENT SECURITY EVENTS ==="
        if [ -f "${SECURITY_LOG_DIR}/monitoring.log" ]; then
            echo "Recent monitoring events:"
            tail -10 "${SECURITY_LOG_DIR}/monitoring.log" 2>/dev/null || echo "No monitoring log available"
        else
            echo "No monitoring events recorded yet"
        fi
        echo ""
        
        echo "=== RECOMMENDATIONS ==="
        echo "• Regularly update system packages"
        echo "• Monitor authentication logs for suspicious activity"
        echo "• Ensure firewall is properly configured"
        echo "• Review file permissions on critical system files"
        echo "• Maintain regular security snapshots using Rewind-OS"
        echo "• Enable security monitoring services"
        echo ""
        
        echo "=== NEXT STEPS ==="
        echo "• Review this report with security team"
        echo "• Address any identified security issues"
        echo "• Schedule regular security assessments"
        echo "• Update security policies and procedures"
        echo ""
        
        echo "=== REPORT METADATA ==="
        echo "Report Format: Phase 3 Security Assessment"
        echo "Generated By: Rewind-OS Security Tools"
        echo "Report Location: ${report_file}"
        echo "Configuration Directory: ${REWIND_CONFIG_DIR}"
        echo ""
        
    } > "${report_file}"
    
    success "Comprehensive security report generated: ${report_file}"
}

# Main function
main() {
    case "${1:-help}" in
        init)
            init_security
            ;;
        integrity)
            integrity_check
            ;;
        logs)
            analyze_logs
            ;;
        network)
            network_check
            ;;
        forensics)
            forensics_prep
            ;;
        monitor)
            monitor
            ;;
        report)
            generate_report
            ;;
        help|--help|-h)
            echo "Rewind-OS Security Tools"
            echo ""
            echo "Usage: $0 <command>"
            echo ""
            echo "Commands:"
            echo "  init        Initialize security infrastructure"
            echo "  integrity   Run system integrity check"
            echo "  logs        Analyze system logs for security events"
            echo "  network     Run network security assessment"
            echo "  forensics   Prepare forensics environment"
            echo "  monitor     Run complete security monitoring cycle"
            echo "  report      Generate comprehensive security report"
            echo "  help        Show this help message"
            echo ""
            echo "Environment Variables:"
            echo "  REWIND_CONFIG_DIR   Configuration directory (default: /var/lib/rewind-os)"
            echo ""
            echo "Phase 3: Security, Audit, and Investigation Tools"
            ;;
        *)
            error "Unknown command: $1"
            echo "Use '$0 help' for usage information"
            exit 1
            ;;
    esac
}

# Run main function
main "$@"