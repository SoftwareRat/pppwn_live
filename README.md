# PPPwn Live ISO

Minimal Buildroot-based Linux live ISO that automatically runs the PPPwn PS4 exploit.

## Quick Start

1. Download ISO from releases
2. Flash to USB with Rufus/Ventoy/dd
3. Connect PS4 via Ethernet
4. Boot and wait for automatic completion

## Supported PS4 Firmware
- 9.00, 9.60, 10.00, 10.01, 11.00

## Build
```bash
make pppwn_defconfig
make all
```

## License
GPL-3.0