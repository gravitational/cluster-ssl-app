TELE ?= $(shell which tele)
GRAVITY ?= $(shell which gravity)
RUNTIME_VERSION ?= $(shell $(TELE) version | awk '/^[vV]ersion:/ {print $$2}')
VER ?= $(shell git describe --long --tags --always|awk -F'[.-]' '{print $$1 "." $$2 "." $$4}')-$(RUNTIME_VERSION)

REPOSITORY := gravitational.io
NAME := cluster-ssl-app
OPS_URL ?= https://opscenter.localhost.localdomain:33009
# gravity uses `/var/lib/gravity` directory if state-dir is empty
STATE_DIR ?=

EXTRA_GRAVITY_OPTIONS ?=

CONTAINERS := cluster-ssl-hook:$(VER)

IMPORT_IMAGE_FLAGS := --set-image=cluster-ssl-hook:$(VER)

FILE_LIST := $(shell ls -1A)
WHITELISTED_RESOURCE_NAMES := resources

IMPORT_OPTIONS := --vendor \
		--state-dir=$(STATE_DIR) \
		--ops-url=$(OPS_URL) \
		--insecure \
		--repository=$(REPOSITORY) \
		--name=$(NAME) \
		--version=$(VER) \
		--glob=**/*.yaml \
		$(foreach resource, $(filter-out $(WHITELISTED_RESOURCE_NAMES), $(FILE_LIST)), --exclude="$(resource)") \
		$(IMPORT_IMAGE_FLAGS)

BUILD_DIR := build
TARBALL := $(BUILD_DIR)/cluster-ssl-app.tar.gz

.PHONY: all
all: clean images

.PHONY: what-version
what-version:
	@echo $(VER)

.PHONY: images
images:
	cd images && $(MAKE) -f Makefile VERSION=$(VER)

.PHONY: import
import: images
	-$(GRAVITY) app delete --ops-url=$(OPS_URL) --state-dir=$(STATE_DIR) $(REPOSITORY)/$(NAME):$(VER) --force --insecure $(EXTRA_GRAVITY_OPTIONS)
	$(GRAVITY) app import $(IMPORT_OPTIONS) $(EXTRA_GRAVITY_OPTIONS) .

.PHONY: export
export: $(TARBALL)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(TARBALL): import $(BUILD_DIR)
	$(GRAVITY) package export $(REPOSITORY)/$(NAME):$(VER) $(TARBALL) $(EXTRA_GRAVITY_OPTIONS)

.PHONY: clean
clean:
	$(MAKE) -C images clean
