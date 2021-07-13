# -*- encoding: utf-8 -*-
# stub: test-kitchen 3.0.0 ruby lib

Gem::Specification.new do |s|
  s.name = "test-kitchen".freeze
  s.version = "3.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Fletcher Nichol".freeze]
  s.date = "2021-07-02"
  s.description = "Test Kitchen is an integration tool for developing and testing infrastructure code and software on isolated target platforms.".freeze
  s.email = ["fnichol@nichol.ca".freeze]
  s.executables = ["kitchen".freeze]
  s.files = ["bin/kitchen".freeze]
  s.homepage = "https://kitchen.ci/".freeze
  s.licenses = ["Apache-2.0".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.5".freeze)
  s.rubygems_version = "3.1.4".freeze
  s.summary = "Test Kitchen is an integration tool for developing and testing infrastructure code and software on isolated target platforms.".freeze

  s.installed_by_version = "3.1.4" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<mixlib-shellout>.freeze, [">= 1.2", "< 4.0"])
    s.add_runtime_dependency(%q<net-scp>.freeze, [">= 1.1", "< 4.0"])
    s.add_runtime_dependency(%q<net-ssh>.freeze, [">= 2.9", "< 7.0"])
    s.add_runtime_dependency(%q<net-ssh-gateway>.freeze, [">= 1.2", "< 3.0"])
    s.add_runtime_dependency(%q<ed25519>.freeze, ["~> 1.2"])
    s.add_runtime_dependency(%q<bcrypt_pbkdf>.freeze, ["~> 1.0"])
    s.add_runtime_dependency(%q<thor>.freeze, [">= 0.19", "< 2.0"])
    s.add_runtime_dependency(%q<mixlib-install>.freeze, ["~> 3.6"])
    s.add_runtime_dependency(%q<winrm>.freeze, ["~> 2.0"])
    s.add_runtime_dependency(%q<winrm-elevated>.freeze, ["~> 1.0"])
    s.add_runtime_dependency(%q<winrm-fs>.freeze, ["~> 1.1"])
    s.add_runtime_dependency(%q<chef-utils>.freeze, [">= 16.4.35"])
    s.add_runtime_dependency(%q<license-acceptance>.freeze, [">= 1.0.11", "< 3.0"])
    s.add_development_dependency(%q<rb-readline>.freeze, [">= 0"])
    s.add_development_dependency(%q<bundler>.freeze, [">= 0"])
    s.add_development_dependency(%q<rake>.freeze, [">= 0"])
    s.add_development_dependency(%q<aruba>.freeze, ["~> 0.11", "< 1.0"])
    s.add_development_dependency(%q<fakefs>.freeze, ["~> 1.0"])
    s.add_development_dependency(%q<minitest>.freeze, ["~> 5.3", "< 5.15"])
    s.add_development_dependency(%q<mocha>.freeze, ["~> 1.1"])
    s.add_development_dependency(%q<cucumber>.freeze, [">= 2.1", "< 4.0"])
    s.add_development_dependency(%q<countloc>.freeze, ["~> 0.4"])
    s.add_development_dependency(%q<maruku>.freeze, ["~> 0.6"])
  else
    s.add_dependency(%q<mixlib-shellout>.freeze, [">= 1.2", "< 4.0"])
    s.add_dependency(%q<net-scp>.freeze, [">= 1.1", "< 4.0"])
    s.add_dependency(%q<net-ssh>.freeze, [">= 2.9", "< 7.0"])
    s.add_dependency(%q<net-ssh-gateway>.freeze, [">= 1.2", "< 3.0"])
    s.add_dependency(%q<ed25519>.freeze, ["~> 1.2"])
    s.add_dependency(%q<bcrypt_pbkdf>.freeze, ["~> 1.0"])
    s.add_dependency(%q<thor>.freeze, [">= 0.19", "< 2.0"])
    s.add_dependency(%q<mixlib-install>.freeze, ["~> 3.6"])
    s.add_dependency(%q<winrm>.freeze, ["~> 2.0"])
    s.add_dependency(%q<winrm-elevated>.freeze, ["~> 1.0"])
    s.add_dependency(%q<winrm-fs>.freeze, ["~> 1.1"])
    s.add_dependency(%q<chef-utils>.freeze, [">= 16.4.35"])
    s.add_dependency(%q<license-acceptance>.freeze, [">= 1.0.11", "< 3.0"])
    s.add_dependency(%q<rb-readline>.freeze, [">= 0"])
    s.add_dependency(%q<bundler>.freeze, [">= 0"])
    s.add_dependency(%q<rake>.freeze, [">= 0"])
    s.add_dependency(%q<aruba>.freeze, ["~> 0.11", "< 1.0"])
    s.add_dependency(%q<fakefs>.freeze, ["~> 1.0"])
    s.add_dependency(%q<minitest>.freeze, ["~> 5.3", "< 5.15"])
    s.add_dependency(%q<mocha>.freeze, ["~> 1.1"])
    s.add_dependency(%q<cucumber>.freeze, [">= 2.1", "< 4.0"])
    s.add_dependency(%q<countloc>.freeze, ["~> 0.4"])
    s.add_dependency(%q<maruku>.freeze, ["~> 0.6"])
  end
end
