FROM alpine:latest

# Default firmware version
ARG FIRMWARE_VERSION=1100

# Install necessary dependencies and download PPPwn++
RUN apk add --no-cache bash wget curl unzip tar && \
    ARCH=$(uname -m) && \
    if [ "$ARCH" != "x86_64" ] && [ "$ARCH" != "aarch64" ] && [ "$ARCH" != "mipsel" ]; then \
        echo "Unsupported architecture: $ARCH" && exit 1; \
    fi && \
    echo "Downloading ${ARCH}-linux-musl.zip..." && \
    wget -q https://github.com/xfangfang/PPPwn_cpp/releases/latest/download/${ARCH}-linux-musl.zip && \
    if [ ! -f "${ARCH}-linux-musl.zip" ]; then \
        echo "Error: Failed to download ${ARCH}-linux-musl.zip"; exit 1; \
    fi && \
    unzip -p ${ARCH}-linux-musl.zip | tar -xzOf - pppwn > /opt/pppwn/pppwn && \
    rm ${ARCH}-linux-musl.zip && \
    chmod +x /opt/pppwn/pppwn

# Copy the startup script
COPY start.sh /opt/pppwn/start.sh
RUN chmod +x /opt/pppwn/start.sh

# Default command
CMD ["/opt/pppwn/start.sh"]