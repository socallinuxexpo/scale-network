#
# Builds Openwrt images for ar71xx & ipq806x targets used at Scale
# Assumes all dependency tools are already installed
#

include include/*.mk

# Export all variables by default
.EXPORT_ALL_VARIABLES:

SHELL = /usr/bin/env bash

# WNDR by default
TARGET ?= ar71xx

BUILD_DIR ?= build
# Set to configure -j (defaults to nproc)
JOBS ?= $(shell nproc)

BUILD_SECRETS ?= ../facts/secrets/$(TARGET)-openwrt-example.yaml
KEYPATH ?= ../facts/keys/

# bins
GOMPLATE := $(shell command -v gomplate 2> /dev/null)
CURL := $(shell command -v curl 2> /dev/null)

OPENWRT_VER ?= fb15cb4ce9559021d463b5cb3816d8a9eeb8f3f9
# If bumping opkg it needs to be a commit that exists in the fork
# https://github.com/sarcasticadmin/opkgs
OPENWRT_PKG_VERSION ?= 4e46ebd5b900c7d3a7478564cba69e8bea8a4d60

SHORT_VER = $(shell echo $(OPENWRT_VER) | cut -c 1-7)
IMAGEBUILDER = source-$(TARGET)-$(SHORT_VER)
TAR_EXT = .tar.gz

TMPL_SRC_DIR = files
TMPL_OUT_DIR = $(BUILD_DIR)/$(IMAGEBUILDER)/files

ifndef CURL
  $(error "curl is not available please install it")
endif

# TODO: Fix this after getting feedback from upstream opkgs
# https://github.com/openwrt/packages/issues/20184
define FEEDS_CONF_DEFAULT
src-git packages https://github.com/sarcasticadmin/opkgs.git^$(OPENWRT_PKG_VERSION)
endef

PHONY: download-image extract templates clean clean-templates

download-image: $(BUILD_DIR)/$(OPENWRT_VER)$(TAR_EXT)

extract: $(BUILD_DIR)/$(IMAGEBUILDER)

$(BUILD_DIR)/$(OPENWRT_VER)$(TAR_EXT): | $(BUILD_DIR)
	curl -L -o $(BUILD_DIR)/$(OPENWRT_VER)$(TAR_EXT) https://github.com/openwrt/openwrt/archive/$(OPENWRT_VER)$(TAR_EXT)

$(BUILD_DIR)/$(IMAGEBUILDER): $(BUILD_DIR)/$(OPENWRT_VER)$(TAR_EXT)
	@cd $(BUILD_DIR) && \
	  mkdir -p $(IMAGEBUILDER) && \
	  tar -zxmf  $(OPENWRT_VER)$(TAR_EXT) -C $(IMAGEBUILDER) --strip-components 1

$(BUILD_DIR)/$(IMAGEBUILDER)/feeds.conf.default: extract
	@cd $(BUILD_DIR)/$(IMAGEBUILDER) \
	  && echo "$$FEEDS_CONF_DEFAULT" > feeds.conf.default

feeds: $(BUILD_DIR)/$(IMAGEBUILDER)/feeds.conf.default

$(BUILD_DIR)/$(IMAGEBUILDER)/.config: feeds
	@cd $(BUILD_DIR)/$(IMAGEBUILDER) \
	  && ./scripts/feeds update -a \
	  && ./scripts/feeds install -a	\
	  && cat ../../configs/$(TARGET)-generic.config > .config \
	  && cat ../../configs/common.config >> .config \
	  && make defconfig

diffconfig:
	@cd $(BUILD_DIR)/$(IMAGEBUILDER) && ./scripts/diffconfig.sh > .diffconfig

commonconfig: diffconfig
	ifneq ($(TARGET), x86)
	  $(error "common config can only be generated from x86")
	endif
	cat ./$(BUILD_DIR)/$(IMAGEBUILDER)/.diffconfig | grep -v CONFIG_TARGET > ./configs/common.config

targetconfig: diffconfig
	comm -23 <(sort ./$(BUILD_DIR)/$(IMAGEBUILDER)/.diffconfig) <(sort ./configs/common.config) > ./configs/$(TARGET)-generic.config

config: $(BUILD_DIR)/$(IMAGEBUILDER)/.config

menuconfig:
	@cd $(BUILD_DIR)/$(IMAGEBUILDER) && $(MAKE) menuconfig

build-img: $(BUILD_DIR)/$(IMAGEBUILDER)/.config
	@cd $(BUILD_DIR)/$(IMAGEBUILDER) \
	  && echo SCALE_VER=$(shell git rev-parse HEAD) > $(TMPL_SRC_DIR)/etc/scale-release \
	  && echo OPENWRT_VER=$(OPENWRT_VER) >> $(TMPL_SRC_DIR)/etc/scale-release \
	  && $(MAKE) download \
	  && $(MAKE) V=s -j $(JOBS)

# Common way to package up the build artifacts due to the various limits of
# some CI tools
package:
	mkdir -p $(BUILD_DIR)/artifacts
	# TODO: Look into striping path to only be from targets/ onward
	tar zcvf $(BUILD_DIR)/artifacts/$(TARGET)-$(SHORT_VER)-artifacts.tar.gz \
	  -C $(BUILD_DIR)/$(IMAGEBUILDER)/bin/targets/*/generic ./

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

clean-all:
	rm -rf $(BUILD_DIR)

clean:
	rm -rf $(BUILD_DIR)/$(IMAGEBUILDER)

clean-config:
	rm -f ./$(BUILD_DIR)/$(IMAGEBUILDER)/.config
	rm -f ./$(BUILD_DIR)/$(IMAGEBUILDER)/.diffconfig

clean-templates:
	rm -rf $(BUILD_DIR)/$(IMAGEBUILDER)/files

templates: $(TMPL_OUT_DIR)

$(TMPL_OUT_DIR): $(TMPL_SRC_DIR) $(BUILD_SECRETS) | $(BUILD_DIR)/$(IMAGEBUILDER)
ifndef GOMPLATE
  $(error "gomplate is not available please install it")
endif
	$(GOMPLATE) -d openwrt=$(BUILD_SECRETS) -d keys_dir=$(KEYPATH) --input-dir=$(TMPL_SRC_DIR) --output-dir=$(TMPL_OUT_DIR)
	# TODO: should do this automatically for .sh file types
	chmod 750 $(TMPL_OUT_DIR)/root/bin/config-version.sh
	chmod 750 $(TMPL_OUT_DIR)/root/bin/wifi-details.sh
	chmod 750 $(TMPL_OUT_DIR)/root/bin/apinger-pop.sh
	chmod 755 $(TMPL_OUT_DIR)/root
	chmod 700 $(TMPL_OUT_DIR)/root/.ssh
	chmod 640 $(TMPL_OUT_DIR)/root/.ssh/authorized_keys
	@cd $(TMPL_OUT_DIR)/etc/config && ln -s network.0 network && ln -s wireless.0 wireless
	@cd $(TMPL_OUT_DIR)/etc && ln -s /tmp/resolv.conf.d/resolv.conf.auto resolv.conf
	touch $(TMPL_OUT_DIR)

bump:
	bash scripts/openwrt_bump.sh
