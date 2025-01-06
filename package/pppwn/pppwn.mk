################################################################################
#
# pppwn
#
################################################################################

PPPWN_VERSION = latest
PPPWN_SITE_METHOD = local
PPPWN_SITE = $(BR2_EXTERNAL_PPPWN_LIVE_PATH)/package/pppwn/binaries
PPPWN_SOURCE = $(PPPWN_BINARY_ZIP)
PPPWN_LICENSE = GPL-3.0
PPPWN_LICENSE_FILES = LICENSE
PPPWN_DEPENDENCIES = host-jq

# Define architecture-specific zip file
ifeq ($(BR2_x86_64),y)
PPPWN_BINARY_ZIP = x86_64-linux-musl.zip
else ifeq ($(BR2_aarch64),y)
PPPWN_BINARY_ZIP = aarch64-linux-musl.zip
endif

define PPPWN_EXTRACT_CMDS
    # Extract PPPwn binary (two-step extraction: zip -> tar.gz -> binary)
    echo "Contents of build directory before extraction:"
    ls -la $(@D)
    
    echo "Extracting $(PPPWN_BINARY_ZIP)..."
    unzip -o -d $(@D) $(@D)/$(PPPWN_BINARY_ZIP) || exit 1
    
    echo "Contents after zip extraction:"
    ls -la $(@D)
    
    echo "Extracting tar.gz..."
    cd $(@D) && tar xvf pppwn.tar.gz || exit 1
    
    echo "Contents after tar extraction:"
    ls -la $(@D)
    find $(@D) -name pppwn -type f
    
    # Download stage1.bin
    wget -O $(@D)/stage1.bin \
        "https://github.com/B-Dem/PPPwnUI/raw/main/PPPwn/goldhen/1100/stage1.bin" || exit 1
    
    # Download and extract stage2.bin
    curl -L -o $(@D)/GoldHEN.7z \
        "$$(curl -s https://api.github.com/repos/GoldHEN/GoldHEN/releases | $(HOST_DIR)/bin/jq -r '.[0].assets[0].browser_download_url')" || exit 1
    cd $(@D) && 7z e GoldHEN.7z pppnw_stage2/stage2_v*.7z -r -aoa || exit 1
    cd $(@D) && 7z e stage2_v*.7z stage2_11.00.bin -r -aoa || exit 1
    cd $(@D) && mv stage2_11.00.bin stage2.bin
    
    # Clean up temporary files
    cd $(@D) && rm -f GoldHEN.7z stage2_v*.7z pppwn.tar.gz $(PPPWN_BINARY_ZIP)
    
    echo "Final contents of build directory:"
    ls -la $(@D)
endef

define PPPWN_INSTALL_TARGET_CMDS
    echo "Contents of build directory during install:"
    ls -la $(@D)
    find $(@D) -name pppwn -type f
    
    # Install binary with execute permissions
    $(INSTALL) -D -m 0755 $(@D)/pppwn $(TARGET_DIR)/usr/bin/pppwn
    
    # Create and populate data directory
    $(INSTALL) -d $(TARGET_DIR)/usr/share/pppwn
    $(INSTALL) -m 0644 $(@D)/stage1.bin $(TARGET_DIR)/usr/share/pppwn/
    $(INSTALL) -m 0644 $(@D)/stage2.bin $(TARGET_DIR)/usr/share/pppwn/
endef

$(eval $(generic-package))