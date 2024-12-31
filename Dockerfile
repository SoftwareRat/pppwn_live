FROM ubuntu:22.04

# Set non-interactive frontend
ENV DEBIAN_FRONTEND=noninteractive

# Install build dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    wget \
    git \
    bc \
    bison \
    flex \
    libelf-dev \
    libssl-dev \
    cpio \
    rsync \
    python3 \
    unzip \
    xz-utils \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /build

# Copy build scripts
COPY scripts/build.sh /build/
COPY scripts/download_deps.sh /build/

# Make scripts executable
RUN chmod +x /build/*.sh

# Set entrypoint
ENTRYPOINT ["/build/build.sh"]
