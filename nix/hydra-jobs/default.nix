inputs:

let

  inherit (inputs.nixpkgs-lib)
    lib
    ;

  inherit (lib.attrsets)
    filterAttrs
    genAttrs
    updateManyAttrsByPath
    ;

  inherit (lib.lists)
    init
    last
    map
    subtractLists
    ;

  inherit (lib.trivial)
    pipe
    ;

  inherit (inputs.self)
    legacyPackages
    legacyPackagesTests
    library
    nixosConfigurations
    ;

  inherit (library.systems)
    defaultSystems
    ;

  inherit (library.attrsets)
    removeDirectoriesRecursiveAttrs
    ;

  inherit (library.path)
    getDirectoryNames
    ;

  removeByPath =
    pathList: set:
    updateManyAttrsByPath [
      {
        path = init pathList;
        update = old: filterAttrs (n: v: n != (last pathList)) old;
      }
    ] set;

in

{

  scale-network =
    pipe
      (defaultSystems (system: removeDirectoriesRecursiveAttrs legacyPackages.${system}.scale-network))
      (
        map removeByPath [
          [
            "aarch64-darwin"
            "dhcptest"
          ]
          [
            "aarch64-darwin"
            "isc-dhcp"
          ]
          [
            "aarch64-linux"
            "dhcptest"
          ]
          [
            "x86_64-darwin"
            "dhcptest"
          ]
          [
            "x86_64-darwin"
            "isc-dhcp"
          ]
        ]
      );

  scale-tests = defaultSystems (
    system: removeDirectoriesRecursiveAttrs legacyPackagesTests.${system}.scale-tests
  );

  scale-nixos-tests =
    pipe
      (defaultSystems (
        system: removeDirectoriesRecursiveAttrs legacyPackagesTests.${system}.scale-nixos-tests
      ))
      (
        map removeByPath [
          [
            "aarch64-darwin"
            "core"
          ]
          [
            "aarch64-linux"
            "core"
          ]
          [
            "x86_64-darwin"
            "core"
          ]
        ]
      );

  scale-nixos-systems =
    let

      all-systems = getDirectoryNames ../nixos-configurations;

      # aarch64-linux list is small; curate list here
      aarch64-linux-systems = [ "massflash-pi" ];

      # currently all remaining systems are x86_64-linux
      x86_64-linux-systems = subtractLists aarch64-linux-systems all-systems;

    in
    {

      "aarch64-linux" = genAttrs aarch64-linux-systems (
        host: nixosConfigurations.${host}.config.system.build.toplevel
      );

      "x86_64-linux" = genAttrs x86_64-linux-systems (
        host: nixosConfigurations.${host}.config.system.build.toplevel
      );

    };

}
