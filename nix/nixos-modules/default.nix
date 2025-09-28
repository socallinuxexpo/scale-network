inputs: {
  default =
    { ... }:
    {
      imports = [
        ./base.nix
        ./facts.nix
        ./libvirt.nix
        ./time.nix
        ./services
        ./users
        ./routers
      ];
    };
}
