{
  lib,
  ...
}:
let
  inherit (lib)
    types
    ;

  inherit (lib.options)
    mkOption
    ;
in
{
  options.scale-network.facts = {

    ipv4 = mkOption {
      type = types.str;
    };

    ipv6 = mkOption {
      type = types.str;
    };

    eth = mkOption {
      type = types.str;
    };

  };
}
