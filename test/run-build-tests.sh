#!/bin/bash
# Comprehensive build test runner for PPPwn Live ISO

set -e

# Test configuration
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$TEST_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_header() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

# Test execution function
run_test_suite() {
    local test_script="$1"
    local test_name="$2"
    
    log_header "Running $test_name..."
    echo "----------------------------------------"
    
    if [ ! -f "$test_script" ]; then
        log_error "Test script not found: $test_script"
        return 1
    fi
    
    if [ ! -x "$test_script" ]; then
        log_error "Test script not executable: $test_script"
        return 1
    fi
    
    # Run the test script
    if "$test_script"; then
        log_info "$test_name completed successfully"
        return 0
    else
        log_error "$test_name failed"
        return 1
    fi
}

# Main test execution
main() {
    local total_suites=0
    local passed_suites=0
    local failed_suites=0
    
    log_info "Starting comprehensive build validation test suite..."
    log_info "Project root: $PROJECT_ROOT"
    echo
    
    # Test suite 1: Build validation
    ((total_suites++))
    if run_test_suite "${TEST_DIR}/build-validation.sh" "Build Validation Tests"; then
        ((passed_suites++))
    else
        ((failed_suites++))
    fi
    echo
    
    # Test suite 2: Runtime functionality tests
    ((total_suites++))
    if run_test_suite "${TEST_DIR}/runtime-functionality.sh" "Runtime Functionality Tests"; then
        ((passed_suites++))
    else
        ((failed_suites++))
    fi
    echo
    
    # Test suite 3: ISO validation (only if build output exists)
    if [ -d "${PROJECT_ROOT}/output" ]; then
        ((total_suites++))
        if run_test_suite "${TEST_DIR}/iso-validation.sh" "ISO Generation and Boot Tests"; then
            ((passed_suites++))
        else
            ((failed_suites++))
        fi
        echo
    else
        log_warn "Skipping ISO validation tests - no build output found"
        log_warn "Run 'make' to build the project first for complete testing"
        echo
    fi
    
    # Print final results
    log_header "Final Test Results"
    echo "----------------------------------------"
    log_info "Total test suites: $total_suites"
    log_info "Passed: $passed_suites"
    
    if [ $failed_suites -gt 0 ]; then
        log_error "Failed: $failed_suites"
        echo
        log_error "Some tests failed. Please review the output above."
        exit 1
    else
        log_info "Failed: $failed_suites"
        echo
        log_info "🎉 All build validation tests passed!"
        
        if [ ! -d "${PROJECT_ROOT}/output" ]; then
            echo
            log_info "💡 Tip: Run 'make' to build the project and enable ISO validation tests"
        fi
    fi
}

# Show usage information
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Run comprehensive build validation tests for PPPwn Live ISO"
    echo
    echo "Options:"
    echo "  -h, --help       Show this help message"
    echo "  --build-only     Run only build validation tests"
    echo "  --runtime-only   Run only runtime functionality tests"
    echo "  --iso-only       Run only ISO validation tests"
    echo
    echo "Examples:"
    echo "  $0                   # Run all available tests"
    echo "  $0 --build-only      # Run only build validation"
    echo "  $0 --runtime-only    # Run only runtime functionality"
    echo "  $0 --iso-only        # Run only ISO validation"
}

# Parse command line arguments
case "${1:-}" in
    -h|--help)
        show_usage
        exit 0
        ;;
    --build-only)
        log_info "Running build validation tests only..."
        exec "${TEST_DIR}/build-validation.sh"
        ;;
    --runtime-only)
        log_info "Running runtime functionality tests only..."
        exec "${TEST_DIR}/runtime-functionality.sh"
        ;;
    --iso-only)
        log_info "Running ISO validation tests only..."
        if [ ! -d "${PROJECT_ROOT}/output" ]; then
            log_error "No build output found. Run 'make' first."
            exit 1
        fi
        exec "${TEST_DIR}/iso-validation.sh"
        ;;
    "")
        # No arguments, run main function
        main "$@"
        ;;
    *)
        log_error "Unknown option: $1"
        show_usage
        exit 1
        ;;
esac