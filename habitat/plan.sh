pkg_name=license_scout
pkg_origin=chef
pkg_version="2.6.11"
pkg_license=("Apache-2.0")
pkg_maintainer="Chef Release Engineering <releng@chef.io>"
pkg_upstream_url="https://github.com/chef/license_scout"
pkg_description="Discovers license files of a project's dependencies."
pkg_bin_dirs=(bin)

pkg_build_deps=(
  core/make
  core/cmake
  core/gcc
  core/pkg-config
  core/sed
)

pkg_deps=(
  core/openssl
  core/zlib
  core/ruby26
  core/git
  core/curl
  core/coreutils
  core/erlang20/20.3.8.26
  core/busybox-static
)

do_unpack() {
  mkdir -pv "$HAB_CACHE_SRC_PATH/$pkg_dirname"
  cp -R "$PLAN_CONTEXT"/../* "$HAB_CACHE_SRC_PATH/$pkg_dirname"
}

do_prepare() {
  build_line "Scoping default paths to Habitat installation"
  sed -i -r "s|^(\s*)default :escript_bin, \".+\"|\1default :escript_bin, \"$(hab pkg path core/erlang20)/bin/escript\"|" "$HAB_CACHE_SRC_PATH/$pkg_dirname/lib/license_scout/config.rb"
  sed -i -r "s|^(\s*)default :ruby_bin, \".+\"|\1default :ruby_bin, \"$(hab pkg path core/ruby26)/bin/ruby\"|" "$HAB_CACHE_SRC_PATH/$pkg_dirname/lib/license_scout/config.rb"

  local _ruby_gems=$(pkg_path_for "core/ruby26")/lib/ruby/gems/2.6.0
  local _pkg_gems="$pkg_prefix/lib"

  export GEM_HOME="${_pkg_gems}/ruby/2.6.0"
  build_line "Setting GEM_HOME=$GEM_HOME"

  export GEM_PATH="${_ruby_gems}:${GEM_HOME}"
  build_line "Setting GEM_PATH=$GEM_PATH"

  build_line "Setting environment variables required to compile libgit2 for rugged gem"

  export OPENSSL_INCLUDE_DIR="$(pkg_path_for core/openssl)/include"
  build_line "Setting OPENSSL_INCLUDE_DIR=$OPENSSL_INCLUDE_DIR"

  export OPENSSL_SSL_LIBRARY="$(pkg_path_for core/openssl)/lib/libssl.so"
  build_line "Setting OPENSSL_SSL_LIBRARY=$OPENSSL_SSL_LIBRARY"

  export OPENSSL_CRYPTO_LIBRARY="$(pkg_path_for core/openssl)/lib/libcrypto.so"
  build_line "Setting OPENSSL_CRYPTO_LIBRARY=$OPENSSL_CRYPTO_LIBRARY"

  export ZLIB_LIBRARY="$(pkg_path_for core/zlib)/libz.so"
  build_line "Setting ZLIB_LIBRARY=$ZLIB_LIBRARY"
}

do_build() {
  build_line "Build License Scout"
  pushd "$HAB_CACHE_SRC_PATH/$pkg_dirname"
    gem build "$pkg_name.gemspec"
  popd
}

do_install() {
  build_line "Install License Scout"
  pushd "$HAB_CACHE_SRC_PATH/$pkg_dirname"
    gem install "$pkg_name-$pkg_version.gem" --no-document
    gem install berkshelf --no-document
  popd

  build_line "Remove all the unnecessary ruby binaries and artifacts"
  rm -rf "$GEM_HOME/cache"

  build_line "Moving native parsing binaries into bin directory"
  install -m 0755 "$HAB_CACHE_SRC_PATH/$pkg_dirname/bin/gemfile_json" "$pkg_prefix/bin/gemfile_json"
  install -m 0755 "$HAB_CACHE_SRC_PATH/$pkg_dirname/bin/mix_lock_json" "$pkg_prefix/bin/mix_lock_json"
  install -m 0755 "$HAB_CACHE_SRC_PATH/$pkg_dirname/bin/rebar_lock_json" "$pkg_prefix/bin/rebar_lock_json"

  build_line "Ensure license_scout binaries are executable from anywhere"
  wrap_license_scout_bin

  fix_interpreter "$pkg_prefix/bin/gemfile_json" core/ruby26 ruby
}

wrap_license_scout_bin() {
  local wrap_bin="$pkg_prefix/bin/$pkg_name"
  local real_bin="$GEM_HOME/gems/$pkg_name-$pkg_version/bin/$pkg_name"

  build_line "Adding wrapper $wrap_bin to $real_bin"
  cat <<EOF > "$wrap_bin"
#!$(pkg_path_for busybox-static)/bin/sh
set -e
if test -n "$DEBUG"; then set -x; fi

export GEM_HOME="$GEM_HOME"
export GEM_PATH="$GEM_PATH"
unset RUBYOPT GEMRC

exec $(pkg_path_for core/ruby26)/bin/ruby $real_bin \$@
EOF
  chmod -v 755 "$wrap_bin"
}
