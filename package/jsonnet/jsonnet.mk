################################################################################
#
# jsonnet
#
################################################################################

JSONNET_VERSION = v0.11.2
JSONNET_SITE = $(call github,google,go-jsonnet,$(JSONNET_VERSION))
JSONNET_LICENSE = Apache-2.0
JSONNET_LICENSE_FILES = LICENSE

JSONNET_BUILD_TARGETS = jsonnet

define JSONNET_GO_GET
	cd $(@D)/$(JSONNET_WORKSPACE) && \
		GOPATH=$(@D)/$(JSONNET_WORKSPACE) \
		$(GO_BIN) get $(JSONNET_SRC_SUBDIR)/jsonnet
endef

JSONNET_PRE_BUILD_HOOKS += JSONNET_GO_GET

$(eval $(golang-package))
