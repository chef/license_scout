pkg_name=fixture
pkg_origin=chef
pkg_version="0.1.0"
pkg_maintainer="The Habitat Maintainers <humans@habitat.sh>"
pkg_license=("Apache-2.0")
pkg_deps=(
core/node
chef/no-such-package-by-this-name
)
pkg_build_deps=(core/make core/gcc)
