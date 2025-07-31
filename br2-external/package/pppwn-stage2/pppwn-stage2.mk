################################################################################
#
# pppwn-stage2
#
################################################################################

PPPWN_STAGE2_VERSION = master
PPPWN_STAGE2_SITE = https://github.com/TheOfficialFloW/PPPwn.git
PPPWN_STAGE2_SITE_METHOD = git
PPPWN_STAGE2_LICENSE = MIT
PPPWN_STAGE2_LICENSE_FILES = LICENSE

PPPWN_STAGE2_INSTALL_PATH = $(call qstrip,$(BR2_PACKAGE_PPPWN_STAGE2_INSTALL_PATH))

define PPPWN_STAGE2_INSTALL_TARGET_CMDS
	$(INSTALL) -d -m 0755 $(TARGET_DIR)$(PPPWN_STAGE2_INSTALL_PATH)
	if [ -d $(@D)/stage2 ]; then \
		cp -r $(@D)/stage2/* $(TARGET_DIR)$(PPPWN_STAGE2_INSTALL_PATH)/; \
	else \
		echo "Warning: stage2 directory not found in source"; \
	fi
endef

$(eval $(generic-package))