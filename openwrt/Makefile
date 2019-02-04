#
# Builds Lede (Openwrt) images for Netgear 3700v2, 3800, & 3800ch used at Scale
# Assumes all dependency tools are already installed
#

BUILD_DIR = build
BUILD_SECRETS = ../facts/secrets/openwrt.yaml

# bins
GOMPLATE := $(shell command -v gomplate 2> /dev/null)
CURL := $(shell command -v curl 2> /dev/null)

LEDE_VER = 8c6f00ef4f17999c5110166764773e40b9a934de
IMAGEBUILDER = source-$(LEDE_VER)
TAR_EXT = .tar.gz

TMPL_SRC_DIR = files
TMPL_OUT_DIR = $(BUILD_DIR)/$(IMAGEBUILDER)/files

ifndef CURL
  $(error "curl is not available please install it")
endif

PHONY: download-image extract templates clean clean-templates

download-image: $(BUILD_DIR)/$(LEDE_VER)$(TAR_EXT)

extract: $(BUILD_DIR)/$(IMAGEBUILDER)

$(BUILD_DIR)/$(LEDE_VER)$(TAR_EXT): | $(BUILD_DIR)
	curl -L -o $(BUILD_DIR)/$(LEDE_VER)$(TAR_EXT) https://github.com/lede-project/source/archive/$(LEDE_VER)$(TAR_EXT)

$(BUILD_DIR)/$(IMAGEBUILDER): $(BUILD_DIR)/$(LEDE_VER)$(TAR_EXT)
	@cd $(BUILD_DIR) && tar -zxmf  $(LEDE_VER)$(TAR_EXT)

$(BUILD_DIR)/$(IMAGEBUILDER)/.config: extract
	@cd $(BUILD_DIR)/$(IMAGEBUILDER) \
	  && ./scripts/feeds update -a \
	  && ./scripts/feeds install -a	\
	  && cp ../../diffconfig .config \
	  && make defconfig

build-img: $(BUILD_DIR)/$(IMAGEBUILDER)/.config
	@cd $(BUILD_DIR)/$(IMAGEBUILDER) && $(MAKE) download && $(MAKE) V=s -j 4

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

clean:
	rm -rf $(BUILD_DIR)

clean-templates:
	rm -rf $(BUILD_DIR)/$(IMAGEBUILDER)/files

templates: $(TMPL_OUT_DIR)

$(TMPL_OUT_DIR): $(TMPL_SRC_DIR) $(BUILD_SECRETS) | $(BUILD_DIR)/$(IMAGEBUILDER)
ifndef GOMPLATE
  $(error "gomplate is not available please install it")
endif
	$(GOMPLATE) -d openwrt=$(BUILD_SECRETS) --input-dir=$(TMPL_SRC_DIR) --output-dir=$(TMPL_OUT_DIR)
	# TODO: should do this automatically for .sh file types
	chmod 750 $(TMPL_OUT_DIR)/root/bin/wifi-details.sh
	chmod 755 $(TMPL_OUT_DIR)/root
	chmod 750 $(TMPL_OUT_DIR)/root/.ssh
	touch $(TMPL_OUT_DIR)
