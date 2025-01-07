#!/bin/bash
set -e

chmod +x "${TARGET_DIR}/etc/init.d/S50pppwn"

# Remove conflicting grub.cfg from target directory
rm -f "${TARGET_DIR}/boot/grub/grub.cfg"