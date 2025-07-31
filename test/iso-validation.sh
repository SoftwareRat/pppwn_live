#!/bin/bash
# ISO generation and boot validation test for PPPwn Live ISO

set -e

# Test configuration
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$TEST_DIR")"
BUILD_DIR="${PROJECT_ROOT}/output"
TEMP_DIR="/tmp/pppwn-iso-test-$$"

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
    # Kill any background QEMU processes
    pkill -f "qemu.*pppwn" 2>/dev/null || true
}

trap cleanup EXIT

# Test 1: Check if ISO file exists and is valid
test_iso_existence() {
    log_info "Testing ISO file existence and validity..."
    
    local iso_file="${BUILD_DIR}/images/rootfs.iso9660"
    
    if [ ! -f "$iso_file" ]; then
        test_failed "ISO existence" "ISO file not found at $iso_file"
        return 1
    fi
    
    # Check if file is actually an ISO
    if ! file "$iso_file" | grep -q "ISO 9660"; then
        test_failed "ISO validity" "File is not a valid ISO 9660 image"
        return 1
    fi
    
    # Check minimum size (should be at least 10MB for a minimal system)
    local size=$(stat -c%s "$iso_file" 2>/dev/null || stat -f%z "$iso_file" 2>/dev/null)
    if [ "$size" -lt 10485760 ]; then
        test_failed "ISO size" "ISO file too small (less than 10MB): $size bytes"
        return 1
    fi
    
    test_passed "ISO existence and validity"
}

# Test 2: Verify ISO contents
test_iso_contents() {
    log_info "Testing ISO contents..."
    
    local iso_file="${BUILD_DIR}/images/rootfs.iso9660"
    
    if [ ! -f "$iso_file" ]; then
        test_failed "ISO contents" "ISO file not found"
        return 1
    fi
    
    # Create temporary mount point
    mkdir -p "$TEMP_DIR/iso_mount"
    
    # Try to mount the ISO (requires root or loop device support)
    if command -v isoinfo >/dev/null 2>&1; then
        # Use isoinfo to check contents without mounting
        local contents=$(isoinfo -l -i "$iso_file" 2>/dev/null)
        
        # Check for essential boot files
        if ! echo "$contents" | grep -q "isolinux"; then
            test_failed "ISO contents" "Missing isolinux bootloader"
            return 1
        fi
        
        if ! echo "$contents" | grep -q "vmlinuz"; then
            test_failed "ISO contents" "Missing kernel image"
            return 1
        fi
        
        if ! echo "$contents" | grep -q "rootfs.cpio.gz"; then
            test_failed "ISO contents" "Missing initrd/rootfs"
            return 1
        fi
        
        test_passed "ISO contents"
    else
        log_warn "isoinfo not available, skipping detailed ISO content check"
        test_passed "ISO contents (skipped - no isoinfo)"
    fi
}

# Test 3: Basic boot test with QEMU
test_basic_boot() {
    log_info "Testing basic boot with QEMU..."
    
    local iso_file="${BUILD_DIR}/images/rootfs.iso9660"
    
    if [ ! -f "$iso_file" ]; then
        test_failed "basic boot" "ISO file not found"
        return 1
    fi
    
    # Check if QEMU is available
    if ! command -v qemu-system-x86_64 >/dev/null 2>&1; then
        log_warn "QEMU not available, skipping boot test"
        test_passed "basic boot (skipped - no QEMU)"
        return 0
    fi
    
    # Create temporary directory for QEMU output
    mkdir -p "$TEMP_DIR/qemu_test"
    
    # Start QEMU in background with timeout
    local qemu_log="$TEMP_DIR/qemu_test/boot.log"
    local qemu_pid
    
    # Run QEMU with serial console output
    timeout 60 qemu-system-x86_64 \
        -cdrom "$iso_file" \
        -m 512M \
        -nographic \
        -serial file:"$qemu_log" \
        -no-reboot \
        -enable-kvm 2>/dev/null || \
    timeout 60 qemu-system-x86_64 \
        -cdrom "$iso_file" \
        -m 512M \
        -nographic \
        -serial file:"$qemu_log" \
        -no-reboot 2>/dev/null &
    
    qemu_pid=$!
    
    # Wait for boot process or timeout
    local boot_timeout=45
    local elapsed=0
    
    while [ $elapsed -lt $boot_timeout ]; do
        if [ -f "$qemu_log" ] && grep -q "login:" "$qemu_log"; then
            log_info "Boot successful - login prompt detected"
            kill $qemu_pid 2>/dev/null || true
            test_passed "basic boot"
            return 0
        fi
        
        if [ -f "$qemu_log" ] && grep -q "PPPwn Live System" "$qemu_log"; then
            log_info "Boot successful - PPPwn system detected"
            kill $qemu_pid 2>/dev/null || true
            test_passed "basic boot"
            return 0
        fi
        
        if [ -f "$qemu_log" ] && grep -q "Kernel panic" "$qemu_log"; then
            log_error "Kernel panic detected during boot"
            kill $qemu_pid 2>/dev/null || true
            test_failed "basic boot" "Kernel panic during boot"
            return 1
        fi
        
        sleep 2
        elapsed=$((elapsed + 2))
    done
    
    # Timeout reached
    kill $qemu_pid 2>/dev/null || true
    
    if [ -f "$qemu_log" ]; then
        log_warn "Boot test timed out. Last few lines of boot log:"
        tail -10 "$qemu_log" | while read line; do
            log_warn "  $line"
        done
    fi
    
    test_failed "basic boot" "Boot test timed out after ${boot_timeout}s"
}

# Test 4: Verify bootloader configuration
test_bootloader_config() {
    log_info "Testing bootloader configuration..."
    
    local isolinux_cfg="${PROJECT_ROOT}/br2-external/configs/isolinux.cfg"
    
    if [ ! -f "$isolinux_cfg" ]; then
        test_failed "bootloader config" "isolinux.cfg not found"
        return 1
    fi
    
    # Check for essential bootloader entries
    if ! grep -q "default" "$isolinux_cfg"; then
        test_failed "bootloader config" "Missing default boot entry"
        return 1
    fi
    
    if ! grep -q "kernel" "$isolinux_cfg"; then
        test_failed "bootloader config" "Missing kernel specification"
        return 1
    fi
    
    if ! grep -q "initrd" "$isolinux_cfg"; then
        test_failed "bootloader config" "Missing initrd specification"
        return 1
    fi
    
    test_passed "bootloader configuration"
}

# Test 5: Verify kernel configuration
test_kernel_config() {
    log_info "Testing kernel configuration..."
    
    local kernel_config="${PROJECT_ROOT}/br2-external/configs/linux.config"
    
    if [ ! -f "$kernel_config" ]; then
        test_failed "kernel config" "linux.config not found"
        return 1
    fi
    
    # Check for essential kernel options
    local required_options=(
        "CONFIG_X86_64=y"
        "CONFIG_NET=y"
        "CONFIG_ETHERNET=y"
        "CONFIG_ISO9660_FS=y"
    )
    
    for option in "${required_options[@]}"; do
        if ! grep -q "^$option" "$kernel_config"; then
            test_failed "kernel config" "Missing required kernel option: $option"
            return 1
        fi
    done
    
    test_passed "kernel configuration"
}

# Test 6: Verify filesystem structure in build output
test_filesystem_structure() {
    log_info "Testing filesystem structure in build output..."
    
    local target_dir="${BUILD_DIR}/target"
    
    if [ ! -d "$target_dir" ]; then
        test_failed "filesystem structure" "Target directory not found"
        return 1
    fi
    
    # Check for essential directories and files
    local required_paths=(
        "usr/bin/pppwn"
        "usr/bin/pppwn-runner"
        "usr/bin/network-detector"
        "usr/bin/status-display"
        "etc/init.d/S95pppwn-setup"
        "usr/share/pppwn"
    )
    
    for path in "${required_paths[@]}"; do
        if [ ! -e "${target_dir}/$path" ]; then
            test_failed "filesystem structure" "Missing required path: $path"
            return 1
        fi
    done
    
    test_passed "filesystem structure"
}

# Main test execution
main() {
    log_info "Starting PPPwn Live ISO generation and boot validation tests..."
    log_info "Project root: $PROJECT_ROOT"
    log_info "Build directory: $BUILD_DIR"
    
    # Check if build output exists
    if [ ! -d "$BUILD_DIR" ]; then
        log_error "Build output directory not found. Please run a build first."
        exit 1
    fi
    
    # Run all tests
    test_iso_existence
    test_iso_contents
    test_bootloader_config
    test_kernel_config
    test_filesystem_structure
    test_basic_boot
    
    # Print results
    echo
    log_info "Test Results:"
    log_info "  Passed: $TESTS_PASSED"
    if [ $TESTS_FAILED -gt 0 ]; then
        log_error "  Failed: $TESTS_FAILED"
        exit 1
    else
        log_info "  Failed: $TESTS_FAILED"
        log_info "All ISO validation tests passed!"
    fi
}

# Run main function if script is executed directly
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    main "$@"
fi