FROM alpine:latest

ARG FIRMWARE_VERSION=1100

RUN ARCH=$(uname -m) && \
    if [ "$ARCH" != "x86_64" ] && [ "$ARCH" != "aarch64" ] && [ "$ARCH" != "mipsel" ]; then \
        echo "Unsupported architecture: $ARCH" && exit 1; \
    fi && \
    apk add --no-cache bash wget curl unzip tar && \
    mkdir -p /opt/pppwn && cd /opt/pppwn && \
    wget -q https://github.com/xfangfang/PPPwn_cpp/releases/latest/download/${ARCH}-linux-musl.zip && \
    unzip -p ${ARCH}-linux-musl.zip | tar -xzOf - pppwn > pppwn && rm ${ARCH}-linux-musl.zip && \
    wget -q https://github.com/B-Dem/PPPwnUI/raw/main/PPPwn/goldhen/${FIRMWARE_VERSION}/stage{1,2}.bin && \
    chmod +x pppwn

CMD ["/opt/pppwn/pppwn", "-i", "eth0", "--fw", "${FIRMWARE_VERSION}", "--stage1", "/opt/pppwn/stage1.bin", "--stage2", "/opt/pppwn/stage2.bin", "-a"]