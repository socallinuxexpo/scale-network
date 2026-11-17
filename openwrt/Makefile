#
# Builds Openwrt images for targets used at Scale
# Assumes all dependency tools are already installed
#

include include/*.mk

# Export all variables by default
.EXPORT_ALL_VARIABLES:

SHELL = /usr/bin/env bash

# WNDR by default
TARGET ?= ath79

BUILD_DIR ?= build
# Set to configure -j (defaults to nproc)
JOBS ?= $(shell nproc)

BUILD_SECRETS ?= ../facts/aps/$(TARGET)-openwrt-example.yaml
KEYPATH ?= ../facts/keys/

# bins
GOMPLATE := $(shell command -v gomplate 2> /dev/null)
CURL := $(shell command -v curl 2> /dev/null)

OPENWRT_VER ?= 41a1874c700dc0bbf300b5a14abf3ebb90d99859
# If bumping opkg it needs to be a commit that exists in the fork
# https://github.com/sarcasticadmin/opkgs
OPENWRT_PKG_VERSION ?= 2db11f3ab40add40e91255e01049aed052b8c3a3

SHORT_VER = $(shell echo $(OPENWRT_VER) | cut -c 1-7)
IMAGEBUILDER = source-$(TARGET)-$(SHORT_VER)
TAR_EXT = .tar.gz

# SCALE local changes to the OpenWrt tree (applied once right after extract)
# and to feed checkouts (applied after `feeds update`, before `feeds install`).
# See source-patches/README.md
SOURCE_PATCHES_DIR = source-patches
# Feed patches live in $(SOURCE_PATCHES_DIR)/feeds/<feed>/*.patch
FEED_PATCHES := $(wildcard $(SOURCE_PATCHES_DIR)/feeds/*/*.patch)
PACKAGES_FEED_TAR = $(BUILD_DIR)/opkgs-$(OPENWRT_PKG_VERSION)$(TAR_EXT)
PACKAGES_FEED_CHECK = $(BUILD_DIR)/opkgs-$(OPENWRT_PKG_VERSION).check
# SOURCE_PATCH_MODE is the only switch that chooses apply vs try-without.
# It is never flipped automatically (a source-check flag does not start a
# trial build). Set it explicitly on the make command line, or via a
# workflow_dispatch input / GitLab pipeline variable (see the CI comments).
#   apply  (default) – apply every patch; run at most the cheap source
#                      check as an advisory hint; no extra builds.
#   check            – run only `make check-source-patches`; do not extract
#                      a build tree or build an image.
#   trial            – without-patch build. Honors SKIP_SOURCE_PATCHES; if
#                      that is empty, skips patches the source check flags.
#                      If nothing is flagged either, exits and asks you to
#                      set SKIP_SOURCE_PATCHES (e.g. all ids on a bump).
SOURCE_PATCH_MODE ?= apply
# Comma/space-separated patch ids to leave out (NNN, stem, filename, or a
# qualified feed id such as packages/001). Honored only when
# SOURCE_PATCH_MODE=trial. After changing it, re-extract OpenWrt-tree
# patches (`make clean`, or a different BUILD_DIR) and re-apply feed
# patches (`make clean-feeds`).
SKIP_SOURCE_PATCHES ?=

ifeq ($(filter $(SOURCE_PATCH_MODE),apply check trial),)
  $(error SOURCE_PATCH_MODE must be apply, check, or trial (got '$(SOURCE_PATCH_MODE)'))
endif

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

PHONY: download-image extract templates clean clean-templates clean-feeds check-source-patches

download-image: $(BUILD_DIR)/$(OPENWRT_VER)$(TAR_EXT) $(if $(FEED_PATCHES),$(PACKAGES_FEED_TAR))

ifeq ($(SOURCE_PATCH_MODE),check)
# check: source check only. A flagged result is a report, never a trial build.
extract templates build-img package config feeds menuconfig: check-source-patches
	@echo "SOURCE_PATCH_MODE=check: not building an image"
else
extract: $(BUILD_DIR)/$(IMAGEBUILDER)
endif

$(BUILD_DIR)/$(OPENWRT_VER)$(TAR_EXT): | $(BUILD_DIR)
	curl -L -o $(BUILD_DIR)/$(OPENWRT_VER)$(TAR_EXT) https://github.com/openwrt/openwrt/archive/$(OPENWRT_VER)$(TAR_EXT)

$(PACKAGES_FEED_TAR): | $(BUILD_DIR)
	curl -L -o $(PACKAGES_FEED_TAR) https://github.com/sarcasticadmin/opkgs/archive/$(OPENWRT_PKG_VERSION)$(TAR_EXT)

# Extract into a temporary dir and only rename it once the source patches
# applied, so a failed patch never leaves a half-patched tree behind.
# After changing OpenWrt-tree patches or SOURCE_PATCH_MODE/SKIP_SOURCE_PATCHES
# run `make clean` (or use a different BUILD_DIR) to re-extract. After
# changing only feed patches, `make clean-feeds` is enough.
$(BUILD_DIR)/$(IMAGEBUILDER): $(BUILD_DIR)/$(OPENWRT_VER)$(TAR_EXT) $(if $(FEED_PATCHES),$(PACKAGES_FEED_TAR))
	@[ ! -e $(BUILD_DIR)/$(IMAGEBUILDER) ] || \
	  { echo "$(BUILD_DIR)/$(IMAGEBUILDER) already exists, run 'make clean' to re-extract" >&2; exit 1; }
	@cd $(BUILD_DIR) && \
	  rm -rf $(IMAGEBUILDER).tmp && \
	  mkdir -p $(IMAGEBUILDER).tmp && \
	  tar -zxmf  $(OPENWRT_VER)$(TAR_EXT) -C $(IMAGEBUILDER).tmp --strip-components 1
	@if [ "$(SOURCE_PATCH_MODE)" = trial ]; then \
	  skip="$(SKIP_SOURCE_PATCHES)"; \
	  if [ -z "$$skip" ]; then \
	    echo "SOURCE_PATCH_MODE=trial: SKIP_SOURCE_PATCHES unset, asking the source check which patches are flagged"; \
	    mkdir -p $(BUILD_DIR)/$(IMAGEBUILDER).check; \
	    tar -zxmf $(BUILD_DIR)/$(OPENWRT_VER)$(TAR_EXT) -C $(BUILD_DIR)/$(IMAGEBUILDER).check --strip-components 1; \
	    feed_args=""; \
	    if [ -n "$(FEED_PATCHES)" ]; then \
	      rm -rf $(PACKAGES_FEED_CHECK); \
	      mkdir -p $(PACKAGES_FEED_CHECK); \
	      tar -zxmf $(PACKAGES_FEED_TAR) -C $(PACKAGES_FEED_CHECK) --strip-components 1; \
	      feed_args="--feed packages=$(PACKAGES_FEED_CHECK)"; \
	    fi; \
	    skip=`./scripts/check_source_patches.sh --flagged-ids $(BUILD_DIR)/$(IMAGEBUILDER).check $(SOURCE_PATCHES_DIR) $(CURDIR)/.. $$feed_args` || rc=$$?; \
	    rm -rf $(BUILD_DIR)/$(IMAGEBUILDER).check $(PACKAGES_FEED_CHECK); \
	    if [ "$${rc:-0}" = 1 ]; then exit 1; fi; \
	    if [ -z "$$skip" ]; then \
	      echo "SOURCE_PATCH_MODE=trial: no patches flagged and SKIP_SOURCE_PATCHES is empty." >&2; \
	      echo "Set SKIP_SOURCE_PATCHES explicitly (e.g. all ids after an OPENWRT_VER bump)." >&2; \
	      echo "A source check alone never starts a trial build." >&2; \
	      rm -rf $(BUILD_DIR)/$(IMAGEBUILDER).tmp; \
	      exit 1; \
	    fi; \
	  fi; \
	  echo "SOURCE_PATCH_MODE=trial: building with SKIP_SOURCE_PATCHES=$$skip"; \
	  printf '%s\n' "$$skip" > $(BUILD_DIR)/$(IMAGEBUILDER).skip-source-patches; \
	  SKIP_SOURCE_PATCHES="$$skip" ./scripts/apply_source_patches.sh $(BUILD_DIR)/$(IMAGEBUILDER).tmp $(SOURCE_PATCHES_DIR); \
	else \
	  if [ -n "$(SKIP_SOURCE_PATCHES)" ]; then \
	    echo "SOURCE_PATCH_MODE=apply: ignoring SKIP_SOURCE_PATCHES=$(SKIP_SOURCE_PATCHES) (use SOURCE_PATCH_MODE=trial to skip patches)"; \
	  fi; \
	  echo "SOURCE_PATCH_MODE=apply: applying all source patches"; \
	  : > $(BUILD_DIR)/$(IMAGEBUILDER).skip-source-patches; \
	  SKIP_SOURCE_PATCHES= ./scripts/apply_source_patches.sh $(BUILD_DIR)/$(IMAGEBUILDER).tmp $(SOURCE_PATCHES_DIR); \
	fi
	@mv $(BUILD_DIR)/$(IMAGEBUILDER).tmp $(BUILD_DIR)/$(IMAGEBUILDER)
	@if [ "$(SOURCE_PATCH_MODE)" = apply ]; then \
	  echo "SOURCE_PATCH_MODE=apply: advisory source check (will not start a trial build)"; \
	  $(MAKE) check-source-patches; rc=$$?; \
	  if [ $$rc -eq 2 ]; then \
	    echo "SOURCE_PATCH_MODE=apply: source check flagged one or more patches; report only. Set SOURCE_PATCH_MODE=trial explicitly to build without them."; \
	  elif [ $$rc -ne 0 ]; then \
	    exit $$rc; \
	  fi; \
	fi

# Cheap source-level advisory check (comments/whitespace ignored). Not the
# deciding verdict: see source-patches/README.md. Uses a pristine unpack of
# OPENWRT_VER and, when feed patches exist, of the packages feed at
# OPENWRT_PKG_VERSION, so a previous extract is not touched. Exit 2 means
# confirm or review, not "drop the patch".
check-source-patches: $(BUILD_DIR)/$(OPENWRT_VER)$(TAR_EXT) $(if $(FEED_PATCHES),$(PACKAGES_FEED_TAR)) | $(BUILD_DIR)
	@rm -rf $(BUILD_DIR)/$(IMAGEBUILDER).check $(PACKAGES_FEED_CHECK)
	@mkdir -p $(BUILD_DIR)/$(IMAGEBUILDER).check
	@tar -zxmf $(BUILD_DIR)/$(OPENWRT_VER)$(TAR_EXT) -C $(BUILD_DIR)/$(IMAGEBUILDER).check --strip-components 1
	@feed_args=""; \
	  if [ -n "$(FEED_PATCHES)" ]; then \
	    mkdir -p $(PACKAGES_FEED_CHECK); \
	    tar -zxmf $(PACKAGES_FEED_TAR) -C $(PACKAGES_FEED_CHECK) --strip-components 1; \
	    feed_args="--feed packages=$(PACKAGES_FEED_CHECK)"; \
	  fi; \
	  ./scripts/check_source_patches.sh $(BUILD_DIR)/$(IMAGEBUILDER).check $(SOURCE_PATCHES_DIR) $(CURDIR)/.. $$feed_args
	@rm -rf $(BUILD_DIR)/$(IMAGEBUILDER).check $(PACKAGES_FEED_CHECK)

# Depend on the extracted tree, not on `extract`: `extract` is not a file,
# so depending on it re-ran `feeds update`, re-applied feed patches and
# reverted a feed trial on every `make build-img`.
$(BUILD_DIR)/$(IMAGEBUILDER)/feeds.conf.default: | $(BUILD_DIR)/$(IMAGEBUILDER)
	@cd $(BUILD_DIR)/$(IMAGEBUILDER) \
	  && echo "$$FEEDS_CONF_DEFAULT" > feeds.conf.default

ifneq ($(SOURCE_PATCH_MODE),check)
feeds: $(BUILD_DIR)/$(IMAGEBUILDER)/feeds.conf.default

# Feed source patches are applied after `feeds update` and before
# `feeds install`, with the same SOURCE_PATCH_MODE / SKIP handling as
# OpenWrt-tree patches. The skip list written at extract is reused so a
# later `make build-img` without SOURCE_PATCH_MODE=trial on the command
# line still honors a trial extract. An explicit SOURCE_PATCH_MODE=trial
# with a non-empty SKIP_SOURCE_PATCHES on this invocation takes precedence
# over that file, so `make clean-feeds` + a trial `make config` can toggle
# a feed patch on an existing (apply-mode) extract without `make clean`.
# That trial list is saved in .skip-feed-patches so a later plain
# `make build-img` keeps it; `make clean-feeds` + `make config` re-enables.
# Fail-clean is in apply_source_patches.sh.
$(BUILD_DIR)/$(IMAGEBUILDER)/.feeds-updated: $(BUILD_DIR)/$(IMAGEBUILDER)/feeds.conf.default
	@cd $(BUILD_DIR)/$(IMAGEBUILDER) && ./scripts/feeds update -a
	@skip=""; \
	  if [ "$(SOURCE_PATCH_MODE)" = trial ] && [ -n "$(SKIP_SOURCE_PATCHES)" ]; then \
	    skip="$(SKIP_SOURCE_PATCHES)"; \
	    printf '%s\n' "$$skip" > $(BUILD_DIR)/$(IMAGEBUILDER).skip-feed-patches; \
	  elif [ -f $(BUILD_DIR)/$(IMAGEBUILDER).skip-feed-patches ]; then \
	    skip=`tr -d '\n' < $(BUILD_DIR)/$(IMAGEBUILDER).skip-feed-patches`; \
	  elif [ -f $(BUILD_DIR)/$(IMAGEBUILDER).skip-source-patches ]; then \
	    skip=`tr -d '\n' < $(BUILD_DIR)/$(IMAGEBUILDER).skip-source-patches`; \
	  fi; \
	  if [ -n "$$skip" ]; then \
	    echo "Applying feed source patches with SKIP_SOURCE_PATCHES=$$skip"; \
	    SKIP_SOURCE_PATCHES="$$skip" ./scripts/apply_source_patches.sh --feeds $(BUILD_DIR)/$(IMAGEBUILDER) $(SOURCE_PATCHES_DIR); \
	  else \
	    if [ -n "$(SKIP_SOURCE_PATCHES)" ] && [ "$(SOURCE_PATCH_MODE)" != trial ]; then \
	      echo "SOURCE_PATCH_MODE=apply: ignoring SKIP_SOURCE_PATCHES=$(SKIP_SOURCE_PATCHES) (use SOURCE_PATCH_MODE=trial to skip patches)"; \
	    fi; \
	    echo "Applying all feed source patches"; \
	    SKIP_SOURCE_PATCHES= ./scripts/apply_source_patches.sh --feeds $(BUILD_DIR)/$(IMAGEBUILDER) $(SOURCE_PATCHES_DIR); \
	  fi
	@touch $(BUILD_DIR)/$(IMAGEBUILDER)/.feeds-updated

$(BUILD_DIR)/$(IMAGEBUILDER)/.config: $(BUILD_DIR)/$(IMAGEBUILDER)/.feeds-updated
	@cd $(BUILD_DIR)/$(IMAGEBUILDER) \
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
	  -C $(BUILD_DIR)/$(IMAGEBUILDER)/bin/targets/* ./

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

clean-all:
	rm -rf $(BUILD_DIR)

clean:
	rm -rf $(BUILD_DIR)/$(IMAGEBUILDER) $(BUILD_DIR)/$(IMAGEBUILDER).tmp $(BUILD_DIR)/$(IMAGEBUILDER).check \
	  $(BUILD_DIR)/$(IMAGEBUILDER).skip-source-patches $(BUILD_DIR)/$(IMAGEBUILDER).skip-feed-patches $(PACKAGES_FEED_CHECK)

# Re-run feeds update and re-apply feed source patches without wiping the
# toolchain. Use this after changing only source-patches/feeds/.
clean-feeds:
	rm -f $(BUILD_DIR)/$(IMAGEBUILDER)/.feeds-updated $(BUILD_DIR)/$(IMAGEBUILDER).skip-feed-patches
	rm -f $(BUILD_DIR)/$(IMAGEBUILDER)/.config $(BUILD_DIR)/$(IMAGEBUILDER)/.diffconfig
	rm -rf $(BUILD_DIR)/$(IMAGEBUILDER)/feeds

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
# Check that TARGET specific dir exists
ifneq ($(wildcard $(TMPL_SRC_DIR)-$(TARGET)/.),)
	$(GOMPLATE) -d openwrt=$(BUILD_SECRETS) -d keys_dir=$(KEYPATH) --input-dir=$(TMPL_SRC_DIR)-$(TARGET) --output-dir=$(TMPL_OUT_DIR)
endif
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
endif

bump:
	bash scripts/openwrt_bump.sh
