let
  rev = "0b97a9c4755ee71e64bac9408c766f13a930999a";
  pkgs = builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/${rev}.tar.gz";
    sha256 = "030knsmkqy7fhpi8dsxhm76lvhak551bvzicgsnjidhwv063bw32";
  };
  nixpkgs = import pkgs {
    config = {
      packageOverrides = pkgs_: with pkgs_; {
        haskell = haskell // {
          packages = haskell.packages // {
            ghc861-profiling = haskell.packages.ghc861.override {
              overrides = self: super: {
                mkDerivation = args: super.mkDerivation (args // {
                  enableLibraryProfiling = true;
                });
              };
            };
            ghc861 = haskell.packages.ghc861.override {
              overrides = self: super: {
                io-capture = haskell.lib.overrideCabal super.io-capture (old: rec {
                  doCheck = false;
                });
              };
            };
          };
        };
      };
    };
  };
in { compiler ? "ghc861", ci ? false }:

let
  inherit (nixpkgs) pkgs haskell;

  f = { mkDerivation, stdenv
      , mtl
      , base
      , hlint
      , parsec
      , containers
      , haskeline
      }:
      let hlint' = haskell.lib.dontCheck hlint;
      in mkDerivation rec {
        pname = "amuletml";
        version = "0.1.0.0";
        src = if pkgs.lib.inNixShell then null else ./.;

        isLibrary = false;
        isExecutable = true;

        executableHaskellDepends = [
          mtl base hlint parsec containers haskeline
        ];

        buildDepends = [ pkgs.cabal-install hlint' ];

        homepage = "https://hydraz.semi.works/posts/2019-01-28.html";
        description = "MLΔ";
        license = stdenv.lib.licenses.bsd3;
      };

  haskellPackages = pkgs.haskell.packages.${compiler};

  drv = haskellPackages.callPackage f {};

in
  if pkgs.lib.inNixShell then drv.env else drv
