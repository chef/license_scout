pkg_name=license_scout
pkg_origin=chef
pkg_version="2.0.5"
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
  core/ruby25
  core/git
  core/curl
  core/coreutils
  core/erlang18/18.3
  core/busybox-static
)

do_unpack() {
  mkdir -pv "$HAB_CACHE_SRC_PATH/$pkg_dirname"
  cp -R "$PLAN_CONTEXT"/../* "$HAB_CACHE_SRC_PATH/$pkg_dirname"
}

do_prepare() {
  build_line "Scoping default paths to Habitat installation"
  sed -i -r "s|^(\s*)default :escript_bin, \".+\"|\1default :escript_bin, \"$(hab pkg path core/erlang18)/bin/escript\"|" "$HAB_CACHE_SRC_PATH/$pkg_dirname/lib/license_scout/config.rb"
  sed -i -r "s|^(\s*)default :ruby_bin, \".+\"|\1default :ruby_bin, \"$(hab pkg path core/ruby25)/bin/ruby\"|" "$HAB_CACHE_SRC_PATH/$pkg_dirname/lib/license_scout/config.rb"
}

do_build() {
  return 0
}

do_install() {
  rm -rf .bundle

  local _bundler_dir=$(pkg_path_for "core/ruby25")/lib/ruby/gems/2.5.0
  local _vendor_dir="$pkg_prefix/vendor/bundle"

  GEM_HOME="${_vendor_dir}/ruby/2.5.0"
  GEM_PATH="${_bundler_dir}:${GEM_HOME}"
  BUNDLE_SILENCE_ROOT_WARNING=1
  # Required to compile libgit2 for rugged gem
  OPENSSL_INCLUDE_DIR="$(pkg_path_for core/openssl)/include"
  OPENSSL_SSL_LIBRARY="$(pkg_path_for core/openssl)/lib/libssl.so"
  OPENSSL_CRYPTO_LIBRARY="$(pkg_path_for core/openssl)/lib/libcrypto.so"
  ZLIB_LIBRARY="$(pkg_path_for core/zlib)/libz.so"

  build_line "Setting GEM_HOME=$GEM_HOME"
  build_line "Setting GEM_PATH=$GEM_PATH"
  build_line "Setting OPENSSL_INCLUDE_DIR=$OPENSSL_INCLUDE_DIR"
  build_line "Setting OPENSSL_SSL_LIBRARY=$OPENSSL_SSL_LIBRARY"
  build_line "Setting OPENSSL_CRYPTO_LIBRARY=$OPENSSL_CRYPTO_LIBRARY"
  build_line "Setting ZLIB_LIBRARY=$ZLIB_LIBRARY"
  build_line "Setting BUNDLE_SILENCE_ROOT_WARNING=$BUNDLE_SILENCE_ROOT_WARNING"

  export GEM_HOME
  export GEM_PATH
  export OPENSSL_INCLUDE_DIR
  export OPENSSL_SSL_LIBRARY
  export OPENSSL_CRYPTO_LIBRARY
  export ZLIB_LIBRARY
  export BUNDLE_SILENCE_ROOT_WARNING

  build_line "Moving License Scout gem into place"
  cp -R "$HAB_CACHE_SRC_PATH/$pkg_dirname/lib" "$pkg_prefix/lib"
  install -m 0644 "$HAB_CACHE_SRC_PATH/$pkg_dirname/Gemfile.lock" "$pkg_prefix/Gemfile.lock"
  install -m 0644 "$HAB_CACHE_SRC_PATH/$pkg_dirname/Gemfile" "$pkg_prefix/Gemfile"
  install -m 0644 "$HAB_CACHE_SRC_PATH/$pkg_dirname/$pkg_name.gemspec" "$pkg_prefix/$pkg_name.gemspec"

  build_line "'bundle install' gem dependencies"
  bundle install \
    --jobs "$(nproc)" \
    --retry 5 \
    --path "${_vendor_dir}" \
    --shebang "$(pkg_path_for "core/ruby25")/bin/ruby" \
    --without development \
    --gemfile "$pkg_prefix/Gemfile" \
    --no-clean

  build_line "Remove all the unnecessary ruby binaries and artifacts"
  rm -rf "$GEM_HOME/cache"

  build_line "Moving License Scout binaries into bin directory"
  install -m 0755 "$HAB_CACHE_SRC_PATH/$pkg_dirname/bin/$pkg_name" "$pkg_prefix/bin/$pkg_name"
  install -m 0755 "$HAB_CACHE_SRC_PATH/$pkg_dirname/bin/gemfile_json" "$pkg_prefix/bin/gemfile_json"
  install -m 0755 "$HAB_CACHE_SRC_PATH/$pkg_dirname/bin/mix_lock_json" "$pkg_prefix/bin/mix_lock_json"
  install -m 0755 "$HAB_CACHE_SRC_PATH/$pkg_dirname/bin/rebar_lock_json" "$pkg_prefix/bin/rebar_lock_json"

  build_line "Ensure license_scout binaries are executable from anywhere"
  fix_interpreter "$pkg_prefix/bin/$pkg_name" core/ruby25 ruby
  wrap_ruby_bin "$pkg_prefix/bin/$pkg_name"

  fix_interpreter "$pkg_prefix/bin/gemfile_json" core/ruby25 ruby
}

wrap_ruby_bin() {
  local bin="$1"
  build_line "Adding wrapper $bin to ${bin}.real"
  mv -v "$bin" "${bin}.real"
  cat <<EOF > "$bin"
#!$(pkg_path_for busybox-static)/bin/sh
set -e
if test -n "$DEBUG"; then set -x; fi

export GEM_HOME="$GEM_HOME"
export GEM_PATH="$GEM_PATH"
unset RUBYOPT GEMRC

exec $(pkg_path_for core/ruby25)/bin/ruby ${bin}.real \$@
EOF
  chmod -v 755 "$bin"
}
