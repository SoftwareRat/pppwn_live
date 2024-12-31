#!/bin/sh
set -e

# Configure loopback interface
ip addr add 127.0.0.1/8 dev lo
ip link set lo up

# Configure ethernet interface
if command -v udhcpc >/dev/null 2>&1; then
    udhcpc -i eth0 -n -q
else
    ip addr add 192.168.1.2/24 dev eth0
    ip route add default via 192.168.1.1
fi

# Enable IP forwarding and promiscuous mode
echo 1 > /proc/sys/net/ipv4/ip_forward
ip link set eth0 promisc on

# Load PPP modules
modprobe ppp_generic ppp_async ppp_deflate 2>/dev/null || true

exit 0 