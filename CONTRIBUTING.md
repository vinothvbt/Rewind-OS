# Contributing to Rewind-OS

Welcome to Rewind-OS! We're excited about your interest in contributing to the timeline-based system state management project. This guide will help you get started with contributing to Phase 2 and beyond.

## Table of Contents

- [Project Overview](#project-overview)
- [Development Setup](#development-setup)
- [Code Organization](#code-organization)
- [Contributing Guidelines](#contributing-guidelines)
- [Testing](#testing)
- [Documentation](#documentation)
- [Submitting Changes](#submitting-changes)
- [Code Style](#code-style)
- [Feature Requests](#feature-requests)
- [Bug Reports](#bug-reports)

---

## Project Overview

Rewind-OS is a timeline-based system state management solution for NixOS, inspired by Git's branching model. We're currently in Phase 2, which focuses on:

- Enhanced CLI with stash/unstash functionality
- Safe rollback mechanisms with confirmations
- Live configuration management without reboots
- Advanced NixOS integration with systemd services
- Enhanced XFCE desktop integration
- Comprehensive error handling and recovery

### Current Architecture

```
rewind-os/
├── rewind/              # Core Python package
│   ├── __init__.py     # Package initialization
│   ├── cli.py          # Enhanced CLI interface
│   └── timeline.py     # Core timeline operations
├── scripts/            # System integration scripts
│   └── hook-xfce-reload.sh  # Enhanced XFCE integration
├── nix/               # NixOS configuration modules
│   ├── rewind.nix     # Main NixOS module (Phase 2)
│   └── example.nix    # Usage examples
├── tests/             # Test suite (to be created)
├── docs/              # Additional documentation
├── README.md          # Main documentation
├── PHASES.md          # Development roadmap
├── TROUBLESHOOTING.md # User troubleshooting guide
└── CONTRIBUTING.md    # This file
```

---

## Development Setup

### Prerequisites

- **NixOS 23.11+** (recommended) or Linux system with Nix package manager
- **Python 3.8+**
- **Git**
- **XFCE** (for desktop integration testing)
- **Basic understanding of**: Git, Python, Nix, systemd

### Setting Up Development Environment

1. **Clone the Repository:**
   ```bash
   git clone https://github.com/vinothvbt/Rewind-OS.git
   cd Rewind-OS
   ```

2. **Test Basic Functionality:**
   ```bash
   # Test CLI
   python3 -m rewind.cli --help
   python3 -m rewind.cli list
   
   # Create test snapshot
   python3 -m rewind.cli snapshot "Development setup"
   ```

3. **Set Up Development Environment:**
   ```bash
   # Use custom config directory for development
   export REWIND_CONFIG_DIR="$PWD/.rewind-dev"
   export REWIND_DEBUG=1
   
   # Create development alias
   alias rewind-dev='python3 -m rewind.cli'
   ```

4. **Test XFCE Integration (if using XFCE):**
   ```bash
   ./scripts/hook-xfce-reload.sh status
   ./scripts/hook-xfce-reload.sh backup
   ```

### NixOS Development Setup

If you're using NixOS, you can test the full integration:

1. **Create test configuration:**
   ```bash
   cp nix/example.nix /tmp/test-rewind.nix
   # Edit the file to suit your test environment
   ```

2. **Test NixOS module (dry run):**
   ```bash
   sudo nixos-rebuild dry-build -I rewind-os=/path/to/Rewind-OS
   ```

---

## Code Organization

### Core Components

#### `rewind/timeline.py`
- Core timeline management logic
- Snapshot creation and management
- Branch operations
- Stash functionality (Phase 2)
- Data persistence and loading

#### `rewind/cli.py`
- Command-line interface
- Argument parsing and validation
- User interaction (confirmations, prompts)
- Error handling and user feedback
- Command implementations

#### `nix/rewind.nix`
- NixOS module definition
- Systemd service configurations
- Configuration options and validation
- Integration hooks and scripts

#### `scripts/hook-xfce-reload.sh`
- XFCE desktop environment integration
- Component reload mechanisms
- Error recovery and validation
- Backup and restore functionality

---

## Contributing Guidelines

### General Principles

1. **Minimal Changes**: Make the smallest possible changes to achieve your goal
2. **Backward Compatibility**: Don't break existing functionality
3. **Error Handling**: Always include proper error handling
4. **User Experience**: Consider the end-user experience in all changes
5. **Documentation**: Update documentation for user-facing changes

### Types of Contributions

#### 🐛 Bug Fixes
- Fix broken functionality
- Improve error handling
- Resolve edge cases
- Performance improvements

#### ✨ Feature Enhancements
- Extend existing commands
- Add new CLI options
- Improve NixOS integration
- Enhance desktop environment support

#### 📚 Documentation
- Improve setup instructions
- Add troubleshooting guides
- Create usage examples
- Fix typos and clarifications

#### 🧪 Testing
- Add unit tests
- Create integration tests
- End-to-end testing scenarios
- Performance benchmarks

#### 🔧 Infrastructure
- CI/CD improvements
- Build system enhancements
- Development tooling
- Code quality tools

---

## Testing

### Manual Testing

Before submitting changes, test the following scenarios:

#### Basic CLI Operations
```bash
# Timeline operations
python3 -m rewind.cli list
python3 -m rewind.cli snapshot "Test snapshot"
python3 -m rewind.cli list --snapshots
python3 -m rewind.cli info

# Branch operations
python3 -m rewind.cli branch test-branch "Test branch"
python3 -m rewind.cli switch test-branch
python3 -m rewind.cli switch main

# Stash operations (Phase 2)
python3 -m rewind.cli stash "Test stash"
python3 -m rewind.cli list --stashes
python3 -m rewind.cli stash --apply
python3 -m rewind.cli stash --drop

# Restore operations
python3 -m rewind.cli restore <snapshot-id> --info
python3 -m rewind.cli restore <snapshot-id> --force
```

#### Error Scenarios
```bash
# Test error handling
python3 -m rewind.cli restore nonexistent_snapshot
python3 -m rewind.cli switch nonexistent_branch
python3 -m rewind.cli stash --apply  # When no stashes exist

# Test with invalid permissions
chmod 000 ~/.rewind
python3 -m rewind.cli list
chmod 755 ~/.rewind
```

#### XFCE Integration (if applicable)
```bash
# Test all reload modes
./scripts/hook-xfce-reload.sh status
./scripts/hook-xfce-reload.sh smart
./scripts/hook-xfce-reload.sh light
./scripts/hook-xfce-reload.sh validate
./scripts/hook-xfce-reload.sh backup
```

### Creating Tests

We welcome contributions to our test suite. Tests should be placed in a `tests/` directory:

```bash
mkdir -p tests
# Create test files following the pattern: test_*.py
```

Example test structure:
```python
#!/usr/bin/env python3
"""Test timeline operations."""

import unittest
import tempfile
import os
from rewind.timeline import Timeline

class TestTimeline(unittest.TestCase):
    def setUp(self):
        self.temp_dir = tempfile.mkdtemp()
        self.timeline = Timeline(self.temp_dir)
    
    def test_create_snapshot(self):
        snapshot_id = self.timeline.create_snapshot("Test snapshot")
        self.assertIsNotNone(snapshot_id)
        
    def tearDown(self):
        # Cleanup
        import shutil
        shutil.rmtree(self.temp_dir)

if __name__ == '__main__':
    unittest.main()
```

---

## Documentation

### Documentation Standards

1. **Code Comments**: Use docstrings for all functions and classes
2. **User Documentation**: Update README.md for user-facing changes
3. **Examples**: Include practical examples in documentation
4. **Troubleshooting**: Add common issues to TROUBLESHOOTING.md

### Documentation Types

#### Code Documentation
```python
def create_snapshot(self, message: str, auto: bool = False) -> str:
    """Create a new snapshot in the current branch.
    
    Args:
        message: Description of the snapshot
        auto: Whether this is an automatic snapshot
        
    Returns:
        The snapshot ID
        
    Raises:
        PermissionError: If unable to write to config directory
        ValueError: If message is empty
    """
```

#### CLI Help Text
- Clear, concise command descriptions
- Practical examples
- Common use cases
- Error scenarios

#### NixOS Module Documentation
```nix
# Clear option descriptions
enable = mkEnableOption "Rewind-OS timeline-based system management";

configDir = mkOption {
  type = types.str;
  default = "/var/lib/rewind-os";
  description = ''
    Directory to store Rewind-OS configuration and timeline data.
    
    This directory will be created automatically with proper permissions.
    For development, you might want to use a custom location.
  '';
};
```

---

## Submitting Changes

### Pull Request Process

1. **Fork the Repository**
   ```bash
   # Fork on GitHub, then clone your fork
   git clone https://github.com/YOUR_USERNAME/Rewind-OS.git
   ```

2. **Create Feature Branch**
   ```bash
   git checkout -b feature/your-feature-name
   # or
   git checkout -b fix/issue-description
   ```

3. **Make Changes**
   - Follow coding standards
   - Add tests if applicable
   - Update documentation

4. **Test Thoroughly**
   - Run manual tests
   - Test on NixOS if possible
   - Verify XFCE integration

5. **Commit Changes**
   ```bash
   git add .
   git commit -m "feat: add stash persistence functionality"
   # or
   git commit -m "fix: resolve XFCE panel reload issue"
   ```

6. **Submit Pull Request**
   - Clear description of changes
   - Reference any related issues
   - Include testing steps
   - Screenshots for UI changes

### Commit Message Format

Use conventional commit format:

```
type(scope): description

[optional body]

[optional footer]
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes
- `refactor`: Code refactoring
- `test`: Adding tests
- `chore`: Maintenance tasks

**Examples:**
```
feat(cli): add stash list command with filtering options

Added ability to list stashes with optional filtering by branch
and date range. Includes colored output and pagination support.

Closes #123

fix(xfce): handle missing display environment gracefully

The XFCE reload script now properly detects when no display
is available and skips reload operations instead of failing.

test(timeline): add comprehensive stash operation tests

Added unit tests covering all stash operations including
edge cases and error conditions.
```

---

## Code Style

### Python Code Style

Follow PEP 8 with these specifics:

```python
# Use descriptive variable names
timeline_data = self._load_timeline()
current_branch_name = self.get_current_branch()

# Type hints for function signatures
def create_snapshot(self, message: str, auto: bool = False) -> str:
    """Create a new snapshot."""
    pass

# Error handling with specific exceptions
try:
    data = self._load_timeline()
except (FileNotFoundError, json.JSONDecodeError) as e:
    self._handle_timeline_error(e)

# Use f-strings for formatting
print(f"✓ Created snapshot '{snapshot_id}': {message}")

# Comprehensive docstrings
def apply_stash(self, stash_id: str = None, pop: bool = False) -> bool:
    """Apply a stash to the current timeline.
    
    Args:
        stash_id: Specific stash to apply, or None for most recent
        pop: Whether to remove the stash after applying
        
    Returns:
        True if successful, False otherwise
        
    Example:
        >>> timeline.apply_stash(pop=True)  # Apply and remove most recent
        True
    """
```

### Shell Script Style

```bash
#!/bin/bash
# Use strict mode
set -euo pipefail

# Descriptive variable names
readonly CONFIG_DIR="${REWIND_CONFIG_DIR:-${HOME}/.rewind}"
readonly LOG_FILE="${CONFIG_DIR}/xfce-reload.log"

# Function documentation
# Apply smart XFCE reload with error recovery
smart_reload() {
    local start_time=$(date +%s)
    
    info "Starting smart reload..."
    
    # Implementation here
}

# Consistent error handling
handle_error() {
    local exit_code=$?
    local line_number=$1
    error "Script failed at line $line_number with exit code $exit_code"
    exit $exit_code
}

trap 'handle_error $LINENO' ERR
```

### Nix Code Style

```nix
{
  # Clear option organization
  options.services.rewind-os = {
    enable = mkEnableOption "Rewind-OS timeline-based system management";
    
    # Grouped related options
    autoSnapshot = {
      enable = mkEnableOption "Automatic snapshot creation";
      
      interval = mkOption {
        type = types.str;
        default = "hourly";
        description = "Interval for automatic snapshots (systemd timer format)";
      };
    };
  };
  
  # Conditional configuration
  config = mkIf cfg.enable {
    # Implementation
  };
}
```

---

## Feature Requests

### Before Requesting Features

1. **Check Existing Issues**: Search for similar requests
2. **Review Roadmap**: Check PHASES.md for planned features
3. **Consider Scope**: Ensure it fits the project goals

### Feature Request Template

```markdown
## Feature Request

**Is your feature request related to a problem?**
A clear description of the problem.

**Describe the solution you'd like**
A detailed description of what you want to happen.

**Describe alternatives you've considered**
Alternative solutions or features you've considered.

**Additional context**
Screenshots, mockups, or additional context.

**Implementation considerations**
- Backward compatibility
- Performance impact
- Testing requirements
```

---

## Bug Reports

### Bug Report Template

```markdown
## Bug Report

**Environment**
- OS: [e.g., NixOS 23.11]
- Python version: [e.g., 3.11.6]
- Rewind-OS version/commit: [e.g., Phase 2 / abc123]
- Desktop Environment: [e.g., XFCE 4.18]

**Description**
A clear description of the bug.

**Steps to Reproduce**
1. Go to '...'
2. Click on '....'
3. See error

**Expected behavior**
What you expected to happen.

**Actual behavior**
What actually happened.

**Error output**
```
Paste error messages here
```

**Additional context**
Screenshots, logs, or additional information.
```

### Debug Information

When reporting bugs, include:

```bash
# System information
uname -a
python3 --version

# Rewind-OS status
python3 -m rewind.cli info

# Recent logs
cat ~/.rewind/*.log

# Configuration (if relevant)
cat /etc/nixos/configuration.nix | grep -A 20 rewind-os
```

---

## Community Guidelines

### Code of Conduct

- Be respectful and inclusive
- Focus on constructive feedback
- Help newcomers get started
- Share knowledge and best practices

### Communication

- **GitHub Issues**: Bug reports and feature requests
- **Pull Requests**: Code contributions and discussions
- **Documentation**: Improve guides and examples

### Recognition

Contributors will be recognized in:
- README.md contributor section
- Release notes for significant contributions
- Project documentation for major features

---

## Development Roadmap

### Phase 2 (Current) - Completed
- [x] Enhanced CLI with stash functionality
- [x] Safe rollback mechanisms
- [x] Live configuration management
- [x] Advanced NixOS integration
- [x] Enhanced XFCE integration

### Phase 3 (Next)
- [ ] Actual filesystem snapshots (Btrfs/ZFS)
- [ ] Web-based timeline GUI
- [ ] Performance optimizations
- [ ] Multi-desktop environment support

### How to Contribute to Future Phases

1. **Phase 3 Preparation**: Help design filesystem snapshot integration
2. **Testing Infrastructure**: Build comprehensive test suites
3. **Documentation**: Improve user and developer documentation
4. **Performance**: Profile and optimize existing functionality

---

## Getting Help

### For Contributors

- **Code Questions**: Open a GitHub issue with the `question` label
- **Design Discussions**: Use GitHub discussions for architectural questions
- **Bug Reports**: Follow the bug report template

### For Users

- **Installation Issues**: Check TROUBLESHOOTING.md first
- **Usage Questions**: Review README.md and examples
- **Feature Requests**: Use the feature request template

---

## Thank You!

Thank you for considering contributing to Rewind-OS! Your contributions help make timeline-based system management a reality for the NixOS community and beyond.

Every contribution, no matter how small, is valuable:
- **Code**: New features, bug fixes, optimizations
- **Documentation**: Guides, examples, troubleshooting
- **Testing**: Finding bugs, validating features
- **Feedback**: User experience improvements

Welcome to the Rewind-OS community! 🌀