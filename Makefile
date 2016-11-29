VER ?= $(shell git describe --long --tags --always|awk -F'[.-]' '{print $$1 "." $$2 "." $$4}')
REPOSITORY := gravitational.io
NAME := cluster-ssl-app
OPS_URL ?= https://opscenter.localhost.localdomain:33009

EXTRA_GRAVITY_OPTIONS ?=

CONTAINERS := cluster-ssl-hook:$(VER)

IMPORT_IMAGE_FLAGS := --set-image=cluster-ssl-hook:$(VER)

IMPORT_OPTIONS := --vendor \
		--ops-url=$(OPS_URL) \
		--insecure \
		--repository=$(REPOSITORY) \
		--name=$(NAME) \
		--version=$(VER) \
		--glob=**/*.yaml \
		--exclude="build" \
		--exclude="gravity.log" \
		--exclude="images" \
		--exclude="Makefile" \
		--exclude="tool" \
		--exclude=".git" \
		--registry-url=apiserver:5000 \
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
	-gravity app delete --ops-url=$(OPS_URL) $(REPOSITORY)/$(NAME):$(VER) --force --insecure $(EXTRA_GRAVITY_OPTIONS)
	gravity app import $(IMPORT_OPTIONS) $(EXTRA_GRAVITY_OPTIONS) .

.PHONY: export
export: $(TARBALL)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(TARBALL): import $(BUILD_DIR)
	gravity package export $(REPOSITORY)/$(NAME):$(VER) $(TARBALL) $(EXTRA_GRAVITY_OPTIONS)

.PHONY: clean
clean:
	$(MAKE) -C images clean
