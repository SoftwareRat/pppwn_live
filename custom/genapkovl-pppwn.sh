#!/bin/sh
set -eu

# Hyper-Minimal PPPwn Live Environment Generator
HOSTNAME="PPPwnLive"

# Minimal, statically defined directories
DIRS=(
    "etc/runlevels/sysinit"
    "etc/runlevels/boot"
    "etc/network"
    "etc/init.d"
    "root/pppwnlive"
)

cleanup() {
    [ -n "${tmp:-}" ] && rm -rf "$tmp"
}
trap cleanup EXIT

mkfile() {
    local path="$1" owner="${2:-root:root}" perms="${3:-0644}"
    mkdir -p "$(dirname "$path")"
    cat > "$path"
    chown "$owner" "$path"
    chmod "$perms" "$path"
}

tmp="$(mktemp -d)"
cd "$tmp"

for dir in "${DIRS[@]}"; do
    mkdir -p "$tmp/$dir"
done

echo "$HOSTNAME" | mkfile "$tmp/etc/hostname"

mkfile "$tmp/etc/network/interfaces" <<EOF
auto lo
iface lo inet loopback
auto eth0
iface eth0 inet dhcp
EOF

mkfile "$tmp/etc/apk/world" <<EOF
alpine-base
busybox
openrc
EOF

mkfile "$tmp/etc/inittab" root:root 0755 <<EOF
::sysinit:/sbin/openrc sysinit
::sysinit:/sbin/openrc boot
::wait:/sbin/openrc default
tty1::respawn:/sbin/agetty -a root 38400 tty1
::shutdown:/sbin/openrc shutdown
EOF

mkfile "$tmp/etc/init.d/pppwn-launcher" root:root 0755 <<'EOF'
#!/sbin/openrc-run

description="Initialize PPPwn_cpp"

depend() {
    need net
    after network
}

start() {
    # Find first ethernet interface
    ETH_IF=$(ip -o link show | awk -F': ' '$2 ~ /^(eth|en)/ {print $2; exit}')

    if [ -z "$ETH_IF" ]; then
        eerror "No Ethernet interface found"
        return 1
    fi

    # Minimal PPPwn execution
    ebegin "Launching PPPwn on $ETH_IF"
    cd /root/pppwnlive
    ./pppwn -i "$ETH_IF" --fw 1100 \
             --stage1 stage1.bin \
             --stage2 stage2.bin \
             -a
    result=$?
    eend $result "PPPwn failed"

    # Automatic shutdown after exploit
    [ $result -eq 0 ] && poweroff
}
EOF

# Minimal Welcome Banner
mkfile "$tmp/etc/profile.d/welcome.sh" root:root 0755 <<'EOF'
#!/bin/sh
printf "\033[1;34mPPPwnLite\033[0m - Minimal PS4 Jailbreak Environment\n"
printf "Ethernet Required. Exploit Prepared.\n"
EOF

# Setup Extraction and Execution Script
mkfile "$tmp/etc/init.d/pppwn-setup" root:root 0755 <<'EOF'
#!/sbin/openrc-run

description="PPPwn Extraction Setup"

depend() {
    need localmount
}

start() {
    ebegin "Extracting PPPwn Payload"
    tar -xzf /etc/pppwn.tar.gz -C /root
    chmod -R 700 /root/pppwnlive
    eend $?
}
EOF

# Runlevel Configuration
ln -sf /etc/init.d/pppwn-setup "$tmp/etc/runlevels/boot/pppwn-setup"
ln -sf /etc/init.d/pppwn-launcher "$tmp/etc/runlevels/default/pppwn-launcher"

# Minimal Service Dependencies
SERVICES=(
    "devfs:sysinit"
    "dmesg:sysinit"
    "mdev:sysinit"
    "hwdrivers:sysinit"
    "hwclock:boot"
    "modules:boot"
    "sysctl:boot"
    "hostname:boot"
    "bootmisc:boot"
)

for service in "${SERVICES[@]}"; do
    IFS=: read -r name level <<< "$service"
    ln -sf "/etc/init.d/$name" "$tmp/etc/runlevels/$level/$name"
done

# Generate Compressed Overlay
if [ -d "$tmp" ] && [ -d "$tmp/etc" ]; then
  tar -c -C "$tmp" etc | gzip -9 > "$HOSTNAME.apkovl.tar.gz"
else
  echo "Error: Required directories do not exist" && exit 1
fi

# Output overlay for build system
mv "$HOSTNAME.apkovl.tar.gz" .
