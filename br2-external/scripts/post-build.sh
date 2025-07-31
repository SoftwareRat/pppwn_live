#!/bin/bash
#
# PPPwn Live ISO post-build script
# This script runs after the root filesystem is built but before it's packaged
#

set -e

TARGET_DIR="$1"

echo "PPPwn Live ISO: Running post-build customizations..."

# Create necessary directories
mkdir -p "${TARGET_DIR}/etc/pppwn"
mkdir -p "${TARGET_DIR}/var/log/pppwn"
mkdir -p "${TARGET_DIR}/tmp/pppwn"

# Set up automatic login for root
if [ -f "${TARGET_DIR}/etc/inittab" ]; then
    # Replace getty with automatic login
    sed -i 's/getty -L/getty -L -n -l \/bin\/sh/' "${TARGET_DIR}/etc/inittab" || true
fi

# Create PPPwn configuration file
cat > "${TARGET_DIR}/etc/pppwn/config" << 'EOF'
# PPPwn Live ISO Configuration

# System settings
HOSTNAME="pppwnlive"
AUTO_SHUTDOWN=true
TIMEOUT_SECONDS=300

# Network settings
INTERFACE_PATTERNS="eth* en*"
DHCP_TIMEOUT=30
DETECTION_RETRIES=3

# Exploit settings
FIRMWARE_VERSION="1100"
STAGE1_PATH="/usr/share/pppwn/stage1"
STAGE2_PATH="/usr/share/pppwn/stage2"
BINARY_PATH="/usr/bin/pppwn"
RETRY_ATTEMPTS=3
RETRY_DELAY=5

# Display settings
CLEAR_SCREEN=true
SHOW_BANNER=true
VERBOSE_OUTPUT=true
COLOR_OUTPUT=true
EOF

# Set proper permissions
chmod 644 "${TARGET_DIR}/etc/pppwn/config"
chmod 755 "${TARGET_DIR}/var/log/pppwn"
chmod 755 "${TARGET_DIR}/tmp/pppwn"

# Create a simple motd
cat > "${TARGET_DIR}/etc/motd" << 'EOF'
Welcome to PPPwn Live ISO!

This system is designed to automatically execute the PPPwn PS4 exploit.
Please connect your PS4 via Ethernet and follow the on-screen instructions.

For manual operation, PPPwn components are available at:
- Binary: /usr/bin/pppwn
- Stage1: /usr/share/pppwn/stage1/
- Stage2: /usr/share/pppwn/stage2/

EOF

echo "PPPwn Live ISO: Post-build customizations completed successfully"