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
          extraPackages = [ ];
          plugins = with pkgs.vimPlugins; [
            telescope-nvim
            nvim-treesitter.withAllGrammars
          ];
          binPath = pkgs.lib.makeBinPath extraPackages;
          initFile = pkgs.writeTextFile {
            name = "init.lua";
            text = ''
              vim.loader.enable()
              vim.opt.rtp:append("${../.}")
              require "core"
            '';
          };
          neovimConfig = pkgs.neovimUtils.makeNeovimConfig
            {
              customRC = "luafile ${initFile}";
            } // {
            viAlias = true;
            vimAlias = true;
            withNodeJs = false;
            withPython3 = false;
            withRuby = false;
            wrapperArgs = pkgs.lib.escapeShellArgs [ "--suffix" "PATH" ":" "${binPath}" ];
            packpathDirs.myNeovimPackages = {
              start = plugins;
              opt = [ ];
            };
          };
        in
        with pkgs;
        rec {
          packages.nix-nvim = wrapNeovimUnstable neovim-unwrapped neovimConfig;
          packages.default = packages.nix-nvim;
          apps.nix-nvim = flake-utils.lib.mkApp {
            drv = packages.nix-nvim;
            name = "nix-nvim";
            exePath = "/bin/nvim";
          };
          apps.default = apps.nix-nvim;
          devShell = mkShell {
            buildInputs = [
              packages.nix-nvim
            ];
          };
        });
}
