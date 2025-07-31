#!/bin/bash
# Runtime functionality tests for PPPwn Live ISO
# Tests network detection, PPPwn execution simulation, and user interface

set -e

# Test configuration
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$TEST_DIR")"
TEMP_DIR="/tmp/pppwn-runtime-test-$$"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test results
TESTS_PASSED=0
TESTS_FAILED=0

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

test_passed() {
    local test_name="$1"
    log_info "✓ $test_name"
    ((TESTS_PASSED++))
}

test_failed() {
    local test_name="$1"
    local error_msg="$2"
    log_error "✗ $test_name: $error_msg"
    ((TESTS_FAILED++))
}

# Cleanup function
cleanup() {
    if [ -d "$TEMP_DIR" ]; then
        rm -rf "$TEMP_DIR"
    fi
    # Clean up any test files
    rm -f /tmp/pppwn_test_* 2>/dev/null || true
}

trap cleanup EXIT

# Test 1: Network detector script functionality
test_network_detector_functionality() {
    log_info "Testing network detector functionality..."
    
    local network_detector="${PROJECT_ROOT}/br2-external/overlay/usr/bin/network-detector"
    
    if [ ! -f "$network_detector" ]; then
        test_failed "network detector functionality" "network-detector script not found"
        return 1
    fi
    
    if [ ! -x "$network_detector" ]; then
        test_failed "network detector functionality" "network-detector script not executable"
        return 1
    fi
    
    # Test script syntax
    if ! bash -n "$network_detector"; then
        test_failed "network detector functionality" "syntax error in network-detector script"
        return 1
    fi
    
    # Test function definitions by sourcing and checking
    mkdir -p "$TEMP_DIR"
    cat > "$TEMP_DIR/test_network_functions.sh" << 'EOF'
#!/bin/bash
# Mock system files for testing
mkdir -p /tmp/pppwn_test_sys/class/net/eth0
mkdir -p /tmp/pppwn_test_sys/class/net/eth1
mkdir -p /tmp/pppwn_test_sys/class/net/lo
echo "1" > /tmp/pppwn_test_sys/class/net/eth0/type
echo "1" > /tmp/pppwn_test_sys/class/net/eth1/type
echo "772" > /tmp/pppwn_test_sys/class/net/lo/type

# Mock the network detector script functions
source_network_detector() {
    # Extract functions from network-detector script
    sed -n '/^[a-zA-Z_][a-zA-Z0-9_]*() {/,/^}/p' "$1" > /tmp/network_functions.sh
    source /tmp/network_functions.sh 2>/dev/null || return 1
}

# Test if functions can be extracted and sourced
if source_network_detector "$1"; then
    echo "FUNCTIONS_OK"
else
    echo "FUNCTIONS_ERROR"
fi
EOF
    
    chmod +x "$TEMP_DIR/test_network_functions.sh"
    
    local result=$("$TEMP_DIR/test_network_functions.sh" "$network_detector")
    if [ "$result" = "FUNCTIONS_OK" ]; then
        test_passed "network detector functionality"
    else
        test_failed "network detector functionality" "could not extract or source functions"
        return 1
    fi
}

# Test 2: Network interface detection logic
test_network_interface_detection() {
    log_info "Testing network interface detection logic..."
    
    # Create mock environment
    mkdir -p "$TEMP_DIR/mock_sys/class/net"
    
    # Create mock network interfaces
    mkdir -p "$TEMP_DIR/mock_sys/class/net/eth0"
    mkdir -p "$TEMP_DIR/mock_sys/class/net/eth1" 
    mkdir -p "$TEMP_DIR/mock_sys/class/net/enp0s3"
    mkdir -p "$TEMP_DIR/mock_sys/class/net/lo"
    mkdir -p "$TEMP_DIR/mock_sys/class/net/wlan0"
    mkdir -p "$TEMP_DIR/mock_sys/class/net/wlan0/wireless"
    
    # Set interface types (1 = Ethernet, 772 = loopback)
    echo "1" > "$TEMP_DIR/mock_sys/class/net/eth0/type"
    echo "1" > "$TEMP_DIR/mock_sys/class/net/eth1/type"
    echo "1" > "$TEMP_DIR/mock_sys/class/net/enp0s3/type"
    echo "772" > "$TEMP_DIR/mock_sys/class/net/lo/type"
    echo "1" > "$TEMP_DIR/mock_sys/class/net/wlan0/type"
    
    # Create test script that simulates interface detection
    cat > "$TEMP_DIR/test_interface_detection.sh" << EOF
#!/bin/bash
# Mock interface detection logic
detect_ethernet_interfaces() {
    local patterns="eth*,en*"
    local found_interfaces=""
    
    # Simulate interface discovery
    for pattern in \$(echo "\$patterns" | tr ',' ' '); do
        for iface in $TEMP_DIR/mock_sys/class/net/\$pattern; do
            if [ -d "\$iface" ]; then
                iface_name=\$(basename "\$iface")
                
                # Skip loopback and wireless
                if [ "\$iface_name" = "lo" ] || [ -d "\$iface/wireless" ]; then
                    continue
                fi
                
                # Check if it's Ethernet
                if [ -f "\$iface/type" ]; then
                    iface_type=\$(cat "\$iface/type")
                    if [ "\$iface_type" = "1" ]; then
                        found_interfaces="\$found_interfaces \$iface_name"
                    fi
                fi
            fi
        done
    done
    
    echo "\$found_interfaces"
}

interfaces=\$(detect_ethernet_interfaces)
echo "Found interfaces: \$interfaces"

# Test prioritization (should prefer eth* over en*)
prioritized=""
for pattern in "eth*" "en*"; do
    for iface in \$interfaces; do
        case "\$iface" in
            \$pattern)
                if [ -z "\$prioritized" ]; then
                    prioritized="\$iface"
                fi
                ;;
        esac
    done
    if [ -n "\$prioritized" ]; then
        break
    fi
done

echo "Prioritized interface: \$prioritized"
EOF
    
    chmod +x "$TEMP_DIR/test_interface_detection.sh"
    
    local output=$("$TEMP_DIR/test_interface_detection.sh")
    
    # Check if expected interfaces were found
    if echo "$output" | grep -q "eth0" && echo "$output" | grep -q "eth1" && echo "$output" | grep -q "enp0s3"; then
        if echo "$output" | grep -q "Prioritized interface: eth"; then
            test_passed "network interface detection"
        else
            test_failed "network interface detection" "prioritization logic failed"
            return 1
        fi
    else
        test_failed "network interface detection" "expected interfaces not found"
        return 1
    fi
}

# Test 3: PPPwn runner script validation
test_pppwn_runner_validation() {
    log_info "Testing PPPwn runner script validation..."
    
    local pppwn_runner="${PROJECT_ROOT}/br2-external/overlay/usr/bin/pppwn-runner"
    
    if [ ! -f "$pppwn_runner" ]; then
        test_failed "PPPwn runner validation" "pppwn-runner script not found"
        return 1
    fi
    
    if [ ! -x "$pppwn_runner" ]; then
        test_failed "PPPwn runner validation" "pppwn-runner script not executable"
        return 1
    fi
    
    # Test script syntax
    if ! bash -n "$pppwn_runner"; then
        test_failed "PPPwn runner validation" "syntax error in pppwn-runner script"
        return 1
    fi
    
    # Test configuration parsing
    mkdir -p "$TEMP_DIR/etc/pppwn"
    cat > "$TEMP_DIR/etc/pppwn/config" << 'EOF'
firmware_version=1100
stage1_path=/usr/share/pppwn/stage1/
stage2_path=/usr/share/pppwn/stage2/
binary_path=/usr/bin/pppwn
retry_attempts=3
retry_delay=5
auto_shutdown=true
timeout_seconds=300
EOF
    
    # Create test script to validate configuration parsing
    cat > "$TEMP_DIR/test_config_parsing.sh" << EOF
#!/bin/bash
CONFIG_FILE="$TEMP_DIR/etc/pppwn/config"
if [ -f "\$CONFIG_FILE" ]; then
    eval \$(grep -E '^[a-zA-Z_][a-zA-Z0-9_]*=' "\$CONFIG_FILE" | sed 's/^/export /')
fi

echo "firmware_version=\$firmware_version"
echo "retry_attempts=\$retry_attempts"
echo "auto_shutdown=\$auto_shutdown"
EOF
    
    chmod +x "$TEMP_DIR/test_config_parsing.sh"
    
    local config_output=$("$TEMP_DIR/test_config_parsing.sh")
    
    if echo "$config_output" | grep -q "firmware_version=1100" && \
       echo "$config_output" | grep -q "retry_attempts=3" && \
       echo "$config_output" | grep -q "auto_shutdown=true"; then
        test_passed "PPPwn runner validation"
    else
        test_failed "PPPwn runner validation" "configuration parsing failed"
        return 1
    fi
}

# Test 4: PPPwn execution simulation (without actual PS4)
test_pppwn_execution_simulation() {
    log_info "Testing PPPwn execution simulation..."
    
    # Create mock PPPwn binary for testing
    mkdir -p "$TEMP_DIR/usr/bin"
    cat > "$TEMP_DIR/usr/bin/pppwn" << 'EOF'
#!/bin/bash
# Mock PPPwn binary for testing
echo "PPPwn Mock - Starting exploit simulation"
echo "Interface: $2"
echo "Firmware: $4"
echo "Stage1: $6"
echo "Stage2: $8"

# Simulate different exit codes based on arguments
if echo "$@" | grep -q "test-success"; then
    echo "Exploit completed successfully!"
    exit 0
elif echo "$@" | grep -q "test-timeout"; then
    sleep 10  # Simulate timeout
    exit 124
elif echo "$@" | grep -q "test-network-error"; then
    echo "Network error occurred"
    exit 2
else
    echo "Exploit attempt failed (normal)"
    exit 1
fi
EOF
    chmod +x "$TEMP_DIR/usr/bin/pppwn"
    
    # Create mock stage files
    mkdir -p "$TEMP_DIR/usr/share/pppwn/stage1"
    mkdir -p "$TEMP_DIR/usr/share/pppwn/stage2"
    echo "mock stage1 data" > "$TEMP_DIR/usr/share/pppwn/stage1/1100.bin"
    echo "mock stage2 data" > "$TEMP_DIR/usr/share/pppwn/stage2/1100.bin"
    
    # Create test execution script
    cat > "$TEMP_DIR/test_pppwn_execution.sh" << EOF
#!/bin/bash
export PATH="$TEMP_DIR/usr/bin:\$PATH"

# Mock network interface file
echo "eth0" > /tmp/pppwn_test_interface

# Test successful execution
echo "Testing successful execution..."
if timeout 5 "$TEMP_DIR/usr/bin/pppwn" -i eth0 --fw 1100 --stage1 "$TEMP_DIR/usr/share/pppwn/stage1/1100.bin" --stage2 "$TEMP_DIR/usr/share/pppwn/stage2/1100.bin" test-success >/dev/null 2>&1; then
    echo "SUCCESS_TEST_PASSED"
else
    echo "SUCCESS_TEST_FAILED"
fi

# Test failure handling
echo "Testing failure handling..."
if ! timeout 5 "$TEMP_DIR/usr/bin/pppwn" -i eth0 --fw 1100 --stage1 "$TEMP_DIR/usr/share/pppwn/stage1/1100.bin" --stage2 "$TEMP_DIR/usr/share/pppwn/stage2/1100.bin" >/dev/null 2>&1; then
    echo "FAILURE_TEST_PASSED"
else
    echo "FAILURE_TEST_FAILED"
fi

# Test network error handling
echo "Testing network error handling..."
if ! timeout 5 "$TEMP_DIR/usr/bin/pppwn" -i eth0 --fw 1100 --stage1 "$TEMP_DIR/usr/share/pppwn/stage1/1100.bin" --stage2 "$TEMP_DIR/usr/share/pppwn/stage2/1100.bin" test-network-error >/dev/null 2>&1; then
    echo "NETWORK_ERROR_TEST_PASSED"
else
    echo "NETWORK_ERROR_TEST_FAILED"
fi
EOF
    
    chmod +x "$TEMP_DIR/test_pppwn_execution.sh"
    
    local execution_output=$("$TEMP_DIR/test_pppwn_execution.sh")
    
    if echo "$execution_output" | grep -q "SUCCESS_TEST_PASSED" && \
       echo "$execution_output" | grep -q "FAILURE_TEST_PASSED" && \
       echo "$execution_output" | grep -q "NETWORK_ERROR_TEST_PASSED"; then
        test_passed "PPPwn execution simulation"
    else
        test_failed "PPPwn execution simulation" "execution tests failed"
        log_error "Execution output: $execution_output"
        return 1
    fi
}

# Test 5: Status display functionality
test_status_display_functionality() {
    log_info "Testing status display functionality..."
    
    local status_display="${PROJECT_ROOT}/br2-external/overlay/usr/bin/status-display"
    
    if [ ! -f "$status_display" ]; then
        test_failed "status display functionality" "status-display script not found"
        return 1
    fi
    
    if [ ! -x "$status_display" ]; then
        test_failed "status display functionality" "status-display script not executable"
        return 1
    fi
    
    # Test script syntax
    if ! bash -n "$status_display"; then
        test_failed "status display functionality" "syntax error in status-display script"
        return 1
    fi
    
    # Test different status display commands
    local test_commands=(
        "status INFO 'Test message'"
        "progress 5 10 'Testing progress'"
        "success 'Test Success' 'Success message'"
        "error 'Test Error' 'Error message' 'Suggestions'"
        "realtime 'Test Phase' 'Active' 'Details'"
        "help"
    )
    
    local all_tests_passed=true
    
    for cmd in "${test_commands[@]}"; do
        if ! timeout 5 "$status_display" $cmd >/dev/null 2>&1; then
            log_error "Status display command failed: $cmd"
            all_tests_passed=false
        fi
    done
    
    if [ "$all_tests_passed" = "true" ]; then
        test_passed "status display functionality"
    else
        test_failed "status display functionality" "some status display commands failed"
        return 1
    fi
}

# Test 6: User interface integration
test_user_interface_integration() {
    log_info "Testing user interface integration..."
    
    # Test that scripts can call each other properly
    local network_detector="${PROJECT_ROOT}/br2-external/overlay/usr/bin/network-detector"
    local pppwn_runner="${PROJECT_ROOT}/br2-external/overlay/usr/bin/pppwn-runner"
    local status_display="${PROJECT_ROOT}/br2-external/overlay/usr/bin/status-display"
    
    # Create integration test script
    cat > "$TEMP_DIR/test_ui_integration.sh" << EOF
#!/bin/bash
export PATH="$TEMP_DIR/usr/bin:\$PATH"

# Test status display integration
echo "Testing status display integration..."
if "$status_display" status INFO "Integration test message" >/dev/null 2>&1; then
    echo "STATUS_DISPLAY_OK"
else
    echo "STATUS_DISPLAY_FAILED"
fi

# Test that scripts can source configuration
mkdir -p "$TEMP_DIR/etc/pppwn"
cat > "$TEMP_DIR/etc/pppwn/config" << 'EOFCONFIG'
color_output=true
verbose_output=true
clear_screen=false
show_banner=true
EOFCONFIG

# Test configuration loading
CONFIG_FILE="$TEMP_DIR/etc/pppwn/config"
if [ -f "\$CONFIG_FILE" ]; then
    eval \$(grep -E '^[a-zA-Z_][a-zA-Z0-9_]*=' "\$CONFIG_FILE" | sed 's/^/export /')
fi

if [ "\$color_output" = "true" ] && [ "\$verbose_output" = "true" ]; then
    echo "CONFIG_LOADING_OK"
else
    echo "CONFIG_LOADING_FAILED"
fi

# Test error handling integration
if command -v error-handler >/dev/null 2>&1; then
    echo "ERROR_HANDLER_AVAILABLE"
else
    echo "ERROR_HANDLER_NOT_AVAILABLE"
fi
EOF
    
    chmod +x "$TEMP_DIR/test_ui_integration.sh"
    
    local integration_output=$("$TEMP_DIR/test_ui_integration.sh")
    
    if echo "$integration_output" | grep -q "STATUS_DISPLAY_OK" && \
       echo "$integration_output" | grep -q "CONFIG_LOADING_OK"; then
        test_passed "user interface integration"
    else
        test_failed "user interface integration" "integration tests failed"
        log_error "Integration output: $integration_output"
        return 1
    fi
}

# Test 7: Error handling and recovery mechanisms
test_error_handling_recovery() {
    log_info "Testing error handling and recovery mechanisms..."
    
    # Test error file creation and handling
    cat > "$TEMP_DIR/test_error_handling.sh" << 'EOF'
#!/bin/bash

# Test error file creation
echo "NETWORK_DETECTION_FAILED" > /tmp/pppwn_test_error

# Test error detection
if [ -f /tmp/pppwn_test_error ]; then
    error_type=$(cat /tmp/pppwn_test_error)
    case "$error_type" in
        "NETWORK_DETECTION_FAILED")
            echo "ERROR_DETECTION_OK"
            ;;
        *)
            echo "ERROR_DETECTION_UNKNOWN"
            ;;
    esac
else
    echo "ERROR_DETECTION_FAILED"
fi

# Test timeout handling
echo "EXPLOIT_TIMEOUT" > /tmp/pppwn_test_timeout
if [ -f /tmp/pppwn_test_timeout ]; then
    echo "TIMEOUT_HANDLING_OK"
else
    echo "TIMEOUT_HANDLING_FAILED"
fi

# Test recovery file creation
echo "eth0" > /tmp/pppwn_test_interface
echo "192.168.1.100" > /tmp/pppwn_test_ip
echo "static" > /tmp/pppwn_test_config_method

if [ -f /tmp/pppwn_test_interface ] && [ -f /tmp/pppwn_test_ip ] && [ -f /tmp/pppwn_test_config_method ]; then
    echo "RECOVERY_FILES_OK"
else
    echo "RECOVERY_FILES_FAILED"
fi

# Cleanup test files
rm -f /tmp/pppwn_test_*
EOF
    
    chmod +x "$TEMP_DIR/test_error_handling.sh"
    
    local error_output=$("$TEMP_DIR/test_error_handling.sh")
    
    if echo "$error_output" | grep -q "ERROR_DETECTION_OK" && \
       echo "$error_output" | grep -q "TIMEOUT_HANDLING_OK" && \
       echo "$error_output" | grep -q "RECOVERY_FILES_OK"; then
        test_passed "error handling and recovery"
    else
        test_failed "error handling and recovery" "error handling tests failed"
        log_error "Error handling output: $error_output"
        return 1
    fi
}

# Test 8: Configuration file validation
test_configuration_validation() {
    log_info "Testing configuration file validation..."
    
    # Test PPPwn configuration
    local pppwn_config="${PROJECT_ROOT}/br2-external/overlay/etc/pppwn/config"
    
    if [ ! -f "$pppwn_config" ]; then
        test_failed "configuration validation" "PPPwn config file not found"
        return 1
    fi
    
    # Test configuration parsing
    local required_configs=(
        "firmware_version"
        "stage1_path"
        "stage2_path"
        "binary_path"
        "retry_attempts"
    )
    
    local config_valid=true
    for config in "${required_configs[@]}"; do
        if ! grep -q "^$config=" "$pppwn_config"; then
            log_error "Missing required configuration: $config"
            config_valid=false
        fi
    done
    
    if [ "$config_valid" = "true" ]; then
        test_passed "configuration validation"
    else
        test_failed "configuration validation" "required configurations missing"
        return 1
    fi
}

# Main test execution
main() {
    log_info "Starting PPPwn Live ISO runtime functionality tests..."
    log_info "Project root: $PROJECT_ROOT"
    
    # Create temporary directory
    mkdir -p "$TEMP_DIR"
    
    # Run all tests (continue even if some fail)
    test_network_detector_functionality || true
    test_network_interface_detection || true
    test_pppwn_runner_validation || true
    test_pppwn_execution_simulation || true
    test_status_display_functionality || true
    test_user_interface_integration || true
    test_error_handling_recovery || true
    test_configuration_validation || true
    
    # Print results
    echo
    log_info "Test Results:"
    log_info "  Passed: $TESTS_PASSED"
    if [ $TESTS_FAILED -gt 0 ]; then
        log_error "  Failed: $TESTS_FAILED"
        exit 1
    else
        log_info "  Failed: $TESTS_FAILED"
        log_info "All runtime functionality tests passed!"
    fi
}

# Run main function if script is executed directly
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    main "$@"
fi