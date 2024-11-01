#!/bin/sh
set -eu
set -o pipefail

# Hyper-Minimal PPPwn Live Environment Generator
readonly HOSTNAME="${HOSTNAME:-PPPwnLive}"
readonly UMASK=022

# Required commands
readonly REQUIRED_COMMANDS="tar gzip mktemp mkdir chown chmod ln"

# Minimal, statically defined directories
readonly DIRS=(
    "etc/runlevels/sysinit"
    "etc/runlevels/boot"
    "etc/network"
    "etc/init.d"
    "root/pppwnlive"
)

# Service dependencies with their runlevels
readonly SERVICES=(
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

# Error handling
die() {
    echo "ERROR: $*" >&2
    exit 1
}

# Cleanup function
cleanup() {
    if [ -n "${tmp:-}" ] && [ -d "$tmp" ]; then
        rm -rf "$tmp"
    fi
}

# Check for required commands
check_requirements() {
    local cmd
    for cmd in $REQUIRED_COMMANDS; do
        command -v "$cmd" >/dev/null 2>&1 || die "Required command '$cmd' not found"
    done
}

# Create file with proper permissions
mkfile() {
    local path="$1" owner="${2:-root:root}" perms="${3:-0644}"
    mkdir -p "$(dirname "$path")" || die "Failed to create directory for $path"
    cat > "$path" || die "Failed to create file $path"
    chown "$owner" "$path" || die "Failed to set owner for $path"
    chmod "$perms" "$path" || die "Failed to set permissions for $path"
}

main() {
    # Set secure umask
    umask "$UMASK"

    # Check requirements
    check_requirements

    # Create temporary directory
    tmp="$(mktemp -d)" || die "Failed to create temporary directory"
    trap cleanup EXIT
    cd "$tmp" || die "Failed to change to temporary directory"

    # Create directory structure
    local dir
    for dir in "${DIRS[@]}"; do
        mkdir -p "$tmp/$dir" || die "Failed to create directory $dir"
    done

    # Create base configuration files
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
    cd /root/pppwnlive || return 1
    ./pppwn -i "$ETH_IF" --fw 1100 \
            --stage1 stage1.bin \
            --stage2 stage2.bin \
            -a
    result=$?
    eend $result "PPPwn failed"

    # Automatic shutdown after exploit
    [ $result -eq 0 ] && poweroff
    return $result
}
EOF

    mkfile "$tmp/etc/profile.d/welcome.sh" root:root 0755 <<'EOF'
#!/bin/sh
printf '\033[1;34mPPPwnLite\033[0m - Minimal PS4 Jailbreak Environment\n'
printf 'Ethernet Required. Exploit Prepared.\n'
EOF

    mkfile "$tmp/etc/init.d/pppwn-setup" root:root 0755 <<'EOF'
#!/sbin/openrc-run

description="PPPwn Extraction Setup"

depend() {
    need localmount
}

start() {
    ebegin "Extracting PPPwn Payload"
    if [ ! -f /etc/pppwn.tar.gz ]; then
        eerror "PPPwn payload file not found"
        return 1
    fi
    tar -xzf /etc/pppwn.tar.gz -C /root || return 1
    chmod -R 700 /root/pppwnlive || return 1
    eend $?
}
EOF

    # Create runlevel directories
    mkdir -p "$tmp/etc/runlevels/default" || die "Failed to create runlevel directory"

    # Create service symlinks
    ln -sf /etc/init.d/pppwn-setup "$tmp/etc/runlevels/boot/pppwn-setup" || die "Failed to create service symlink"
    ln -sf /etc/init.d/pppwn-launcher "$tmp/etc/runlevels/default/pppwn-launcher" || die "Failed to create service symlink"

    # Setup service dependencies
    local service name level
    for service in "${SERVICES[@]}"; do
        IFS=: read -r name level <<< "$service"
        mkdir -p "$tmp/etc/runlevels/$level" || die "Failed to create runlevel directory for $service"
        ln -sf "/etc/init.d/$name" "$tmp/etc/runlevels/$level/$name" || die "Failed to create service symlink for $service"
    done

    # Create final archive
    tar -c -C "$tmp" etc | gzip -9n > "${HOSTNAME}.apkovl.tar.gz" || die "Failed to create final archive"
}

# Run main function
main "$@"
