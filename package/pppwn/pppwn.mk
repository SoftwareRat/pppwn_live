################################################################################
#
# pppwn
#
################################################################################

PPPWN_VERSION = latest
PPPWN_SITE_METHOD = local
PPPWN_SITE = $(BR2_EXTERNAL_PPPWN_LIVE_PATH)/package/pppwn/binaries
PPPWN_LICENSE = GPL-3.0
PPPWN_LICENSE_FILES = LICENSE
PPPWN_DEPENDENCIES = host-jq host-wget host-curl host-p7zip

# Define architecture-specific zip file
ifeq ($(BR2_x86_64),y)
PPPWN_BINARY_ZIP = x86_64-linux-musl.zip
else ifeq ($(BR2_aarch64),y)
PPPWN_BINARY_ZIP = aarch64-linux-musl.zip
endif

define PPPWN_EXTRACT_CMDS
    # Extract PPPwn binary (two-step extraction: zip -> tar.gz -> binary)
    $(UNZIP) -o -d $(@D) $(PPPWN_SITE)/$(PPPWN_BINARY_ZIP)
    cd $(@D) && tar xf pppwn.tar.gz
    
    # Download stage1.bin
    $(HOST_DIR)/bin/wget -O $(@D)/stage1.bin \
        "https://github.com/B-Dem/PPPwnUI/raw/main/PPPwn/goldhen/1100/stage1.bin"
    
    # Download and extract stage2.bin
    $(HOST_DIR)/bin/curl -L -o $(@D)/GoldHEN.7z \
        "$$($(HOST_DIR)/bin/curl -s https://api.github.com/repos/GoldHEN/GoldHEN/releases | $(HOST_DIR)/bin/jq -r '.[0].assets[0].browser_download_url')"
    cd $(@D) && $(HOST_DIR)/bin/7z e GoldHEN.7z pppnw_stage2/stage2_v*.7z -r -aoa
    cd $(@D) && $(HOST_DIR)/bin/7z e stage2_v*.7z stage2_11.00.bin -r -aoa
    cd $(@D) && mv stage2_11.00.bin stage2.bin
    cd $(@D) && rm -f GoldHEN.7z stage2_v*.7z pppwn.tar.gz
endef

define PPPWN_INSTALL_TARGET_CMDS
    $(INSTALL) -D -m 0755 $(@D)/pppwn $(TARGET_DIR)/usr/bin/pppwn
    $(INSTALL) -d $(TARGET_DIR)/usr/share/pppwn
    $(INSTALL) -m 0644 $(@D)/stage1.bin $(TARGET_DIR)/usr/share/pppwn/
    $(INSTALL) -m 0644 $(@D)/stage2.bin $(TARGET_DIR)/usr/share/pppwn/
endef

$(eval $(generic-package))