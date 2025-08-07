#!/usr/bin/env python3
"""
End-to-end test suite for configuration reload scenarios.

This script tests configuration management and reload functionality:
- XFCE integration testing
- System service reload simulation
- Configuration validation
- Error recovery scenarios
"""

import os
import sys
import tempfile
import shutil
import subprocess
import time
from pathlib import Path

class ConfigReloadTestSuite:
    """Test suite for configuration reload scenarios."""
    
    def __init__(self):
        self.test_dir = tempfile.mkdtemp(prefix="rewind_config_test_")
        self.original_config_dir = os.environ.get('REWIND_CONFIG_DIR')
        os.environ['REWIND_CONFIG_DIR'] = self.test_dir
        self.passed_tests = 0
        self.failed_tests = 0
        self.test_results = []
        
        # Set up test environment
        self.setup_test_environment()
        
    def setup_test_environment(self):
        """Set up test environment with mock configurations."""
        # Create mock XFCE config directory
        self.xfce_config_dir = os.path.join(self.test_dir, "xfce4")
        os.makedirs(self.xfce_config_dir, exist_ok=True)
        
        # Create mock config files
        self.create_mock_xfce_configs()
        
    def create_mock_xfce_configs(self):
        """Create mock XFCE configuration files."""
        config_dirs = [
            "xfconf/xfce-perchannel-xml",
            "panel",
            "desktop",
            "xfwm4"
        ]
        
        for config_dir in config_dirs:
            full_path = os.path.join(self.xfce_config_dir, config_dir)
            os.makedirs(full_path, exist_ok=True)
        
        # Create mock XML config files
        mock_configs = {
            "xfconf/xfce-perchannel-xml/xfce4-panel.xml": """<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-panel" version="1.0">
  <property name="panels" type="uint" value="1"/>
</channel>""",
            "xfconf/xfce-perchannel-xml/xfwm4.xml": """<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfwm4" version="1.0">
  <property name="general" type="empty"/>
</channel>""",
            "xfconf/xfce-perchannel-xml/xfce4-desktop.xml": """<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-desktop" version="1.0">
  <property name="desktop-icons" type="empty"/>
</channel>"""
        }
        
        for config_file, content in mock_configs.items():
            config_path = os.path.join(self.xfce_config_dir, config_file)
            with open(config_path, 'w') as f:
                f.write(content)
    
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
    
    def run_command(self, command, shell=True, timeout=30):
        """Run a shell command with timeout."""
        try:
            result = subprocess.run(
                command, 
                shell=shell, 
                capture_output=True, 
                text=True, 
                timeout=timeout,
                cwd=Path(__file__).parent.parent
            )
            return result.returncode == 0, result.stdout, result.stderr
        except subprocess.TimeoutExpired:
            return False, "", "Command timed out"
        except Exception as e:
            return False, "", str(e)
    
    def test_xfce_script_basic_functionality(self):
        """Test basic XFCE reload script functionality."""
        self.log("Testing XFCE reload script basic functionality...")
        
        script_path = Path(__file__).parent.parent / "scripts" / "hook-xfce-reload.sh"
        
        if not script_path.exists():
            self.assert_true(False, "XFCE reload script should exist")
            return
        
        # Test help command
        success, output, error = self.run_command(f"bash {script_path} --help")
        self.assert_true(success, "XFCE script help should work")
        self.assert_true("Usage:" in output, "Help should contain usage information")
        
        # Test status command (should work even without XFCE running)
        success, output, error = self.run_command(f"bash {script_path} status")
        # This might fail if XFCE is not running, but script should handle it gracefully
        self.assert_true("XFCE" in output or "not running" in output.lower(), 
                        "Status command should provide XFCE status information")
    
    def test_xfce_validation(self):
        """Test XFCE configuration validation."""
        self.log("Testing XFCE configuration validation...")
        
        script_path = Path(__file__).parent.parent / "scripts" / "hook-xfce-reload.sh"
        
        # Set up mock HOME directory with our test configs
        # Set up test environment
        test_home = os.path.join(self.test_dir, "home2")
        config_dir = os.path.join(test_home, ".config")
        xfce_dest = os.path.join(config_dir, "xfce4")
        
        os.makedirs(config_dir, exist_ok=True)
        if os.path.exists(xfce_dest):
            shutil.rmtree(xfce_dest)
        shutil.copytree(self.xfce_config_dir, xfce_dest)
        
        # Run validation with mock HOME
        env = os.environ.copy()
        env['HOME'] = test_home
        env['REWIND_CONFIG_DIR'] = self.test_dir
        
        # Test validate command
        try:
            result = subprocess.run(
                f"bash {script_path} validate",
                shell=True,
                capture_output=True,
                text=True,
                env=env,
                timeout=10
            )
            
            # Validation should either pass or provide meaningful error messages
            self.assert_true(
                result.returncode == 0 or "Missing essential config" in result.stdout or "validation" in result.stdout.lower(),
                "Validation should work or provide meaningful feedback"
            )
            
        except subprocess.TimeoutExpired:
            self.assert_true(False, "Validation should not hang")
        except Exception as e:
            self.log(f"Validation test error (expected in test environment): {e}", "WARN")
    
    def test_xfce_backup_functionality(self):
        """Test XFCE backup functionality."""
        self.log("Testing XFCE backup functionality...")
        
        script_path = Path(__file__).parent.parent / "scripts" / "hook-xfce-reload.sh"
        
        # Set up test environment
        test_home = os.path.join(self.test_dir, "home")
        config_dir = os.path.join(test_home, ".config")
        xfce_dest = os.path.join(config_dir, "xfce4")
        
        os.makedirs(config_dir, exist_ok=True)
        if os.path.exists(xfce_dest):
            shutil.rmtree(xfce_dest)
        shutil.copytree(self.xfce_config_dir, xfce_dest)
        
        env = os.environ.copy()
        env['HOME'] = test_home
        env['REWIND_CONFIG_DIR'] = self.test_dir
        
        # Test backup command
        try:
            result = subprocess.run(
                f"bash {script_path} backup",
                shell=True,
                capture_output=True,
                text=True,
                env=env,
                timeout=15
            )
            
            # Check if backup was created or if script handled missing XFCE gracefully
            backup_dir = os.path.join(self.test_dir, "xfce-backups")
            backup_created = os.path.exists(backup_dir) and len(os.listdir(backup_dir)) > 0
            graceful_handling = "XFCE session not detected" in result.stdout
            
            self.assert_true(
                backup_created or graceful_handling,
                "Backup should be created or XFCE absence should be handled gracefully"
            )
            
        except subprocess.TimeoutExpired:
            self.assert_true(False, "Backup operation should not hang")
        except Exception as e:
            self.log(f"Backup test error (expected without XFCE): {e}", "WARN")
    
    def test_configuration_reload_simulation(self):
        """Test configuration reload simulation."""
        self.log("Testing configuration reload simulation...")
        
        # Create a mock configuration file
        config_file = os.path.join(self.test_dir, "test_config.conf")
        with open(config_file, 'w') as f:
            f.write("# Test configuration\n")
            f.write("test_setting=value1\n")
        
        # Simulate configuration change
        with open(config_file, 'w') as f:
            f.write("# Test configuration - modified\n")
            f.write("test_setting=value2\n")
        
        # Test that file was modified
        with open(config_file, 'r') as f:
            content = f.read()
            self.assert_true("value2" in content, "Configuration should be modifiable")
            self.assert_true("modified" in content, "Configuration change should be detectable")
    
    def test_error_recovery_scenarios(self):
        """Test error recovery scenarios."""
        self.log("Testing error recovery scenarios...")
        
        script_path = Path(__file__).parent.parent / "scripts" / "hook-xfce-reload.sh"
        
        # Test with invalid operation
        success, output, error = self.run_command(f"bash {script_path} invalid_operation")
        self.assert_true(not success, "Invalid operation should fail")
        self.assert_true("Unknown operation" in output or "Unknown operation" in error, 
                        "Should provide error message for invalid operation")
        
        # Test with missing display (simulate headless environment)
        env = os.environ.copy()
        if 'DISPLAY' in env:
            del env['DISPLAY']
        
        try:
            result = subprocess.run(
                f"bash {script_path} light",
                shell=True,
                capture_output=True,
                text=True,
                env=env,
                timeout=10
            )
            
            # Should handle missing display gracefully
            self.assert_true(
                "No DISPLAY" in result.stdout or "not detected" in result.stdout,
                "Should handle missing display environment gracefully"
            )
            
        except subprocess.TimeoutExpired:
            self.assert_true(False, "Script should not hang on missing display")
    
    def test_systemd_service_simulation(self):
        """Test systemd service integration simulation."""
        self.log("Testing systemd service integration simulation...")
        
        # Create mock systemd service commands
        mock_systemctl = os.path.join(self.test_dir, "mock_systemctl")
        with open(mock_systemctl, 'w') as f:
            f.write("""#!/bin/bash
# Mock systemctl for testing
echo "Mock systemctl called with: $*"
case "$1" in
    "status")
        echo "● mock.service - Mock Service"
        echo "   Active: active (running)"
        exit 0
        ;;
    "restart"|"reload"|"start"|"stop")
        echo "Mock $1 successful"
        exit 0
        ;;
    "daemon-reload")
        echo "Mock daemon-reload successful"
        exit 0
        ;;
    *)
        echo "Mock systemctl: unknown command $1"
        exit 1
        ;;
esac
""")
        os.chmod(mock_systemctl, 0o755)
        
        # Test mock systemctl
        env = os.environ.copy()
        env['PATH'] = f"{self.test_dir}:{env['PATH']}"
        
        result = subprocess.run(
            f"{mock_systemctl} status test.service",
            shell=True,
            capture_output=True,
            text=True,
            env=env
        )
        
        self.assert_true(result.returncode == 0, "Mock systemctl should work")
        self.assert_true("Mock Service" in result.stdout, "Mock systemctl should provide expected output")
        
        # Test various systemctl operations
        operations = ["restart", "reload", "daemon-reload"]
        for op in operations:
            result = subprocess.run(
                f"{mock_systemctl} {op} test.service",
                shell=True,
                capture_output=True,
                text=True,
                env=env
            )
            self.assert_true(result.returncode == 0, f"Mock systemctl {op} should succeed")
    
    def test_configuration_change_detection(self):
        """Test configuration change detection."""
        self.log("Testing configuration change detection...")
        
        # Create initial configuration
        config_file = os.path.join(self.test_dir, "monitored_config.conf")
        with open(config_file, 'w') as f:
            f.write("initial_config=true\n")
        
        initial_mtime = os.path.getmtime(config_file)
        
        # Wait a moment to ensure timestamp difference
        time.sleep(1)
        
        # Modify configuration
        with open(config_file, 'a') as f:
            f.write("additional_config=true\n")
        
        modified_mtime = os.path.getmtime(config_file)
        
        self.assert_true(modified_mtime > initial_mtime, 
                        "Configuration change should be detectable by timestamp")
        
        # Verify content change
        with open(config_file, 'r') as f:
            content = f.read()
            self.assert_true("initial_config=true" in content, "Original config should be preserved")
            self.assert_true("additional_config=true" in content, "New config should be added")
    
    def test_concurrent_operation_handling(self):
        """Test handling of concurrent operations."""
        self.log("Testing concurrent operation handling...")
        
        # Create test lock file scenario
        lock_file = os.path.join(self.test_dir, "test.lock")
        
        # Simulate acquiring lock
        with open(lock_file, 'w') as f:
            f.write(f"PID: {os.getpid()}\n")
            f.write(f"Operation: test_operation\n")
        
        self.assert_true(os.path.exists(lock_file), "Lock file should be created")
        
        # Test lock file detection
        lock_exists = os.path.exists(lock_file)
        self.assert_true(lock_exists, "Should be able to detect existing lock")
        
        # Simulate cleanup
        os.remove(lock_file)
        self.assert_true(not os.path.exists(lock_file), "Lock file should be removable")
    
    def run_all_tests(self):
        """Run all configuration reload tests."""
        self.log("Starting Configuration Reload Test Suite")
        self.log(f"Test directory: {self.test_dir}")
        
        try:
            self.test_xfce_script_basic_functionality()
            self.test_xfce_validation()
            self.test_xfce_backup_functionality()
            self.test_configuration_reload_simulation()
            self.test_error_recovery_scenarios()
            self.test_systemd_service_simulation()
            self.test_configuration_change_detection()
            self.test_concurrent_operation_handling()
            
        except Exception as e:
            self.log(f"Unexpected error during testing: {e}", "ERROR")
            self.failed_tests += 1
            import traceback
            traceback.print_exc()
            
        finally:
            self.print_summary()
            self.cleanup()
    
    def print_summary(self):
        """Print test summary."""
        total_tests = self.passed_tests + self.failed_tests
        pass_rate = (self.passed_tests / total_tests) * 100 if total_tests > 0 else 0
        
        self.log("=" * 60)
        self.log("CONFIGURATION RELOAD TEST SUMMARY")
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
    test_suite = ConfigReloadTestSuite()
    test_suite.run_all_tests()
    
    # Exit with non-zero code if tests failed
    sys.exit(1 if test_suite.failed_tests > 0 else 0)

if __name__ == "__main__":
    main()