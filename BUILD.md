# PPPwn Live ISO Build Process

## Overview

PPPwn Live ISO is built using Buildroot, a tool for generating embedded Linux systems. This document describes the build process, requirements, and structure of the Buildroot-based system.

## Build Requirements

### System Requirements
- Linux-based build environment (Ubuntu 20.04+ recommended)
- At least 4GB of free disk space
- At least 2GB of RAM
- Internet connection for downloading dependencies

### Required Packages
```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y \
    build-essential \
    git \
    wget \
    cpio \
    unzip \
    rsync \
    bc \
    libncurses5-dev \
    libssl-dev \
    python3 \
    python3-distutils

# CentOS/RHEL/Fedora
sudo yum groupinstall -y "Development Tools"
sudo yum install -y \
    git \
    wget \
    cpio \
    unzip \
    rsync \
    bc \
    ncurses-devel \
    openssl-devel \
    python3
```

## Build Process

### 1. Clone Repository
```bash
git clone https://github.com/your-org/pppwn-live-iso.git
cd pppwn-live-iso
```

### 2. Initialize Buildroot
The build system automatically downloads Buildroot 2025.05 from the official repository:
```bash
make pppwn_defconfig
```

This command:
- Downloads Buildroot source if not present
- Applies the PPPwn-specific configuration
- Sets up the external tree structure

### 3. Build the ISO
```bash
make all
```

The build process will:
- Download and compile the Linux kernel
- Build all required packages (PPPwn components, utilities)
- Create the root filesystem with overlays
- Generate the bootable ISO image

### 4. Locate Build Artifacts
After successful build, artifacts are located in:
- `output/images/pppwn_live.iso` - Bootable ISO image
- `output/images/bzImage` - Linux kernel
- `output/images/rootfs.cpio.gz` - Root filesystem

## Project Structure

### Buildroot External Tree
```
br2-external/
├── Config.in              # Package configuration
├── external.desc          # External tree description
├── external.mk            # External makefile
├── configs/               # System configurations
│   ├── pppwn_defconfig   # Main Buildroot configuration
│   ├── linux.config     # Linux kernel configuration
│   └── busybox.config   # BusyBox configuration
├── overlay/              # Filesystem overlay
│   ├── etc/             # System configuration files
│   ├── root/            # Root user files
│   └── usr/             # User binaries and data
├── package/             # Custom Buildroot packages
│   ├── pppwn-cpp/       # PPPwn C++ binary package
│   ├── pppwn-stage1/    # Stage1 payload package
│   └── pppwn-stage2/    # Stage2 payload package
└── scripts/             # Build scripts
    ├── post-build.sh    # Post-build customization
    └── post-image.sh    # Post-image processing
```

### Configuration Files
- `configs/pppwn_defconfig` - Main Buildroot configuration targeting x64 minimal system
- `br2-external/configs/linux.config` - Linux kernel configuration with network drivers
- `br2-external/configs/busybox.config` - BusyBox utilities configuration

### Custom Packages
- **pppwn-cpp**: Builds the PPPwn C++ exploit binary from source
- **pppwn-stage1**: Downloads and integrates stage1 payloads
- **pppwn-stage2**: Downloads and integrates stage2 payloads

## Build Customization

### Modifying Configuration
```bash
# Configure Buildroot options
make menuconfig

# Configure Linux kernel
make linux-menuconfig

# Configure BusyBox
make busybox-menuconfig
```

### Adding Custom Files
Add files to the filesystem by placing them in `br2-external/overlay/` following the target filesystem structure.

### Custom Packages
Create new packages in `br2-external/package/` following Buildroot package conventions.

## Troubleshooting

### Common Build Issues

1. **Download failures**: Check internet connection and proxy settings
2. **Compilation errors**: Ensure all build dependencies are installed
3. **Disk space**: Ensure at least 4GB free space in build directory
4. **Permission errors**: Avoid building as root user

### Clean Build
```bash
# Clean build artifacts
make clean

# Clean everything including downloads
make distclean
```

### Verbose Build
```bash
# Enable verbose output for debugging
make V=1
```

## CI/CD Integration

The project uses GitHub Actions for automated builds:
- Builds are triggered on changes to stage1/, stage2/, or configuration files
- Buildroot source is cached between builds
- Successful builds generate ISO artifacts and releases

See `.github/workflows/` for CI/CD configuration details.