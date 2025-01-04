#!/bin/bash
set -e

# Copy banner file
mkdir -p "${TARGET_DIR}/etc"
cp "${BR2_EXTERNAL_PPPWN_PATH}/board/pppwn/rootfs_overlay/etc/banner" "${TARGET_DIR}/etc/"

# Create startup script
cat > "${TARGET_DIR}/etc/init.d/S50pppwn" << "EOF"
#!/bin/sh

start() {
    cat /etc/banner

    # Wait for network interface to be up
    while ! ip link show | grep -q '^[0-9].*UP.*ethernet'; do
        sleep 1
    done
    
    IFACE=$(ip -br link show | awk '$2 == "UP" {print $1}' | head -n1)
    
    # Configure IPv6
    sysctl -w net.ipv6.conf.all.forwarding=1
    sysctl -w net.ipv6.conf.$IFACE.accept_ra=2
    
    # Start PPPwn
    /usr/bin/pppwn -i $IFACE --fw 1100 --stage1 /usr/share/pppwn/stage1.bin --stage2 /usr/share/pppwn/stage2.bin -a
    
    # Handle exit code
    EXIT_CODE=$?
    if [ $EXIT_CODE -ne 0 ]; then
        echo "An error has occurred +++ Error code: $EXIT_CODE"
        sleep 10
    fi
    
    # Shutdown system
    /sbin/poweroff
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

chmod +x "${TARGET_DIR}/etc/init.d/S50pppwn"