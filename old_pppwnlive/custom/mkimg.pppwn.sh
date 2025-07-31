#!/bin/sh

# Add this function to handle kernel module compression
generate_modloop() {
    local kernel_ver="$1"
    local modloop="$2"

    # Create a temporary directory for modules
    mkdir -p /tmp/modloop

    # Copy modules to the temporary directory
    cp -a /lib/modules/${kernel_ver} /tmp/modloop/

    # Compress modules using xz with maximum compression
    cd /tmp/modloop
    if ! tar -cJf "$modloop" lib/modules/${kernel_ver}; then
        echo "Error: Failed to create modloop tarball"
        ls -l /tmp/modloop
        exit 1
    fi

    # Clean up
    rm -rf /tmp/modloop
}

profile_pppwn() {
    profile_standard
    profile_abbrev="pppwn"
    kernel_cmdline="unionfs_size=128M console=tty0 console=ttyS0,115200 quiet loglevel=0 rd.systemd.show_status=auto nowatchdog rd.plymouth=0 plymouth.enable=0 mitigations=off nospectre_v2"
    title="Nano"
    desc="Hyper-minimal profile for PS4 PPPwn jailbreak
          Absolute bare-metal footprint, optimized for single-purpose exploit"
    apks="alpine-base busybox openrc bash agetty"
    boot_addons=""

    local _k _a
    for _k in $kernel_flavors; do
        apks="$apks linux-$_k linux-firmware-none"
        for _a in $kernel_addons; do
            apks="$apks ${_a}-${_k}"
        done
    done

    case "$ARCH" in
    x86*|amd64)
        boot_addons="intel-ucode amd-ucode"
        initrd_ucode="/boot/intel-ucode.img /boot/amd-ucode.img"
        syslinux_serial="0 115200"
        apks="$apks syslinux"
        kernel_cmdline="$kernel_cmdline idle=nomwait processor.max_cstate=1"
        ;;
    aarch64)
        # Nothing (yet)
        ;;
    esac

    apkovl="aports/scripts/genapkovl-pppwn.sh"
    apks="$apks --no-cache"

    post_build() {
        rm -rf /usr/share/doc/* /usr/share/man/* /usr/share/info/*
        find / -type f -name "*.a" -delete
        find / -type f -name "*.la" -delete

        local kernel_ver=$(ls /lib/modules | head -n1)
        generate_modloop "$kernel_ver" "/boot/modloop-lts"
    }
}

filter_packages() {
    local keep_packages="
        alpine-base
        busybox
        bash
        linux-firmware-none
        syslinux
        openrc
    "

    for pkg in $(apk search | grep -E '^(alpine-base|busybox|bash|linux-|syslinux|openrc)'); do
        if echo "$keep_packages" | grep -qw "${pkg%%=*}"; then
            echo "$pkg"
        fi
    done
}

generate_minimal_initramfs() {
    local kernel_version="$1"
    mkdir -p /tmp/initramfs/{bin,dev,etc,lib,proc,sys}
    cp /bin/busybox /tmp/initramfs/bin/
    mknod -m 666 /tmp/initramfs/dev/null c 1 3
    mknod -m 666 /tmp/initramfs/dev/zero c 1 5

    cat > /tmp/initramfs/init << 'EOF'
#!/bin/busybox sh
mount -t proc none /proc
mount -t sysfs none /sys
exec /bin/sh
EOF
    chmod +x /tmp/initramfs/init
    cd /tmp/initramfs
    find . | cpio -H newc -o | gzip > "/boot/initramfs-${kernel_version}"
}
