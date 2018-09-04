################################################################################
#
# etcd
#
################################################################################

ETCD_VERSION = v3.2.24
ETCD_SITE = $(call github,coreos,etcd,$(ETCD_VERSION))
ETCD_LICENSE = Apache-2.0
ETCD_LICENSE_FILES = LICENSE

ETCD_BUILD_TARGETS = cmd/etcd cmd/etcdctl
ETCD_CGO_ENABLED = 0
ETCD_GIT_SHA = $(shell git rev-parse --short HEAD || echo GitNotFound)
ETCD_LDFLAGS = -X $(ETCD_SRC_SUBDIR)/cmd/vendor/$(ETCD_SRC_SUBDIR)/version.GitSHA=$(ETCD_GIT_SHA)

$(eval $(golang-package))
