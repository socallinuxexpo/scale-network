final: prev: {
  frr = prev.frr.overrideAttrs (old: {
    configureFlags = final.lib.remove "--localstatedir=/run/frr" old.configureFlags ++ [
      "--localstatedir=/var"
    ];
  });
}
