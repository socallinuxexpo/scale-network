{ config, ... }:
{
  services.gitlab-runner = {
    enable = true;
    gracefulTermination = true;
    services = {
      shell = {
        authenticationTokenConfigFile = /persist/etc/gitlab/shellAuthenticationToken.env;
        executor = "shell";
        tagList = [ "shell" ];
      };
    };
  };
}
