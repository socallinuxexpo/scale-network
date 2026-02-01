inputs:

let

  inherit (inputs.nixpkgs-lib)
    lib
    ;

  inherit (lib.attrsets)
    filterAttrs
    updateManyAttrsByPath
    ;

  inherit (lib.lists)
    init
    last
    map
    ;

  inherit (lib.trivial)
    pipe
    ;

  inherit (inputs.self)
    legacyPackages
    legacyPackagesTests
    library
    ;

  inherit (library.systems)
    defaultSystems
    ;

  inherit (library.attrsets)
    removeDirectoriesRecursiveAttrs
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

  scale-nixos-tests = defaultSystems (
    system: removeDirectoriesRecursiveAttrs legacyPackagesTests.${system}.scale-nixos-tests
  );

}
