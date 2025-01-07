#!/bin/bash
set -e

chmod +x "${TARGET_DIR}/etc/init.d/S50pppwn"

# Ensure boot/grub directory exists
mkdir -p "${TARGET_DIR}/boot/grub"

# Create the correct grub.cfg for initrd
cat > "${TARGET_DIR}/boot/grub/grub.cfg" << EOF
set default="0"
set timeout="5"

if [ "\${grub_platform}" = "efi" ]; then
    set prefix=(cd0)/boot/grub
    menuentry "PPPwnLive" {
        linux (cd0)/boot/bzImage root=/dev/ram0 console=tty1
        initrd (cd0)/boot/initrd
    }
else
    set prefix=(cd)/boot/grub
    menuentry "PPPwnLive" {
        linux (cd)/boot/bzImage root=/dev/ram0 console=tty1
        initrd (cd)/boot/initrd
    }
fi
EOF