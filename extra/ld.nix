{ pkgs, config, lib, ... }:
with lib;
let
  cfg = config.ld;
in
{
  options.ld = {
    preload = {
      paths = mkOption {
        type = types.listOf types.path;
        default = [ ];
        description = ''
          The libraries to have applications load during startup.
          These paths will be concatenated to the LD_PRELOAD environment variable.
          ld.so picks up this environment variable and loads the libraries before any other libraries.
          This allows overriding certain dynamically linked methods.

          See https://man.archlinux.org/man/ld.so.8.en#LD_PRELOAD
        '';
        example = literalExpression ''
          [ "''${pkgs.faketime}/lib/libfaketime.so.1" ]
        '';
      };
    };
    library = {
      paths = mkOption {
        type = types.listOf types.path;
        default = [ ];
        description = ''
          Directories that are used to dynamically load .so files.
          This can be useful when using prebuilt binaries that try to link
          to specific libraries.

          See https://man.archlinux.org/man/ld.so.8.en#LD_LIBRARY_PATH
        '';
        example = literalExpression ''
          [ "''${pkgs.openssl}/lib" ]
        '';
      };
      packages = mkOption {
        type = types.listOf types.package;
        default = [ ];
        description = ''
          Packages that are used to dynamically load .so files from.
          This supplies ld.library.paths with "''${package}/lib" for each package.

          See https://man.archlinux.org/man/ld.so.8.en#LD_LIBRARY_PATH
        '';
        example = literalExpression ''
          [ pkgs.openssl ]
        '';
      };
    };
  };

  config = {
    ld.library.paths = map (package: "${package}/lib") cfg.library.packages;

    env = optional (length cfg.preload.paths > 0)
      {
        name = "LD_PRELOAD";
        eval = "${concatStringsSep " " cfg.preload.paths} $LD_PRELOAD";
      }
    ++ optional (length cfg.library.paths > 0)
      {
        name = "LD_LIBRARY_PATH";
        eval = "${concatStringsSep ":" cfg.library.paths}:$LD_LIBRARY_PATH";
      };
  };
}
