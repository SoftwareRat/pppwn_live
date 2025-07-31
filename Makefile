# PPPwn Live ISO Makefile
# Buildroot-based build system

# Configuration
BUILDROOT_VERSION = 2025.05
BUILDROOT_URL = https://github.com/buildroot/buildroot.git
BUILDROOT_DIR = buildroot
BR2_EXTERNAL = $(PWD)/br2-external
DEFCONFIG = pppwn_defconfig

# Default target
.PHONY: all
all: iso

# Help target
.PHONY: help
help:
	@echo "PPPwn Live ISO Build System"
	@echo ""
	@echo "Available targets:"
	@echo "  help        - Show this help message"
	@echo "  setup       - Clone Buildroot and set up build environment"
	@echo "  config      - Load PPPwn defconfig"
	@echo "  menuconfig  - Open Buildroot configuration menu"
	@echo "  build       - Build the system"
	@echo "  iso         - Build the complete ISO image"
	@echo "  clean       - Clean build artifacts"
	@echo "  distclean   - Clean everything including Buildroot"
	@echo ""
	@echo "Build process:"
	@echo "  1. make setup    # Clone Buildroot (first time only)"
	@echo "  2. make config   # Load configuration"
	@echo "  3. make iso      # Build ISO image"

# Setup Buildroot
.PHONY: setup
setup:
	@if [ ! -d "$(BUILDROOT_DIR)" ]; then \
		echo "Cloning Buildroot $(BUILDROOT_VERSION)..."; \
		git clone --branch $(BUILDROOT_VERSION) --depth 1 $(BUILDROOT_URL) $(BUILDROOT_DIR); \
	else \
		echo "Buildroot already exists, updating..."; \
		cd $(BUILDROOT_DIR) && git fetch && git checkout $(BUILDROOT_VERSION) && git pull; \
	fi

# Load defconfig
.PHONY: config
config: setup
	@echo "Loading PPPwn defconfig..."
	cd $(BUILDROOT_DIR) && make BR2_EXTERNAL=$(BR2_EXTERNAL) $(DEFCONFIG)

# Open menuconfig
.PHONY: menuconfig
menuconfig: config
	cd $(BUILDROOT_DIR) && make BR2_EXTERNAL=$(BR2_EXTERNAL) menuconfig

# Build the system
.PHONY: build
build: config
	@echo "Building PPPwn Live ISO system..."
	cd $(BUILDROOT_DIR) && make BR2_EXTERNAL=$(BR2_EXTERNAL)

# Build ISO (alias for build)
.PHONY: iso
iso: build
	@echo "PPPwn Live ISO build completed!"
	@if [ -f "$(BUILDROOT_DIR)/output/images/rootfs.iso9660" ]; then \
		echo "ISO image available at: $(BUILDROOT_DIR)/output/images/rootfs.iso9660"; \
		echo "Symlink available at: $(BUILDROOT_DIR)/output/images/pppwn_live.iso"; \
	else \
		echo "Error: ISO image not found!"; \
		exit 1; \
	fi

# Clean build artifacts
.PHONY: clean
clean:
	@if [ -d "$(BUILDROOT_DIR)" ]; then \
		echo "Cleaning build artifacts..."; \
		cd $(BUILDROOT_DIR) && make clean; \
	fi

# Clean everything
.PHONY: distclean
distclean:
	@echo "Cleaning everything..."
	rm -rf $(BUILDROOT_DIR)

# Save current config
.PHONY: saveconfig
saveconfig:
	@if [ -d "$(BUILDROOT_DIR)" ]; then \
		echo "Saving current config to configs/$(DEFCONFIG)..."; \
		cd $(BUILDROOT_DIR) && make BR2_EXTERNAL=$(BR2_EXTERNAL) savedefconfig; \
		cp defconfig ../configs/$(DEFCONFIG); \
	fi

# Show build info
.PHONY: info
info:
	@echo "PPPwn Live ISO Build Information"
	@echo "================================"
	@echo "Buildroot Version: $(BUILDROOT_VERSION)"
	@echo "Buildroot URL: $(BUILDROOT_URL)"
	@echo "BR2_EXTERNAL: $(BR2_EXTERNAL)"
	@echo "Defconfig: $(DEFCONFIG)"
	@echo ""
	@if [ -d "$(BUILDROOT_DIR)" ]; then \
		echo "Buildroot Status: Available"; \
		if [ -f "$(BUILDROOT_DIR)/.config" ]; then \
			echo "Configuration: Loaded"; \
		else \
			echo "Configuration: Not loaded (run 'make config')"; \
		fi; \
		if [ -f "$(BUILDROOT_DIR)/output/images/rootfs.iso9660" ]; then \
			echo "ISO Status: Built"; \
			echo "ISO Size: $$(du -h $(BUILDROOT_DIR)/output/images/rootfs.iso9660 | cut -f1)"; \
		else \
			echo "ISO Status: Not built"; \
		fi; \
	else \
		echo "Buildroot Status: Not available (run 'make setup')"; \
	fi