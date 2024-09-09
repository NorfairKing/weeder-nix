{
  description = "Weeder Nix";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs?ref=nixos-23.11";
    pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
    systems.url = "github:nix-systems/x86_64-linux";
  };

  outputs = { self, flake-utils, nixpkgs, pre-commit-hooks, systems }:
    let
      lib = {
        haskell = import ./nix/lib/haskell;
        weeder = import ./nix/lib/weeder;
      };

    in
    {
      lib = lib.haskell // lib.weeder;

      overlays.default = final: prev: {
        haskell = prev.haskell // {
          lib = prev.haskell.lib
          // builtins.mapAttrs (_k: v: v final) lib.haskell
          //
          {
            weeder = builtins.mapAttrs (_k: v: v final) lib.weeder;
          };
        };
      };
    }
    // flake-utils.lib.eachSystem (import systems) (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        checks = {
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
          pre-commit = pre-commit-hooks.lib.${system}.run {
            src = ./.;
            hooks = {
              nixpkgs-fmt.enable = true;
              deadnix.enable = true;
              tagref.enable = true;
            };
          };
        };

        devShells.default = pkgs.mkShell {
          name = "weeder-nix-shell";
          buildInputs = with pre-commit-hooks.packages.${system}; [
            pkgs.haskellPackages.weeder
            self.formatter.${system}
            statix
          ];
          shellHook = self.checks.${system}.pre-commit.shellHook;
        };

        formatter = pkgs.nixpkgs-fmt;
      });
}
