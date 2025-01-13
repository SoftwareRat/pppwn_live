#!/bin/bash
set -e

chmod +x "${TARGET_DIR}/etc/init.d/S50pppwn"

# Ensure boot/grub directory exists
mkdir -p "${TARGET_DIR}/boot/grub"

# Create UEFI-only grub.cfg
cat > "${TARGET_DIR}/boot/grub/grub.cfg" << EOF
set default="0"
set timeout="5"
set prefix=(cd0)/boot/grub

menuentry "PPPwnLive" {
    linux (cd0)/boot/bzImage root=/dev/ram0 console=tty1
    initrd (cd0)/boot/initrd
}
EOF