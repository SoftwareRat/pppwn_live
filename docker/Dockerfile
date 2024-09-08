# Use Alpine Linux as the base image
FROM alpine:latest

# Set environment variables (adjust as needed)
ENV PPPWN_VERSION=latest

# Set firmware version and architecture as build arguments with default values
ARG FIRMWARE_VERSION=1100
ARG ARCH=x86_64

# Set environment variables from build arguments
ENV FIRMWARE_VERSION=${FIRMWARE_VERSION}
ENV ARCH=${ARCH}

# Install necessary dependencies
RUN apk update && apk add --no-cache \
    bash \
    busybox \
    openrc \
    wget \
    iproute2 \
    curl \
    unzip \
    tar

# Prepare PPPwn binaries and environment
RUN mkdir -p /opt/pppwn \
    && cd /opt/pppwn \
    && wget https://github.com/xfangfang/PPPwn_cpp/releases/${PPPWN_VERSION}/download/${ARCH}-linux-musl.zip \
    && unzip -p ${ARCH}-linux-musl.zip | tar -xzOf - pppwn > pppwn && rm ${ARCH}-linux-musl.zip \
    && wget https://github.com/B-Dem/PPPwnUI/raw/main/PPPwn/goldhen/${FIRMWARE_VERSION}/stage1.bin \
    && wget https://github.com/B-Dem/PPPwnUI/raw/main/PPPwn/goldhen/${FIRMWARE_VERSION}/stage2.bin

# Set up network
RUN echo "auto lo" > /etc/network/interfaces \
    && echo "iface lo inet loopback" >> /etc/network/interfaces \
    && echo "auto eth0" >> /etc/network/interfaces \
    && echo "iface eth0 inet dhcp" >> /etc/network/interfaces

# Enable networking service
RUN rc-update add networking boot

# Run PPPwn
CMD ["/opt/pppwn/pppwn", "-i", "eth0", "--fw", "1100", "--stage1", "/opt/pppwn/stage1.bin", "--stage2", "/opt/pppwn/stage2.bin", "-a"]