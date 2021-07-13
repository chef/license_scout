# -*- encoding: utf-8 -*-
# stub: mixlib-install 3.12.11 ruby lib

Gem::Specification.new do |s|
  s.name = "mixlib-install".freeze
  s.version = "3.12.11"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Thom May".freeze, "Patrick Wright".freeze]
  s.date = "2021-03-17"
  s.email = ["thom@chef.io".freeze, "patrick@chef.io".freeze]
  s.executables = ["mixlib-install".freeze]
  s.files = ["bin/mixlib-install".freeze]
  s.homepage = "https://github.com/chef/mixlib-install".freeze
  s.licenses = ["Apache-2.0".freeze]
  s.rubygems_version = "3.1.4".freeze
  s.summary = "A library for interacting with Chef Software Inc's software distribution systems.".freeze

  s.installed_by_version = "3.1.4" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<mixlib-shellout>.freeze, [">= 0"])
    s.add_runtime_dependency(%q<mixlib-versioning>.freeze, [">= 0"])
    s.add_runtime_dependency(%q<thor>.freeze, [">= 0"])
  else
    s.add_dependency(%q<mixlib-shellout>.freeze, [">= 0"])
    s.add_dependency(%q<mixlib-versioning>.freeze, [">= 0"])
    s.add_dependency(%q<thor>.freeze, [">= 0"])
  end
end
