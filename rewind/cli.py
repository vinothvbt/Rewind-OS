#!/usr/bin/env python3
"""
CLI interface for Rewind-OS timeline operations.

Provides a command-line interface for managing system states through
timeline operations including list, branch, switch, and restore.
"""

import argparse
import sys
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
    success = timeline.restore_snapshot(args.snapshot_id)
    if success:
        print(f"Restored to snapshot '{args.snapshot_id}'")
        print("Note: In a full implementation, this would trigger system restore.")
    else:
        print(f"Failed to restore snapshot '{args.snapshot_id}' (doesn't exist?)")


def cmd_snapshot(args, timeline: Timeline):
    """Handle snapshot command."""
    snapshot_id = timeline.create_snapshot(args.message, auto=False)
    print(f"Created snapshot '{snapshot_id}': {args.message}")


def main():
    """Main CLI entry point."""
    parser = argparse.ArgumentParser(
        description="Rewind-OS: Timeline-based system state management",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  rewind list                    # List all branches
  rewind list --snapshots        # List snapshots in current branch
  rewind branch new-feature      # Create new branch
  rewind switch main             # Switch to main branch
  rewind snapshot "Installed VS Code"  # Create snapshot
  rewind restore snap_1234567890 # Restore to snapshot
        """
    )
    
    subparsers = parser.add_subparsers(dest='command', help='Available commands')
    
    # List command
    list_parser = subparsers.add_parser('list', help='List branches or snapshots')
    list_parser.add_argument('--snapshots', '-s', action='store_true',
                           help='List snapshots instead of branches')
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
    
    # Snapshot command
    snapshot_parser = subparsers.add_parser('snapshot', help='Create a new snapshot')
    snapshot_parser.add_argument('message', help='Description of the snapshot')
    
    # Parse arguments
    args = parser.parse_args()
    
    if not args.command:
        parser.print_help()
        sys.exit(1)
    
    # Initialize timeline
    timeline = Timeline()
    
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
        else:
            print(f"Unknown command: {args.command}")
            sys.exit(1)
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()