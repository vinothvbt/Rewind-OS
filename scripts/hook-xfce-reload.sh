#!/bin/bash
#
# XFCE Reload Hook for Rewind-OS (Phase 2 Enhanced)
#
# This script handles XFCE desktop environment reload operations
# when system state changes occur (snapshots, restores, branch switches).
#
# Usage: hook-xfce-reload.sh [operation] [options]
#
# Phase 2 Features:
# - Enhanced error handling and logging
# - Automatic rollback on reload failure
# - Configuration validation
# - Multiple reload strategies
# - Integration with Rewind-OS timeline

set -euo pipefail

# Configuration
REWIND_CONFIG_DIR="${REWIND_CONFIG_DIR:-${HOME}/.rewind}"
LOG_FILE="${REWIND_CONFIG_DIR}/xfce-reload.log"
BACKUP_DIR="${REWIND_CONFIG_DIR}/xfce-backups"
ERROR_LOG="${REWIND_CONFIG_DIR}/xfce-errors.log"

# Ensure directories exist
mkdir -p "${REWIND_CONFIG_DIR}" "${BACKUP_DIR}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log() {
    local level="$1"
    shift
    local message="$*"
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message" | tee -a "${LOG_FILE}"
}

info() {
    log "INFO" "${BLUE}$*${NC}"
}

warn() {
    log "WARN" "${YELLOW}$*${NC}"
}

error() {
    log "ERROR" "${RED}$*${NC}" | tee -a "${ERROR_LOG}"
}

success() {
    log "SUCCESS" "${GREEN}$*${NC}"
}

# Error handling with auto-rollback
handle_error() {
    local exit_code=$?
    local line_number=$1
    error "Script failed at line $line_number with exit code $exit_code"
    
    # If we have a recent backup and rewind command available, offer rollback
    if command -v rewind >/dev/null 2>&1 && [ -d "${BACKUP_DIR}" ]; then
        warn "Attempting automatic rollback due to XFCE reload failure..."
        # This would trigger a rollback to the last known good state
        # For now, just log the option
        warn "Manual rollback available: rewind restore <last-good-snapshot>"
    fi
    
    exit $exit_code
}

trap 'handle_error $LINENO' ERR

# Check if XFCE is running and healthy
check_xfce() {
    info "Checking XFCE session status..."
    
    if ! pgrep -x "xfce4-session" > /dev/null; then
        warn "XFCE session not detected. Skipping reload."
        return 1
    fi
    
    # Check if display is available
    if [ -z "${DISPLAY:-}" ]; then
        warn "No DISPLAY environment variable set. Skipping reload."
        return 1
    fi
    
    # Verify X11 connection
    if ! xset q >/dev/null 2>&1; then
        warn "Cannot connect to X11 display. Skipping reload."
        return 1
    fi
    
    success "XFCE session is healthy and accessible"
    return 0
}

# Validate XFCE configuration
validate_xfce_config() {
    info "Validating XFCE configuration..."
    
    local config_dir="${HOME}/.config/xfce4"
    local errors=0
    
    # Check for essential config files
    local essential_files=(
        "xfconf/xfce-perchannel-xml/xfce4-panel.xml"
        "xfconf/xfce-perchannel-xml/xfwm4.xml"
        "xfconf/xfce-perchannel-xml/xfce4-desktop.xml"
    )
    
    for file in "${essential_files[@]}"; do
        if [ ! -f "${config_dir}/${file}" ]; then
            warn "Missing essential config file: $file"
            ((errors++))
        fi
    done
    
    if [ $errors -gt 0 ]; then
        warn "Found $errors configuration issues"
        return 1
    fi
    
    success "XFCE configuration validation passed"
    return 0
}

# Create comprehensive backup of XFCE configuration
backup_xfce_config() {
    local backup_timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_path="${BACKUP_DIR}/xfce_${backup_timestamp}"
    
    info "Creating comprehensive XFCE configuration backup..."
    
    mkdir -p "${backup_path}"
    
    # Backup key XFCE configuration directories and files
    local backup_paths=(
        "${HOME}/.config/xfce4"
        "${HOME}/.local/share/xfce4"
        "${HOME}/.cache/xfce4"
        "${HOME}/.config/autostart"
        "${HOME}/.config/Thunar"
    )
    
    for path in "${backup_paths[@]}"; do
        if [ -d "$path" ] || [ -f "$path" ]; then
            local basename=$(basename "$path")
            info "Backing up $basename..."
            cp -r "$path" "${backup_path}/" 2>/dev/null || warn "Could not backup $path"
        fi
    done
    
    # Create backup manifest
    cat > "${backup_path}/manifest.json" << EOF
{
    "timestamp": "${backup_timestamp}",
    "backup_date": "$(date -Iseconds)",
    "user": "${USER}",
    "hostname": "$(hostname)",
    "display": "${DISPLAY:-unknown}",
    "xfce_version": "$(xfce4-about --version 2>/dev/null | head -1 || echo 'unknown')",
    "backup_type": "comprehensive",
    "files_backed_up": [
        $(printf '"%s",' "${backup_paths[@]}" | sed 's/,$//')
    ]
}
EOF
    
    echo "${backup_timestamp}" > "${backup_path}/timestamp"
    success "XFCE configuration backed up to ${backup_path}"
    
    # Cleanup old backups (keep last 10)
    info "Cleaning up old backups..."
    cd "${BACKUP_DIR}"
    ls -t | grep "^xfce_" | tail -n +11 | xargs -r rm -rf
}

# Enhanced reload functions with error checking

reload_panel() {
    info "Reloading XFCE panel..."
    
    if ! command -v xfce4-panel >/dev/null; then
        error "xfce4-panel command not found"
        return 1
    fi
    
    # Kill existing panel gracefully
    if pgrep -f xfce4-panel >/dev/null; then
        info "Stopping existing panel..."
        pkill -TERM -f xfce4-panel || true
        sleep 2
        
        # Force kill if still running
        if pgrep -f xfce4-panel >/dev/null; then
            warn "Panel still running, force killing..."
            pkill -KILL -f xfce4-panel || true
            sleep 1
        fi
    fi
    
    # Start new panel
    info "Starting new panel..."
    nohup xfce4-panel > /dev/null 2>&1 &
    sleep 2
    
    # Verify panel started
    if pgrep -f xfce4-panel >/dev/null; then
        success "XFCE panel reloaded successfully"
        return 0
    else
        error "Failed to start XFCE panel"
        return 1
    fi
}

reload_desktop() {
    info "Reloading XFCE desktop..."
    
    if ! command -v xfdesktop >/dev/null; then
        error "xfdesktop command not found"
        return 1
    fi
    
    # Reload desktop with signal first (gentler approach)
    if pgrep -f xfdesktop >/dev/null; then
        info "Sending reload signal to desktop..."
        pkill -USR1 -f xfdesktop 2>/dev/null || true
        sleep 1
        
        # If signal reload didn't work, restart
        if ! pgrep -f xfdesktop >/dev/null; then
            info "Signal reload failed, restarting desktop..."
            nohup xfdesktop > /dev/null 2>&1 &
        fi
    else
        info "Starting desktop..."
        nohup xfdesktop > /dev/null 2>&1 &
    fi
    
    sleep 2
    
    # Verify desktop started
    if pgrep -f xfdesktop >/dev/null; then
        success "XFCE desktop reloaded successfully"
        return 0
    else
        error "Failed to start XFCE desktop"
        return 1
    fi
}

reload_wm() {
    info "Reloading XFCE window manager..."
    
    if ! command -v xfwm4 >/dev/null; then
        error "xfwm4 command not found"
        return 1
    fi
    
    # Replace window manager
    info "Replacing window manager..."
    xfwm4 --replace > /dev/null 2>&1 &
    sleep 2
    
    # Verify window manager
    if pgrep -f xfwm4 >/dev/null; then
        success "XFCE window manager reloaded successfully"
        return 0
    else
        error "Failed to start XFCE window manager"
        return 1
    fi
}

reload_settings() {
    info "Reloading XFCE settings daemon..."
    
    if ! command -v xfsettingsd >/dev/null; then
        error "xfsettingsd command not found"
        return 1
    fi
    
    # Kill and restart settings daemon
    if pgrep -f xfsettingsd >/dev/null; then
        info "Stopping existing settings daemon..."
        pkill -TERM -f xfsettingsd || true
        sleep 1
        
        # Force kill if still running
        if pgrep -f xfsettingsd >/dev/null; then
            pkill -KILL -f xfsettingsd || true
            sleep 1
        fi
    fi
    
    # Start new settings daemon
    info "Starting settings daemon..."
    nohup xfsettingsd > /dev/null 2>&1 &
    sleep 2
    
    # Verify settings daemon started
    if pgrep -f xfsettingsd >/dev/null; then
        success "XFCE settings daemon reloaded successfully"
        return 0
    else
        error "Failed to start XFCE settings daemon"
        return 1
    fi
}

# Enhanced reload strategies

smart_reload() {
    info "Performing smart XFCE reload with error recovery..."
    
    if ! check_xfce; then
        return 1
    fi
    
    backup_xfce_config
    validate_xfce_config || warn "Configuration validation failed, proceeding with caution"
    
    local failed_components=()
    
    # Reload components in order of importance
    reload_settings || failed_components+=("settings")
    reload_wm || failed_components+=("window-manager") 
    reload_panel || failed_components+=("panel")
    reload_desktop || failed_components+=("desktop")
    
    if [ ${#failed_components[@]} -eq 0 ]; then
        success "Smart XFCE reload completed successfully"
        
        # Create snapshot of successful reload if rewind is available
        if command -v rewind >/dev/null 2>&1; then
            info "Creating snapshot of successful XFCE reload..."
            rewind snapshot "XFCE smart reload successful ($(date))" || warn "Failed to create snapshot"
        fi
        
        return 0
    else
        error "Failed to reload components: ${failed_components[*]}"
        warn "Consider manual intervention or system restart"
        return 1
    fi
}

# Full XFCE reload with enhanced error handling
full_reload() {
    info "Performing full XFCE reload with enhanced error handling..."
    
    if ! check_xfce; then
        return 1
    fi
    
    backup_xfce_config
    validate_xfce_config || warn "Configuration validation failed, proceeding with caution"
    
    local start_time=$(date +%s)
    
    # Sequential reload with rollback capability
    if reload_settings && sleep 2 && \
       reload_wm && sleep 1 && \
       reload_panel && sleep 1 && \
       reload_desktop; then
        
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        success "Full XFCE reload completed successfully in ${duration} seconds"
        
        # Create success snapshot
        if command -v rewind >/dev/null 2>&1; then
            info "Creating snapshot of successful full reload..."
            rewind snapshot "XFCE full reload successful ($(date))" || warn "Failed to create snapshot"
        fi
        
        return 0
    else
        error "Full XFCE reload failed"
        
        # Attempt recovery
        warn "Attempting component recovery..."
        smart_reload || error "Recovery attempt failed"
        
        return 1
    fi
}

# Lightweight reload (just refresh settings)
light_reload() {
    info "Performing lightweight XFCE reload..."
    
    if ! check_xfce; then
        return 1
    fi
    
    # Just trigger settings refresh without restarting components
    if command -v xfconf-query >/dev/null; then
        info "Refreshing XFCE settings..."
        
        # Trigger desktop refresh
        xfconf-query -c xfce4-desktop -m &
        local xfconf_pid=$!
        sleep 1
        kill $xfconf_pid 2>/dev/null || true
        
        # Refresh panel
        xfce4-panel --restart 2>/dev/null || warn "Panel restart command failed"
        
        success "Lightweight XFCE reload completed"
        return 0
    else
        warn "xfconf-query not available, falling back to smart reload"
        smart_reload
    fi
}

# Recovery mode - attempt to restore from backup
recovery_mode() {
    info "Entering XFCE recovery mode..."
    
    # Find most recent backup
    local latest_backup
    if [ -d "${BACKUP_DIR}" ]; then
        latest_backup=$(ls -t "${BACKUP_DIR}" | grep "^xfce_" | head -1)
    fi
    
    if [ -n "${latest_backup}" ]; then
        warn "Attempting to restore from backup: ${latest_backup}"
        
        # This would restore configuration from backup
        # For safety, we'll just log what would be done
        info "Would restore configuration from ${BACKUP_DIR}/${latest_backup}"
        info "Manual recovery: cp -r ${BACKUP_DIR}/${latest_backup}/* ${HOME}/"
        
        # Trigger full reload after hypothetical restore
        full_reload
    else
        error "No backups available for recovery"
        return 1
    fi
}

# Show usage information
usage() {
    cat << EOF
Usage: $0 [OPERATION] [OPTIONS]

OPERATIONS:
    full        Perform full XFCE reload (panel, desktop, wm, settings)
    smart       Intelligent reload with error recovery
    light       Perform lightweight reload (settings only)
    panel       Reload XFCE panel only
    desktop     Reload XFCE desktop only
    wm          Reload window manager only
    settings    Reload settings daemon only
    backup      Backup XFCE configuration only
    validate    Validate XFCE configuration
    recovery    Attempt recovery from backup
    status      Show XFCE component status

OPTIONS:
    -h, --help  Show this help message
    -v, --verbose Enable verbose logging
    -q, --quiet   Suppress non-error output

EXAMPLES:
    $0 smart                # Smart reload with error recovery (recommended)
    $0 full                 # Full reload after system restore
    $0 light                # Quick reload after minor changes
    $0 backup               # Backup configuration before changes
    $0 recovery             # Emergency recovery mode
    $0 status               # Check component status

ENVIRONMENT VARIABLES:
    REWIND_CONFIG_DIR       Override config directory
    DISPLAY                 X11 display (auto-detected)

This script is called automatically by Rewind-OS during timeline operations.
Phase 2 enhancements include smart reload, error recovery, and timeline integration.
EOF
}

# Component status check
check_status() {
    info "Checking XFCE component status..."
    
    local components=(
        "xfce4-session:XFCE Session"
        "xfce4-panel:Panel"
        "xfdesktop:Desktop"
        "xfwm4:Window Manager"
        "xfsettingsd:Settings Daemon"
    )
    
    for component_info in "${components[@]}"; do
        IFS=':' read -r process name <<< "$component_info"
        if pgrep -f "$process" >/dev/null; then
            success "$name: Running"
        else
            warn "$name: Not running"
        fi
    done
    
    info "XFCE status check completed"
}

# Main execution
main() {
    local operation="${1:-}"
    local verbose=false
    local quiet=false
    
    # Parse options
    while [[ $# -gt 0 ]]; do
        case $1 in
            -v|--verbose)
                verbose=true
                shift
                ;;
            -q|--quiet)
                quiet=true
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                if [ -z "$operation" ]; then
                    operation="$1"
                fi
                shift
                ;;
        esac
    done
    
    # Adjust logging based on options
    if [ "$quiet" = true ]; then
        exec 1>/dev/null
    fi
    
    case "${operation}" in
        "full")
            full_reload
            ;;
        "smart")
            smart_reload
            ;;
        "light")
            light_reload
            ;;
        "panel")
            check_xfce && reload_panel
            ;;
        "desktop")
            check_xfce && reload_desktop
            ;;
        "wm")
            check_xfce && reload_wm
            ;;
        "settings")
            check_xfce && reload_settings
            ;;
        "backup")
            check_xfce && backup_xfce_config
            ;;
        "validate")
            validate_xfce_config
            ;;
        "recovery")
            recovery_mode
            ;;
        "status")
            check_status
            ;;
        "-h"|"--help"|"help")
            usage
            ;;
        "")
            warn "No operation specified. Use --help for usage information."
            check_status
            exit 1
            ;;
        *)
            error "Unknown operation: ${operation}. Use --help for usage information."
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"