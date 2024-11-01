# PPPwnLive
# ⚠️ [Work is already underway on a new ISO for GoldHEN v2.4b18](https://github.com/SoftwareRat/pppwn_live/issues/3)

`pppwn_live` is a Linux live ISO based on Alpine Linux, designed to run [pppwn_cpp](https://github.com/xfangfang/PPPwn_cpp), a PS4 exploit, directly from the ISO on any PC. The system automatically shuts down after completing its tasks.

## Table of Contents
- [Features](#features)
- [Requirements](#requirements)
- [Usage](#usage)
  - [ISO Usage](#iso-usage)
  - [Docker Usage](#docker-usage)
    - [Docker CLI](#docker-cli)
    - [Docker Compose](#docker-compose)
    - [Building Docker Images Manually](#building-docker-images-manually)
- [Screenshots](#screenshots)
- [Development](#development)
  - [Prerequisites](#prerequisites)
  - [Preparing the Custom Files](#preparing-the-custom-files)
  - [Build the ISO](#build-the-iso)
- [Contributing](#contributing)
- [License](#license)
- [Acknowledgments](#acknowledgments)

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
- If using Docker:
   - PlayStation 4 console running **firmware versions 9.00, 9.60, 10.00, 10.01, or 11.00**
- If using live ISO:
   - PlayStation 4 console running **firmware version 11.00** only

## Usage

### ISO Usage

1. **Download the ISO:**
   Get the latest ISO from the [releases page](https://github.com/SoftwareRat/pppwn_live/releases). Choose the x64 version for Intel/AMD processors or the aarch64 version for ARM-based processors, depending on your PC architecture.

2. **Create Bootable Media:**
   - For USB: Use [Ventoy](https://www.ventoy.net/en/doc_start.html) (all desktop operating systems), [Rufus](https://rufus.ie/) (Windows), or `dd` (Linux/Mac):
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

### Docker Usage

#### Docker CLI

1. **Pull the Docker Image:**
   Get the latest Docker image from [Docker Hub](https://hub.docker.com/r/softwarerat/pppwn_live/tags):
   ```bash
   docker pull softwarerat/pppwn_live:latest
   ```

2. **Run the Docker Container:**
   Start the container with the desired firmware version using the `FIRMWARE_VERSION` environment variable:
   ```bash
   docker run --rm -e FIRMWARE_VERSION=1100 --network host softwarerat/pppwn_live
   ```
   Replace `1100` with the firmware version you need.

3. **Automatic Shutdown:**
   The container will run `pppwn_cpp` and automatically shut down after completing its tasks.

#### Docker Compose

1. **Use the Existing `docker-compose.yml` File:**
   The `docker-compose.yml` file is located in the `docker` folder of the repository. Use the following configuration:
   ```yaml
   version: '3'

   services:
     pppwn:
       image: softwarerat/pppwn_live:latest
       environment:
         - FIRMWARE_VERSION=1100
       network_mode: host
       restart: unless-stopped
   ```

2. **Start the Docker Compose Service:**
   Run the following command from the root of the repository:
   ```bash
   docker-compose -f docker/docker-compose.yml up
   ```
   Replace `1100` with the firmware version you need. The service will automatically shut down after completing its tasks.

#### Building Docker Images Manually

1. **Use the Existing `Dockerfile`:**
   The `Dockerfile` is located in the `docker` folder of the repository. If you need to build the Docker image manually, use the following command from the root of the repository:
   ```bash
   docker build -f docker/Dockerfile -t pppwn_image .
   ```

2. **Run the Docker Container:**
   Use the following command to start the container:
   ```bash
   docker run --rm -e FIRMWARE_VERSION=1100 --network host pppwn_image
   ```
   Replace `1100` with the firmware version you need.

## Screenshots
![Screenshot of PPPwnLive ISO booted, showing a terminal interface with system information and instructions](images/screenshot.png)

## Development

If you'd like to create the ISO yourself, follow these steps:

### Prerequisites

You'll need an Alpine Linux system with the following packages installed:

```bash
apk add --no-cache alpine-sdk alpine-conf xorriso squashfs-tools grub grub-efi doas alpine-base busybox openrc bash agetty
```

### Preparing the Custom Files

1. Copy the content of the custom folder in this repository to `aports/scripts`.
2. Create the `pppwn.tar.gz` file: This archive should have the following structure:

```bash
tar -ztvf pppwn.tar.gz
-rwxr-xr-x  0 username group  452780 May 20 00:10 pppwnlive/pppwn
-rw-r--r--  0 username group     500 Sep  5 15:43 pppwnlive/stage1.bin
-rw-r--r--  0 username group    2705 Sep  5 15:43 pppwnlive/stage2.bin
```
- `pppwn` is the `pppwn_cpp` binary, which must be downloaded or compiled for your desired architecture.
- `stage1.bin` and `stage2.bin` are the required payloads, the pre-created ones use GoldHEN which you can download from [B-Dem's PPPwnUI](https://github.com/B-Dem/PPPwnUI/tree/main/PPPwn/goldhen/1100).
- After creating `pppwn.tar.gz`, copy it to the `aports/scripts` folder.

### Build the ISO

To create the ISO, run the following command from the root of the repository:

```bash
sh aports/scripts/mkimage.sh --tag edge --outdir <your desired ISO output path> --arch <your desired architecture> --repository https://dl-cdn.alpinelinux.org/alpine/edge/main --profile pppwn
```

Replace `<your desired ISO output path>` and `<your desired architecture>` with appropriate values.

## Contributing

Contributions are welcome! Please fork the repository and submit a pull request. For major changes, open an issue first to discuss proposed changes.

## License

This project is licensed under the [GNU General Public License v3.0](LICENSE).

## Acknowledgments

- [Alpine Linux](https://alpinelinux.org/) for their lightweight distribution
- [xfangfang](https://github.com/xfangfang/PPPwn_cpp) for developing the C++ version of PPPwn
- [TheFloW](https://github.com/TheOfficialFloW/PPPwn) for the original discovery and creation of PPPwn
- [SiSTRo](https://github.com/SiSTR0) and the [GoldHEN Team](https://github.com/GoldHEN/GoldHEN) for developing GoldHEN, the PS4 Homebrew Enabler used in this project
