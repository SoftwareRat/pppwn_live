#!/bin/sh -e

# Set the hostname
HOSTNAME="PPPwnLive"

cleanup() {
	rm -rf "$tmp"
}

makefile() {
	OWNER="$1"
	PERMS="$2"
	FILENAME="$3"
	cat > "$FILENAME"
	chown "$OWNER" "$FILENAME"
	chmod "$PERMS" "$FILENAME"
}

rc_add() {
	mkdir -p "$tmp"/etc/runlevels/"$2"
	ln -sf /etc/init.d/"$1" "$tmp"/etc/runlevels/"$2"/"$1"
}

tmp="$(mktemp -d)"
trap cleanup exit

mkdir -p "$tmp"/etc
mkdir -p "$tmp"/etc/init.d
mkdir -p "$tmp"/etc/profile.d
mkdir -p "$tmp"/etc/apk
mkdir -p "$tmp"/root

# WAR: Search for an aports/scripts/pppwn.tar.gz file in the home directory and copy it to "$tmp"/etc/
find ~ -path "*/aports/scripts/pppwn.tar.gz" -exec cp {} "$tmp"/etc/pppwn.tar.gz \;

makefile root:root 0644 "$tmp"/etc/hostname <<EOF
$HOSTNAME
EOF

mkdir -p "$tmp"/etc/network
makefile root:root 0644 "$tmp"/etc/network/interfaces <<EOF
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
EOF

makefile root:root 0644 "$tmp"/etc/apk/world <<EOF
alpine-base
busybox
openrc
bash
agetty
EOF

# Configure /etc/inittab for auto-login
mkdir -p "$tmp/etc"
makefile root:root 0755 "$tmp"/etc/inittab <<EOF
# /etc/inittab

::sysinit:/sbin/openrc sysinit
::sysinit:/sbin/openrc boot
::wait:/sbin/openrc default

tty1::respawn:/sbin/agetty 38400 tty1 --autologin root --noclear
tty2::respawn:/sbin/getty 38400 tty2

::shutdown:/sbin/openrc shutdown

ttyS0::respawn:/sbin/getty -L 0 ttyS0 vt100
EOF

makefile root:root 0644 "$tmp"/etc/profile.d/motd.sh <<EOF
#!/bin/bash
clear
echo -e "\033[1;34m▗▄▄▖ \033[1;36m▗▄▄▖ \033[1;34m▗▄▄▖ \033[1;37m▗▖ \033[1;37m▗▖\033[1;34m▗▖  \033[1;36m▗▖▗▖   \033[1;34m▗▄▄▄▖\033[1;37m▗▖  \033[1;34m▗▖\033[1;37m▗▄▄▄▖\033[0m"
echo -e "\033[1;34m▐▌ ▐▌\033[1;36m▐▌ ▐▌\033[1;34m▐▌ ▐▌\033[1;37m▐▌ ▐▌\033[1;36m▐▛▚▖\033[1;34m▐▌\033[1;37m▐▌     \033[1;34m█  \033[1;37m▐▌  \033[1;34m▐▌\033[1;37m▐▌   \033[0m"
echo -e "\033[1;34m▐▛▀▘ \033[1;36m▐▛▀▘ \033[1;34m▐▛▀▘ \033[1;37m▐▌ ▐▌\033[1;36m▐▌ ▝▜▌\033[1;37m▐▌     \033[1;34m█  \033[1;37m▐▌  \033[1;34m▐▛▀▀▘\033[0m"
echo -e "\033[1;34m▐▌   \033[1;36m▐▌   \033[1;34m▐▌   \033[1;37m▐▙█▟▌\033[1;36m▐▌  ▐▌\033[1;34m▐▙▄▄▖\033[1;37m▗▄█▄▖ \033[1;36m▝▚▞▘ \033[1;34m▐▙▄▄▖\033[0m"

echo
echo -e "\033[1;37mWelcome to \033[1;34mPPPwnLive\033[1;37m!\033[0m Please make sure to have your Ethernet cable plugged in and connected to the PlayStation 4."
echo
echo -e "\033[1;31mCredits:\033[0m"
echo -e "- \033[1;34mxfangfang\033[0m (\033[4mhttps://github.com/xfangfang/PPPwn_cpp\033[0m) for developing the C++ version of PPPwn"
echo -e "- \033[1;34mTheFloW\033[0m (\033[4mhttps://github.com/TheOfficialFloW/PPPwn\033[0m) for the original discovery and creation of PPPwn"
EOF

makefile root:root 0755 "$tmp"/etc/setup.sh <<EOF
#!/bin/sh

tar -xzf /etc/pppwn.tar.gz -C /root/
chmod +x /root/pppwnlive/pppwn

# Find the first available ethernet interface
ETH_IF=\$(ip -o link show | awk -F': ' '\$2 ~ /^eth|^en/ {print \$2; exit}')

# Enable the ethernet interface
ip link set dev \$ETH_IF up

if [ -n "\$ETH_IF" ]; then
    # Run pppwn command with the detected interface
    cd /root/pppwnlive
    while true; do
        ./pppwn -i "\$ETH_IF" --fw 1100 --stage1 stage1.bin --stage2 stage2.bin -a
        echo "PPPwn finished execution. Shutting down..."
        sleep 3
        poweroff
    done
else
    echo "No ethernet interface found. Please check your connection."
    echo "Press any key to shutdown..."
    read -n 1 -s
    poweroff
fi
EOF

# Use /root/.profile to automatically run /etc/setup.sh
makefile root:root 0644 "$tmp"/etc/.profile <<EOF
/etc/setup.sh
EOF

# WAR: Create an OpenRC service to move the profile
makefile root:root 0755 "$tmp"/etc/init.d/move-profile <<EOF
#!/sbin/openrc-run

description="Move /etc/.profile to /root/.profile"

depend() {
    need localmount
    before local
}

start() {
    ebegin "Moving /etc/.profile to /root/.profile"
    mv /etc/.profile /root/.profile 2>/dev/null
    eend $?
}
EOF

# Enable necessary services for networking
rc_add devfs sysinit
rc_add dmesg sysinit
rc_add mdev sysinit
rc_add hwdrivers sysinit
rc_add modloop sysinit

rc_add hwclock boot
rc_add modules boot
rc_add sysctl boot
rc_add hostname boot
rc_add bootmisc boot
rc_add syslog boot
rc_add move-profile boot

rc_add mount-ro shutdown
rc_add killprocs shutdown
rc_add savecache shutdown
tar -c -C "$tmp" etc | gzip -9n > $HOSTNAME.apkovl.tar.gz