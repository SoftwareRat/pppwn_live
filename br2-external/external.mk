# PPPwn Live ISO Buildroot external makefile

# Include package makefiles
include $(sort $(wildcard $(BR2_EXTERNAL_PPPWN_PATH)/package/*/*.mk))