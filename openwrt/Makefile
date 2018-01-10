#
# Builds Lede (Openwrt) images for Netgear 3700v2, 3800, & 3800ch used at Scale
# Assumes all dependency tools are already installed
#

BUILD_DIR = build
DEFAULT_PACKAGES = -dnsmasq -firewall -ip6tables -iptables -odhcp6c -odhcpd-ipv6only -odhcpd -ppp -ppp-mod-pppoe kmod-usb-serial kmod-usb-serial-ftdi kmod-usb-serial-pl2303
BUILD_3700_FLAGS = PROFILE=wndr3700v2 PACKAGES="$(DEFAULT_PACKAGES)"
BUILD_3800_FLAGS = PROFILE=wndr3800 PACKAGES="$(DEFAULT_PACKAGES)"
BUILD_3800CH_FLAGS = PROFILE=wndr3800ch PACKAGES="$(DEFAULT_PACKAGES)"
BUILD_SECRETS = ../facts/secrets/openwrt.yaml

# bins
GOMPLATE := $(shell command -v gomplate 2> /dev/null)
CURL := $(shell command -v curl 2> /dev/null)

LEDE_VER = 17.01.4
IMAGEBUILDER = lede-imagebuilder-$(LEDE_VER)-ar71xx-generic.Linux-x86_64
TAR_EXT = .tar.xz

TMPL_SRC_DIR = files
TMPL_OUT_DIR = $(BUILD_DIR)/$(IMAGEBUILDER)/files

ifndef CURL
  $(error "curl is not available please install it")
endif

PHONY: download-image extract template clean clean-templates

download-image: $(BUILD_DIR)/$(IMAGEBUILDER)$(TAR_EXT)

extract: $(BUILD_DIR)/$(IMAGEBUILDER)

$(BUILD_DIR)/$(IMAGEBUILDER)$(TAR_EXT): | $(BUILD_DIR)
	curl -o $(BUILD_DIR)/$(IMAGEBUILDER)$(TAR_EXT) https://downloads.lede-project.org/releases/$(LEDE_VER)/targets/ar71xx/generic/$(IMAGEBUILDER)$(TAR_EXT)

$(BUILD_DIR)/$(IMAGEBUILDER): $(BUILD_DIR)/$(IMAGEBUILDER)$(TAR_EXT)
	@cd $(BUILD_DIR) && tar -xJmf  $(IMAGEBUILDER)$(TAR_EXT)

build-3700: extract
	@cd $(BUILD_DIR)/$(IMAGEBUILDER) && $(MAKE) image $(BUILD_3700_FLAGS)

build-3800: extract
	@cd $(BUILD_DIR)/$(IMAGEBUILDER) && $(MAKE) image  $(BUILD_3800_FLAGS)

build-3800ch: extract
	@cd $(BUILD_DIR)/$(IMAGEBUILDER) && $(MAKE) image $(BUILD_3800CH_FLAGS)

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
	touch $(TMPL_OUT_DIR)
