ifeq ($(origin VERSION), undefined)
# avoid ?= lazily evaluating version.sh (and thus rerunning the shell command several times)
VERSION := $(shell ./version.sh)
endif

TELE ?= $(shell which tele)
GRAVITY ?= $(shell which gravity)
GRAVITY_VERSION ?= 8.0.10
DOCKER_REPOSITORY_PREFIX ?= "172.28.128.101:30050"

REPOSITORY := gravitational.io
NAME := cluster-ssl-app
OPS_URL ?=
# gravity uses `/var/lib/gravity` directory if state-dir is empty
STATEDIR ?= state

EXTRA_GRAVITY_OPTIONS ?=
# add state directory to the commands if STATEDIR variable not empty
ifneq ($(STATEDIR),)
	EXTRA_GRAVITY_OPTIONS +=  --state-dir=$(STATEDIR)
endif

CONTAINERS := cluster-ssl-hook:$(VERSION)

IMPORT_IMAGE_FLAGS := --set-image=cluster-ssl-hook:$(VERSION)

FILE_LIST := $(shell ls -1A)
WHITELISTED_RESOURCE_NAMES := resources

IMPORT_OPTIONS := --vendor \
		--ops-url=$(OPS_URL) \
		--repository=$(REPOSITORY) \
		--name=$(NAME) \
		--version=$(VERSION) \
		--glob=**/*.yaml \
		$(foreach resource, $(filter-out $(WHITELISTED_RESOURCE_NAMES), $(FILE_LIST)), --exclude="$(resource)") \
		$(IMPORT_IMAGE_FLAGS)

BUILD_DIR := build
BINARIES_DIR := bin
TARBALL := $(BUILD_DIR)/application.tar
UNAME := $(shell uname | tr A-Z a-z)

$(STATEDIR):
	mkdir -p $(STATEDIR)

.PHONY: all
all: clean images

.PHONY: what-version
what-version:
	@echo $(VERSION)

.PHONY: images
images:
	cd $(PWD)/images &&	$(MAKE) VERSION=$(VERSION) && cd $(PWD)

.PHONY: docker-push
docker-push:
	docker tag cluster-ssl-hook:$(VERSION) $(DOCKER_REPOSITORY_PREFIX)/cluster-ssl-hook:$(VERSION)
	docker push $(DOCKER_REPOSITORY_PREFIX)/cluster-ssl-hook:$(VERSION)

.PHONY: helm-install
helm-install:
	helm --kubeconfig ~/go/src/github.com/mulesoft/rke2-playground/ansible/kubeconfig.yaml install cluster-ssl resources/chart \
		--values resources/custom-values.yaml --set "image.tag=$(VERSION)" --set "image.repository=$(DOCKER_REPOSITORY_PREFIX)/cluster-ssl-hook"

.PHONY: helm-uninstall
helm-uninstall:
	helm --kubeconfig ~/go/src/github.com/mulesoft/rke2-playground/ansible/kubeconfig.yaml uninstall cluster-ssl

.PHONY: build-app
build-app: images

.PHONY: import
import: images | $(STATEDIR)
	-$(GRAVITY) app delete --ops-url=$(OPS_URL) $(REPOSITORY)/$(NAME):$(VERSION) --force $(EXTRA_GRAVITY_OPTIONS)
	$(GRAVITY) app import $(IMPORT_OPTIONS) $(EXTRA_GRAVITY_OPTIONS) .

.PHONY: export
export: $(TARBALL)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(TARBALL): import | $(BUILD_DIR)
	$(GRAVITY) package export --ops-url=$(OPS_URL) $(REPOSITORY)/$(NAME):$(VERSION) $(TARBALL) $(EXTRA_GRAVITY_OPTIONS)

$(BINARIES_DIR):
	mkdir -p $(BINARIES_DIR)

.PHONY: download-binaries
download-binaries: $(BINARIES_DIR)
	aws s3 cp --only-show-errors s3://gravity-installers/gravity/release/$(GRAVITY_VERSION)/$(UNAME)-amd64/tele $(BINARIES_DIR)/tele
	aws s3 cp --only-show-errors s3://gravity-installers/gravity/release/$(GRAVITY_VERSION)/$(UNAME)-amd64/gravity $(BINARIES_DIR)/gravity
	chmod +x $(BINARIES_DIR)/gravity $(BINARIES_DIR)/tele

.PHONY: clean
clean: clean-state-dir
	rm -rf $(BUILD_DIR)

clean-state-dir:
	-rm -rf $(STATEDIR)
