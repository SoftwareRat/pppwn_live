# PPPwn_live

A minimal Linux live system optimized for network operations and fast boot times.

## Features

- Minimal Linux system (<50MB)
- Custom init system optimized for automation
- Fast boot time (<10 seconds)
- Automated network configuration with PPP support
- Docker-based reproducible builds
- x86_64 and aarch64 support (aarch64 in development)

## Requirements

- Docker
- make
- bash
- sudo (for ISO creation)

## Building

```bash
# Build the system
make

# Create ISO
make iso

# Clean build artifacts
make clean
```

## Directory Structure

```
.
├── configs/          # Configuration files for kernel and busybox
├── overlay/          # System overlay files
├── scripts/          # Build and automation scripts
├── src/             # Custom init and system components
└── docker/          # Docker build environment
```

## Network Configuration

The system automatically configures network interfaces and supports PPP protocol handling. All network configurations can be found in `overlay/etc/network/`.

## Development

- Written in modern C (C11)
- Uses shell scripts for automation
- Makefile-based build system
- Docker-based reproducible builds

## License

GPLv3 - See LICENSE file for details.

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request
