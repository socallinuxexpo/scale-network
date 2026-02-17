test-all:
	nix run .#verify-scale-network
	nix run .#verify-scale-tests
	nix run .#verify-scale-nixos-tests
	nix run .#verify-scale-systems
