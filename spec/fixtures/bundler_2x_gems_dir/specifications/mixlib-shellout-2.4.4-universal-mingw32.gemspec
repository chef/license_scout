# -*- encoding: utf-8 -*-
# stub: mixlib-shellout 2.4.4 universal-mingw32 lib

Gem::Specification.new do |s|
  s.name = "mixlib-shellout".freeze
  s.version = "2.4.4"
  s.platform = "universal-mingw32".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Chef Software Inc.".freeze]
  s.date = "2018-12-12"
  s.description = "Run external commands on Unix or Windows".freeze
  s.email = "info@chef.io".freeze
  s.homepage = "https://github.com/chef/mixlib-shellout".freeze
  s.required_ruby_version = Gem::Requirement.new(">= 2.2".freeze)
  s.rubygems_version = "3.0.3".freeze
  s.summary = "Run external commands on Unix or Windows".freeze

  s.installed_by_version = "3.0.3" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<win32-process>.freeze, ["~> 0.8.2"])
      s.add_runtime_dependency(%q<wmi-lite>.freeze, ["~> 1.0"])
    else
      s.add_dependency(%q<win32-process>.freeze, ["~> 0.8.2"])
      s.add_dependency(%q<wmi-lite>.freeze, ["~> 1.0"])
    end
  else
    s.add_dependency(%q<win32-process>.freeze, ["~> 0.8.2"])
    s.add_dependency(%q<wmi-lite>.freeze, ["~> 1.0"])
  end
end
