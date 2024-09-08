#!/bin/bash

# Set default firmware version if not provided
FIRMWARE_VERSION="${FIRMWARE_VERSION:-1100}"

# Download the correct stage1 and stage2 binaries for the firmware version
echo "Downloading firmware binaries for version ${FIRMWARE_VERSION}..."
wget -q https://github.com/B-Dem/PPPwnUI/raw/main/PPPwn/goldhen/${FIRMWARE_VERSION}/stage1.bin
wget -q https://github.com/B-Dem/PPPwnUI/raw/main/PPPwn/goldhen/${FIRMWARE_VERSION}/stage2.bin

if [ ! -f "stage1.bin" ] || [ ! -f "stage2.bin" ]; then
    echo "Error: Failed to download firmware binaries for version ${FIRMWARE_VERSION}"
    exit 1
fi

# Run the PPPwn++ binary with the correct firmware version and downloaded stages
/opt/pppwn/pppwn -i eth0 --fw "$FIRMWARE_VERSION" --stage1 /opt/pppwn/stage1.bin --stage2 /opt/pppwn/stage2.bin -a