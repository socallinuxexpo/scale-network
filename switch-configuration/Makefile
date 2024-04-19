PERL := $(shell command -v perl 2> /dev/null)

JROOT_SECRET = `cat ../facts/secrets/jroot_pw`
JROOT_SECRET ?= scale # Dummy value

ifndef PERL
  $(error "perl is not available please install it")
endif

all: switch-maps-outputs

lint:	.lint

.lint: config/scripts/*.pl
	cd config && \
		find . -name '*.pl' | xargs '-I{}' perl -Mstrict -Mdiagnostics -M'warnings FATAL=>q(all)' -cw {}
	touch .lint

../facts/secrets/jroot_pw:
	echo "$(JROOT_SECRET)" > ../facts/secrets/jroot_pw

.secrets: .lint ../facts/secrets/jroot_pw ../facts/keys/*
	echo "Using $JROOT_SECRET as secret"
	touch .secrets

build-switch-configs: .build-switch-configs

.build-switch-configs: .lint .secrets config/v6_prefix config/switchtypes config/types/* config/vlans config/vlans.d/* config/scripts/build_switch_configs.pl config/scripts/switch_template.pm
	cd config && \
		perl scripts/build_switch_configs.pl
	touch .build-switch-configs

# Make the switch-maps-bundle which is a collection of all the switch port maps
# this is a for printing for the cable team
switch-maps-outputs: config/switch-maps/refs.ps config/switch-maps/refs.pdf config/switch-maps/stickers.ps config/switch-maps/stickers.pdf

# Bundle is technically obsolete at this point and doesn't work properly any more
#config/switch-maps/bundle.ps: .build-switch-configs .build-switch-configs
#	cd config && \
#		perl scripts/generate_ps_maps.pl > switch-maps/bundle.ps

config/switch-maps/refs.ps: .build-switch-configs .build-switch-configs
	cd config && \
		perl scripts/generate_ps_refs.pl > switch-maps/refs.ps


config/switch-maps/refs.pdf: config/switch-maps/refs.ps
	cd config && \
		gs -sDEVICE=pdfwrite -sOutputFile=switch-maps/refs.pdf <switch-maps/refs.ps > /dev/null

config/switch-maps/stickers.ps: .build-switch-configs .build-switch-configs
	cd config && \
		perl scripts/generate_ps_stickers.pl > switch-maps/stickers.ps

config/switch-maps/stickers.pdf: config/switch-maps/stickers.ps
	cd config && \
		gs -sDEVICE=pdfwrite -sOutputFile=switch-maps/stickers.pdf <switch-maps/stickers.ps > /dev/null

clean:
	rm -f .build-switch-configs .lint .secrets
	cd config && \
		rm -rf output/* switch-maps/*

