#!/usr/bin/env python3
"""
End-to-end test suite for Rewind-OS timeline operations.

This script tests the complete timeline functionality including:
- Snapshot creation and listing
- Branch operations
- Stash management
- Restore operations
- Error handling
"""

import os
import sys
import tempfile
import shutil
import subprocess
import json
from pathlib import Path

# Add the parent directory to sys.path to import rewind modules
sys.path.insert(0, str(Path(__file__).parent.parent))

from rewind.timeline import Timeline
from rewind.cli import main as cli_main

class RewindTestSuite:
    """End-to-end test suite for Rewind-OS."""
    
    def __init__(self):
        self.test_dir = tempfile.mkdtemp(prefix="rewind_test_")
        self.original_config_dir = os.environ.get('REWIND_CONFIG_DIR')
        os.environ['REWIND_CONFIG_DIR'] = self.test_dir
        self.timeline = Timeline(self.test_dir)
        self.passed_tests = 0
        self.failed_tests = 0
        self.test_results = []
        
    def log(self, message, level="INFO"):
        """Log test messages."""
        print(f"[{level}] {message}")
        
    def assert_true(self, condition, message):
        """Assert that condition is true."""
        if condition:
            self.log(f"✓ PASS: {message}", "PASS")
            self.passed_tests += 1
            self.test_results.append({"test": message, "result": "PASS"})
            return True
        else:
            self.log(f"✗ FAIL: {message}", "FAIL")
            self.failed_tests += 1
            self.test_results.append({"test": message, "result": "FAIL"})
            return False
            
    def assert_equal(self, actual, expected, message):
        """Assert that actual equals expected."""
        return self.assert_true(actual == expected, f"{message} (expected: {expected}, got: {actual})")
        
    def run_cli_command(self, args):
        """Run CLI command and return result."""
        try:
            # Temporarily redirect sys.argv
            original_argv = sys.argv
            sys.argv = ['rewind'] + args
            
            # Capture output
            from io import StringIO
            original_stdout = sys.stdout
            captured_output = StringIO()
            sys.stdout = captured_output
            
            # Run command
            try:
                cli_main()
                success = True
                error = None
            except SystemExit as e:
                success = e.code == 0
                error = e.code
            except Exception as e:
                success = False
                error = str(e)
            
            # Restore original state
            sys.stdout = original_stdout
            sys.argv = original_argv
            
            output = captured_output.getvalue()
            return success, output, error
            
        except Exception as e:
            return False, "", str(e)
    
    def test_timeline_initialization(self):
        """Test timeline initialization."""
        self.log("Testing timeline initialization...")
        
        # Test timeline creation
        self.assert_true(
            os.path.exists(self.timeline.timeline_file),
            "Timeline file should be created"
        )
        
        # Test current branch file
        self.assert_true(
            os.path.exists(self.timeline.current_branch_file),
            "Current branch file should be created"
        )
        
        # Test default branch
        current_branch = self.timeline.get_current_branch()
        self.assert_equal(current_branch, "main", "Default branch should be 'main'")
        
        # Test branches list
        branches = self.timeline.list_branches()
        self.assert_equal(len(branches), 1, "Should have exactly one branch initially")
        self.assert_equal(branches[0]['name'], "main", "First branch should be 'main'")
        
    def test_snapshot_operations(self):
        """Test snapshot creation and listing."""
        self.log("Testing snapshot operations...")
        
        # Test snapshot creation
        snapshot_id = self.timeline.create_snapshot("Test snapshot 1")
        self.assert_true(snapshot_id.startswith("snap_"), "Snapshot ID should start with 'snap_'")
        
        # Test snapshot listing
        snapshots = self.timeline.list_snapshots()
        self.assert_equal(len(snapshots), 1, "Should have one snapshot")
        self.assert_equal(snapshots[0]['message'], "Test snapshot 1", "Snapshot message should match")
        
        # Test multiple snapshots
        snapshot_id2 = self.timeline.create_snapshot("Test snapshot 2")
        snapshots = self.timeline.list_snapshots()
        self.assert_equal(len(snapshots), 2, "Should have two snapshots")
        
        # Test automatic snapshots
        auto_snapshot_id = self.timeline.create_snapshot("Auto snapshot", auto=True)
        snapshots = self.timeline.list_snapshots()
        auto_snapshots = [s for s in snapshots if s.get('auto', False)]
        self.assert_equal(len(auto_snapshots), 1, "Should have one automatic snapshot")
        
    def test_branch_operations(self):
        """Test branch creation and switching."""
        self.log("Testing branch operations...")
        
        # Create test snapshot for branching
        self.timeline.create_snapshot("Base snapshot")
        
        # Test branch creation
        success = self.timeline.create_branch("test-branch", "Test branch")
        self.assert_true(success, "Branch creation should succeed")
        
        # Test duplicate branch creation
        success = self.timeline.create_branch("test-branch", "Duplicate")
        self.assert_true(not success, "Duplicate branch creation should fail")
        
        # Test branch listing
        branches = self.timeline.list_branches()
        self.assert_equal(len(branches), 2, "Should have two branches")
        branch_names = [b['name'] for b in branches]
        self.assert_true("test-branch" in branch_names, "test-branch should exist")
        
        # Test branch switching
        success = self.timeline.switch_branch("test-branch")
        self.assert_true(success, "Branch switching should succeed")
        
        current_branch = self.timeline.get_current_branch()
        self.assert_equal(current_branch, "test-branch", "Current branch should be 'test-branch'")
        
        # Test switching to non-existent branch
        success = self.timeline.switch_branch("non-existent")
        self.assert_true(not success, "Switching to non-existent branch should fail")
        
        # Switch back to main
        self.timeline.switch_branch("main")
        
    def test_stash_operations(self):
        """Test stash functionality."""
        self.log("Testing stash operations...")
        
        # Test stash creation
        stash_id = self.timeline.create_stash("Test stash 1")
        self.assert_true(stash_id.startswith("stash_"), "Stash ID should start with 'stash_'")
        
        # Test stash listing
        stashes = self.timeline.list_stashes()
        self.assert_equal(len(stashes), 1, "Should have one stash")
        self.assert_equal(stashes[0]['message'], "Test stash 1", "Stash message should match")
        
        # Test multiple stashes
        self.timeline.create_stash("Test stash 2")
        stashes = self.timeline.list_stashes()
        self.assert_equal(len(stashes), 2, "Should have two stashes")
        
        # Test stash apply
        success = self.timeline.apply_stash()
        self.assert_true(success, "Stash apply should succeed")
        
        # Test stash pop (apply and remove)
        success = self.timeline.apply_stash(pop=True)
        self.assert_true(success, "Stash pop should succeed")
        
        stashes = self.timeline.list_stashes()
        self.assert_equal(len(stashes), 1, "Should have one stash after pop")
        
        # Test stash drop
        success = self.timeline.drop_stash()
        self.assert_true(success, "Stash drop should succeed")
        
        stashes = self.timeline.list_stashes()
        self.assert_equal(len(stashes), 0, "Should have no stashes after drop")
        
        # Test operations on empty stash list
        success = self.timeline.apply_stash()
        self.assert_true(not success, "Apply on empty stash list should fail")
        
        success = self.timeline.drop_stash()
        self.assert_true(not success, "Drop on empty stash list should fail")
        
    def test_restore_operations(self):
        """Test snapshot restore functionality."""
        self.log("Testing restore operations...")
        
        # Create snapshots for testing
        snapshot_id1 = self.timeline.create_snapshot("Snapshot for restore test 1")
        snapshot_id2 = self.timeline.create_snapshot("Snapshot for restore test 2")
        
        # Test restore
        success = self.timeline.restore_snapshot(snapshot_id1)
        self.assert_true(success, "Snapshot restore should succeed")
        
        # Verify restore record was created
        snapshots = self.timeline.list_snapshots()
        restore_records = [s for s in snapshots if 'restored_from' in s]
        self.assert_equal(len(restore_records), 1, "Should have one restore record")
        self.assert_equal(restore_records[0]['restored_from'], snapshot_id1, "Restore record should reference correct snapshot")
        
        # Test restore with non-existent snapshot
        success = self.timeline.restore_snapshot("nonexistent_snapshot")
        self.assert_true(not success, "Restore of non-existent snapshot should fail")
        
    def test_cli_integration(self):
        """Test CLI command integration."""
        self.log("Testing CLI integration...")
        
        # Set force mode to avoid interactive prompts
        os.environ['REWIND_FORCE'] = '1'
        
        try:
            # Test list command
            success, output, error = self.run_cli_command(['list'])
            self.assert_true(success, "CLI list command should succeed")
            self.assert_true("main" in output, "CLI list should show main branch")
            
            # Test snapshot command
            success, output, error = self.run_cli_command(['snapshot', 'CLI test snapshot'])
            self.assert_true(success, "CLI snapshot command should succeed")
            self.assert_true("Created snapshot" in output, "CLI should confirm snapshot creation")
            
            # Test list snapshots
            success, output, error = self.run_cli_command(['list', '--snapshots'])
            self.assert_true(success, "CLI list snapshots should succeed")
            self.assert_true("CLI test snapshot" in output, "CLI should show created snapshot")
            
            # Test stash commands
            success, output, error = self.run_cli_command(['stash', 'CLI test stash'])
            self.assert_true(success, "CLI stash command should succeed")
            
            success, output, error = self.run_cli_command(['list', '--stashes'])
            self.assert_true(success, "CLI list stashes should succeed")
            self.assert_true("CLI test stash" in output, "CLI should show created stash")
            
            # Test info command
            success, output, error = self.run_cli_command(['info'])
            self.assert_true(success, "CLI info command should succeed")
            self.assert_true("Current branch" in output, "CLI info should show current branch")
            
        finally:
            # Clean up environment
            if 'REWIND_FORCE' in os.environ:
                del os.environ['REWIND_FORCE']
    
    def test_error_handling(self):
        """Test error handling scenarios."""
        self.log("Testing error handling...")
        
        # Test with corrupted timeline file
        timeline_backup = None
        if os.path.exists(self.timeline.timeline_file):
            with open(self.timeline.timeline_file, 'r') as f:
                timeline_backup = f.read()
            
            # Corrupt the file
            with open(self.timeline.timeline_file, 'w') as f:
                f.write("invalid json content")
        
        try:
            # Should handle corrupted file gracefully
            new_timeline = Timeline(self.test_dir)
            branches = new_timeline.list_branches()
            self.assert_true(len(branches) > 0, "Should recover from corrupted timeline file")
            
        finally:
            # Restore original timeline
            if timeline_backup:
                with open(self.timeline.timeline_file, 'w') as f:
                    f.write(timeline_backup)
        
        # Test with readonly directory
        readonly_dir = os.path.join(self.test_dir, "readonly")
        os.makedirs(readonly_dir, exist_ok=True)
        os.chmod(readonly_dir, 0o444)
        
        try:
            # Should handle readonly directory gracefully
            readonly_timeline = Timeline(readonly_dir)
            # This should either work or fail gracefully without crashing
            
        except PermissionError:
            self.assert_true(True, "Should handle permission errors gracefully")
        finally:
            # Restore permissions for cleanup
            os.chmod(readonly_dir, 0o755)
    
    def test_data_persistence(self):
        """Test data persistence across timeline instances."""
        self.log("Testing data persistence...")
        
        # Create data with first timeline instance
        snapshot_id = self.timeline.create_snapshot("Persistence test")
        stash_id = self.timeline.create_stash("Persistence stash")
        self.timeline.create_branch("persist-branch", "Persistence branch")
        
        # Create new timeline instance
        new_timeline = Timeline(self.test_dir)
        
        # Verify data persistence
        snapshots = new_timeline.list_snapshots()
        self.assert_true(any(s['message'] == "Persistence test" for s in snapshots), 
                        "Snapshots should persist across instances")
        
        stashes = new_timeline.list_stashes()
        self.assert_true(any(s['message'] == "Persistence stash" for s in stashes),
                        "Stashes should persist across instances")
        
        branches = new_timeline.list_branches()
        self.assert_true(any(b['name'] == "persist-branch" for b in branches),
                        "Branches should persist across instances")
    
    def run_all_tests(self):
        """Run all test suites."""
        self.log("Starting Rewind-OS End-to-End Test Suite")
        self.log(f"Test directory: {self.test_dir}")
        
        try:
            self.test_timeline_initialization()
            self.test_snapshot_operations()
            self.test_branch_operations()
            self.test_stash_operations()
            self.test_restore_operations()
            self.test_cli_integration()
            self.test_error_handling()
            self.test_data_persistence()
            
        except Exception as e:
            self.log(f"Unexpected error during testing: {e}", "ERROR")
            self.failed_tests += 1
            
        finally:
            self.print_summary()
            self.cleanup()
    
    def print_summary(self):
        """Print test summary."""
        total_tests = self.passed_tests + self.failed_tests
        pass_rate = (self.passed_tests / total_tests) * 100 if total_tests > 0 else 0
        
        self.log("=" * 60)
        self.log("TEST SUMMARY")
        self.log("=" * 60)
        self.log(f"Total tests: {total_tests}")
        self.log(f"Passed: {self.passed_tests}")
        self.log(f"Failed: {self.failed_tests}")
        self.log(f"Pass rate: {pass_rate:.1f}%")
        
        if self.failed_tests > 0:
            self.log("\nFAILED TESTS:")
            for result in self.test_results:
                if result['result'] == 'FAIL':
                    self.log(f"  - {result['test']}")
        
        self.log("=" * 60)
        
        # Create test report
        report = {
            "timestamp": str(Path(__file__).stat().st_mtime),
            "total_tests": total_tests,
            "passed": self.passed_tests,
            "failed": self.failed_tests,
            "pass_rate": pass_rate,
            "test_directory": self.test_dir,
            "results": self.test_results
        }
        
        report_file = os.path.join(self.test_dir, "test_report.json")
        with open(report_file, 'w') as f:
            json.dump(report, f, indent=2)
        
        self.log(f"Test report saved to: {report_file}")
    
    def cleanup(self):
        """Clean up test environment."""
        try:
            shutil.rmtree(self.test_dir)
            self.log(f"Cleaned up test directory: {self.test_dir}")
        except Exception as e:
            self.log(f"Warning: Could not clean up test directory: {e}", "WARN")
        
        # Restore original environment
        if self.original_config_dir:
            os.environ['REWIND_CONFIG_DIR'] = self.original_config_dir
        elif 'REWIND_CONFIG_DIR' in os.environ:
            del os.environ['REWIND_CONFIG_DIR']

def main():
    """Main test runner."""
    test_suite = RewindTestSuite()
    test_suite.run_all_tests()
    
    # Exit with non-zero code if tests failed
    sys.exit(1 if test_suite.failed_tests > 0 else 0)

if __name__ == "__main__":
    main()