inputs:

let

  inherit (inputs.self)
    legacyPackages
    library
    ;

  inherit (library.systems)
    defaultSystems
    ;

  inherit (library.attrsets)
    removeDirectoriesRecursiveAttrs
    ;

in

{

  scale-network = defaultSystems (
    system: removeDirectoriesRecursiveAttrs legacyPackages.${system}.scale-network
  );

}
