#!/bin/bash
#
# PPPwn Live ISO post-image script
# This script runs after all images are built and can customize the final ISO
#

set -e

BINARIES_DIR="$1"
TARGET_DIR="$2"

echo "PPPwn Live ISO: Running post-image customizations..."

# Check if ISO was created
if [ -f "${BINARIES_DIR}/rootfs.iso9660" ]; then
    echo "PPPwn Live ISO: ISO image created successfully at ${BINARIES_DIR}/rootfs.iso9660"
    
    # Create a more user-friendly filename
    if [ ! -f "${BINARIES_DIR}/pppwn_live.iso" ]; then
        ln -sf rootfs.iso9660 "${BINARIES_DIR}/pppwn_live.iso"
        echo "PPPwn Live ISO: Created symlink pppwn_live.iso"
    fi
    
    # Display ISO information
    ISO_SIZE=$(du -h "${BINARIES_DIR}/rootfs.iso9660" | cut -f1)
    echo "PPPwn Live ISO: Final ISO size: ${ISO_SIZE}"
else
    echo "PPPwn Live ISO: Warning - ISO image not found"
    exit 1
fi

# Verify critical files are present in the image
echo "PPPwn Live ISO: Verifying critical components..."

# Create a temporary mount point to verify contents
TEMP_MOUNT=$(mktemp -d)
trap "umount ${TEMP_MOUNT} 2>/dev/null || true; rmdir ${TEMP_MOUNT}" EXIT

# Try to mount and verify (this may not work in all build environments)
if command -v mount >/dev/null 2>&1; then
    if mount -o loop,ro "${BINARIES_DIR}/rootfs.iso9660" "${TEMP_MOUNT}" 2>/dev/null; then
        echo "PPPwn Live ISO: Successfully mounted ISO for verification"
        
        # Check for kernel
        if [ -f "${TEMP_MOUNT}/boot/bzImage" ] || [ -f "${TEMP_MOUNT}/isolinux/bzImage" ]; then
            echo "PPPwn Live ISO: ✓ Kernel found"
        else
            echo "PPPwn Live ISO: ✗ Kernel not found"
        fi
        
        # Check for initrd
        if [ -f "${TEMP_MOUNT}/boot/rootfs.cpio.gz" ] || [ -f "${TEMP_MOUNT}/isolinux/rootfs.cpio.gz" ]; then
            echo "PPPwn Live ISO: ✓ Initrd found"
        else
            echo "PPPwn Live ISO: ✗ Initrd not found"
        fi
        
        umount "${TEMP_MOUNT}"
    else
        echo "PPPwn Live ISO: Could not mount ISO for verification (this may be normal in build environments)"
    fi
fi

echo "PPPwn Live ISO: Post-image customizations completed successfully"

# Create build info file
cat > "${BINARIES_DIR}/build_info.txt" << EOF
PPPwn Live ISO Build Information
================================

Build Date: $(date)
Build Host: $(hostname)
ISO File: rootfs.iso9660
ISO Size: ${ISO_SIZE:-Unknown}
Symlink: pppwn_live.iso

Components:
- PPPwn C++ binary
- Stage1 payloads
- Stage2 payloads
- Network detection scripts
- Automatic execution system

Usage:
1. Burn this ISO to a USB drive or CD
2. Boot from the media
3. Connect PS4 via Ethernet
4. Follow on-screen instructions

EOF

echo "PPPwn Live ISO: Build information saved to ${BINARIES_DIR}/build_info.txt"