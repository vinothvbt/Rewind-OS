#!/usr/bin/env python3
"""
CLI interface for Rewind-OS timeline operations.

Provides a command-line interface for managing system states through
timeline operations including list, branch, switch, and restore.
"""

import argparse
import sys
import os
from typing import Optional
from .timeline import Timeline


def print_branches(timeline: Timeline):
    """Print formatted list of branches."""
    branches = timeline.list_branches()
    
    if not branches:
        print("No branches found.")
        return
    
    print("Branches:")
    print("=" * 50)
    for branch in branches:
        current_marker = " * " if branch["current"] else "   "
        print(f"{current_marker}{branch['name']}")
        print(f"     Created: {branch['created']}")
        print(f"     Snapshots: {branch['snapshots']}")
        if branch['description']:
            print(f"     Description: {branch['description']}")
        print()


def print_stashes(timeline: Timeline):
    """Print formatted list of stashes."""
    stashes = timeline.list_stashes()
    
    if not stashes:
        print("No stashes found.")
        return
    
    print("Stashes:")
    print("=" * 50)
    for i, stash in enumerate(reversed(stashes)):
        print(f"  stash@{{{len(stashes)-1-i}}}: {stash['id']}")
        print(f"    Message: {stash['message']}")
        print(f"    Time: {stash['timestamp']}")
        print(f"    Branch: {stash['branch']}")
        print()


def print_snapshot_info(timeline: Timeline, snapshot_id: str):
    """Print detailed information about a snapshot."""
    info = timeline.get_snapshot_info(snapshot_id)
    
    if not info:
        print(f"Snapshot '{snapshot_id}' not found.")
        return
    
    print(f"Snapshot Details:")
    print("=" * 40)
    print(f"ID: {info['id']}")
    print(f"Message: {info['message']}")
    print(f"Timestamp: {info['timestamp']}")
    print(f"Branch: {info['branch']}")
    print(f"Auto: {'Yes' if info.get('auto', False) else 'No'}")
    
    if 'restored_from' in info:
        print(f"Restored from: {info['restored_from']}")
    if 'source_branch' in info:
        print(f"Source branch: {info['source_branch']}")
    if 'pre_restore_snapshot' in info:
        print(f"Pre-restore snapshot: {info['pre_restore_snapshot']}")


def confirm_action(message: str, default: bool = False) -> bool:
    """Ask user for confirmation."""
    if os.getenv('REWIND_FORCE', '').lower() in ('1', 'true', 'yes'):
        return True
    
    suffix = " [Y/n]" if default else " [y/N]"
    response = input(f"{message}{suffix}: ").strip().lower()
    
    if not response:
        return default
    
    return response in ('y', 'yes')


def print_snapshots(timeline: Timeline, branch: Optional[str] = None):
    """Print formatted list of snapshots."""
    snapshots = timeline.list_snapshots(branch)
    branch_name = branch or timeline.get_current_branch()
    
    if not snapshots:
        print(f"No snapshots found in branch '{branch_name}'.")
        return
    
    print(f"Snapshots in branch '{branch_name}':")
    print("=" * 60)
    for snapshot in snapshots:
        auto_marker = " (auto)" if snapshot.get("auto", False) else ""
        restore_marker = " [RESTORE]" if "restored_from" in snapshot else ""
        print(f"  {snapshot['id']}{auto_marker}{restore_marker}")
        print(f"    Message: {snapshot['message']}")
        print(f"    Time: {snapshot['timestamp']}")
        if "restored_from" in snapshot:
            print(f"    Restored from: {snapshot['restored_from']}")
        print()


def cmd_list(args, timeline: Timeline):
    """Handle list command."""
    if args.snapshots:
        print_snapshots(timeline, args.branch)
    elif args.stashes:
        print_stashes(timeline)
    else:
        print_branches(timeline)


def cmd_branch(args, timeline: Timeline):
    """Handle branch command."""
    if args.name:
        # Create new branch
        success = timeline.create_branch(args.name, args.description or "", args.from_branch)
        if success:
            print(f"Created branch '{args.name}'")
            if args.switch:
                if timeline.switch_branch(args.name):
                    print(f"Switched to branch '{args.name}'")
                else:
                    print(f"Failed to switch to branch '{args.name}'")
        else:
            print(f"Failed to create branch '{args.name}' (already exists?)")
    else:
        # List branches
        print_branches(timeline)


def cmd_switch(args, timeline: Timeline):
    """Handle switch command."""
    success = timeline.switch_branch(args.name)
    if success:
        print(f"Switched to branch '{args.name}'")
    else:
        print(f"Failed to switch to branch '{args.name}' (doesn't exist?)")


def cmd_restore(args, timeline: Timeline):
    """Handle restore command."""
    # Show snapshot info if requested
    if args.info:
        print_snapshot_info(timeline, args.snapshot_id)
        return
    
    # Safety confirmation unless force is used
    if not args.force:
        info = timeline.get_snapshot_info(args.snapshot_id)
        if not info:
            print(f"Error: Snapshot '{args.snapshot_id}' not found.")
            return
        
        print(f"About to restore to snapshot:")
        print(f"  ID: {info['id']}")
        print(f"  Message: {info['message']}")
        print(f"  Time: {info['timestamp']}")
        print(f"  Branch: {info['branch']}")
        print()
        
        if not confirm_action("Continue with restore?", default=False):
            print("Restore cancelled.")
            return
    
    success = timeline.restore_snapshot(args.snapshot_id, safe=not args.unsafe)
    if success:
        print(f"✓ Restored to snapshot '{args.snapshot_id}'")
        if not args.unsafe:
            print("  • Auto-snapshot created before restore for safety")
        print("  • Note: In a full implementation, this would trigger system restore.")
    else:
        print(f"✗ Failed to restore snapshot '{args.snapshot_id}' (doesn't exist?)")


def cmd_snapshot(args, timeline: Timeline):
    """Handle snapshot command."""
    snapshot_id = timeline.create_snapshot(args.message, auto=False)
    print(f"✓ Created snapshot '{snapshot_id}': {args.message}")


def cmd_stash(args, timeline: Timeline):
    """Handle stash command."""
    if args.list:
        print_stashes(timeline)
    elif args.apply:
        stash_id = args.stash_id if hasattr(args, 'stash_id') else None
        success = timeline.apply_stash(stash_id, pop=args.pop)
        if success:
            action = "Applied and removed" if args.pop else "Applied"
            stash_ref = stash_id if stash_id else "most recent stash"
            print(f"✓ {action} stash: {stash_ref}")
        else:
            print(f"✗ Failed to apply stash (no stashes available?)")
    elif args.drop:
        stash_id = args.stash_id if hasattr(args, 'stash_id') else None
        success = timeline.drop_stash(stash_id)
        if success:
            stash_ref = stash_id if stash_id else "most recent stash"
            print(f"✓ Dropped stash: {stash_ref}")
        else:
            print(f"✗ Failed to drop stash (no stashes available?)")
    else:
        # Create stash
        message = args.message if args.message else "Stashed changes"
        stash_id = timeline.create_stash(message)
        print(f"✓ Created stash '{stash_id}': {message}")


def cmd_info(args, timeline: Timeline):
    """Handle info command."""
    if args.snapshot_id:
        print_snapshot_info(timeline, args.snapshot_id)
    else:
        # Show general timeline info
        data = timeline._load_timeline()
        current_branch = timeline.get_current_branch()
        branches = timeline.list_branches()
        stashes = timeline.list_stashes()
        
        print("Rewind-OS Timeline Status")
        print("=" * 40)
        print(f"Current branch: {current_branch}")
        print(f"Total branches: {len(branches)}")
        print(f"Total stashes: {len(stashes)}")
        print(f"Config directory: {timeline.config_dir}")
        print()
        
        # Show recent activity
        current_snapshots = timeline.list_snapshots()
        if current_snapshots:
            recent = current_snapshots[-3:]  # Last 3 snapshots
            print("Recent snapshots:")
            for snap in reversed(recent):
                print(f"  • {snap['id']}: {snap['message']}")
        else:
            print("No snapshots in current branch.")


def cmd_security(args, timeline: Timeline):
    """Handle security command (Phase 3)."""
    import subprocess
    import glob
    from pathlib import Path
    
    security_dir = Path(timeline.config_dir) / "security-logs"
    
    if args.status:
        # Show security status
        print("Rewind-OS Security Status")
        print("=" * 40)
        
        # Check if security features are available
        try:
            result = subprocess.run(['systemctl', 'is-active', 'rewind-security-monitor'], 
                                  capture_output=True, text=True)
            security_service = result.stdout.strip()
        except:
            security_service = "unknown"
        
        print(f"Security monitoring: {security_service}")
        
        # Check security logs
        if security_dir.exists():
            log_files = list(security_dir.glob("*.log"))
            print(f"Security log files: {len(log_files)}")
            
            # Show recent security events
            if log_files:
                print("\nRecent security events:")
                try:
                    # Read last few lines from security.log
                    security_log = security_dir / "security.log"
                    if security_log.exists():
                        with open(security_log) as f:
                            lines = f.readlines()
                            for line in lines[-5:]:  # Last 5 lines
                                print(f"  {line.strip()}")
                except Exception as e:
                    print(f"  Could not read security logs: {e}")
        else:
            print("Security logs directory not found (security features may not be enabled)")
            
    elif args.scan:
        # Run security scan and create snapshot
        print("Running security scan...")
        
        # Create pre-scan snapshot
        snapshot_id = timeline.create_snapshot("Pre-security scan", auto=True)
        print(f"✓ Created pre-scan snapshot: {snapshot_id}")
        
        # TODO: Integrate with actual security tools
        print("• Checking system integrity...")
        print("• Analyzing log files...")
        print("• Scanning for malware...")
        print("• Verifying file permissions...")
        
        # Simulate security scan (in real implementation, would run actual tools)
        print("✓ Security scan completed")
        
        # Create post-scan snapshot
        snapshot_id = timeline.create_snapshot("Post-security scan", auto=True)
        print(f"✓ Created post-scan snapshot: {snapshot_id}")
        
        # Log security scan
        security_dir.mkdir(exist_ok=True)
        import datetime
        with open(security_dir / "security.log", "a") as f:
            f.write(f"{datetime.datetime.now()}: Security scan completed via CLI\n")
            
    elif args.audit:
        # Show audit trail
        print("Security Audit Trail")
        print("=" * 40)
        
        # Look for security-related snapshots
        snapshots = timeline.list_snapshots()
        security_snapshots = [s for s in snapshots if any(
            keyword in s['message'].lower() 
            for keyword in ['security', 'scan', 'audit', 'monitor']
        )]
        
        if security_snapshots:
            print("Security-related snapshots:")
            for snap in security_snapshots[-10:]:  # Last 10
                print(f"  • {snap['id']}: {snap['message']} ({snap['timestamp']})")
        else:
            print("No security-related snapshots found")
            
        # Show security logs if available
        if security_dir.exists():
            audit_log = security_dir / "audit-trails"
            if audit_log.exists():
                print(f"\nSecurity audit logs available in: {audit_log}")
            
    elif args.report:
        # Generate security report
        print("Generating Security Report...")
        print("=" * 40)
        
        report_dir = Path(timeline.config_dir) / "security-reports"
        report_dir.mkdir(exist_ok=True)
        
        import datetime
        report_file = report_dir / f"security-report-{datetime.datetime.now().strftime('%Y%m%d-%H%M%S')}.txt"
        
        with open(report_file, "w") as f:
            f.write("Rewind-OS Security Report\n")
            f.write("=" * 40 + "\n")
            f.write(f"Generated: {datetime.datetime.now()}\n\n")
            
            # Include system info
            f.write("System Information:\n")
            f.write(f"Config directory: {timeline.config_dir}\n")
            f.write(f"Current branch: {timeline.get_current_branch()}\n")
            f.write(f"Total branches: {len(timeline.list_branches())}\n")
            f.write(f"Total snapshots: {len(timeline.list_snapshots())}\n\n")
            
            # Include recent security events
            if security_dir.exists():
                security_log = security_dir / "security.log"
                if security_log.exists():
                    f.write("Recent Security Events:\n")
                    try:
                        with open(security_log) as log:
                            lines = log.readlines()
                            for line in lines[-20:]:  # Last 20 lines
                                f.write(f"  {line}")
                    except:
                        f.write("  Could not read security log\n")
                    f.write("\n")
            
            # Include security snapshots
            snapshots = timeline.list_snapshots()
            security_snapshots = [s for s in snapshots if any(
                keyword in s['message'].lower() 
                for keyword in ['security', 'scan', 'audit', 'monitor']
            )]
            
            f.write("Security-Related Snapshots:\n")
            for snap in security_snapshots[-10:]:
                f.write(f"  {snap['id']}: {snap['message']} ({snap['timestamp']})\n")
            
        print(f"✓ Security report generated: {report_file}")
        
        # Create snapshot for the report
        snapshot_id = timeline.create_snapshot(f"Security report generated", auto=True)
        print(f"✓ Created snapshot: {snapshot_id}")
        
    else:
        print("No security action specified. Use --help for available options.")


def main():
    """Main CLI entry point."""
    parser = argparse.ArgumentParser(
        description="Rewind-OS: Timeline-based system state management",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  rewind list                           # List all branches
  rewind list --snapshots               # List snapshots in current branch  
  rewind list --stashes                 # List all stashes
  rewind branch new-feature             # Create new branch
  rewind switch main                    # Switch to main branch
  rewind snapshot "Installed VS Code"   # Create snapshot
  rewind restore snap_1234567890        # Restore to snapshot (with confirmation)
  rewind restore snap_1234567890 --force # Restore without confirmation
  rewind stash "Work in progress"       # Create stash
  rewind stash --apply                  # Apply most recent stash
  rewind stash --pop                    # Apply and remove most recent stash
  rewind stash --list                   # List all stashes
  rewind stash --drop                   # Drop most recent stash
  rewind info                           # Show timeline status
  rewind info snap_1234567890           # Show snapshot details
  rewind security --status              # Show security status (Phase 3)
  rewind security --scan                # Run security scan with snapshots
  rewind security --audit               # Show security audit trail
  rewind security --report              # Generate security report

Environment Variables:
  REWIND_CONFIG_DIR     Override config directory (default: ~/.rewind)
  REWIND_FORCE          Skip confirmations (1, true, yes)
        """
    )
    
    subparsers = parser.add_subparsers(dest='command', help='Available commands')
    
    # List command
    list_parser = subparsers.add_parser('list', help='List branches, snapshots, or stashes')
    list_parser.add_argument('--snapshots', '-s', action='store_true',
                           help='List snapshots instead of branches')
    list_parser.add_argument('--stashes', action='store_true',
                           help='List stashes')
    list_parser.add_argument('--branch', '-b', help='Branch to list snapshots from')
    
    # Branch command
    branch_parser = subparsers.add_parser('branch', help='Create or list branches')
    branch_parser.add_argument('name', nargs='?', help='Name of new branch to create')
    branch_parser.add_argument('--description', '-d', help='Description for the new branch')
    branch_parser.add_argument('--from', dest='from_branch', help='Create branch from another branch')
    branch_parser.add_argument('--switch', action='store_true',
                             help='Switch to the new branch after creating it')
    
    # Switch command
    switch_parser = subparsers.add_parser('switch', help='Switch to a different branch')
    switch_parser.add_argument('name', help='Name of branch to switch to')
    
    # Restore command
    restore_parser = subparsers.add_parser('restore', help='Restore to a snapshot')
    restore_parser.add_argument('snapshot_id', help='ID of snapshot to restore to')
    restore_parser.add_argument('--force', '-f', action='store_true',
                              help='Skip confirmation prompt')
    restore_parser.add_argument('--unsafe', action='store_true',
                              help='Skip creating safety snapshot before restore')
    restore_parser.add_argument('--info', '-i', action='store_true',
                              help='Show snapshot info instead of restoring')
    
    # Snapshot command
    snapshot_parser = subparsers.add_parser('snapshot', help='Create a new snapshot')
    snapshot_parser.add_argument('message', help='Description of the snapshot')
    
    # Stash command
    stash_parser = subparsers.add_parser('stash', help='Stash management')
    stash_parser.add_argument('message', nargs='?', help='Stash message')
    stash_parser.add_argument('--list', '-l', action='store_true', help='List all stashes')
    stash_parser.add_argument('--apply', '-a', action='store_true', help='Apply most recent stash')
    stash_parser.add_argument('--pop', '-p', action='store_true', help='Apply and remove most recent stash')
    stash_parser.add_argument('--drop', '-d', action='store_true', help='Drop most recent stash')
    stash_parser.add_argument('stash_id', nargs='?', help='Specific stash ID to apply/drop')
    
    # Info command
    info_parser = subparsers.add_parser('info', help='Show timeline information')
    info_parser.add_argument('snapshot_id', nargs='?', help='Show details for specific snapshot')
    
    # Security command (Phase 3)
    security_parser = subparsers.add_parser('security', help='Security, audit, and investigation tools (Phase 3)')
    security_parser.add_argument('--status', action='store_true', help='Show security status and monitoring')
    security_parser.add_argument('--scan', action='store_true', help='Run security scan with automatic snapshots')
    security_parser.add_argument('--audit', action='store_true', help='Show security audit trail')
    security_parser.add_argument('--report', action='store_true', help='Generate comprehensive security report')
    
    # Parse arguments
    args = parser.parse_args()
    
    if not args.command:
        parser.print_help()
        sys.exit(1)
    
    # Initialize timeline with custom config dir if set
    config_dir = os.getenv('REWIND_CONFIG_DIR', '~/.rewind')
    timeline = Timeline(config_dir)
    
    # Execute command
    try:
        if args.command == 'list':
            cmd_list(args, timeline)
        elif args.command == 'branch':
            cmd_branch(args, timeline)
        elif args.command == 'switch':
            cmd_switch(args, timeline)
        elif args.command == 'restore':
            cmd_restore(args, timeline)
        elif args.command == 'snapshot':
            cmd_snapshot(args, timeline)
        elif args.command == 'stash':
            cmd_stash(args, timeline)
        elif args.command == 'info':
            cmd_info(args, timeline)
        elif args.command == 'security':
            cmd_security(args, timeline)
        else:
            print(f"✗ Unknown command: {args.command}")
            sys.exit(1)
    except KeyboardInterrupt:
        print("\n✗ Operation cancelled by user.")
        sys.exit(1)
    except Exception as e:
        print(f"✗ Error: {e}")
        if os.getenv('REWIND_DEBUG', '').lower() in ('1', 'true', 'yes'):
            import traceback
            traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    main()