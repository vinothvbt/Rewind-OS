#!/bin/bash
#
# Rewind-OS Test Runner
#
# This script runs all end-to-end tests for Rewind-OS Phase 2
# and provides comprehensive test reporting.
#
# Usage: ./tests/run_tests.sh [OPTIONS]
#

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
TEST_OUTPUT_DIR="${PROJECT_DIR}/test_results"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test configuration
VERBOSE=false
SKIP_CLEANUP=false
TEST_FILTER=""
PARALLEL=false

# Usage information
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Run Rewind-OS end-to-end test suite.

OPTIONS:
    -v, --verbose       Enable verbose output
    -k, --keep          Skip cleanup (keep test artifacts)
    -f, --filter REGEX  Only run tests matching regex
    -p, --parallel      Run tests in parallel (experimental)
    -h, --help          Show this help message

EXAMPLES:
    $0                  # Run all tests
    $0 -v               # Run with verbose output
    $0 -f timeline      # Run only timeline tests
    $0 -v -k            # Verbose with artifact preservation

TEST SUITES:
    - Timeline Operations (test_e2e_timeline.py)
    - Configuration Reload (test_config_reload.py)
    - XFCE Integration (part of config reload)
    - CLI Interface (part of timeline tests)

ENVIRONMENT VARIABLES:
    REWIND_TEST_TIMEOUT    Test timeout in seconds (default: 300)
    REWIND_TEST_VERBOSE    Enable verbose mode (1, true, yes)
    REWIND_TEST_KEEP       Skip cleanup (1, true, yes)
EOF
}

# Logging functions
log() {
    echo -e "$(date '+%H:%M:%S') $*"
}

info() {
    log "${BLUE}[INFO]${NC} $*"
}

warn() {
    log "${YELLOW}[WARN]${NC} $*"
}

error() {
    log "${RED}[ERROR]${NC} $*"
}

success() {
    log "${GREEN}[SUCCESS]${NC} $*"
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -k|--keep)
                SKIP_CLEANUP=true
                shift
                ;;
            -f|--filter)
                TEST_FILTER="$2"
                shift 2
                ;;
            -p|--parallel)
                PARALLEL=true
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done
    
    # Check environment variables
    if [[ "${REWIND_TEST_VERBOSE:-}" =~ ^(1|true|yes)$ ]]; then
        VERBOSE=true
    fi
    
    if [[ "${REWIND_TEST_KEEP:-}" =~ ^(1|true|yes)$ ]]; then
        SKIP_CLEANUP=true
    fi
}

# Setup test environment
setup_test_environment() {
    info "Setting up test environment..."
    
    # Create test output directory
    mkdir -p "$TEST_OUTPUT_DIR"
    
    # Set up Python path
    export PYTHONPATH="$PROJECT_DIR:${PYTHONPATH:-}"
    
    # Set test configuration
    export REWIND_CONFIG_DIR="$TEST_OUTPUT_DIR/test_config"
    export REWIND_DEBUG="${VERBOSE}"
    export REWIND_FORCE=1  # Skip interactive prompts in tests
    
    # Test timeout
    export REWIND_TEST_TIMEOUT="${REWIND_TEST_TIMEOUT:-300}"
    
    info "Test environment configured:"
    info "  Project directory: $PROJECT_DIR"
    info "  Test output: $TEST_OUTPUT_DIR"
    info "  Python path: $PYTHONPATH"
    info "  Config directory: $REWIND_CONFIG_DIR"
}

# Check prerequisites
check_prerequisites() {
    info "Checking prerequisites..."
    
    # Check Python
    if ! command -v python3 >/dev/null; then
        error "Python 3 is required but not found"
        exit 1
    fi
    
    local python_version
    python_version=$(python3 --version 2>&1 | cut -d' ' -f2)
    info "Python version: $python_version"
    
    # Check if we can import rewind modules
    if ! python3 -c "import sys; sys.path.insert(0, '$PROJECT_DIR'); import rewind.timeline" 2>/dev/null; then
        error "Cannot import rewind modules. Please check the project structure."
        exit 1
    fi
    
    # Check project structure
    local required_files=(
        "$PROJECT_DIR/rewind/__init__.py"
        "$PROJECT_DIR/rewind/cli.py"
        "$PROJECT_DIR/rewind/timeline.py"
        "$PROJECT_DIR/scripts/hook-xfce-reload.sh"
    )
    
    for file in "${required_files[@]}"; do
        if [[ ! -f "$file" ]]; then
            error "Required file not found: $file"
            exit 1
        fi
    done
    
    success "Prerequisites check passed"
}

# Run a single test
run_test() {
    local test_file="$1"
    local test_name="$(basename "$test_file" .py)"
    local output_file="$TEST_OUTPUT_DIR/${test_name}_${TIMESTAMP}.log"
    local result_file="$TEST_OUTPUT_DIR/${test_name}_${TIMESTAMP}.result"
    
    info "Running test: $test_name"
    
    local start_time
    start_time=$(date +%s)
    
    # Set up test-specific environment
    local test_config_dir="$TEST_OUTPUT_DIR/${test_name}_config_${TIMESTAMP}"
    export REWIND_CONFIG_DIR="$test_config_dir"
    
    local success=false
    local exit_code=0
    
    if [[ "$VERBOSE" == "true" ]]; then
        # Run with real-time output
        if timeout "$REWIND_TEST_TIMEOUT" python3 "$test_file" 2>&1 | tee "$output_file"; then
            success=true
        else
            exit_code=$?
        fi
    else
        # Capture output to file
        if timeout "$REWIND_TEST_TIMEOUT" python3 "$test_file" > "$output_file" 2>&1; then
            success=true
        else
            exit_code=$?
        fi
    fi
    
    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    # Create result summary
    cat > "$result_file" << EOF
{
    "test_name": "$test_name",
    "test_file": "$test_file",
    "success": $success,
    "exit_code": $exit_code,
    "duration": $duration,
    "timestamp": "$TIMESTAMP",
    "output_file": "$output_file",
    "config_dir": "$test_config_dir"
}
EOF
    
    if [[ "$success" == "true" ]]; then
        success "Test $test_name completed successfully in ${duration}s"
    else
        error "Test $test_name failed with exit code $exit_code after ${duration}s"
        if [[ "$VERBOSE" != "true" ]]; then
            warn "Last 20 lines of output:"
            tail -20 "$output_file" || true
        fi
    fi
    
    # Cleanup test config if not keeping artifacts
    if [[ "$SKIP_CLEANUP" != "true" ]]; then
        rm -rf "$test_config_dir" 2>/dev/null || true
    fi
    
    return $exit_code
}

# Run all tests
run_tests() {
    info "Starting Rewind-OS test suite..."
    
    local test_files=(
        "$SCRIPT_DIR/test_e2e_timeline.py"
        "$SCRIPT_DIR/test_config_reload.py"
    )
    
    # Filter tests if requested
    if [[ -n "$TEST_FILTER" ]]; then
        local filtered_files=()
        for test_file in "${test_files[@]}"; do
            if [[ "$(basename "$test_file")" =~ $TEST_FILTER ]]; then
                filtered_files+=("$test_file")
            fi
        done
        test_files=("${filtered_files[@]}")
        info "Filtered to ${#test_files[@]} tests matching '$TEST_FILTER'"
    fi
    
    if [[ ${#test_files[@]} -eq 0 ]]; then
        warn "No tests to run"
        return 0
    fi
    
    local total_tests=${#test_files[@]}
    local passed_tests=0
    local failed_tests=0
    local failed_test_names=()
    
    info "Running $total_tests test suite(s)..."
    
    # Run tests
    for test_file in "${test_files[@]}"; do
        if [[ ! -f "$test_file" ]]; then
            warn "Test file not found: $test_file"
            continue
        fi
        
        if run_test "$test_file"; then
            ((passed_tests++))
        else
            ((failed_tests++))
            failed_test_names+=("$(basename "$test_file" .py)")
        fi
    done
    
    # Generate summary report
    generate_summary_report "$total_tests" "$passed_tests" "$failed_tests" "${failed_test_names[@]:-}"
    
    # Return appropriate exit code
    return $failed_tests
}

# Generate summary report
generate_summary_report() {
    local total_tests="$1"
    local passed_tests="$2"
    local failed_tests="$3"
    shift 3
    local failed_test_names=("$@")
    
    local pass_rate=0
    if [[ $total_tests -gt 0 ]]; then
        pass_rate=$(( (passed_tests * 100) / total_tests ))
    fi
    
    local summary_file="$TEST_OUTPUT_DIR/test_summary_${TIMESTAMP}.json"
    local report_file="$TEST_OUTPUT_DIR/test_report_${TIMESTAMP}.md"
    
    # JSON summary
    cat > "$summary_file" << EOF
{
    "timestamp": "$TIMESTAMP",
    "total_tests": $total_tests,
    "passed_tests": $passed_tests,
    "failed_tests": $failed_tests,
    "pass_rate": $pass_rate,
    "failed_test_names": [$(printf '"%s",' "${failed_test_names[@]}" | sed 's/,$//')],
    "test_output_dir": "$TEST_OUTPUT_DIR",
    "environment": {
        "python_version": "$(python3 --version 2>&1)",
        "system": "$(uname -a)",
        "project_dir": "$PROJECT_DIR"
    }
}
EOF
    
    # Markdown report
    cat > "$report_file" << EOF
# Rewind-OS Test Report

**Generated:** $(date)  
**Test Run ID:** $TIMESTAMP

## Summary

- **Total Tests:** $total_tests
- **Passed:** $passed_tests
- **Failed:** $failed_tests
- **Pass Rate:** $pass_rate%

## Test Results

EOF
    
    # Add individual test results
    for result_file in "$TEST_OUTPUT_DIR"/*_"$TIMESTAMP".result; do
        if [[ -f "$result_file" ]]; then
            local test_name
            test_name=$(grep '"test_name"' "$result_file" | cut -d'"' -f4)
            local success
            success=$(grep '"success"' "$result_file" | cut -d' ' -f2 | tr -d ',')
            local duration
            duration=$(grep '"duration"' "$result_file" | cut -d' ' -f2 | tr -d ',')
            
            if [[ "$success" == "true" ]]; then
                echo "- ✅ **$test_name** - Passed (${duration}s)" >> "$report_file"
            else
                echo "- ❌ **$test_name** - Failed (${duration}s)" >> "$report_file"
            fi
        fi
    done
    
    if [[ $failed_tests -gt 0 ]]; then
        cat >> "$report_file" << EOF

## Failed Tests

EOF
        for failed_test in "${failed_test_names[@]}"; do
            echo "### $failed_test" >> "$report_file"
            echo "" >> "$report_file"
            local output_file="$TEST_OUTPUT_DIR/${failed_test}_${TIMESTAMP}.log"
            if [[ -f "$output_file" ]]; then
                echo '```' >> "$report_file"
                tail -50 "$output_file" >> "$report_file" 2>/dev/null || echo "Could not read output file" >> "$report_file"
                echo '```' >> "$report_file"
            fi
            echo "" >> "$report_file"
        done
    fi
    
    cat >> "$report_file" << EOF

## Environment

- **Python:** $(python3 --version 2>&1)
- **System:** $(uname -a)
- **Project Directory:** $PROJECT_DIR
- **Test Output Directory:** $TEST_OUTPUT_DIR

## Test Artifacts

All test logs and results are available in: \`$TEST_OUTPUT_DIR\`
EOF
    
    # Print summary to console
    echo
    echo "================================================================"
    echo "                    TEST SUMMARY"
    echo "================================================================"
    echo "Total tests:   $total_tests"
    echo "Passed:        $passed_tests"
    echo "Failed:        $failed_tests"
    echo "Pass rate:     $pass_rate%"
    echo "Duration:      ${SECONDS}s"
    echo "================================================================"
    
    if [[ $failed_tests -gt 0 ]]; then
        echo "Failed tests:"
        for failed_test in "${failed_test_names[@]}"; do
            echo "  - $failed_test"
        done
        echo "================================================================"
    fi
    
    echo "Reports generated:"
    echo "  JSON Summary: $summary_file"
    echo "  Markdown Report: $report_file"
    echo "  Test Artifacts: $TEST_OUTPUT_DIR"
    echo "================================================================"
}

# Cleanup function
cleanup() {
    if [[ "$SKIP_CLEANUP" != "true" ]]; then
        info "Cleaning up temporary test artifacts..."
        # Clean up any remaining test directories
        find "$TEST_OUTPUT_DIR" -name "*_config_*" -type d -exec rm -rf {} + 2>/dev/null || true
    else
        info "Skipping cleanup (artifacts preserved in $TEST_OUTPUT_DIR)"
    fi
}

# Main execution
main() {
    # Parse arguments
    parse_args "$@"
    
    # Set up cleanup trap
    trap cleanup EXIT
    
    # Setup and run tests
    setup_test_environment
    check_prerequisites
    
    local exit_code=0
    if ! run_tests; then
        exit_code=1
    fi
    
    # Final cleanup
    cleanup
    
    if [[ $exit_code -eq 0 ]]; then
        success "All tests passed! 🎉"
    else
        error "Some tests failed. Check the reports for details."
    fi
    
    exit $exit_code
}

# Run main function with all arguments
main "$@"