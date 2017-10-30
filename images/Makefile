VERSION ?= latest

HOOK_TAG := cluster-ssl-hook:$(VERSION)

.PHONY: all
all: images

.PHONY: images
images: hook
	docker tag $(HOOK_TAG) cluster-ssl-hook:latest

.PHONY: hook
hook:
	docker build --pull -t $(HOOK_TAG) $(PWD)/hook
