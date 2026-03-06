{
  lib,
  config,
  ...
}:
let
  cfg = config.scale-network.users.erikaker;
  inherit (lib.modules)
    mkIf
    ;

  inherit (lib.options)
    mkEnableOption
    ;
in
{
  options.scale-network.users.erikaker.enable = mkEnableOption "user erikaker";

  config = mkIf cfg.enable {
    users.users = {
      erikaker = {
        isNormalUser = true;
        uid = 2016;
        extraGroups = [ "wheel" ];
        openssh.authorizedKeys.keys = [
          "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCZVFpFwtwzvDhknUBdYSg3i7gisnHUfj3tMpSskOb3BSC+QLB0pghzu8V09k3JBPZAmBh63GdSRjVn28eTl+cOD/Rk/5Ly1UVAXB0WCE+7vTWVvLUwzfW+52LrzSShs+NVgMN09i14mhp2fTy+WKqV4qqOF8f+MegwoxgYcbqEv8kuVGood35gyxxs02JjZu2q0finoK1KHvXGD4d3YWdK4IUHVAKh6NY3YL8nf9thEgpMXilhEOsyfflQJjBnRvXizR2U6DZ3WtVNnVp9KzY0s3U4CQ8+lCQMjr+gpprwCc1kt+TBhmR2Bb61dRWteZwBkex7uocp5BA9cAeSy2Up2bGrwsxOs+qxkfx+8h9eCCH+tVS64vl9bRPS50/jlTw6joYTXBR8YqOq3WTwJ+T6kHKVZAsdZb5CQ8ZtCZ2tOInQzMBLbEKJ8snn5lxTXz4BeqJYMOmfWYjbHyv4Qvn49X/G7XsdexonikS9VzFzgzg2vP5NRvudDCj2bLvYIfI8+4LZZRkV7SooUPMC1Lar+ZJGQlEIXdg4sSP71YeFZWsYH4QdKQB3IdESOqPX4gD1yVN1W3Ol/gcT9G0/N1OWOup+V2+aMXacuGEh8iH85GRHyF9ToBFYsEaaVs2TUhFLdhmS+A/kBwas5KpowqxFQWYTwSoOyz04wXwqn0PLQQ== eraker@gmail.com"
        ];
      };
    };
  };
}
