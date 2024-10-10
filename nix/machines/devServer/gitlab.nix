{ config, pkgs, ... }:
{
  services.gitlab-runner = {
    enable = true;
    gracefulTermination = true;
    services = {
      shell = {
        authenticationTokenConfigFile = /persist/etc/gitlab/shellAuthToken.env;
        executor = "shell";
        tagList = [ "shell" ];
      };
    };
  };

  # include for gl-runner cli
  environment.systemPackages = [ pkgs.gitlab-runner ];
}
