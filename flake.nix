{
  inputs.nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/*";
  inputs.flake-utils.url = "https://flakehub.com/f/numtide/flake-utils/*";

  outputs = { self, ...}@inputs:
    inputs.flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import inputs.nixpkgs { inherit system; };
      in {
        packages = {
          binary = pkgs.buildGoModule {
            name = "mailu-quadlet";
            src = ./.;
            vendorHash = "sha256-oXQ1QFZ383ijYCD/SRFpuBgHThnoxuXg6yQPziQJ4zY=";
          };
          container = pkgs.dockerTools.buildLayeredImage {
            name = "mailu-quadlet";
            tag = "${system}";
            config = {
              Entrypoint = [ "${self.packages.${system}.binary}/bin/cli" ];
              WorkingDir = "/data";
              volumes = {
                "/data" = {};
              };
            };
          };
        };
      }
    );
}
