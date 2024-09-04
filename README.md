# PPPwnLive

`pppwn_live` is a Linux live ISO based on Alpine Linux, designed to run [pppwn_cpp](https://github.com/xfangfang/PPPwn_cpp), a PS4 exploit, directly from the ISO on any PC. The system automatically shuts down after completing its tasks.

## Features

- Lightweight live ISO based on Alpine Linux
- Includes and automatically runs [pppwn_cpp](https://github.com/xfangfang/PPPwn_cpp)
- Designed for easy execution on any PC
- Automatic shutdown after task completion

## Requirements

- PC with USB port or CD/DVD drive
- USB drive or CD/DVD for bootable media
- Basic knowledge of booting from external media

## Usage

1. **Download the ISO:**
   Get the latest `pppwn_live` ISO from the [releases page](#).

2. **Create Bootable Media:**
   - For USB: Use [Rufus](https://rufus.ie/) (Windows) or `dd` (Linux/Mac):
     ```bash
     sudo dd if=pppwn_live.iso of=/dev/sdX bs=4M
     sync
     ```
     Replace `/dev/sdX` with your USB drive identifier.
   - For CD/DVD: Burn the ISO using your preferred software.

3. **Boot from Media:**
   - Insert the bootable media and restart your PC.
   - Enter BIOS/UEFI (usually F2, F12, Delete, or Esc during startup).
   - Set boot priority to your bootable media.
   - Save and exit BIOS/UEFI.

4. **Run pppwn_cpp:**
   The system will automatically start and run `pppwn_cpp`. Follow on-screen instructions.

5. **Automatic Shutdown:**
   The system will shut down automatically after completing its tasks.

## Contributing

Contributions are welcome! Please fork the repository and submit a pull request. For major changes, open an issue first to discuss proposed changes.

## License

This project is licensed under the [GNU General Public License v3.0](LICENSE).

## Acknowledgments

- [Alpine Linux](https://alpinelinux.org/) for their lightweight distribution
- [xfangfang](https://github.com/xfangfang/PPPwn_cpp) for developing the C++ version of PPPwn
- [TheOfficialFloW](https://github.com/TheOfficialFloW/PPPwn) for the original discovery and creation of PPPwn
