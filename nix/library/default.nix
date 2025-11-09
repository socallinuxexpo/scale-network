inputs:
let

  inherit (builtins)
    readDir
    ;

  inherit (inputs.nixpkgs-lib) lib;

  inherit (lib.attrsets)
    attrNames
    filterAttrs
    mapAttrs'
    nameValuePair
    ;

  inherit (lib.fixedPoints)
    fix
    ;

  inherit (lib.lists)
    toList
    ;

  inherit (lib.strings)
    concatMapStrings
    concatStringsSep
    splitString
    substring
    toLower
    toUpper
    ;

  inherit (lib.trivial)
    const
    flip
    pipe
    ;

in
fix (finalLibrary: {

  path = fix (finalPath: {

    /**
      Filter the contents of a directory path for directories only.

      # Inputs

      `contents`

      : 1\. The contents of a directory path.

      # Type

      ```
      filterDirectories :: AttrSet -> AttrSet
      ```

      # Examples
      :::{.example}
      ## `lib.path.filterDirectories` usage example

      ```nix
      x = {
        "default.nix" = "regular";
        djacu = "directory";
        programs = "directory";
        services = "directory";
      }
      filterDirectories x
      => {
        djacu = "directory";
        programs = "directory";
        services = "directory";
      }
      ```

      :::
    */
    filterDirectories = filterAttrs (const (fileType: fileType == "directory"));

    /**
      Get list of directories names under parent.

      # Inputs

      `path`

      : 1\. The parent path.

      # Type

      ```
      getDirectoryNames :: Path -> [String]
      ```

      # Examples
      :::{.example}
      ## `lib.path.getDirectoryNames` usage example

      ```nix
      getDirectoryNames ./home-modules
      => [
        "djacu"
        "programs"
        "services"
      ]
      ```
    */
    getDirectoryNames = flip pipe [
      finalPath.getDirectories
      attrNames
    ];

    /**
      Get attribute set of directories under parent.

      # Inputs

      `path`

      : 1\. The parent path.

      # Type

      ```
      getDirectories :: Path -> AttrSet
      ```

      # Examples
      :::{.example}
      ## `lib.path.getDirectories` usage example

      ```nix
      getDirectories ./home-modules
      => {
        djacu = "directory";
        programs = "directory";
        services = "directory";
      }
      ```
    */
    getDirectories = flip pipe [
      readDir
      finalPath.filterDirectories
    ];

    /**
      Join a parent path to one or more children.

      # Inputs

      `parent`

      : 1\. A parent path.

      `paths`

      : 2\. The paths to append.

      # Type

      ```
      joinParentToPaths :: Path -> String | [ String ] -> String
      ```

      # Examples
      :::{.example}
      ## `lib.path.joinParentToPaths` usage example

      ```nix
      joinParentToPaths ./home-modules "users"
      => /home/djacu/dev/djacu/theonecfg/home-modules/users
      joinParentToPaths ./home-modules [ "users" djacu" "module.nix" "]
      => /home/djacu/dev/djacu/theonecfg/home-modules/users/djacu/module.nix
      ```

      :::
    */
    joinParentToPaths = parent: paths: parent + ("/" + concatStringsSep "/" (toList paths));

  });

  strings = fix (finalStrings: {

    mutFirstChar =
      f: s:
      let
        firstChar = f (substring 0 1 s);
        rest = substring 1 (-1) s;
      in
      firstChar + rest;

    kebabToCamel =
      s:
      finalStrings.mutFirstChar toLower (
        concatMapStrings (finalStrings.mutFirstChar toUpper) (splitString "-" s)
      );

    attrNamesKebabToCamel = mapAttrs' (
      name: value: nameValuePair (finalStrings.kebabToCamel name) value
    );

  });

})
