# PPPwn Live ISO Testing Framework

This directory contains comprehensive tests for the PPPwn Live ISO project, covering build validation, runtime functionality, and ISO generation verification.

## Test Structure

### Build Validation Tests (`build-validation.sh`)
- **Purpose**: Validates Buildroot configuration, package setup, and build dependencies
- **Coverage**: 
  - Defconfig validation
  - External tree structure
  - Package configurations
  - Overlay structure
  - Dependency resolution
  - Build scripts
  - Configuration files

### Runtime Functionality Tests (`runtime-functionality.sh`)
- **Purpose**: Tests runtime scripts and functionality without requiring actual hardware
- **Coverage**:
  - Network detector functionality
  - Network interface detection logic
  - PPPwn runner script validation
  - PPPwn execution simulation (mock)
  - Status display functionality
  - User interface integration
  - Error handling and recovery mechanisms
  - Configuration file validation

### ISO Validation Tests (`iso-validation.sh`)
- **Purpose**: Validates generated ISO files and basic boot functionality
- **Coverage**:
  - ISO file existence and validity
  - ISO contents verification
  - Bootloader configuration
  - Kernel configuration
  - Filesystem structure
  - Basic boot testing with QEMU (if available)

## Usage

### Run All Tests
```bash
./test/run-build-tests.sh
```

### Run Specific Test Suites
```bash
# Build validation only
./test/run-build-tests.sh --build-only

# Runtime functionality only
./test/run-build-tests.sh --runtime-only

# ISO validation only (requires build output)
./test/run-build-tests.sh --iso-only
```

### Run Individual Test Scripts
```bash
# Individual test scripts
./test/build-validation.sh
./test/runtime-functionality.sh
./test/iso-validation.sh
```

## Requirements

### For Build Validation Tests
- Basic shell environment
- Git (for dependency resolution tests)
- Network access (optional, for Buildroot cloning)

### For Runtime Functionality Tests
- Shell environment with standard utilities
- No special requirements (uses mocking)

### For ISO Validation Tests
- Build output directory (`output/`)
- `isoinfo` utility (optional, for detailed ISO inspection)
- QEMU (`qemu-system-x86_64`) (optional, for boot testing)

## Test Output

All tests provide colored output with clear pass/fail indicators:
- ✓ Green checkmarks for passed tests
- ✗ Red X marks for failed tests
- Detailed error messages for failures
- Summary statistics at the end

## Integration with CI/CD

These tests are designed to be integrated into GitHub Actions workflows:

```yaml
- name: Run Build Validation Tests
  run: ./test/run-build-tests.sh --build-only

- name: Run Runtime Functionality Tests
  run: ./test/run-build-tests.sh --runtime-only

- name: Run ISO Validation Tests
  run: ./test/run-build-tests.sh --iso-only
  if: steps.build.outcome == 'success'
```

## Test Development

### Adding New Tests

1. **Build Validation**: Add test functions to `build-validation.sh`
2. **Runtime Functionality**: Add test functions to `runtime-functionality.sh`
3. **ISO Validation**: Add test functions to `iso-validation.sh`

### Test Function Template
```bash
test_new_functionality() {
    log_info "Testing new functionality..."
    
    # Test implementation here
    if [ condition ]; then
        test_passed "new functionality"
    else
        test_failed "new functionality" "error description"
        return 1
    fi
}
```

### Mock Testing

Runtime functionality tests use extensive mocking to test scripts without requiring actual hardware:
- Mock network interfaces in `/tmp/mock_sys/class/net/`
- Mock PPPwn binary for execution testing
- Mock configuration files for parsing tests
- Mock system files for integration testing

## Troubleshooting

### Common Issues

1. **Permission Errors**: Ensure test scripts are executable (`chmod +x test/*.sh`)
2. **Network Issues**: Some tests may skip network-dependent functionality
3. **Missing Dependencies**: Tests will skip optional components if not available
4. **Build Output Missing**: ISO validation tests require successful build first

### Debug Mode

Run tests with bash debug mode for detailed execution:
```bash
bash -x ./test/build-validation.sh
```

### Test Isolation

Each test creates temporary directories and cleans up automatically:
- Build validation: `/tmp/pppwn-test-$$`
- Runtime functionality: `/tmp/pppwn-runtime-test-$$`
- ISO validation: `/tmp/pppwn-iso-test-$$`

## Contributing

When adding new functionality to the PPPwn Live ISO system:

1. Add corresponding tests to the appropriate test suite
2. Ensure tests cover both success and failure scenarios
3. Use mocking for hardware-dependent functionality
4. Update this README if adding new test categories
5. Verify tests pass in CI/CD environment

## Requirements Coverage

This testing framework addresses the following requirements from the specification:

- **Requirement 7.4**: Buildroot defconfig optimized for live system requirements
- **Requirement 7.5**: Defconfig targets minimal system size while including necessary components
- **Requirement 3.1**: Automatic hardware detection
- **Requirement 3.2**: Network interface configuration for PS4 detection
- **Requirement 4.1**: Clear user guidance messages
- **Requirement 4.2**: Real-time status output during execution