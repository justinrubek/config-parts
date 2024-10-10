{
  nixpkgs,
  systems,
  ...
}: {
  self,
  inputs,
  config,
  lib,
  withSystem,
  ...
}: let
  cfg = config.config-parts.darwin;

  # collect all configurations so they can be exposed as flake outputs
  configs = builtins.mapAttrs (_: config: config.darwinConfig) cfg.configurations;
in {
  options = {
    config-parts.darwin = {
      nix-darwin = lib.mkOption {
        type = lib.types.unspecified;
        default = inputs.nix-darwin;
        description = "the nix-darwin flake";
      };

      modules.shared = lib.mkOption {
        type = lib.types.listOf lib.types.unspecified;
        default = [];
        description = ''
          a list of modules to be shared with all configurations
        '';
      };
      configurations = lib.mkOption {
        type = lib.types.attrsOf (lib.types.submodule ({
          name,
          config,
          ...
        }: {
          _file = ./nix-darwin.nix;
          options = {
            system = lib.mkOption {
              type = lib.types.enum (import systems);
            };

            modules = lib.mkOption {
              type = lib.types.listOf lib.types.unspecified;
              default = [];
              description = "List of modules to include for the configuration.";
            };

            # outputs
            darwinConfig = lib.mkOption {
              type = lib.types.unspecified;
              readOnly = true;
              description = "The nix-darwin configuration.";
            };

            darwinPackage = lib.mkOption {
              type = lib.types.package;
              readOnly = true;
              description = "The package output that contains the system's switch script";
            };

            finalModules = lib.mkOption {
              type = lib.types.listOf lib.types.unspecified;
              readOnly = true;
              description = "All modules that are included in the configuration.";
            };

            entryPoint = lib.mkOption {
              type = lib.types.unspecified;
              readOnly = true;
              description = "The entry point module of the configuration.";
            };
          };

          config = {
            entryPoint = "${self}/darwin/configurations/${name}";

            finalModules =
              cfg.modules.shared
              ++ config.modules
              ++ [
                config.entryPoint
                {
                  nixpkgs.hostPlatform = config.system;
                }
              ];

            darwinConfig = withSystem config.system ({
              inputs',
              self',
              ...
            }:
              cfg.nix-darwin.lib.darwinSystem {
                inherit (config) system;
                modules = config.finalModules;
                specialArgs = {
                  inherit inputs inputs' self self';
                };
              });

            darwinPackage = config.darwin.system;
          };
        }));
      };
    };
  };

  config = {
    flake.darwinConfigurations = configs;
  };
}
