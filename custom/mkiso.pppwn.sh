#!/bin/sh

profile_pppwn() {
    profile_standard
    profile_abbrev="pppwn"
    title="Extended"
    desc="Contains only the minimal.
        Designed to run the PPPwn jailbreak.
        For the PlayStation 4"
    kernel_cmdline="unionfs_size=512M console=tty0 console=ttyS0,115200"
    syslinux_serial="0 115200"
    boot_addons="amd-ucode intel-ucode"
    initrd_ucode="/boot/amd-ucode.img /boot/intel-ucode.img"
    apks="alpine-base busybox openrc bash agetty"
	local _k _a
	for _k in $kernel_flavors; do
		apks="$apks linux-$_k"
		for _a in $kernel_addons; do
			apks="$apks $_a-$_k"
		done
	done

    apks="$apks linux-firmware linux-firmware-none"
    apkovl="aports/scripts/genapkovl-pppwn.sh"
}