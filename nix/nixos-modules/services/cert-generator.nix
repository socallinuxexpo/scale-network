{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.scale-network.services.cert-generator;

  inherit (lib)
    types
    ;

  inherit (lib.modules)
    mkIf
    ;

  inherit (lib.options)
    mkEnableOption
    mkOption
    ;
in
{
  options.scale-network.services.cert-generator = {

    enable = mkEnableOption "";

    certPath = mkOption {
      type = types.str;
      default = "/persist/etc/cert-generator";
      description = "TODO: @sarcasticadmin";
    };

    certCert = mkOption {
      type = types.str;
      default = "${cfg.certPath}/cert.crt";
      description = "TODO: @sarcasticadmin";
    };

    certKey = mkOption {
      type = types.str;
      default = "${cfg.certPath}/cert.key";
      description = "TODO: @sarcasticadmin";
    };

    commonName = mkOption {
      type = types.str;
      description = "TODO: @sarcasticadmin";
    };

  };

  config = mkIf cfg.enable {

    systemd.services.cert-generator = {
      before = [ "network.target" ];
      path = with pkgs; [
        openssl
      ];
      unitConfig = {
        ConditionPathExists = "!${cfg.certPath}/cert.crt";
      };
      serviceConfig = {
        ExecStart = "${lib.getExe pkgs.openssl} req -new -newkey rsa:4096 -days 365 -nodes -x509 -subj '/C=US/ST=California/L=Pasadena/O=SCaLE Security/OU=NOC/CN=${cfg.commonName}' -keyout ${cfg.certKey} -out ${cfg.certCert}";
      };
      wantedBy = [ "network.target" ];
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.certPath} 775 root wheel"
    ];

  };
}
