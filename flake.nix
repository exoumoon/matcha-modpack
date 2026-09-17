{
  description = "";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    invar = {
      url = "github:exoumoon/invar";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self, ... }@inputs:
    let
      supportedSystems = [ "x86_64-linux" ];

      forEachSupportedSystem =
        fn:
        inputs.nixpkgs.lib.genAttrs supportedSystems (
          system:
          fn {
            inherit system;
            pkgs = import inputs.nixpkgs {
              inherit system;
              config.allowUnfree = true;
            };
          }
        );
    in
    {
      devShells = forEachSupportedSystem (
        { pkgs, system }:
        {
          default = pkgs.mkShell rec {
            buildInputs = with pkgs; [
              # HACK: `invar` can't find `libssl.so.3` for some reason :D
              pkg-config
              openssl
              inputs.invar.packages.${system}.default

              (pkgs.writeShellScriptBin "start-server" ''
                set -e

                docker compose down
                invar pack export
                # docker compose up -d
                # docker compose logs -f --no-log-prefix
                docker compose up --no-log-prefix
              '')
            ];

            LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath buildInputs;
          };
        }
      );

      formatter = forEachSupportedSystem ({ pkgs, ... }: pkgs.nixfmt-tree);
    };
}
