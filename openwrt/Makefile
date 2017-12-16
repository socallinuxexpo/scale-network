#
# Builds Lede (Openwrt) images for Netgear 3700v2, 3800, & 3800ch used at Scale
# Assumes all dependency tools are already installed
#

BUILD_DIR = build
DEFAULT_PACKAGES = -dnsmasq -firewall -ip6tables -iptables -odhcp6c -odhcpd-ipv6only -odhcpd -ppp -ppp-mod-pppoe kmod-usb-serial kmod-usb-serial-ftdi kmod-usb-serial-pl2303
BUILD_3700_FLAGS = PROFILE=wndr3700v2 PACKAGES="$(DEFAULT_PACKAGES)"
BUILD_3800_FLAGS = PROFILE=wndr3800 PACKAGES="$(DEFAULT_PACKAGES)"
BUILD_3800CH_FLAGS = PROFILE=wndr3800ch PACKAGES="$(DEFAULT_PACKAGES)"

LEDE_VER = 17.01.4
IMAGEBUILDER = lede-imagebuilder-$(LEDE_VER)-ar71xx-generic.Linux-x86_64
TAR_EXT = .tar.xz

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
