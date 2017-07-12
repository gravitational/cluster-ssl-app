VERSION ?= latest

HOOK_TAG := cluster-ssl-hook:$(VERSION)

.PHONY: all
all: images

.PHONY: images
images: hook
	docker tag $(HOOK_TAG) cluster-ssl-hook:latest

HOOK_BINS := hook/bin
$(HOOK_BINS):
	mkdir -p $(HOOK_BINS)
	wget https://pkg.cfssl.org/R1.2/cfssl_linux-amd64 -O hook/bin/cfssl
	wget https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64 -O hook/bin/cfssljson

.PHONY: hook
hook: $(HOOK_BINS)
	docker build --pull -t $(HOOK_TAG) $(PWD)/hook

.PHONY: clean
clean:
	-rm -rf $(HOOK_BINS)
