# PPPwn Live ISO

`pppwn_live` is a Buildroot-based Linux live ISO designed to automatically execute the [PPPwn](https://github.com/TheOfficialFloW/PPPwn) PS4 exploit using [pppwn_cpp](https://github.com/xfangfang/PPPwn_cpp). The system provides a minimal, secure, and automated environment that boots from any x64 PC and automatically shuts down after completing the exploit.

## Table of Contents
- [Features](#features)
- [Requirements](#requirements)
- [Quick Start](#quick-start)
- [Usage](#usage)
  - [Creating Bootable Media](#creating-bootable-media)
  - [Booting and Execution](#booting-and-execution)
  - [Troubleshooting](#troubleshooting)
- [Supported Firmware Versions](#supported-firmware-versions)
- [Build from Source](#build-from-source)
- [System Architecture](#system-architecture)
- [Security Features](#security-features)
- [Contributing](#contributing)
- [License](#license)
- [Acknowledgments](#acknowledgments)

## Features

- **Minimal Buildroot-based system** - Optimized for size and security
- **Automatic hardware detection** - Detects and configures network interfaces
- **PS4 console detection** - Automatically connects to PlayStation 4 consoles
- **Real-time status display** - Clear progress indicators and user guidance
- **Automatic shutdown** - Secure shutdown after successful exploit completion
- **Error recovery** - Comprehensive error handling with recovery options
- **Security hardening** - Memory clearing and minimal attack surface
- **CI/CD integration** - Automated builds with GitHub Actions

## Requirements

### Hardware Requirements
- x64 PC with at least 512MB RAM
- USB port or CD/DVD drive for bootable media
- Ethernet port and cable
- PlayStation 4 console with supported firmware

### PlayStation 4 Requirements
- PS4 console running firmware version **9.00, 9.60, 10.00, 10.01, or 11.00**
- Ethernet cable to connect PS4 to PC
- PS4 should be in rest mode or powered off initially

## Quick Start

1. **Download the latest ISO** from the [releases page](https://github.com/your-org/pppwn-live-iso/releases)
2. **Create bootable media** using Ventoy, Rufus, or dd
3. **Connect PS4 to PC** via Ethernet cable
4. **Boot from the media** and follow on-screen instructions
5. **Wait for automatic completion** and shutdown

## Usage

### Creating Bootable Media

#### Using Ventoy (Recommended)
1. Download [Ventoy](https://www.ventoy.net/en/doc_start.html)
2. Install Ventoy to your USB drive
3. Copy the ISO file to the USB drive
4. Boot from USB and select the ISO

#### Using Rufus (Windows)
1. Download [Rufus](https://rufus.ie/)
2. Select your USB drive and the downloaded ISO
3. Click "START" to create bootable media

#### Using dd (Linux/macOS)
```bash
sudo dd if=pppwn_live.iso of=/dev/sdX bs=4M status=progress
sync
```
Replace `/dev/sdX` with your USB drive identifier.

### Booting and Execution

1. **Insert bootable media** and restart your PC
2. **Enter BIOS/UEFI** (usually F2, F12, Delete, or Esc during startup)
3. **Set boot priority** to your bootable media
4. **Save and exit** BIOS/UEFI

The system will automatically:
- Boot into the PPPwn Live environment
- Display a welcome banner with instructions
- Detect available network interfaces
- Configure network settings for PS4 communication
- Wait for PS4 console connection
- Execute the PPPwn exploit when PS4 is detected
- Display real-time status and progress
- Shut down automatically after successful completion

### Troubleshooting

#### Common Issues

**No network interfaces detected:**
- Ensure your PC has a working Ethernet port
- Try different Ethernet cables
- Check if network drivers are loaded (most common drivers included)

**PS4 not detected:**
- Ensure PS4 is connected via Ethernet cable
- Put PS4 in rest mode or power it off completely
- Wait for the system to detect the console (may take 1-2 minutes)
- Try restarting the PS4 if detection fails

**Exploit execution fails:**
- Verify your PS4 firmware version is supported
- Ensure stable network connection
- The system will automatically retry failed attempts
- Check the error messages for specific guidance

**System hangs or freezes:**
- Wait at least 5 minutes before considering it frozen
- If frozen, restart and try again
- Some hardware may require specific boot parameters

#### Advanced Troubleshooting

**Emergency shell access:**
If you need to troubleshoot manually, you can access an emergency shell:
1. During boot, press `Ctrl+C` when prompted
2. This provides root shell access for advanced users
3. Use `pppwn-runner --help` for manual execution options

**Verbose output:**
For detailed debugging information:
1. Edit boot parameters and add `debug=1`
2. This enables verbose logging and status output

## Supported Firmware Versions

| PS4 Firmware | Status | Notes |
|--------------|--------|-------|
| 9.00         | ✅ Supported | Stable |
| 9.60         | ✅ Supported | Stable |
| 10.00        | ✅ Supported | Stable |
| 10.01        | ✅ Supported | Stable |
| 11.00        | ✅ Supported | Stable |
| Other        | ❌ Not supported | Use official PPPwn tools |

## Build from Source

See [BUILD.md](BUILD.md) for detailed build instructions.

### Quick Build
```bash
# Clone repository
git clone https://github.com/your-org/pppwn-live-iso.git
cd pppwn-live-iso

# Build ISO
make pppwn_defconfig
make all

# ISO will be available at output/images/pppwn_live.iso
```

## System Architecture

PPPwn Live ISO uses a Buildroot-based architecture for minimal size and maximum security:

- **Base System**: Buildroot 2025.05 with minimal Linux kernel
- **PPPwn Integration**: Custom Buildroot packages for PPPwn components
- **Network Stack**: Optimized for PS4 communication protocols
- **User Interface**: Console-based with clear status indicators
- **Security**: Memory clearing, minimal services, automatic shutdown

### Key Components

- `pppwn-cpp`: Main exploit binary
- `network-detector`: Automatic network interface detection
- `pppwn-runner`: Exploit execution coordinator
- `status-display`: User interface and progress reporting
- `security-hardening`: System security measures

## Security Features

- **Minimal attack surface**: Only essential components included
- **Memory clearing**: Sensitive data cleared on shutdown
- **Read-only filesystem**: Core system files protected
- **Automatic shutdown**: Prevents unauthorized access after completion
- **No persistent storage**: Runs entirely from memory
- **Network isolation**: Only PS4 communication protocols enabled

## Contributing

Contributions are welcome! Please see our contribution guidelines:

1. **Fork the repository** and create a feature branch
2. **Follow coding standards** and include tests where applicable
3. **Update documentation** for any user-facing changes
4. **Submit a pull request** with a clear description of changes

### Development Setup

```bash
# Clone repository
git clone https://github.com/your-org/pppwn-live-iso.git
cd pppwn-live-iso

# Set up development environment
make pppwn_defconfig
make menuconfig  # Optional: customize configuration

# Build and test
make all
```

### Reporting Issues

When reporting issues, please include:
- PC hardware specifications
- PS4 firmware version
- Error messages or screenshots
- Steps to reproduce the issue

## License

This project is licensed under the [GNU General Public License v3.0](LICENSE).

## Acknowledgments

- **[TheOfficialFloW](https://github.com/TheOfficialFloW/PPPwn)** - Original PPPwn discovery and development
- **[xfangfang](https://github.com/xfangfang/PPPwn_cpp)** - PPPwn C++ implementation
- **[Buildroot Project](https://buildroot.org/)** - Embedded Linux build system
- **[SiSTRo](https://github.com/SiSTR0) and [GoldHEN Team](https://github.com/GoldHEN/GoldHEN)** - GoldHEN homebrew enabler
- **Community contributors** - Testing, feedback, and improvements

---

**⚠️ Disclaimer**: This tool is for educational and research purposes only. Users are responsible for complying with applicable laws and console terms of service. The developers are not responsible for any damage or legal consequences resulting from the use of this software.