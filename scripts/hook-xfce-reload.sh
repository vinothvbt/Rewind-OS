#!/bin/bash
#
# XFCE Reload Hook for Rewind-OS
#
# This script handles XFCE desktop environment reload operations
# when system state changes occur (snapshots, restores, branch switches).
#
# Usage: hook-xfce-reload.sh [operation] [options]
#

set -euo pipefail

# Configuration
REWIND_CONFIG_DIR="${HOME}/.rewind"
LOG_FILE="${REWIND_CONFIG_DIR}/xfce-reload.log"
BACKUP_DIR="${REWIND_CONFIG_DIR}/xfce-backups"

# Ensure directories exist
mkdir -p "${REWIND_CONFIG_DIR}" "${BACKUP_DIR}"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "${LOG_FILE}"
}

# Error handling
error() {
    log "ERROR: $*"
    exit 1
}

# Check if XFCE is running
check_xfce() {
    if ! pgrep -x "xfce4-session" > /dev/null; then
        log "XFCE session not detected. Skipping reload."
        exit 0
    fi
}

# Backup current XFCE configuration
backup_xfce_config() {
    local backup_timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_path="${BACKUP_DIR}/xfce_${backup_timestamp}"
    
    log "Backing up XFCE configuration to ${backup_path}"
    
    mkdir -p "${backup_path}"
    
    # Backup key XFCE configuration directories
    if [[ -d "${HOME}/.config/xfce4" ]]; then
        cp -r "${HOME}/.config/xfce4" "${backup_path}/" 2>/dev/null || log "Warning: Could not backup .config/xfce4"
    fi
    
    if [[ -d "${HOME}/.local/share/xfce4" ]]; then
        cp -r "${HOME}/.local/share/xfce4" "${backup_path}/" 2>/dev/null || log "Warning: Could not backup .local/share/xfce4"
    fi
    
    echo "${backup_timestamp}" > "${backup_path}/timestamp"
    log "XFCE configuration backed up successfully"
}

# Reload XFCE panel
reload_panel() {
    log "Reloading XFCE panel..."
    
    if command -v xfce4-panel > /dev/null; then
        # Kill and restart panel
        pkill -f xfce4-panel || true
        sleep 1
        nohup xfce4-panel > /dev/null 2>&1 &
        log "XFCE panel reloaded"
    else
        log "Warning: xfce4-panel command not found"
    fi
}

# Reload desktop
reload_desktop() {
    log "Reloading XFCE desktop..."
    
    if command -v xfdesktop > /dev/null; then
        # Reload desktop
        pkill -f xfdesktop || true
        sleep 1
        nohup xfdesktop > /dev/null 2>&1 &
        log "XFCE desktop reloaded"
    else
        log "Warning: xfdesktop command not found"
    fi
}

# Reload window manager
reload_wm() {
    log "Reloading XFCE window manager..."
    
    if command -v xfwm4 > /dev/null; then
        # Reload window manager settings
        xfwm4 --replace > /dev/null 2>&1 &
        log "XFCE window manager reloaded"
    else
        log "Warning: xfwm4 command not found"
    fi
}

# Reload settings daemon
reload_settings() {
    log "Reloading XFCE settings daemon..."
    
    if command -v xfsettingsd > /dev/null; then
        # Kill and restart settings daemon
        pkill -f xfsettingsd || true
        sleep 1
        nohup xfsettingsd > /dev/null 2>&1 &
        log "XFCE settings daemon reloaded"
    else
        log "Warning: xfsettingsd command not found"
    fi
}

# Full XFCE reload
full_reload() {
    log "Performing full XFCE reload..."
    
    check_xfce
    backup_xfce_config
    
    reload_settings
    sleep 2
    reload_panel
    sleep 1
    reload_desktop
    sleep 1
    reload_wm
    
    log "Full XFCE reload completed"
}

# Lightweight reload (just refresh settings)
light_reload() {
    log "Performing lightweight XFCE reload..."
    
    check_xfce
    
    # Just reload settings without restarting components
    if command -v xfconf-query > /dev/null; then
        # Trigger settings reload
        xfconf-query -c xfce4-desktop -m &
        local xfconf_pid=$!
        sleep 1
        kill $xfconf_pid 2>/dev/null || true
    fi
    
    log "Lightweight XFCE reload completed"
}

# Show usage information
usage() {
    cat << EOF
Usage: $0 [OPERATION] [OPTIONS]

OPERATIONS:
    full        Perform full XFCE reload (panel, desktop, wm, settings)
    light       Perform lightweight reload (settings only)
    panel       Reload XFCE panel only
    desktop     Reload XFCE desktop only
    wm          Reload window manager only
    settings    Reload settings daemon only
    backup      Backup XFCE configuration only

OPTIONS:
    -h, --help  Show this help message

EXAMPLES:
    $0 full                 # Full reload after system restore
    $0 light                # Quick reload after minor changes
    $0 backup               # Backup configuration before changes

This script is called automatically by Rewind-OS during timeline operations.
EOF
}

# Main execution
main() {
    local operation="${1:-}"
    
    case "${operation}" in
        "full")
            full_reload
            ;;
        "light")
            light_reload
            ;;
        "panel")
            check_xfce
            reload_panel
            ;;
        "desktop")
            check_xfce
            reload_desktop
            ;;
        "wm")
            check_xfce
            reload_wm
            ;;
        "settings")
            check_xfce
            reload_settings
            ;;
        "backup")
            check_xfce
            backup_xfce_config
            ;;
        "-h"|"--help"|"help")
            usage
            ;;
        "")
            log "No operation specified. Use --help for usage information."
            exit 1
            ;;
        *)
            error "Unknown operation: ${operation}. Use --help for usage information."
            ;;
    esac
}

# Run main function with all arguments
main "$@"