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
          login = pkgs.writeShellScriptBin "login"
          ''
            ${pkgs.buildah}/bin/buildah login ghcr.io
          '';
          build = pkgs.writeShellScriptBin "build"
          ''
            TIMESTAMP=$(${pkgs.coreutils}/bin/date -I)
            nix build .#packages.aarch64-linux.container --out-link "result-arm64-$TIMESTAMP"
            nix build .#packages.x86_64-linux.container --out-link "result-amd64-$TIMESTAMP"
          '';
          publish = pkgs.writeShellScriptBin "publish"
          ''
            TIMESTAMP=$(${pkgs.coreutils}/bin/date -I)
            ${pkgs.buildah}/bin/buildah manifest exists ghcr.io/cyberworm-uk/mailu-quadlet:"$TIMESTAMP" && \
              ${pkgs.buildah}/bin/buildah manifest rm ghcr.io/cyberworm-uk/mailu-quadlet:"$TIMESTAMP"
              ${pkgs.podman}/bin/podman load -i "result-arm64-$TIMESTAMP" && \
                ${pkgs.podman}/bin/podman load -i "result-amd64-$TIMESTAMP" && \
              ${pkgs.buildah}/bin/buildah manifest create ghcr.io/cyberworm-uk/mailu-quadlet:"$TIMESTAMP" && \
                ${pkgs.buildah}/bin/buildah manifest add ghcr.io/cyberworm-uk/mailu-quadlet:"$TIMESTAMP" localhost/mailu-quadlet:aarch64-linux && \
                ${pkgs.buildah}/bin/buildah manifest add ghcr.io/cyberworm-uk/mailu-quadlet:"$TIMESTAMP" localhost/mailu-quadlet:x86_64-linux && \
              ${pkgs.buildah}/bin/buildah manifest push --all ghcr.io/cyberworm-uk/mailu-quadlet:"$TIMESTAMP" docker://ghcr.io/cyberworm-uk/mailu-quadlet:"$TIMESTAMP" && \
                ${pkgs.buildah}/bin/buildah manifest push --all ghcr.io/cyberworm-uk/mailu-quadlet:"$TIMESTAMP" docker://ghcr.io/cyberworm-uk/mailu-quadlet:latest
          '';
        };
        devShells.default = pkgs.mkShell {
          packages = [
            pkgs.go
            pkgs.gopls
          ];
        };
      }
    );
}
