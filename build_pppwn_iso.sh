#!/bin/bash
set -e

# Configuration
BUILDROOT_VERSION="2024.02.9"
WORK_DIR="$(pwd)/pppwn_buildroot"
BR_DIR="${WORK_DIR}/buildroot-${BUILDROOT_VERSION}"
OUTPUT_DIR="${WORK_DIR}/output"
OVERLAY_DIR="${WORK_DIR}/overlay"

# Function to check dependencies
check_dependencies() {
    local dependencies=(wget curl jq 7z unzip make gcc git rsync bc)
    for cmd in "${dependencies[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            echo "Error: $cmd is not installed. Please install it and retry."
            exit 1
        fi
    done
}

# Create directories required by the script
prepare_directories() {
    mkdir -p "${WORK_DIR}" \
             "${OVERLAY_DIR}/etc/init.d" \
             "${OVERLAY_DIR}/usr/bin" \
             "${OVERLAY_DIR}/usr/share/pppwn"
}

# Download and extract Buildroot
download_buildroot() {
    if [ ! -d "${BR_DIR}" ]; then
        echo "Downloading Buildroot version ${BUILDROOT_VERSION}..."
        wget "https://buildroot.org/downloads/buildroot-${BUILDROOT_VERSION}.tar.gz" -P "${WORK_DIR}"
        tar xf "${WORK_DIR}/buildroot-${BUILDROOT_VERSION}.tar.gz" -C "${WORK_DIR}"
        rm "${WORK_DIR}/buildroot-${BUILDROOT_VERSION}.tar.gz"
    else
        echo "Buildroot directory already exists. Skipping download."
    fi
}

# Download required binaries and assets
download_assets() {
    local pppwn_dir="${OVERLAY_DIR}/usr/share/pppwn"
    local bin_dir="${OVERLAY_DIR}/usr/bin"
    
    cd "${pppwn_dir}"

    echo "Downloading stage1.bin..."
    wget -O stage1.bin "https://github.com/B-Dem/PPPwnUI/raw/main/PPPwn/goldhen/1100/stage1.bin"

    echo "Downloading stage2.bin..."
    curl -L -o GoldHEN.7z "$(curl -s https://api.github.com/repos/GoldHEN/GoldHEN/releases | jq -r '.[0].assets[0].browser_download_url')"
    7z e GoldHEN.7z pppnw_stage2/stage2_v*.7z -r -aoa
    7z e stage2_v*.7z stage2_11.00.bin -r -aoa
    mv stage2_11.00.bin stage2.bin
    rm -f GoldHEN.7z stage2_v*.7z

    echo "Downloading latest PPPwn binary..."
    PPPWN_URL=$(curl -s "https://api.github.com/repos/xfangfang/PPPwn_cpp/releases" | jq -r '[.[] | select(.prerelease == true or .prerelease == false)][0].assets[] | select(.name | endswith("x86_64-linux-musl.zip")).browser_download_url')
    wget -O pppwn.zip "${PPPWN_URL}"
    unzip pppwn.zip
    tar xf pppwn.tar.gz
    
    chmod +x pppwn
    mv pppwn "${bin_dir}/"
    rm -f pppwn.zip pppwn.tar.gz
}

# Create a simple IPv6 network configuration
create_network_config() {
    # Create the network directory structure first
    mkdir -p "${OVERLAY_DIR}/etc/network"
    
    cat > "${OVERLAY_DIR}/etc/network/interfaces" << 'EOF'
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet6 static
    address fe80::1/64
EOF
}

# Create startup script that runs PPPwn
create_startup_script() {
    # First, create the check_status script
    cat > "${OVERLAY_DIR}/usr/bin/check_status" << 'EOF'
#!/bin/sh

# Function to reset ethernet interface
reseteth() {
    ifconfig eth0 down
    sleep 1
    ifconfig eth0 up
    sleep 3
}

run_pppwn() {
    /usr/bin/pppwn -i eth0 --fw 1100 \
        --stage1 /usr/share/pppwn/stage1.bin \
        --stage2 /usr/share/pppwn/stage2.bin
}

check_pppwn() {
    echo "Checking PPPwn status..."
    if dmesg | grep -q "\[+\] Done!"; then
        echo "PPPwn payload successful - shutting down..."
        killall pppoe-server
        halt
        exit 0
    fi
    return 1
}

# Check for GoldHEN first
echo "Checking for GoldHEN..."
pppoe-server -I eth0 -T 60 -N 1 -C isp -S isp -L 192.168.1.1 -R 192.168.1.2 &
sleep 2

# Wait for connection
while ! ping -c 1 192.168.1.2 >/dev/null 2>&1; do
    sleep 2
done
sleep 5

# Check if GoldHEN port is open
if nmap -n -p 3232 192.168.1.2 | grep -q '3232/tcp open'; then
    echo "GoldHEN detected - shutting down..."
    killall pppoe-server
    halt
    exit 0
fi

# Try PPPwn indefinitely
attempt=1

while true; do
    echo "PPPwn attempt $attempt"
    check_pppwn
    if [ $? -eq 0 ]; then
        break
    fi
    
    echo "PPPwn attempt $attempt failed, retrying..."
    killall pppoe-server
    reseteth
    sleep 2
    
    echo "Running PPPwn attempt $attempt..."
    run_pppwn
    
    attempt=$((attempt + 1))
done
EOF
    chmod +x "${OVERLAY_DIR}/usr/bin/check_status"

    # Create the startup service that calls check_status
    cat > "${OVERLAY_DIR}/etc/init.d/S99pppwn" << 'EOF'
#!/bin/sh

start() {
    # Find first ethernet interface
    IFACE=$(ip -o link show | awk -F': ' '$2 ~ /^eth[0-9]+/ {print $2; exit}')

    if [ -z "$IFACE" ]; then
        echo "No ethernet interface found!"
        poweroff
    fi

    # Configure network interface
    ip link set "$IFACE" up

    # Run PPPwn first without auto mode
    echo "Starting initial PPPwn attempt..."
    /usr/bin/pppwn -i "$IFACE" --fw 1100 \
        --stage1 /usr/share/pppwn/stage1.bin \
        --stage2 /usr/share/pppwn/stage2.bin

    # After PPPwn exits, run the status checker which will handle retries if needed
    /usr/bin/check_status
}

case "$1" in
    start)
        start
        ;;
    *)
        echo "Usage: $0 start"
        exit 1
esac
EOF
    chmod +x "${OVERLAY_DIR}/etc/init.d/S99pppwn"
}

# Create a kernel IPv6 config fragment
create_kernel_ipv6_config() {
    cat > "${BR_DIR}/kernel-ipv6.config" << 'EOF'
CONFIG_IPV6=y
CONFIG_IPV6_ROUTER_PREF=y
CONFIG_IPV6_MULTIPLE_TABLES=y
CONFIG_IPV6_SEG6_LWTUNNEL=y
EOF
}

# Configure Buildroot with both legacy (Syslinux) and UEFI (GRUB2) support
configure_buildroot() {
    cd "${BR_DIR}"

    # Start with a default config
    make defconfig

    # Create the IPv6 fragment
    create_kernel_ipv6_config

    # Remove i386 and add x86_64
    sed -i 's/BR2_i386=y/# BR2_i386 is not set/' .config

    # Append our settings for a hybrid ISO
    cat >> .config << EOF
# Architecture
BR2_x86_64=y

# System Configuration
BR2_TOOLCHAIN_BUILDROOT_MUSL=y
BR2_INIT_BUSYBOX=y

# Required packages
BR2_PACKAGE_RPCBIND=y
BR2_PACKAGE_PPPD=y
BR2_PACKAGE_RPCBIND=y
BR2_PACKAGE_NMAP=y
BR2_PACKAGE_NMAP_NMAP=y
BR2_PACKAGE_PPPOE=y
BR2_PACKAGE_RPCBIND=y

# IPv6 Support
BR2_TOOLCHAIN_BUILDROOT_WCHAR=y
BR2_USE_MMU=y
BR2_TOOLCHAIN_HAS_IPV6=y
BR2_PACKAGE_LINUX_TOOLS_IPV6=y

# Filesystem images
BR2_TARGET_ROOTFS_ISO9660=y
BR2_TARGET_ROOTFS_ISO9660_BOOT_MENU=n
BR2_TARGET_ROOTFS_ISO9660_HYBRID=y
BR2_TARGET_ROOTFS_ISO9660_BOOT_CATALOG=y

# Legacy BIOS boot via Syslinux
BR2_TARGET_SYSLINUX=y
BR2_TARGET_SYSLINUX_MBR=y
BR2_TARGET_SYSLINUX_ISOLINUX=y
BR2_TARGET_SYSLINUX_PXE=n
BR2_TARGET_SYSLINUX_EFI=n

# UEFI boot via GRUB2
BR2_TARGET_GRUB2=y
BR2_TARGET_GRUB2_I386_PC=y
BR2_TARGET_GRUB2_EFI_X86_64=y
BR2_TARGET_GRUB2_BUILTIN_MODULES_PC="boot linux ext2 fat squash4 part_msdos part_gpt normal"
BR2_TARGET_GRUB2_BUILTIN_MODULES_EFI="boot linux ext2 fat squash4 part_msdos part_gpt normal efi_gop"
BR2_TARGET_GRUB2_BUILTIN_CONFIG_PC="${BR_DIR}/grub.cfg"
BR2_TARGET_GRUB2_BUILTIN_CONFIG_EFI="${BR_DIR}/grub.cfg"

# Linux kernel build
BR2_LINUX_KERNEL=y
BR2_LINUX_KERNEL_USE_ARCH_DEFAULT_CONFIG=y
BR2_LINUX_KERNEL_INSTALL_TARGET=y

# Enable our IPv6 kernel config fragment
BR2_LINUX_KERNEL_CONFIG_FRAGMENT_FILES="${BR_DIR}/kernel-ipv6.config"

# Root filesystem overlay
BR2_ROOTFS_OVERLAY="${OVERLAY_DIR}"
EOF

    # Remove any legacy watchdog configurations if they exist
    sed -i '/BR2_PACKAGE_WATCHDOG/d' .config

    # Update configuration based on newly appended settings
    make olddefconfig

    # Create a minimal grub.cfg in both locations
    mkdir -p "${OVERLAY_DIR}/boot/grub2"
    cat > "${OVERLAY_DIR}/boot/grub2/grub.cfg" << EOF
set default="0"
set timeout="10"

menuentry "PPPwn Live" {
    linux /boot/bzImage root=/dev/sr0
    initrd /boot/initrd
}
EOF

    # Also copy it to the overlay for the final image
    cp "${BR_DIR}/grub.cfg" "${OVERLAY_DIR}/boot/grub2/grub.cfg"

    # Create syslinux configuration for legacy boot
    mkdir -p "${OVERLAY_DIR}/boot/syslinux"
    cat > "${OVERLAY_DIR}/boot/syslinux/syslinux.cfg" << EOF
PROMPT 0
TIMEOUT 0
DEFAULT pppwn

LABEL pppwn
    MENU LABEL PPPwn Live
    LINUX /boot/bzImage
    APPEND root=/dev/sr0
EOF
}

# Clean any previous build artifacts
clean_build() {
    if [ -d "${BR_DIR}" ]; then
        echo "Cleaning previous build artifacts..."
        cd "${BR_DIR}"
        make clean
    fi
}

# Build the ISO image
build_iso() {
    cd "${BR_DIR}"
    echo "Building the ISO image..."
    make -j"$(nproc)"

}

########################
# Main Script Execution
########################
echo "Checking dependencies..."
check_dependencies

echo "Preparing directories..."
prepare_directories

echo "Downloading Buildroot..."
download_buildroot

echo "Downloading assets..."
download_assets

echo "Creating network configuration..."
create_network_config

echo "Creating startup script..."
create_startup_script

echo "Cleaning previous builds (if any)..."
clean_build

echo "Configuring Buildroot..."
configure_buildroot

echo "Building ISO..."
build_iso

echo "Build complete!"
echo "ISO can be found at: ${BR_DIR}/output/images/rootfs.iso9660"