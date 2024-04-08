{
  description = "Weeder Nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs?ref=nixos-23.11";
    pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
  };

  outputs = { self, nixpkgs, pre-commit-hooks }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
      };
    in
    with pkgs.lib;
    {
      lib.${system} =
        let
          addHieOutput = pkgs.callPackage ./nix/addHieOutput.nix { };
          weederCheckScriptFor = pkgs.callPackage ./nix/weederCheckFor.nix {
            weeder = pkgs.haskellPackages.weeder;
          };
          makeWeederCheck = args@{ packages, ... }:
            weederCheckScriptFor (args // {
              packages = builtins.map addHieOutput packages;
            });
        in
        {
          inherit addHieOutput weederCheckFor makeWeederCheck;
        };
      checks.${system} = {
        yesod = self.lib.${system}.makeWeederCheck {
          name = "yesod-weeder";
          reportOnly = true;
          packages = (with pkgs.haskellPackages; [
            yesod
            yesod-auth
            yesod-auth-oauth
            yesod-bin
            yesod-core
            yesod-eventsource
            yesod-form
            yesod-form-multi
            yesod-newsfeed
            yesod-persistent
            yesod-sitemap
            yesod-static
            yesod-test
            yesod-websockets
          ]);
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
          nixpkgs-fmt
          statix
        ];
        shellHook = self.checks.${system}.pre-commit.shellHook;
      };
    };
}
