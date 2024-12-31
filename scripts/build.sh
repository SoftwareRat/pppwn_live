#!/bin/bash
set -e

# Configuration
KERNEL_VERSION="6.12.7"
BUSYBOX_VERSION="1.36.1"
BUILD_DIR="/build/output"
SYSROOT="${BUILD_DIR}/sysroot"

# Create build directory structure
mkdir -p "${BUILD_DIR}" "${SYSROOT}"

# Download and build kernel
wget -q "https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-${KERNEL_VERSION}.tar.xz"
tar xf "linux-${KERNEL_VERSION}.tar.xz"
cd "linux-${KERNEL_VERSION}"
cp ../configs/kernel/minimal.config .config
yes "" | make olddefconfig
make -j$(nproc)
cp arch/x86_64/boot/bzImage "${BUILD_DIR}/kernel"
cd ..

# Download and build busybox
wget -q "https://busybox.net/downloads/busybox-${BUSYBOX_VERSION}.tar.bz2"
tar xf "busybox-${BUSYBOX_VERSION}.tar.bz2"
cd "busybox-${BUSYBOX_VERSION}"
cp ../configs/busybox/minimal.config .config
yes "" | make oldconfig
make -j$(nproc) CONFIG_PREFIX="${SYSROOT}"
make install CONFIG_PREFIX="${SYSROOT}"
cd ..

# Create minimal initramfs
cd "${SYSROOT}"
mkdir -p {bin,sbin,etc,proc,sys,dev,run,tmp}
chmod 1777 tmp

# Set up network configuration
mkdir -p etc/network
cat > etc/network/interfaces << EOF
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet manual
    pre-up ip link set eth0 promisc on
    up ip link set eth0 up
EOF

# Copy init and tools
cp -a ../src/init sbin/init
cp -a ../overlay/etc .

# Create device nodes
mknod -m 666 dev/null c 1 3
mknod -m 666 dev/zero c 1 5
mknod -m 666 dev/random c 1 8
mknod -m 666 dev/urandom c 1 9
mknod -m 666 dev/tty c 5 0
mknod -m 600 dev/console c 5 1
mknod -m 666 dev/ptmx c 5 2

find . | cpio -H newc -o | gzip > "${BUILD_DIR}/initramfs.gz" 