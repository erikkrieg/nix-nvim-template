{
  description = "Erik's Neovim configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/23.05";
    unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { flake-utils, nixpkgs, ... }:
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = import nixpkgs { inherit system; };
          neovimConfig = { };
        in
        with pkgs;
        rec {
          packages.default = wrapNeovimUnstable neovim-unwrapped neovimConfig;
          apps.default = flake-utils.lib.mkApp {
            drv = packages.nix-nvim;
            name = "nix-nvim";
            exePath = "/bin/nvim";
          };
          devShell = mkShell {
            buildInputs = [
              packages.default
            ];
          };
        });
}
