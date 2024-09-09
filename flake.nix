{
  description = "Weeder Nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs?ref=nixos-23.11";
    pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
    systems.url = "github:nix-systems/x86_64-linux";
  };

  outputs = { self, nixpkgs, pre-commit-hooks, systems }:
    let
      forAllSystems = function:
        nixpkgs.lib.genAttrs (import systems) (system: function nixpkgs.legacyPackages.${system});

      lib = {
        haskell = import ./nix/lib/haskell;
        weeder = import ./nix/lib/weeder;
      };

      combinedLib = lib.haskell // lib.weeder;
    in
    {
      overlays = {
        default = final: prev: {
          haskell = prev.haskell // {
            lib = prev.haskell.lib
              // builtins.mapAttrs (_k: v: v final) lib.haskell
              // {
              weeder = builtins.mapAttrs (_k: v: v final) lib.weeder;
            };
          };
        };
      } // forAllSystems (_: import ./nix/overlay.nix);

      lib = combinedLib
        // forAllSystems (pkgs: builtins.mapAttrs (_k: v: v pkgs) combinedLib);

      checks = forAllSystems (pkgs: {
        validity = self.lib.makeCheck pkgs {
          name = "validity";
          reportOnly = true;
          packages = [
            "validity"
            # "genvalidity"
          ];
        };
        yesod = self.lib.makeCheck pkgs {
          name = "yesod-weeder";
          reportOnly = true;
          packages = [
            "yesod"
            "yesod-auth"
            "yesod-auth-oauth"
            "yesod-bin"
            "yesod-core"
            "yesod-eventsource"
            "yesod-form"
            "yesod-form-multi"
            "yesod-newsfeed"
            "yesod-persistent"
            "yesod-sitemap"
            "yesod-static"
            "yesod-test"
            "yesod-websockets"
          ];
        };
        pre-commit = pre-commit-hooks.lib.${pkgs.system}.run {
          src = ./.;
          hooks = {
            nixpkgs-fmt.enable = true;
            deadnix.enable = true;
            tagref.enable = true;
          };
        };
      });

      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          name = "weeder-nix-shell";
          buildInputs = with pre-commit-hooks.packages.${pkgs.system}; [
            pkgs.haskellPackages.weeder
            self.formatter.${pkgs.system}
            statix
          ];
          shellHook = self.checks.${pkgs.system}.pre-commit.shellHook;
        };
      });

      formatter = forAllSystems (pkgs: pkgs.nixpkgs-fmt);
    };
}
