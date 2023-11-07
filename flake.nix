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
          binPath = pkgs.lib.makeBinPath extraPackages;
          styler-nvim = with pkgs; vimUtils.buildVimPlugin
            {
              name = "styler.nvim";
              pname = "styler.nvim";
              src = fetchFromGitHub {
                owner = "folke";
                repo = "styler.nvim";
                rev = "d5b7e43af4fdaa06e4175c84f4f57b633ae7e6ff";
                sha256 = "sha256-BlePqxukucbrUPqk4NzqXsw+3RC/jU9WOpy40D0NbwQ=";
              };
            };
          plugins = with pkgs.vimPlugins; [
            lazy-nvim
            alpha-nvim
            nvim-web-devicons
            telescope-nvim
            nvim-treesitter.withAllGrammars

            # colorscheme
            styler-nvim
            catppuccin-nvim
            tokyonight-nvim
          ];
          packpathDirs.myNeovimPackages = {
            start = plugins;
            opt = [ ];
          };
          initFile = pkgs.writeTextFile {
            name = "init.lua";
            text = ''
              vim.loader.enable()
              vim.opt.rtp:append("${./nvim}")
              require("core")
            '';
          };
          neovimConfig = pkgs.neovimUtils.makeNeovimConfig
            {
              customRC = "luafile ${initFile}";
            } // {
            inherit packpathDirs;
            viAlias = true;
            vimAlias = true;
            withNodeJs = false;
            withPython3 = false;
            withRuby = false;
            wrapperArgs = pkgs.lib.escapeShellArgs [ "--suffix" "PATH" ":" "${binPath}" ];
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
              just
              stylua
            ];
          };
        });
}
