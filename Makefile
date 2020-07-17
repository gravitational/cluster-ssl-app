export VERSION ?= $(shell ./version.sh)
TELE ?= $(shell which tele)
GRAVITY ?= $(shell which gravity)

REPOSITORY := gravitational.io
NAME := cluster-ssl-app
OPS_URL ?= https://opscenter.localhost.localdomain:33009
# gravity uses `/var/lib/gravity` directory if state-dir is empty
STATE_DIR ?=

EXTRA_GRAVITY_OPTIONS ?=

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
TARBALL := $(BUILD_DIR)/cluster-ssl-app.tar.gz

.PHONY: all
all: clean images

.PHONY: what-version
what-version:
	@echo $(VERSION)

.PHONY: images
images:
	cd $(PWD)/images &&	$(MAKE) VERSION=$(VERSION) && cd $(PWD)

.PHONY: build-app
build-app: images

.PHONY: import
import: images
	-$(GRAVITY) app delete --ops-url=$(OPS_URL) $(REPOSITORY)/$(NAME):$(VERSION) --force $(EXTRA_GRAVITY_OPTIONS)
	$(GRAVITY) app import $(IMPORT_OPTIONS) $(EXTRA_GRAVITY_OPTIONS) .

.PHONY: export
export: $(TARBALL)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(TARBALL): import $(BUILD_DIR)
	$(GRAVITY) package export $(REPOSITORY)/$(NAME):$(VERSION) $(TARBALL) $(EXTRA_GRAVITY_OPTIONS)

$(BINARIES_DIR):
	mkdir -p $(BINARIES_DIR)

.PHONY: download-binaries
download-binaries: $(BINARIES_DIR)
	for name in gravity tele; \
	do \
		curl https://get.gravitational.io/telekube/bin/$(GRAVITY_VERSION)/linux/x86_64/$$name -o $(BINARIES_DIR)/$$name; \
		chmod +x $(BINARIES_DIR)/$$name; \
	done

.PHONY: clean
clean:
	rm -rf $(TARBALL)