# PPPwnLive

[![License: GPL-3.0](https://img.shields.io/badge/License-GPL%203.0-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

A customized Linux live system built with Buildroot, optimized for both x86_64 and aarch64 architectures.

## Quick Start

1. Download the latest ISO from [Releases](https://github.com/SoftwareRat/pppwn_live/releases)
2. Write the ISO to a USB drive using your preferred tool
3. Boot from the USB drive
4. Follow the screen instructions

## Development

### Prerequisites

For building from source:
- Linux/macOS/Windows (via WSL2) development environment
- Required packages:
    - gcc-multilib
    - wget
    - unzip
    - bc
    - rsync
    - file
    - perl
    - cpio
    - gzip
    - bzip2
    - patch
    - tar
    - findutils
    - curl
    - jq
    - 7zip
- At least 8GB of free disk space
- At least 4GB RAM recommended

Note: Windows users must install and configure Windows Subsystem for Linux 2 (WSL2) with a supported Linux distribution.

### Building from Source

1. Clone this repository:
```bash
git clone https://github.com/SoftwareRat/pppwn_live.git
cd pppwn_live
```

2. Download and extract Buildroot:
```bash
wget https://buildroot.org/downloads/buildroot-2024.02.9.tar.gz
tar xf buildroot-2024.02.9.tar.gz
mv buildroot-2024.02.9 buildroot
```

3. Build for your architecture:

For x86_64:
```bash
cd buildroot
make BR2_EXTERNAL=../pppwn_live pppwn_x86_64_defconfig
make
```

For aarch64:
```bash
cd buildroot
make BR2_EXTERNAL=../pppwn_live pppwn_aarch64_defconfig
make
```

The build process may take 30-60 minutes depending on your system. Once complete, find the ISO image in `output/images/`.

### Build Options

To customize the build:
```bash
make menuconfig  # After loading the appropriate defconfig
```

### Troubleshooting

- Ensure all prerequisites are installed
- Check build logs in `buildroot/output/build/build.log`
- For build errors, try `make clean` before rebuilding

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE) file for details.