#!/bin/bash

# Firmware version passed as argument or default to 1100
FIRMWARE_VERSION=${1:-1100}

# Download the firmware binaries
echo "Downloading firmware binaries for version $FIRMWARE_VERSION..."
wget -q -P /opt/pppwn https://github.com/B-Dem/PPPwnUI/raw/main/PPPwn/goldhen/${FIRMWARE_VERSION}/stage1.bin
wget -q -P /opt/pppwn https://github.com/B-Dem/PPPwnUI/raw/main/PPPwn/goldhen/${FIRMWARE_VERSION}/stage2.bin

# Check if the files were downloaded correctly
if [ ! -f "/opt/pppwn/stage1.bin" ] || [ ! -f "/opt/pppwn/stage2.bin" ]; then
    echo "Error: Failed to download firmware binaries for version $FIRMWARE_VERSION"
    exit 1
fi

# Run PPPwn++
/opt/pppwn/pppwn -i eth0 --fw $FIRMWARE_VERSION --stage1 /opt/pppwn/stage1.bin --stage2 /opt/pppwn/stage2.bin -a