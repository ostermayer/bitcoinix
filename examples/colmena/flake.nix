{
  description = "Colemna Hive configuration (fullnode)";

  # The nixConfig here only affects the flake itself, not the system
  # configuration!
  nixConfig = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];

    extra-substituters = [
      "https://colmena.cachix.org"
      "https://nix-community.cachix.org"
      "https://bitcoinix.cachix.org"
    ];
    extra-trusted-public-keys = [
      "colmena.cachix.org-1:7BzpDnjjH8ki2CT3f6GdOk7QAzPOl+1t3LvTLXqYcSg="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "bitcoinix.cachix.org-1:DvEwg0KpxaYae9Hn3ptski7Bkv2xZAHMuzwF6xiH1T8="
    ];
  };

  inputs = {
    # Pin the latest release tag listed at https://github.com/bitcoinix/bitcoinix/tags
    bitcoinix.url = "github:bitcoinix/bitcoinix/v0.1.2";

    # Use the nixpkgs that bitcoinix is tested with
    nixpkgs.follows = "bitcoinix/nixpkgs";

    colmena = {
      url = "github:nix-community/colmena/v0.5.0";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.stable.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      ...
    }@inputs:
    let
      toolingSupportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = inputs.nixpkgs.lib.genAttrs toolingSupportedSystems;
    in
    {
      colmenaHive = inputs.colmena.lib.makeHive {
        meta = {
          # Do not allow deployments without a node filter set
          allowApplyAll = false;

          # Default nixpkgs. This must be specified, otherwise the colmena will not build:
          # "Hint: Use the same version of Colmena as in the Flake input."
          # " ... "
          # "error: meta.nixpkgs must be specified in hermetic mode."
          nixpkgs = import inputs.nixpkgs {
            system = "x86_64-linux";
          };

          specialArgs = {
            system = "x86_64-linux";
          };

          nodeNixpkgs = {
            fullnode = import inputs.nixpkgs {
              system = "x86_64-linux";
            };
          };

          nodeSpecialArgs = { };
        };

        defaults = {
          imports = [
            # Include the common defaults to all machine configuration
            ./nixos/common.nix
          ];
        };

        ##################
        #### FULL NODE
        ##################
        fullnode =
          let
            name = "fullnode";
          in
          { ... }:
          {
            deployment = {
              targetHost = "${name}.example.com";
              targetUser = "root";
              buildOnTarget = true;
            };

            imports = [
              inputs.bitcoinix.nixosModules.default
              (inputs.bitcoinix + "/modules/presets/secure-node.nix")

              # Load node configuration
              ./nixos/configs/${name}/configuration.nix
            ];

            nix-bitcoin = {
              # Automatically generate all secrets required by services.
              # The secrets are stored in /etc/nix-bitcoin-secrets on remote
              # node and must be backuped.
              generateSecrets = true;
            };
          };
      };

      # Create a dev shell when calling `nix develop`
      devShells = forAllSystems (system: {
        default = import ./shell.nix {
          pkgs = inputs.nixpkgs.legacyPackages.${system};
          inherit system self;
        };
      });
    };
}
