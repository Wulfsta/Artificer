{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
  };
  outputs = { 
    self, 
    nixpkgs
  }:
  let
    supportedSystems = [ "x86_64-linux" ];
    forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; });
    pkgs = nixpkgs.legacyPackages.system;
  in 
  {
    packages = forAllSystems (system:
      let
        pkgs = nixpkgsFor.${system};
      in
      {
        slvs = pkgs.stdenv.mkDerivation {
          pname = "slvs";
          version = "2.4.2";

          src = pkgs.fetchFromGitHub {
            owner = "realthunder";
            repo = "solvespace";
            rev = "526a260b0c45586c0319de208fd7e97c43c49bf4";
            hash = "sha256-gLdp+I/axD17ZL8HaRYAEkq3tm8fYNaMGFTaAYharuE=";
            fetchSubmodules = true;
          };

          preConfigure = ''
            sed '/#include <limits.h>/a #include <limits>' -i src/solvespace.h
          '';

          nativeBuildInputs = with pkgs; [
            cmake
            pkg-config
          ];

          buildInputs = with pkgs; [
            util-linux
            pcre
            fontconfig
            freetype
            glew
            gtkmm2
            json_c
            libGL
            libGLU
            libpng12
            libspnav
            pangomm
          ];
        };
        py-slvs = pkgs.python3Packages.buildPythonPackage {
          pname = "py-slvs";
          version = "1.0.4";

          src = pkgs.fetchFromGitHub {
            owner = "realthunder";
            repo = "slvs_py";
            rev = "c94979b0204a63f26683c45ede1136a2a99cb365";
            hash = "sha256-bOdTmSMAA0QIRlcIQHkrnDH2jGjGJqs2i5Xaxu2STMU=";
            fetchSubmodules = true;
          };

          nativeBuildInputs = with pkgs; [
            cmake
          ];

          buildInputs = [ 
            self.packages.${system}.slvs
            pkgs.swig4
            pkgs.python3Packages.pivy
            pkgs.python3Packages.scikit-build
          ];

          doCheck = false;

          dontUseCmakeConfigure = true;
        };
        freecad = pkgs.freecad.overrideDerivation (old: {
          src = pkgs.fetchFromGitHub {
            owner = "realthunder";
            repo = "FreeCAD";
            rev = "2022.10.21-2-edge";
            hash = "sha256-KnU4IqyeOIE+BUm0CJRWXoqcuhKS7DOqpLIbYwc3EYY=";
          };

          buildInputs = old.buildInputs ++ [ self.packages.${system}.py-slvs ];
        });
      }
    );
    apps = forAllSystems (system: {
      freecad = {
        type = "app";
        program = "${self.packages.${system}.freecad}/bin/freecad";
      };
    });
  };
}
