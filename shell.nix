{ pkgs ? import ./pkgs.nix {}, ci ? false }:

with pkgs;
mkShell {
  nativeBuildInputs = [
    ruby.devEnv
    git
    pkg-config
    bundix
    jq
    websocat
  ];
  # Don't set rpath for native addons
  NIX_DONT_SET_RPATH = true;
  NIX_NO_SELF_RPATH = true;
  shellHook = ''
    set -o allexport
    . ./.env
    set +o allexport
    set -v
    ${
      lib.optionalString ci
      ''
      set -o errexit
      set -o nounset
      set -o pipefail
      shopt -s inherit_errexit
      ''
    }
    mkdir --parents "$(pwd)/tmp"

    export BUNDLE_PATH=vendor
    export BUNDLE_CACHE_ALL=true
    export BUNDLE_NO_INSTALL=true
    export BUNDLE_FORCE_RUBY_PLATFORM=true

    alias jekyll='bundler exec jekyll'

    set +v
  '';
}
