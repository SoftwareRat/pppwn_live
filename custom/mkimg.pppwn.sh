#!/bin/sh

profile_pppwn() {
    profile_standard
    kernel_cmdline="unionfs_size=128M console=tty0 console=ttyS0,115200 quiet loglevel=0 rd.systemd.show_status=auto rd.plymouth=0 plymouth.enable=0 mitigations=off nowatchdog nospectre_v2"
    title="Nano"
    desc="Hyper-minimal profile for PS4 PPPwn jailbreak
          Absolute bare-metal footprint, optimized for single-purpose exploit"
    apks="alpine-base busybox openrc bash"

    # Dynamic kernel package selection with minimal footprint
    local _k _a
    for _k in $kernel_flavors; do
        apks="$apks linux-$_k linux-firmware-none"
        for _a in $kernel_addons; do
            apks="$apks ${_a}-${_k}"
        done
    done

    # Architecture-specific ultra-optimization
    case "$ARCH" in
    x86*|amd64)
        # Minimal microcode, serial console, and bootloader
        boot_addons="minimal-ucode"
        initrd_ucode="/boot/minimal-ucode.img"
        syslinux_serial="0 115200"
        apks="$apks syslinux isolinux"

        # Disable unnecessary architectural features
        kernel_cmdline="$kernel_cmdline idle=nomwait processor.max_cstate=1"
        ;;
    esac

    # Custom overlay for PPPwn-specific configuration
    apkovl="aports/scripts/genapkovl-pppwn-ultra.sh"

    # Network and system optimization
    # Removed all unnecessary network packages
    apks="$apks --no-cache"

    # Post-build optimization hook
    post_build() {
        # Remove unnecessary documentation and localization
        rm -rf /usr/share/doc/* /usr/share/man/* /usr/share/info/*
        find / -type f -name "*.a" -delete
        find / -type f -name "*.la" -delete
    }
}

# Strict package filtering function
filter_packages() {
    # Aggressive package removal for minimal footprint
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

# Custom initramfs generator for ultra-minimal boot
generate_ultra_minimal_initramfs() {
    local kernel_version="$1"

    # Create a bare-minimum initramfs
    mkdir -p /tmp/initramfs/{bin,dev,etc,lib,proc,sys}

    # Copy only essential binaries
    cp /bin/busybox /tmp/initramfs/bin/

    # Create minimal set of device nodes
    mknod -m 666 /tmp/initramfs/dev/null c 1 3
    mknod -m 666 /tmp/initramfs/dev/zero c 1 5

    # Generate init script
    cat > /tmp/initramfs/init << 'EOF'
#!/bin/busybox sh
mount -t proc none /proc
mount -t sysfs none /sys
exec /bin/sh
EOF
    chmod +x /tmp/initramfs/init

    # Create the initramfs
    cd /tmp/initramfs
    find . | cpio -H newc -o | gzip > "/boot/initramfs-ultra-${kernel_version}"
}
