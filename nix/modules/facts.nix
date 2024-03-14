{ config, lib, ... }:

with lib;

{
  options.facts = {
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
