{
  lib,
  config,
  ...
}:
let
  cfg = config.scale-network.user.gene;
  inherit (lib.modules)
    mkIf
    ;

  inherit (lib.options)
    mkEnableOption
    ;
in
{
  options.scale-network.users.gene.enable = mkEnableOption "user gene";

  config = mkIf cfg.enable {
    users.user = {
      gene = {
        isNormalUser = true;
        uid = 2013;
        extraGroups = [ "wheel" ];
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIp42X5DZ713+bgbOO+GXROufUFdxWo7NjJbGQ285x3N"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFvLaPTfG3r+bcbI6DV4l69UgJjnwmZNCQk79HXyf1Pt"
        ];
      };
    };
  };
}
