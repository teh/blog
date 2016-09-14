{ stdenv, nodejs-6_x, zopfli, git, lib }:
let
  #  Notes:
  #  * This still caches in HOME, can't find out how to disable so we
  #    store in a temporary directory which is cleaned up after the build.
  #  * This connects NPM to the internet which is sad but
  #    packaging NPM for nix is even sadder :(
  node_modules = stdenv.mkDerivation {
    name = "node_modules";
    src = builtins.filterSource (path: type: baseNameOf path == "package.json") ./.;
    phases = "unpackPhase installPhase";
    buildInputs = [ nodejs-6_x git ];
    installPhase = ''
      mkdir ./npm-home
      mkdir -p $out
      export HOME=$(readlink -f ./npm-home)  # For .npm/cache. Will be discarded.
      cp ./package.json $out/
      cd $out
      npm install
  '';
  };
in stdenv.mkDerivation {
  name = "theshortlog";
  phases = "unpackPhase buildPhase installPhase";
  buildInputs = [ nodejs-6_x zopfli node_modules ];

  src = builtins.filterSource (path: type: (builtins.baseNameOf path != "node_modules")) ./.;

  buildPhase = ''
    rm -rf public
    ln -s ${node_modules}/node_modules node_modules
    ${node_modules}/node_modules/.bin/hexo generate
  '';

  installPhase = ''
    mkdir -p $out
    cp -r public/* $out/
  '';
}
