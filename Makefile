# PPPwn_live build system
SHELL := /bin/bash
.PHONY: all clean docker-build iso

# Configuration
ISO_NAME := pppwn-live
KERNEL_VERSION := 6.12.7
BUSYBOX_VERSION := 1.36.1
DOCKER_IMAGE := pppwn-builder
OUTPUT_DIR := output

# Docker configuration
DOCKER_BUILD_CMD := docker build -t $(DOCKER_IMAGE) .
DOCKER_RUN_CMD := docker run --rm -v $(PWD):/build $(DOCKER_IMAGE)

all: docker-build build-system iso

# Build Docker image
docker-build:
	$(DOCKER_BUILD_CMD)

# Build the system inside Docker
build-system:
	mkdir -p $(OUTPUT_DIR)
	$(DOCKER_RUN_CMD)

# Create bootable ISO
iso: build-system
	@echo "Creating bootable ISO..."
	./scripts/build-iso.sh $(ISO_NAME) $(OUTPUT_DIR)
	@echo "ISO created: $(OUTPUT_DIR)/$(ISO_NAME).iso"

# Clean build artifacts
clean:
	rm -rf $(OUTPUT_DIR)
	rm -f *.iso
	docker rmi $(DOCKER_IMAGE) || true

# Development targets
dev-shell:
	docker run --rm -it -v $(PWD):/build $(DOCKER_IMAGE) /bin/bash

# Check build dependencies
check-deps:
	@which docker >/dev/null 2>&1 || (echo "Error: Docker is required" && exit 1)
	@which make >/dev/null 2>&1 || (echo "Error: make is required" && exit 1)
	@which bash >/dev/null 2>&1 || (echo "Error: bash is required" && exit 1)

# Build for specific architectures
.PHONY: build-x86_64 build-aarch64
build-x86_64: ARCH=x86_64
build-x86_64: all

build-aarch64: ARCH=aarch64
build-aarch64: all