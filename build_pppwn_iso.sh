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

# Create necessary directories
mkdir -p "${WORK_DIR}" \
         "${OVERLAY_DIR}/etc/init.d" \
         "${OVERLAY_DIR}/usr/bin" \
         "${OVERLAY_DIR}/usr/share/pppwn"

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

# Create startup script
create_startup_script() {
    cat > "${OVERLAY_DIR}/etc/init.d/S99pppwn" << 'EOF'
#!/bin/sh

start() {
    # Wait for network interface to be ready
    sleep 5

    # Find first ethernet interface
    IFACE=$(ip -o link show | awk -F': ' '$2 ~ /^eth[0-9]+/ {print $2; exit}')

    if [ -z "$IFACE" ]; then
        echo "No ethernet interface found!"
        poweroff
    fi

    # Run PPPwn
    /usr/bin/pppwn -i "$IFACE" --fw 1100 \
        --stage1 /usr/share/pppwn/stage1.bin \
        --stage2 /usr/share/pppwn/stage2.bin -a

    EXITCODE=$?

    if [ $EXITCODE -eq 0 ]; then
        poweroff
    else
        echo "An error has occurred +++ Error code: $EXITCODE"
        sleep 10
        poweroff
    fi
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

# Configure and build Buildroot
configure_buildroot() {
    cd "${BR_DIR}"

    # Start with default configuration
    make defconfig

    # Update configuration using sed for architecture
    sed -i 's/BR2_i386=y/# BR2_i386 is not set/' .config

    # Create clean configuration with only needed options
    cat >> .config << EOF
# Architecture
BR2_x86_64=y

# System Configuration
BR2_TOOLCHAIN_BUILDROOT_MUSL=y
BR2_INIT_BUSYBOX=y
BR2_SYSTEM_DHCP="eth0"

# Target packages
BR2_PACKAGE_DHCPCD=y

# Filesystem images
BR2_TARGET_ROOTFS_ISO9660=y
BR2_TARGET_ROOTFS_ISO9660_BOOT_MENU=n
BR2_TARGET_ROOTFS_ISO9660_GRUB2=n
BR2_TARGET_ROOTFS_ISO9660_HYBRID=y
BR2_TARGET_SYSLINUX=y
BR2_TARGET_ROOTFS_ISO9660_BOOT_CATALOG=y

# Boot configuration
BR2_TARGET_SYSLINUX_MBR=y
BR2_TARGET_SYSLINUX_ISOLINUX=y

# Linux kernel
BR2_LINUX_KERNEL=y
BR2_LINUX_KERNEL_USE_ARCH_DEFAULT_CONFIG=y
BR2_LINUX_KERNEL_INSTALL_TARGET=y

# Root filesystem overlay
BR2_ROOTFS_OVERLAY="${OVERLAY_DIR}"
EOF

    # Remove any legacy watchdog configurations if they exist
    sed -i '/BR2_PACKAGE_WATCHDOG/d' .config

    # Update configuration
    make olddefconfig
}

# Clean previous builds to avoid legacy option issues
clean_build() {
    cd "${BR_DIR}"
    echo "Cleaning previous Buildroot builds..."
    make clean
    make distclean
}

# Build function
build_iso() {
    cd "${BR_DIR}"
    echo "Starting the build process with parallel jobs..."
    make -j"$(nproc)"
}

# Main execution
echo "Checking dependencies..."
check_dependencies

echo "Starting build process..."
echo "Downloading Buildroot..."
download_buildroot

echo "Downloading assets..."
download_assets

echo "Creating startup script..."
create_startup_script

echo "Cleaning previous builds (if any)..."
clean_build

echo "Configuring Buildroot..."
configure_buildroot

echo "Building ISO..."
build_iso

echo "Build complete! ISO can be found at: ${BR_DIR}/output/images/rootfs.iso9660"