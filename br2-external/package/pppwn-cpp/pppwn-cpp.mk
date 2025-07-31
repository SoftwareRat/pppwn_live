################################################################################
#
# pppwn-cpp
#
################################################################################

PPPWN_CPP_VERSION = main
PPPWN_CPP_SITE = https://github.com/xfangfang/PPPwn_cpp.git
PPPWN_CPP_SITE_METHOD = git
PPPWN_CPP_LICENSE = GPL-3.0
PPPWN_CPP_LICENSE_FILES = LICENSE
PPPWN_CPP_DEPENDENCIES = host-cmake libpcap

PPPWN_CPP_CONF_OPTS = \
	-DBUILD_TEST=OFF \
	-DUSE_SYSTEM_PCAPPLUSPLUS=OFF \
	-DUSE_SYSTEM_PCAP=ON

ifeq ($(BR2_PACKAGE_PPPWN_CPP_CLI),y)
PPPWN_CPP_CONF_OPTS += -DBUILD_CLI=ON
else
PPPWN_CPP_CONF_OPTS += -DBUILD_CLI=OFF
endif

define PPPWN_CPP_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/buildroot-build/pppwn $(TARGET_DIR)/usr/bin/pppwn
endef

$(eval $(cmake-package))