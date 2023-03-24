Command := $(firstword $(MAKECMDGOALS))
Arguments := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))

default: show 

bhyveImage:
	@echo "nix building $(Arguments) bhyve Image"
	nix build ".#nixosConfigurations.$(Arguments).config.system.build.bhyveImage"

qemuVm:
	@echo "nix building $(Arguments) qemu VM"
	nix build ".#nixosConfigurations.$(Arguments).config.system.build.vm"

all:	bhyveImage qemuvm
        	

show:
	@echo "A simple wrapper for nix build "$(Arguments)"!";
	@echo "You will need NIXOS Installed!!! :-)";
	@echo "Available test are:"
	@echo 
	@ls nix/tests/.
	@echo 
	@echo "Try typing make at the CLI and hit TAB (on your keyboard) for targets"
	@echo 
	nix flake show;

nixtests: 
	@echo "Available test are:"
	@ls nix/tests/.
	@echo
	@echo "nix building and running nixos $(Arguments) tests"
	nix build ".#packages.x86_64-linux.scaleTests.$(Arguments)"

%::
	@true
