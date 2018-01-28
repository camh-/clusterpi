################################################################################
#
# labelmount
#
################################################################################

LABELMOUNT_LICENSE = GPL-2.0+

define LABELMOUNT_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0644 \
		$(BR2_EXTERNAL_clusterpi_PATH)/package/labelmount/11-label-mount.rules \
		$(TARGET_DIR)/etc/udev/rules.d
	$(INSTALL) -D -m 0755 \
		$(BR2_EXTERNAL_clusterpi_PATH)/package/labelmount/labelmount \
		$(TARGET_DIR)/sbin
endef

$(eval $(generic-package))
