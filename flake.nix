{
  description = "Weeder Nix";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs?ref=nixos-23.11";
    pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
    systems.url = "github:nix-systems/default";
  };

  outputs = { self, flake-utils, nixpkgs, pre-commit-hooks, systems }:
    flake-utils.lib.eachSystem (import systems) (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            (import ./nix/overlay.nix)
          ];
        };
      in
      with pkgs.lib;
      {
        overlays = import ./nix/overlay.nix;
        lib = pkgs.weeder-nix;
        checks = {
          validity = self.lib.${system}.makeWeederCheck {
            name = "validity";
            reportOnly = true;
            packages = [
              "validity"
              # "genvalidity"
            ];
          };
          yesod = self.lib.${system}.makeWeederCheck {
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
