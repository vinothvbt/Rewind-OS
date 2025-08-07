#!/usr/bin/env python3
"""
Timeline operations for Rewind-OS.

This module handles the core timeline functionality including:
- Listing available snapshots and branches
- Creating new branches
- Switching between branches
- Restoring to previous states
"""

import os
import json
import subprocess
import datetime
from pathlib import Path
from typing import List, Dict, Optional


class Timeline:
    """Manages timeline operations for system state management."""
    
    def __init__(self, config_dir: str = "~/.rewind"):
        """Initialize Timeline with configuration directory."""
        self.config_dir = Path(config_dir).expanduser()
        self.config_dir.mkdir(parents=True, exist_ok=True)
        
        self.timeline_file = self.config_dir / "timeline.json"
        self.current_branch_file = self.config_dir / "current_branch"
        
        # Initialize timeline data if it doesn't exist
        if not self.timeline_file.exists():
            self._init_timeline()
    
    def _init_timeline(self):
        """Initialize the timeline data structure."""
        initial_data = {
            "branches": {
                "main": {
                    "created": datetime.datetime.now().isoformat(),
                    "snapshots": [],
                    "description": "Main timeline branch"
                }
            },
            "current_branch": "main"
        }
        
        with open(self.timeline_file, 'w') as f:
            json.dump(initial_data, f, indent=2)
        
        with open(self.current_branch_file, 'w') as f:
            f.write("main")
    
    def _load_timeline(self) -> Dict:
        """Load timeline data from file."""
        try:
            with open(self.timeline_file, 'r') as f:
                return json.load(f)
        except (FileNotFoundError, json.JSONDecodeError):
            self._init_timeline()
            return self._load_timeline()
    
    def _save_timeline(self, data: Dict):
        """Save timeline data to file."""
        with open(self.timeline_file, 'w') as f:
            json.dump(data, f, indent=2)
    
    def get_current_branch(self) -> str:
        """Get the current active branch."""
        try:
            with open(self.current_branch_file, 'r') as f:
                return f.read().strip()
        except FileNotFoundError:
            return "main"
    
    def list_branches(self) -> List[Dict]:
        """List all available branches with their snapshots."""
        data = self._load_timeline()
        current_branch = self.get_current_branch()
        
        branches = []
        for branch_name, branch_data in data.get("branches", {}).items():
            branch_info = {
                "name": branch_name,
                "current": branch_name == current_branch,
                "created": branch_data.get("created", "Unknown"),
                "description": branch_data.get("description", ""),
                "snapshots": len(branch_data.get("snapshots", []))
            }
            branches.append(branch_info)
        
        return branches
    
    def list_snapshots(self, branch: Optional[str] = None) -> List[Dict]:
        """List snapshots in a specific branch or current branch."""
        data = self._load_timeline()
        branch_name = branch or self.get_current_branch()
        
        if branch_name not in data.get("branches", {}):
            return []
        
        return data["branches"][branch_name].get("snapshots", [])
    
    def create_branch(self, name: str, description: str = "", from_branch: Optional[str] = None) -> bool:
        """Create a new branch from current or specified branch."""
        data = self._load_timeline()
        
        if name in data.get("branches", {}):
            return False  # Branch already exists
        
        source_branch = from_branch or self.get_current_branch()
        source_data = data["branches"].get(source_branch, {})
        
        new_branch = {
            "created": datetime.datetime.now().isoformat(),
            "description": description,
            "snapshots": source_data.get("snapshots", []).copy(),
            "parent": source_branch
        }
        
        data["branches"][name] = new_branch
        self._save_timeline(data)
        return True
    
    def switch_branch(self, name: str) -> bool:
        """Switch to a different branch."""
        data = self._load_timeline()
        
        if name not in data.get("branches", {}):
            return False  # Branch doesn't exist
        
        # Update current branch
        data["current_branch"] = name
        self._save_timeline(data)
        
        with open(self.current_branch_file, 'w') as f:
            f.write(name)
        
        return True
    
    def create_snapshot(self, message: str, auto: bool = False) -> str:
        """Create a new snapshot in the current branch."""
        data = self._load_timeline()
        current_branch = self.get_current_branch()
        
        snapshot_id = f"snap_{int(datetime.datetime.now().timestamp())}"
        snapshot = {
            "id": snapshot_id,
            "message": message,
            "timestamp": datetime.datetime.now().isoformat(),
            "auto": auto,
            "branch": current_branch
        }
        
        if current_branch not in data["branches"]:
            data["branches"][current_branch] = {
                "created": datetime.datetime.now().isoformat(),
                "snapshots": [],
                "description": f"Branch {current_branch}"
            }
        
        data["branches"][current_branch]["snapshots"].append(snapshot)
        self._save_timeline(data)
        
        return snapshot_id
    
    def restore_snapshot(self, snapshot_id: str, safe: bool = True) -> bool:
        """Restore system to a specific snapshot."""
        data = self._load_timeline()
        current_branch = self.get_current_branch()
        
        # Find the snapshot
        snapshot = None
        source_branch = None
        for branch_name, branch_data in data["branches"].items():
            for snap in branch_data.get("snapshots", []):
                if snap["id"] == snapshot_id:
                    snapshot = snap
                    source_branch = branch_name
                    break
            if snapshot:
                break
        
        if not snapshot:
            return False
        
        # Safety check: create auto-snapshot before restore if safe mode enabled
        if safe:
            auto_snapshot_id = self.create_snapshot(
                f"Auto-snapshot before restore to {snapshot_id}", 
                auto=True
            )
        
        # In a real implementation, this would trigger the actual system restore
        # For now, we'll just simulate it by creating a restore record
        restore_record = {
            "id": f"restore_{int(datetime.datetime.now().timestamp())}",
            "message": f"Restored to snapshot {snapshot_id}: {snapshot['message']}",
            "timestamp": datetime.datetime.now().isoformat(),
            "auto": False,
            "branch": current_branch,
            "restored_from": snapshot_id,
            "source_branch": source_branch,
            "pre_restore_snapshot": auto_snapshot_id if safe else None
        }
        
        data["branches"][current_branch]["snapshots"].append(restore_record)
        self._save_timeline(data)
        
        return True
    
    def create_stash(self, message: str = "Stashed changes") -> str:
        """Create a stash of current changes."""
        data = self._load_timeline()
        current_branch = self.get_current_branch()
        
        stash_id = f"stash_{int(datetime.datetime.now().timestamp())}"
        stash = {
            "id": stash_id,
            "message": message,
            "timestamp": datetime.datetime.now().isoformat(),
            "branch": current_branch,
            "type": "stash"
        }
        
        # Create stashes list if it doesn't exist
        if "stashes" not in data:
            data["stashes"] = []
        
        data["stashes"].append(stash)
        self._save_timeline(data)
        
        return stash_id
    
    def list_stashes(self) -> List[Dict]:
        """List all stashes."""
        data = self._load_timeline()
        return data.get("stashes", [])
    
    def apply_stash(self, stash_id: str = None, pop: bool = False) -> bool:
        """Apply a stash. If stash_id is None, applies the most recent stash."""
        data = self._load_timeline()
        stashes = data.get("stashes", [])
        
        if not stashes:
            return False
        
        # Find the stash
        stash = None
        stash_index = None
        if stash_id:
            for i, s in enumerate(stashes):
                if s["id"] == stash_id:
                    stash = s
                    stash_index = i
                    break
        else:
            # Use most recent stash
            stash = stashes[-1]
            stash_index = len(stashes) - 1
        
        if not stash:
            return False
        
        current_branch = self.get_current_branch()
        
        # Create snapshot for stash application
        apply_record = {
            "id": f"stash_apply_{int(datetime.datetime.now().timestamp())}",
            "message": f"Applied stash {stash['id']}: {stash['message']}",
            "timestamp": datetime.datetime.now().isoformat(),
            "auto": False,
            "branch": current_branch,
            "stash_applied": stash["id"],
            "type": "stash_apply"
        }
        
        data["branches"][current_branch]["snapshots"].append(apply_record)
        
        # Remove stash if pop=True
        if pop and stash_index is not None:
            data["stashes"].pop(stash_index)
        
        self._save_timeline(data)
        return True
    
    def drop_stash(self, stash_id: str = None) -> bool:
        """Drop a stash. If stash_id is None, drops the most recent stash."""
        data = self._load_timeline()
        stashes = data.get("stashes", [])
        
        if not stashes:
            return False
        
        if stash_id:
            # Find and remove specific stash
            for i, stash in enumerate(stashes):
                if stash["id"] == stash_id:
                    data["stashes"].pop(i)
                    self._save_timeline(data)
                    return True
            return False
        else:
            # Remove most recent stash
            data["stashes"].pop()
            self._save_timeline(data)
            return True
    
    def get_snapshot_info(self, snapshot_id: str) -> Optional[Dict]:
        """Get detailed information about a specific snapshot."""
        data = self._load_timeline()
        
        for branch_name, branch_data in data["branches"].items():
            for snap in branch_data.get("snapshots", []):
                if snap["id"] == snapshot_id:
                    snap_info = snap.copy()
                    snap_info["branch"] = branch_name
                    return snap_info
        
        return None