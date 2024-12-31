#!/bin/bash
set -e

ISO_NAME="$1"
OUTPUT_DIR="$2"
ISO_ROOT="${OUTPUT_DIR}/iso"

# Create ISO structure
mkdir -p "${ISO_ROOT}"/{boot,isolinux}

# Copy kernel and initramfs
cp "${OUTPUT_DIR}/kernel" "${ISO_ROOT}/boot/vmlinuz"
cp "${OUTPUT_DIR}/initramfs.gz" "${ISO_ROOT}/boot/initrd.gz"

# Create isolinux config optimized for PS4
cat > "${ISO_ROOT}/isolinux/isolinux.cfg" << EOF
UI menu.c32
PROMPT 0
TIMEOUT 1
DEFAULT pppwn

LABEL pppwn
    MENU LABEL PPPwn Live
    LINUX /boot/vmlinuz
    INITRD /boot/initrd.gz
    APPEND console=tty0 console=ttyS0,115200n8 nomodeset quiet net.ifnames=0 biosdevname=0
EOF

# Copy isolinux files
cp /usr/lib/ISOLINUX/isolinux.bin "${ISO_ROOT}/isolinux/"
cp /usr/lib/syslinux/modules/bios/menu.c32 "${ISO_ROOT}/isolinux/"
cp /usr/lib/syslinux/modules/bios/libutil.c32 "${ISO_ROOT}/isolinux/"

# Create ISO with minimal options
xorriso -as mkisofs \
    -o "${OUTPUT_DIR}/${ISO_NAME}.iso" \
    -b isolinux/isolinux.bin \
    -c isolinux/boot.cat \
    -no-emul-boot \
    -boot-load-size 4 \
    -boot-info-table \
    -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \
    -volid "PPPWN_LIVE" \
    -quiet \
    "${ISO_ROOT}"
