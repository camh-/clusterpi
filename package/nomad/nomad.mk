################################################################################
#
# nomad
#
################################################################################

NOMAD_VERSION = v0.7.1
NOMAD_SITE = $(call github,hashicorp,nomad,$(NOMAD_VERSION))
NOMAD_LICENSE = MPL-2.0
NOMAD_LICENSE_FILES = LICENSE

NOMAD_LDFLAGS = -X main.gitCommit=$(NOMAD_VERSION)

$(eval $(golang-package))
