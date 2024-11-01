#!/bin/sh

profile_pppwn() {
    profile_abbrev="pppwn"
    title="PPPwn"
    desc="Minimal ISO for PPPwn jailbreak on PlayStation 4"

    # Kernel configuration
    kernel_flavors="lts"
    kernel_cmdline="console=tty0 console=ttyS0,115200 quiet"

    # Minimal package selection
    apks="alpine-base busybox openrc bash agetty"
    apks="$apks linux-$kernel_flavors linux-firmware-none"

    # Architecture-specific configurations
    case "$ARCH" in
    x86*|amd64)
        boot_addons="amd-ucode intel-ucode"
        initrd_ucode="/boot/amd-ucode.img /boot/intel-ucode.img"
        syslinux_serial="0 115200"
        apks="$apks syslinux"
        ;;
    esac

    # Custom overlay for PPPwn-specific configurations
    apkovl="genapkovl-pppwn.sh"

    # Disable unnecessary services
    local _service
    for _service in hwdrivers bootmisc hostname syslog; do
        rc_add local $_service boot
    done

    # Enable required services
    rc_add local pppoe boot
}
