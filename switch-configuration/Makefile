PERL := $(shell command -v perl 2> /dev/null)

JROOT_SECRET = `cat ../facts/secrets/jroot_pw`
JROOT_SECRET ?= scale # Dummy value

ifndef PERL
  $(error "perl is not available please install it")
endif

all: switch-maps-outputs

lint:	.lint

.lint: config/scripts/*.pl config/scripts/Loader.pm config/scripts/switch_config_loader config/scripts/get_switch_config.cgi config/scripts/switch_pinger
	cd config && \
		find . -name '*.pl' | xargs '-I{}' perl -I scripts -Mstrict -Mdiagnostics -M'warnings FATAL=>q(all)' -cw {}
	cd config/scripts && \
		for f in Loader.pm switch_config_loader get_switch_config.cgi switch_pinger; do \
			perl -I. -Mstrict -Mdiagnostics -M'warnings FATAL=>q(all)' -cw $$f || exit 1; \
		done
	touch .lint

perms:	.perms

.perms: config/scripts/*.pl config/scripts/make_lldp_map config/scripts/switch_pinger
	cd config/scripts && \
		chmod ugo+x *.pl make_lldp_map switch_pinger
	touch .perms

../facts/secrets/jroot_pw:
	echo "$(JROOT_SECRET)" > ../facts/secrets/jroot_pw

.secrets: .lint ../facts/secrets/jroot_pw ../facts/keys/*
	echo "Using $JROOT_SECRET as secret"
	touch .secrets

build-switch-configs: .build-switch-configs

.build-switch-configs: .lint .secrets config/switchtypes config/types/* config/vlans config/vlans.d/* config/trunktypes config/scripts/build_switch_configs.pl config/scripts/switch_template.pm
	cd config && \
		perl scripts/build_switch_configs.pl && \
		touch .build-switch-configs

# Make the switch-maps-bundle which is a collection of all the switch port maps
# this is a for printing for the cable team
switch-maps-outputs: perms config/switch-maps/refs.ps config/switch-maps/refs.pdf config/switch-maps/stickers.ps config/switch-maps/stickers.pdf

# Bundle is technically obsolete at this point and doesn't work properly any more
#config/switch-maps/bundle.ps: .build-switch-configs .build-switch-configs
#	cd config && \
#		perl scripts/generate_ps_maps.pl > switch-maps/bundle.ps

config/switch-maps/refs.ps: .build-switch-configs
	cd config && \
		perl scripts/generate_ps_refs.pl > switch-maps/refs.ps


config/switch-maps/refs.pdf: config/switch-maps/refs.ps
	cd config && \
		gs -sDEVICE=pdfwrite -sOutputFile=switch-maps/refs.pdf <switch-maps/refs.ps > /dev/null

config/switch-maps/stickers.ps: .build-switch-configs
	cd config && \
		perl scripts/generate_ps_stickers.pl > switch-maps/stickers.ps

config/switch-maps/stickers.pdf: config/switch-maps/stickers.ps
	cd config && \
		gs -sDEVICE=pdfwrite -sOutputFile=switch-maps/stickers.pdf <switch-maps/stickers.ps > /dev/null

clean:
	rm -f .build-switch-configs .lint .secrets
	cd config && \
		rm -rf output/* switch-maps/*

