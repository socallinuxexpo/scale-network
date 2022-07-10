PERL := $(shell command -v perl 2> /dev/null)

JROOT_SECRET ?= scale # Dummy value

ifndef PERL
  $(error "perl is not available please install it")
endif

lint:
	find . -iname "*.pl" | xargs -i perl -Mstrict -Mdiagnostics -M'warnings FATAL=>q(all)' -cw {}

secrets:
	echo "$(JROOT_SECRET)" > ../facts/secrets/jroot_pw

build-switch-configs: secrets
	cd config && \
		./scripts/build_switch_configs.pl

# Make the switch-maps-bundle which is a collection of all the switch port maps
# this is a for printing for the cable team
switch-maps-bundle: config/switch-maps/maps.ps config/switch-maps/bundle.ps config/switch-maps/stickers.ps

config/switch-maps/bundle.ps:
	cd config && \
		perl scripts/generate_ps_maps.pl > switch-maps/bundle.ps

config/switch-maps/bundle.ps:
	cd config && \
		perl scripts/generate_ps_refs.pl > switch-maps/bundle.ps

config/switch-maps/stickers.ps:
	cd config && \
		perl scripts/generate_ps_stickers.pl > switch-maps/stickers.ps
