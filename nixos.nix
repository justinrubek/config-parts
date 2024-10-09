{
  nixpkgs,
  systems,
  ...
}: {
  self,
  inputs,
  config,
  lib,
  ...
}: let
  cfg = config.config-parts.nixos;

  # collect all nixosConfigurations so they can be exposed as flake outputs
  configs = builtins.mapAttrs (_: config: config.nixosConfig) cfg.configurations;

  # TODO: determine if these are useful and where to expose them from
  packages = builtins.attrValues (builtins.mapAttrs (_: config: let
    # collect the configurations under an attribute set so they can be used
    # as flake.packages outputs
    namespaced = {${config.system}.${config.packageName} = config.nixosPackage;};
  in
    namespaced)
  cfg);
in {
  options = {
    config-parts.nixos = {
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
          options = {
            system = lib.mkOption {
              type = lib.types.enum (import systems);
            };

            modules = lib.mkOption {
              type = lib.types.listOf lib.types.unspecified;
              default = [];
              description = "List of modules to include for the configuration.";
            };

            nixosConfig = lib.mkOption {
              type = lib.types.unspecified;
              readOnly = true;
              description = "The nixos configuration.";
            };

            entryPoint = lib.mkOption {
              type = lib.types.unspecified;
              readOnly = true;
              description = "The entry point module of the configuration.";
            };

            packageName = lib.mkOption {
              type = lib.types.str;
              readOnly = true;
              description = "The name of the exported package.";
            };

            nixosPackage = lib.mkOption {
              type = lib.types.package;
              readOnly = true;
              description = "The package output that contains the system's build.toplevel.";
            };
          };

          config = let
            entryPoint = "${self}/nixos/configurations/${name}";
          in {
            nixosConfig = nixpkgs.lib.nixosSystem {
              inherit (config) system;
              modules =
                cfg.modules.shared
                ++ config.modules
                ++ [
                  entryPoint
                  {
                    _module.args = {
                      inherit inputs self;
                    };
                  }
                  {
                    networking = {
                      hostName = name;
                      hostId = builtins.substring 0 8 (builtins.hashString "md5" name);
                    };
                    nix.flakes.enable = true;
                    system.configurationRevision = self.rev or "dirty";
                  }
                ];
            };

            nixosPackage = config.nixosConfig.config.system.build.toplevel;
            packageName = "nixos/configuration/${name}";
          };
        }));
      };
    };
  };

  config = {
    flake.nixosConfigurations = configs;
  };
}
