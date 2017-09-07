pkg_name=license_scout
pkg_origin=chef
pkg_version="0.1.2"
pkg_maintainer="The Chef Maintainers <humans@chef.io>"
pkg_license=('Apache-2.0')
pkg_source="nosuchfile.tar.gz"
pkg_shasum="no_such_sha"
pkg_deps=(core/ruby core/coreutils)
pkg_build_deps=(core/bundler core/git core/gcc core/make)
pkg_lib_dirs=(lib)
pkg_bin_dirs=(bin)
pkg_description="LicenseScout discovers and collects the licenses of a project and its dependencies, including transitive dependencies."
pkg_upstream_url="https://github.com/chef/license_scout"

do_download() {
  return 0
}

do_verify() {
  return 0
}

do_unpack() {
  mkdir -pv "$HAB_CACHE_SRC_PATH/$pkg_dirname"
  cp -R "$PLAN_CONTEXT"/../* "$HAB_CACHE_SRC_PATH/$pkg_dirname"
}

do_prepare() {
  export BUNDLE_SILENCE_ROOT_WARNING=1 GEM_PATH
  build_line "Setting BUNDLE_SILENCE_ROOT_WARNING=$BUNDLE_SILENCE_ROOT_WARNING"
  GEM_PATH="$(pkg_path_for core/bundler)"
  build_line "Setting GEM_PATH=$GEM_PATH"
}

do_build() {
  return 0
}

do_install() {
  bundle install \
    --jobs "$(nproc)" \
    --path "$pkg_prefix/lib" \
    --retry 5 \
    --standalone \
    --frozen \
    --without development test

  cp -R lib/* "$pkg_prefix/lib"
  install -m 0755 bin/$pkg_name "$pkg_prefix/bin/$pkg_name"
  install -m 0755 bin/config_to_json "$pkg_prefix/bin/config_to_json"
  install -m 0644 Gemfile.lock "$pkg_prefix/Gemfile.lock"
  install -m 0644 Gemfile.lock "$pkg_prefix/license_scout.gemspec"
  fix_interpreter "$pkg_prefix/bin/$pkg_name" core/coreutils bin/env
}
