PERL := $(shell command -v perl 2> /dev/null)

ifndef PERL
  $(error "perl is not available please install it")
endif

# Make the switch-maps-bundle which is a collection of all the switch port maps
# this is a for printing for the cable team
switch-maps-bundle: config/switch-maps/bundle.ps

config/switch-maps/bundle.ps:
	cd config && \
	perl scripts/generate_ps_refs.pl > switch-maps/bundle.ps
