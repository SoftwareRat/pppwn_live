################################################################################
#
# pppwn-stage1
#
################################################################################

PPPWN_STAGE1_VERSION = master
PPPWN_STAGE1_SITE = https://github.com/TheOfficialFloW/PPPwn.git
PPPWN_STAGE1_SITE_METHOD = git
PPPWN_STAGE1_LICENSE = MIT
PPPWN_STAGE1_LICENSE_FILES = LICENSE

PPPWN_STAGE1_INSTALL_PATH = $(call qstrip,$(BR2_PACKAGE_PPPWN_STAGE1_INSTALL_PATH))

define PPPWN_STAGE1_INSTALL_TARGET_CMDS
	$(INSTALL) -d -m 0755 $(TARGET_DIR)$(PPPWN_STAGE1_INSTALL_PATH)
	if [ -d $(@D)/stage1 ]; then \
		cp -r $(@D)/stage1/* $(TARGET_DIR)$(PPPWN_STAGE1_INSTALL_PATH)/; \
	else \
		echo "Warning: stage1 directory not found in source"; \
	fi
endef

$(eval $(generic-package))