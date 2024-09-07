# PPPwnLive

`pppwn_live` is a Linux live ISO based on Alpine Linux, designed to run [pppwn_cpp](https://github.com/xfangfang/PPPwn_cpp), a PS4 exploit, directly from the ISO on any PC. The system automatically shuts down after completing its tasks.

## Features

- Lightweight live ISO based on [Alpine Linux](https://alpinelinux.org/)
- Includes and automatically runs [pppwn_cpp](https://github.com/xfangfang/PPPwn_cpp)
- Designed for easy execution on any PC
- Automatic shutdown after task completion

## Requirements

- PC with USB port or CD/DVD drive
- USB drive or CD/DVD for bootable media
- Ethernet cable and port on the PC running PPPwnLive 
- Basic knowledge of booting from external media
- PlayStation 4 console running **firmware version 11.00** only

## Usage

1. **Download the ISO:**
   Get the latest `pppwn_live` ISO from the [releases page](#).

2. **Create Bootable Media:**
   - For USB: Use [Ventoy](https://www.ventoy.net/en/doc_start.html) (all desktop operating systems), [Rufus](https://rufus.ie/) (Windows) or `dd` (Linux/Mac):
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

## Building the ISO

If you'd like to create the ISO yourself, follow these steps:

### Prerequisites

You'll need an Alpine Linux system with the following packages installed:

```bash
apk add --no-cache alpine-sdk alpine-conf xorriso squashfs-tools grub grub-efi doas alpine-base busybox openrc bash agetty
```
### Preparing the Custom Files
1. Copy the content of the custom folder in this repository to aport/scripts.
2. Create the pppwn.tar.gz file: This archive should have the following structure:
```bash
tar -ztvf pppwn.tar.gz                                                                             
-rwxr-xr-x  0 username group  452780 May 20 00:10 pppwnlive/pppwn
-rw-r--r--  0 username group     500 Sep  5 15:43 pppwnlive/stage1.bin
-rw-r--r--  0 username group    2705 Sep  5 15:43 pppwnlive/stage2.bin
```

`pppwn` is the `pppwn_cpp` binary, which must be downloaded or compiled for your desired architecture.
`stage1.bin` and `stage2.bin` are the required payloads, the pre-created ones use GoldHEN which you can download from [B-Dem's PPPwnUI](https://github.com/B-Dem/PPPwnUI/tree/main/PPPwn/goldhen/1100).
After creating `pppwn.tar.gz`, copy it to the `custom` folder.

### Build the ISO
To create the ISO, run the following command from the root of the repository: (change outdir and arch accordingly)
```sh
sh aports/scripts/mkimage.sh --tag edge --outdir (your desired ISO output path) --arch (your desired architecture) --repository https://dl-cdn.alpinelinux.org/alpine/edge/main --profile pppwn
```
This will generate the ISO with your custom configuration.

## Contributing

Contributions are welcome! Please fork the repository and submit a pull request. For major changes, open an issue first to discuss proposed changes.

## License

This project is licensed under the [GNU General Public License v3.0](LICENSE).

## Acknowledgments

- [Alpine Linux](https://alpinelinux.org/) for their lightweight distribution
- [xfangfang](https://github.com/xfangfang/PPPwn_cpp) for developing the C++ version of PPPwn
- [TheFloW](https://github.com/TheOfficialFloW/PPPwn) for the original discovery and creation of PPPwn
- [SiSTRo](https://github.com/SiSTR0) and the [GoldHEN Team](https://github.com/GoldHEN/GoldHEN) developing GoldHEN, the PS4 Homebrew Enabler used in this project