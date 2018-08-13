################################################################################
#
# kubernetes
#
################################################################################

KUBERNETES_VERSION = v1.11.1
KUBERNETES_SITE = $(call github,kubernetes,kubernetes,$(KUBERNETES_VERSION))
KUBERNETES_LICENSE = Apache-2.0
KUBERNETES_LICENSE_FILES = LICENSE

KUBERNETES_SRC_SUBDIR = k8s.io/kubernetes

KUBERNETES_BUILD_TARGETS_bootstap = \
	cmd/kubelet \
	cmd/kubeadm \
	cmd/kubectl

KUBERNETES_BUILD_TARGETS_server = \
	cmd/kube-proxy \
	cmd/kube-apiserver \
	cmd/kube-controller-manager \
	cmd/cloud-controller-manager \
	cmd/kubelet \
	cmd/kubeadm \
	cmd/hyperkube \
	cmd/kube-scheduler \
	vendor/k8s.io/kube-aggregator \
	vendor/k8s.io/apiextensions-apiserver \
	cluster/gce/gci/mounter

KUBERNETES_BUILD_TARGETS_node = \
	cmd/kube-proxy \
	cmd/kubelet \
	cmd/kubeadm

KUBERNETES_BUILD_TARGETS_client = \
	cmd/kubectl

ifeq ($(BR2_PACKAGE_KUBERNETES_BOOTSTRAP),y)
_KUBERNETES_BUILD_TARGETS += $(KUBERNETES_BUILD_TARGETS_bootstrap)
endif

ifeq ($(BR2_PACKAGE_KUBERNETES_SERVER),y)
_KUBERNETES_BUILD_TARGETS += $(KUBERNETES_BUILD_TARGETS_server)
endif

ifeq ($(BR2_PACKAGE_KUBERNETES_NODE),y)
_KUBERNETES_BUILD_TARGETS += $(KUBERNETES_BUILD_TARGETS_node)
endif

ifeq ($(BR2_PACKAGE_KUBERNETES_CLIENT),y)
_KUBERNETES_BUILD_TARGETS += $(KUBERNETES_BUILD_TARGETS_client)
endif

# Remove the duplicates from selecting multiple build options
KUBERNETES_BUILD_TARGETS = $(sort $(_KUBERNETES_BUILD_TARGETS))

# Build targets that should be build with CGO_ENABLED=0
KUBERNETES_BUILD_TARGET_CGO_ENABLED_cmd/kube-proxy = 0
KUBERNETES_BUILD_TARGET_CGO_ENABLED_cmd/kube-apiserver = 0
KUBERNETES_BUILD_TARGET_CGO_ENABLED_cmd/kube-controller-manager = 0
KUBERNETES_BUILD_TARGET_CGO_ENABLED_cmd/cloud-controller-manager = 0
KUBERNETES_BUILD_TARGET_CGO_ENABLED_cmd/kube-scheduler = 0
KUBERNETES_BUILD_TARGET_CGO_ENABLED_vendor/k8s.io/kube-aggregator = 0
KUBERNETES_BUILD_TARGET_CGO_ENABLED_cmd/kubeadm = 0
KUBERNETES_BUILD_TARGET_CGO_ENABLED_cmd/kubectl = 0

KUBERNETES_LDFLAGS = $(shell bash -c "cd $(KUBERNETES_SRC_PATH) && source hack/lib/init.sh && kube::version::ldflags")

# Generate required files for the build. Ultimately uses the go compiler in
# $(BR_PATH) to build host binaries to generate the necessary files.
define KUBERNETES_PRE_BUILD_CMD
	PATH=$(BR_PATH) $(MAKE) -C $(KUBERNETES_SRC_PATH) generated_files
endef
KUBERNETES_PRE_BUILD_HOOKS += KUBERNETES_PRE_BUILD_CMD

KUBERNETES_INSTALL_BINS = $(notdir $(KUBERNETES_BUILD_TARGETS))

$(eval $(golang-package))
