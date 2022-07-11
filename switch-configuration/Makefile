PERL := $(shell command -v perl 2> /dev/null)

JROOT_SECRET ?= scale # Dummy value

ifndef PERL
  $(error "perl is not available please install it")
endif

all: switch-maps-bundle

.lint: config/scripts/*.pl
	find . -name '*.pl' | xargs '-I{}' perl -Mstrict -Mdiagnostics -M'warnings FATAL=>q(all)' -cw {}
	touch .lint

lint:	.lint

.secrets: .lint
	echo "$(JROOT_SECRET)" > ../facts/secrets/jroot_pw
	touch .secrets

.build-switch-configs: .lint .secrets config/switchtypes config/types/* config/vlans config/vlans.d/* config/scripts/build_switch_configs.pl config/scripts/switch_template.pl
	cd config && \
		./scripts/build_switch_configs.pl
	touch .build-switch-configs

# Make the switch-maps-bundle which is a collection of all the switch port maps
# this is a for printing for the cable team
switch-maps-bundle: config/switch-maps/bundle.ps config/switch-maps/refs.ps config/switch-maps/stickers.ps

config/switch-maps/bundle.ps: .build-switch-configs config/switch-maps/*.eps
	cd config && \
		perl scripts/generate_ps_maps.pl > switch-maps/bundle.ps

config/switch-maps/refs.ps: .build-switch-configs config/switch-maps/*.eps
	cd config && \
		perl scripts/generate_ps_refs.pl > switch-maps/refs.ps

config/switch-maps/stickers.ps: .build-switch-configs config/switch-maps/*.eps
	cd config && \
		perl scripts/generate_ps_stickers.pl > switch-maps/stickers.ps
