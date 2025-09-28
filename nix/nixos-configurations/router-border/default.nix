{
  release = "unstable";

  modules =
    {
      config,
      lib,
      ...
    }:
    {
      imports = [
        ./configuration.nix
        ./hardware-configuration.nix
        ./disko.nix
      ];

      config = {
        nixpkgs.hostPlatform = "x86_64-linux";
        networking.hostName = "router-border";
      };
    };
}
