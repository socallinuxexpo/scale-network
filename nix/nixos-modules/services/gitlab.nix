{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.scale-network.services.gitlab;

  inherit (lib.modules)
    mkIf
    ;

  inherit (lib.types)
    int
    ;

  inherit (lib.options)
    mkEnableOption
    ;
in
{
  options.scale-network.services.gitlab = {
    enable = mkEnableOption "SCaLE network GitLab runner";

    concurrent = lib.mkOption {
      type = int;
      default = 3;
      description = ''
        Number of concurrent jobs to schedule on the gitlab-runner
      '';
    };
  };

  config = mkIf cfg.enable {
    services.gitlab-runner = {
      enable = true;
      gracefulTermination = true;
      settings.concurrent = cfg.concurrent;
      services = {
        shell = {
          # make sure this is a quote path so it doesnt end up in /nix/store
          authenticationTokenConfigFile = "/persist/etc/gitlab/shellAuthToken.env";
          executor = "shell";
        };
      };
    };

    # include for gl-runner cli
    environment.systemPackages = [
      pkgs.gitlab-runner
    ];
  };
}
