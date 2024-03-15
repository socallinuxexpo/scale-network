{ config, pkgs, ... }:
{
  nixpkgs.overlays = [
    (super: self: {
      cachecache = (builtins.getFlake "github:cleverca22/cachecache/2cb7c3fb55752cecc39751e0bfffdbe8c28db967").packages.x86_64-linux.cachecache;
    })
  ];
  users.users.cachecache = {
    home = "/var/lib/cachecache";
    isSystemUser = true;
    createHome = true;
    group = "cachecache";
  };
  users.groups.cachecache = { };
  systemd.services.cachecache = {
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.cachecache ];
    script = ''
      exec cachecache
    '';
    serviceConfig = {
      User = "cachecache";
      WorkingDirectory = config.users.users.cachecache.home;
    };
  };
}
