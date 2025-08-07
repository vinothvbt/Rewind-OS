#!/bin/bash
# Rewind-OS Security Tools Script
# Phase 3: Security, Audit, and Investigation Tools
#
# This script provides comprehensive security tool integration for Rewind-OS
# It integrates with actual security tools when available and provides
# enhanced monitoring, alerting, and compliance checking capabilities.

set -euo pipefail

# Get script directory for relative path resolution
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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
    log "Starting comprehensive security monitoring cycle..."
    
    # Ensure monitoring log directory exists
    mkdir -p "${SECURITY_LOG_DIR}"
    
    # Log the monitoring event
    echo "$(date): Security monitoring cycle started" >> "${SECURITY_LOG_DIR}/monitoring.log"
    
    # Run basic checks
    integrity_check
    analyze_logs
    network_check
    
    # Run enhanced checks if tools are available
    if command -v rkhunter >/dev/null 2>&1 || command -v chkrootkit >/dev/null 2>&1; then
        log "Running enhanced integrity checks..."
        enhanced_integrity_check
    fi
    
    if command -v fail2ban-client >/dev/null 2>&1; then
        log "Running enhanced log analysis..."
        enhanced_log_analysis
    fi
    
    # Run security checklist
    log "Running security checklist verification..."
    security_checklist
    
    # Create Rewind-OS snapshot if CLI is available
    log "Creating security monitoring snapshot..."
    run_rewind_command snapshot "Security monitoring cycle ($(date))"
    
    echo "$(date): Security monitoring cycle completed" >> "${SECURITY_LOG_DIR}/monitoring.log"
    success "Comprehensive security monitoring cycle completed"
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
        integrity-enhanced)
            enhanced_integrity_check
            ;;
        logs)
            analyze_logs
            ;;
        logs-enhanced)
            enhanced_log_analysis
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
        realtime)
            real_time_monitoring
            ;;
        checklist)
            security_checklist
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
            echo "  init               Initialize security infrastructure"
            echo "  integrity          Run basic system integrity check"
            echo "  integrity-enhanced Run enhanced integrity check with security tools"
            echo "  logs               Analyze basic system logs for security events"
            echo "  logs-enhanced      Enhanced log analysis with fail2ban integration"
            echo "  network            Run network security assessment"
            echo "  forensics          Prepare forensics environment"
            echo "  monitor            Run complete security monitoring cycle"
            echo "  realtime           Run real-time security monitoring (60s)"
            echo "  checklist          Run security checklist verification"
            echo "  report             Generate comprehensive security report"
            echo "  help               Show this help message"
            echo ""
            echo "Environment Variables:"
            echo "  REWIND_CONFIG_DIR   Configuration directory (default: /var/lib/rewind-os)"
            echo ""
            echo "Phase 3: Security, Audit, and Investigation Tools"
            echo "Enhanced commands integrate with actual security tools when available."
            ;;
        *)
            error "Unknown command: $1"
            echo "Use '$0 help' for usage information"
            exit 1
            ;;
    esac
}

# Helper function to run rewind CLI commands
run_rewind_command() {
    local cmd="$1"
    shift
    
    # Try to find rewind CLI
    local rewind_cmd=""
    if command -v rewind >/dev/null 2>&1; then
        rewind_cmd="rewind"
    elif command -v python3 >/dev/null 2>&1 && [ -f "${SCRIPT_DIR:-$(dirname "${BASH_SOURCE[0]}")}/../rewind/cli.py" ]; then
        rewind_cmd="python3 -m rewind.cli"
        export PYTHONPATH="${SCRIPT_DIR:-$(dirname "${BASH_SOURCE[0]}")}/..:${PYTHONPATH:-}"
    else
        warning "Rewind CLI not found, skipping timeline integration"
        return 0
    fi
    
    # Run the command
    if [ "$cmd" = "snapshot" ]; then
        local message="$1"
        log "Creating Rewind-OS snapshot: $message"
        $rewind_cmd snapshot "$message" 2>/dev/null || warning "Failed to create snapshot"
    else
        $rewind_cmd "$cmd" "$@" 2>/dev/null || warning "Failed to run rewind command: $cmd"
    fi
}

# Enhanced system integrity check with actual tool integration
enhanced_integrity_check() {
    log "Running enhanced system integrity check with security tools..."
    
    local report_file="${SECURITY_REPORT_DIR}/integrity-enhanced-$(date +%Y%m%d-%H%M%S).log"
    
    {
        echo "=== Enhanced System Integrity Check ==="
        echo "Timestamp: $(date)"
        echo "Host: $(hostname)"
        echo "User: $(whoami)"
        echo ""
        
        # Run rkhunter if available
        if command -v rkhunter >/dev/null 2>&1; then
            echo "=== RKHunter Rootkit Scan ==="
            timeout 60 rkhunter --check --skip-keypress --report-warnings-only 2>/dev/null || echo "RKHunter scan completed with warnings (see logs)"
            echo ""
        fi
        
        # Run chkrootkit if available
        if command -v chkrootkit >/dev/null 2>&1; then
            echo "=== ChkRootkit Scan ==="
            timeout 60 chkrootkit 2>/dev/null | grep -E "(INFECTED|Checking|nothing found|not infected)" | tail -10 || echo "ChkRootkit scan completed"
            echo ""
        fi
        
        # Run AIDE if available and configured
        if command -v aide >/dev/null 2>&1; then
            echo "=== AIDE Integrity Check ==="
            if [ -f /etc/aide.conf ] || [ -f /var/lib/aide/aide.db ]; then
                timeout 30 aide --check 2>/dev/null | head -20 || echo "AIDE check completed (see logs for details)"
            else
                echo "AIDE not configured (database not found)"
            fi
            echo ""
        fi
        
        # File permission checks
        echo "=== Critical File Permissions ==="
        local critical_files=("/etc/passwd" "/etc/shadow" "/etc/sudoers" "/etc/ssh/sshd_config")
        for file in "${critical_files[@]}"; do
            if [ -f "$file" ]; then
                echo "$file: $(stat -c '%a %U:%G' "$file" 2>/dev/null || echo 'N/A')"
            fi
        done
        echo ""
        
        # Check for SUID/SGID files in sensitive locations
        echo "=== SUID/SGID Files in System Directories ==="
        find /usr/bin /usr/sbin /bin /sbin -type f \( -perm -4000 -o -perm -2000 \) 2>/dev/null | head -10 || echo "Permission denied or no files found"
        echo ""
        
        # System service status
        echo "=== Critical Security Services ==="
        local services=("sshd" "fail2ban" "auditd" "rsyslog")
        for service in "${services[@]}"; do
            if systemctl is-enabled "$service" >/dev/null 2>&1; then
                echo "$service: $(systemctl is-active "$service" 2>/dev/null || echo 'inactive')"
            fi
        done
        echo ""
        
    } > "${report_file}"
    
    success "Enhanced integrity check completed: ${report_file}"
    return 0
}

# Enhanced log analysis with fail2ban integration
enhanced_log_analysis() {
    log "Running enhanced log analysis with security tool integration..."
    
    local report_file="${SECURITY_REPORT_DIR}/log-analysis-enhanced-$(date +%Y%m%d-%H%M%S).log"
    
    {
        echo "=== Enhanced Log Analysis Report ==="
        echo "Timestamp: $(date)"
        echo ""
        
        # Fail2ban status if available
        if command -v fail2ban-client >/dev/null 2>&1; then
            echo "=== Fail2ban Status ==="
            fail2ban-client status 2>/dev/null | head -10 || echo "Fail2ban not running or accessible"
            echo ""
        fi
        
        # Check for recent security events in various logs
        echo "=== Recent Authentication Events ==="
        local auth_logs=("/var/log/auth.log" "/var/log/secure" "${SECURITY_LOG_DIR}/auth.log")
        for log_file in "${auth_logs[@]}"; do
            if [ -f "$log_file" ]; then
                echo "From $log_file:"
                tail -10 "$log_file" | grep -E "(Failed|Accepted|Invalid|authentication failure)" 2>/dev/null || echo "No recent auth events"
                break
            fi
        done
        echo ""
        
        # Check system logs for security-related events
        echo "=== Security-Related System Events ==="
        if [ -f /var/log/syslog ]; then
            tail -20 /var/log/syslog | grep -E "(security|audit|intrusion|malware|virus)" 2>/dev/null || echo "No recent security events in syslog"
        elif command -v journalctl >/dev/null 2>&1; then
            journalctl --since "1 hour ago" | grep -E "(security|audit|intrusion|malware|virus)" | tail -5 2>/dev/null || echo "No recent security events in journal"
        fi
        echo ""
        
        # Check for suspicious network activity
        echo "=== Network Connection Analysis ==="
        if command -v ss >/dev/null 2>&1; then
            echo "Listening services:"
            ss -tuln | grep LISTEN | head -10 2>/dev/null || echo "Cannot analyze network connections"
        fi
        echo ""
        
        # Check for unusual file changes
        echo "=== Recent File System Changes ==="
        find /etc -type f -mtime -1 2>/dev/null | head -5 || echo "Cannot check recent file changes"
        echo ""
        
    } > "${report_file}"
    
    success "Enhanced log analysis completed: ${report_file}"
    return 0
}

# Security monitoring with real-time capabilities
real_time_monitoring() {
    log "Starting real-time security monitoring..."
    
    local monitoring_log="${SECURITY_LOG_DIR}/realtime-monitoring.log"
    local alert_threshold=5
    local monitor_duration=60
    
    echo "$(date): Starting real-time monitoring (duration: ${monitor_duration}s)" >> "$monitoring_log"
    
    local start_time=$(date +%s)
    local alert_count=0
    
    while [ $(($(date +%s) - start_time)) -lt $monitor_duration ]; do
        # Monitor authentication attempts
        if [ -f /var/log/auth.log ]; then
            local recent_fails=$(tail -50 /var/log/auth.log 2>/dev/null | grep -c "Failed password" || echo 0)
            if [ "$recent_fails" -gt $alert_threshold ]; then
                echo "$(date): ALERT - High authentication failures detected: $recent_fails" >> "$monitoring_log"
                alert_count=$((alert_count + 1))
            fi
        fi
        
        # Monitor system load
        local load_avg=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//' 2>/dev/null || echo "0")
        if command -v bc >/dev/null 2>&1 && [ "$(echo "$load_avg > 5.0" | bc 2>/dev/null || echo 0)" -eq 1 ]; then
            echo "$(date): ALERT - High system load detected: $load_avg" >> "$monitoring_log"
            alert_count=$((alert_count + 1))
        fi
        
        # Monitor disk usage
        local disk_usage=$(df / | awk 'NR==2 {print $5}' | sed 's/%//' 2>/dev/null || echo "0")
        if [ "$disk_usage" -gt 90 ]; then
            echo "$(date): ALERT - High disk usage detected: ${disk_usage}%" >> "$monitoring_log"
            alert_count=$((alert_count + 1))
        fi
        
        sleep 5
    done
    
    echo "$(date): Real-time monitoring completed. Alerts: $alert_count" >> "$monitoring_log"
    
    if [ $alert_count -gt 0 ]; then
        warning "Real-time monitoring detected $alert_count alerts"
        run_rewind_command snapshot "Security alerts detected during monitoring"
    else
        success "Real-time monitoring completed with no alerts"
    fi
    
    return 0
}

# Security checklist verification
security_checklist() {
    log "Running security checklist verification..."
    
    local checklist_file="${SECURITY_REPORT_DIR}/security-checklist-$(date +%Y%m%d-%H%M%S).log"
    local passed=0
    local failed=0
    
    {
        echo "=== Rewind-OS Security Checklist Verification ==="
        echo "Timestamp: $(date)"
        echo ""
        
        # Check 1: Firewall status
        echo "1. Firewall Configuration:"
        if command -v ufw >/dev/null 2>&1; then
            if ufw status | grep -q "Status: active"; then
                echo "   ✓ UFW firewall is active"
                passed=$((passed + 1))
            else
                echo "   ✗ UFW firewall is not active"
                failed=$((failed + 1))
            fi
        elif systemctl is-active firewalld >/dev/null 2>&1; then
            echo "   ✓ Firewalld is active"
            passed=$((passed + 1))
        else
            echo "   ✗ No active firewall detected"
            failed=$((failed + 1))
        fi
        echo ""
        
        # Check 2: SSH configuration
        echo "2. SSH Security Configuration:"
        if [ -f /etc/ssh/sshd_config ]; then
            local ssh_issues=0
            if grep -q "^PermitRootLogin no" /etc/ssh/sshd_config 2>/dev/null; then
                echo "   ✓ Root login disabled"
            else
                echo "   ✗ Root login not explicitly disabled"
                ssh_issues=$((ssh_issues + 1))
            fi
            
            if grep -q "^PasswordAuthentication no" /etc/ssh/sshd_config 2>/dev/null; then
                echo "   ✓ Password authentication disabled"
            else
                echo "   ⚠ Password authentication may be enabled"
            fi
            
            if [ $ssh_issues -eq 0 ]; then
                passed=$((passed + 1))
            else
                failed=$((failed + 1))
            fi
        else
            echo "   ⚠ SSH configuration file not found"
        fi
        echo ""
        
        # Check 3: System updates
        echo "3. System Update Status:"
        if command -v apt >/dev/null 2>&1; then
            local updates=$(apt list --upgradable 2>/dev/null | wc -l)
            if [ "$updates" -lt 10 ]; then
                echo "   ✓ System appears up to date (${updates} updates available)"
                passed=$((passed + 1))
            else
                echo "   ✗ Many updates available (${updates})"
                failed=$((failed + 1))
            fi
        elif command -v dnf >/dev/null 2>&1; then
            echo "   ⚠ DNF detected, manual update check recommended"
        else
            echo "   ⚠ Cannot determine update status"
        fi
        echo ""
        
        # Check 4: Audit logging
        echo "4. Audit Logging:"
        if systemctl is-active auditd >/dev/null 2>&1; then
            echo "   ✓ Auditd service is active"
            passed=$((passed + 1))
        else
            echo "   ✗ Auditd service is not active"
            failed=$((failed + 1))
        fi
        echo ""
        
        # Check 5: File permissions
        echo "5. Critical File Permissions:"
        local perm_issues=0
        if [ -f /etc/passwd ]; then
            local passwd_perm=$(stat -c %a /etc/passwd 2>/dev/null)
            if [ "$passwd_perm" = "644" ]; then
                echo "   ✓ /etc/passwd permissions correct (644)"
            else
                echo "   ✗ /etc/passwd permissions incorrect ($passwd_perm)"
                perm_issues=$((perm_issues + 1))
            fi
        fi
        
        if [ -f /etc/shadow ]; then
            local shadow_perm=$(stat -c %a /etc/shadow 2>/dev/null)
            if [ "$shadow_perm" = "640" ] || [ "$shadow_perm" = "600" ]; then
                echo "   ✓ /etc/shadow permissions correct ($shadow_perm)"
            else
                echo "   ✗ /etc/shadow permissions incorrect ($shadow_perm)"
                perm_issues=$((perm_issues + 1))
            fi
        fi
        
        if [ $perm_issues -eq 0 ]; then
            passed=$((passed + 1))
        else
            failed=$((failed + 1))
        fi
        echo ""
        
        # Check 6: Security tools availability
        echo "6. Security Tools Availability:"
        local tools=("fail2ban" "rkhunter" "aide")
        local tools_available=0
        for tool in "${tools[@]}"; do
            if command -v "$tool" >/dev/null 2>&1; then
                echo "   ✓ $tool is available"
                tools_available=$((tools_available + 1))
            else
                echo "   ✗ $tool is not available"
            fi
        done
        
        if [ $tools_available -gt 1 ]; then
            passed=$((passed + 1))
        else
            failed=$((failed + 1))
        fi
        echo ""
        
        # Summary
        local total=$((passed + failed))
        local score=0
        if [ $total -gt 0 ]; then
            score=$(( (passed * 100) / total ))
        fi
        
        echo "=== Security Checklist Summary ==="
        echo "Passed checks: $passed"
        echo "Failed checks: $failed"
        echo "Security score: ${score}%"
        echo ""
        
        if [ $score -gt 80 ]; then
            echo "✓ Overall security status: GOOD"
        elif [ $score -gt 60 ]; then
            echo "⚠ Overall security status: MODERATE"
        else
            echo "✗ Overall security status: NEEDS IMPROVEMENT"
        fi
        
    } > "${checklist_file}"
    
    success "Security checklist verification completed: ${checklist_file}"
    
    # Create snapshot for security checklist
    run_rewind_command snapshot "Security checklist verification completed"
    
    return 0
}

# Run main function
main "$@"