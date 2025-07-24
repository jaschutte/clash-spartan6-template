{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    programmer.url = "github:jaschutte/numato-mimasv2-pic-firmware";
    xilinx.url = "github:jaschutte/nix-fpga-tools";

    clash-compiler.url = "github:clash-lang/clash-compiler";
    clash-cores = {
      url = "github:jaschutte/clash-cores/private-repo";
      inputs.clash-compiler.follows = "clash-compiler";
    };

  };
  outputs = inputs @ { self, flake-utils, xilinx, nixpkgs, programmer, clash-compiler, clash-cores, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        # What version of the GHC compiler to use for protocols
        compiler-version = "ghc910";

        clash-pkgs = (
            (import clash-compiler.inputs.nixpkgs {
              inherit system;
            }).extend clash-compiler.overlays.${compiler-version}
          )."clashPackages-${compiler-version}";

        pkgs = import nixpkgs {
          inherit system;

          config.allowUnfreePredicate = pkg: builtins.elem (pkgs.lib.getName pkg) [
            "saleae-logic-2"
          ];
        };

        overlay = final: prev: {
          main-design = hs-pkgs.developPackage {
            root = ./.;
            overrides = _: _: final;
          };
        } // (clash-cores.overlay.${system} final prev);

        hs-pkgs = clash-pkgs.extend overlay;
      in {
        hs = hs-pkgs;

        packages.default = hs-pkgs.main-design;

        devShells.default = hs-pkgs.shellFor {
          packages = p: [
            p.main-design
          ];

          nativeBuildInputs = [
            # Tool for place & route
            xilinx.packages.${system}.xilinx-ise
            # Programming the FPGA
            programmer.packages.${system}.default
            # Compile clash
            # clash-compiler.packages.${system}.clash-ghc
            hs-pkgs.clash-ghc
            # Synthesis
            pkgs.yosys

            # Language server
            hs-pkgs.cabal-install
            hs-pkgs.haskell-language-server

            # Useful for debugging
            pkgs.saleae-logic-2
          ];
        };
    }
  );
}
