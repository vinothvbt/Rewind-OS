"""
Rewind-OS: Git-like timeline operations for NixOS system configuration management.

This package provides foundational functionality for managing system states
through timeline operations including list, branch, switch, and restore.
"""

__version__ = "0.1.0"
__author__ = "Vinoth"
__description__ = "Timeline-based system state management for NixOS"

from .timeline import Timeline
from .cli import main

__all__ = ["Timeline", "main"]