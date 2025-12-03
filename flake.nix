{
  description = "Weeder Nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs?ref=nixos-25.11";
    pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
  };

  outputs = { self, nixpkgs, pre-commit-hooks }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          (import ./nix/overlay.nix)
        ];
        config.allowBroken = true;
      };
    in
    with pkgs.lib;
    {
      overlays.${system} = import ./nix/overlay.nix;
      lib.${system} = pkgs.weeder-nix;
      checks.${system} = {
        validity = self.lib.${system}.makeWeederCheck {
          name = "validity";
          reportOnly = true;
          packages = [
            "validity"
            "genvalidity"
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
      devShells.${system}.default = pkgs.mkShell {
        name = "weeder-nix-shell";
        buildInputs = with pre-commit-hooks.packages.${system};          [
          pkgs.haskellPackages.weeder
          nixpkgs-fmt
          statix
        ];
        shellHook = self.checks.${system}.pre-commit.shellHook;
      };
    };
}
