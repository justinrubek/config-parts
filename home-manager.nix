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
  cfg = config.config-parts.home;

  # collect all configurations so they can be exposed as flake outputs
  configs = builtins.mapAttrs (_: config: config.homeConfig) cfg.configurations;

  # TODO: determine if these are useful and where to expose them from
  packages = builtins.attrValues (builtins.mapAttrs (_: config: let
    # collect the configurations under an attribute set so they can be used
    # as flake.packages outputs
    namespaced = {${config.system}.${config.packageName} = config.homePackage;};
  in
    namespaced)
  cfg);
in {
  options = {
    config-parts.home = {
      home-manager = lib.mkOption {
        type = lib.types.unspecified;
        default = inputs.home-manager;
        description = "the home-manager flake";
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
        }: let
          # determine the username and hostname from the name
          splitName = builtins.split "@" name;
          username = builtins.elemAt splitName 0;
          hostname = builtins.elemAt splitName 2;
        in {
          _file = ./home-manager.nix;
          options = {
            system = lib.mkOption {
              type = lib.types.enum (import systems);
            };

            username = lib.mkOption {
              type = lib.types.str;
              default = username;
            };

            hostname = lib.mkOption {
              type = lib.types.str;
              default = hostname;
            };

            pkgs = lib.mkOption {
              type = lib.types.unspecified;
              default = nixpkgs.legacyPackages.${config.system};
            };

            homeDirectory = lib.mkOption {
              type = lib.types.str;
              default =
                if !config.pkgs.stdenv.isDarwin
                then "/home/${config.username}"
                else "/Users/${config.username}";
              description = "The path to the home directory of the user.";
            };

            modules = lib.mkOption {
              type = lib.types.listOf lib.types.unspecified;
              default = [];
              description = "List of modules to include for the configuration.";
            };

            # outputs
            homeConfig = lib.mkOption {
              type = lib.types.unspecified;
              readOnly = true;
              description = "The home-manager configuration.";
            };

            homePackage = lib.mkOption {
              type = lib.types.package;
              readOnly = true;
              description = "The home-manager activation package.";
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

            packageName = lib.mkOption {
              type = lib.types.str;
              readOnly = true;
              description = "The name of the exported package output that contains the home-manager activation package.";
            };
          };

          config = {
            entryPoint = "${self}/home/configurations/${name}";

            finalModules =
              cfg.modules.shared
              ++ config.modules
              ++ [
                config.entryPoint
                {
                  _module.args = {
                    inherit (config) homeDirectory username;
                  };
                }
                {
                  home = {
                    inherit (config) username homeDirectory;
                  };
                }
              ];

            homeConfig = withSystem config.system ({
              inputs',
              self',
              ...
            }:
              cfg.home-manager.lib.homeManagerConfiguration {
                inherit (config) pkgs;
                modules = config.finalModules;
                extraSpecialArgs = {
                  inherit inputs inputs' self self';
                };
              });

            homePackage = config.homeConfig.activationPackage;
            packageName = "home/configuration/${name}";
          };
        }));
      };
    };
  };

  config = {
    flake.homeConfigurations = configs;
  };
}
