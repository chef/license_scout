# -*- encoding: utf-8 -*-
# stub: test-kitchen 1.10.2 ruby lib

Gem::Specification.new do |s|
  s.name = "test-kitchen".freeze
  s.version = "1.10.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Fletcher Nichol".freeze]
  s.date = "2016-06-24"
  s.description = "Test Kitchen is an integration tool for developing and testing infrastructure code and software on isolated target platforms.".freeze
  s.email = ["fnichol@nichol.ca".freeze]
  s.executables = ["kitchen".freeze]
  s.files = ["bin/kitchen".freeze]
  s.homepage = "http://kitchen.ci".freeze
  s.licenses = ["Apache 2.0".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 1.9.1".freeze)
  s.rubygems_version = "2.6.6".freeze
  s.summary = "Test Kitchen is an integration tool for developing and testing infrastructure code and software on isolated target platforms.".freeze

  s.installed_by_version = "2.6.6" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<mixlib-shellout>.freeze, ["< 3.0", ">= 1.2"])
      s.add_runtime_dependency(%q<net-scp>.freeze, ["~> 1.1"])
      s.add_runtime_dependency(%q<net-ssh>.freeze, ["< 4.0", ">= 2.9"])
      s.add_runtime_dependency(%q<safe_yaml>.freeze, ["~> 1.0"])
      s.add_runtime_dependency(%q<thor>.freeze, ["~> 0.18"])
      s.add_runtime_dependency(%q<mixlib-install>.freeze, [">= 1.0.4", "~> 1.0"])
      s.add_development_dependency(%q<pry>.freeze, [">= 0"])
      s.add_development_dependency(%q<pry-byebug>.freeze, [">= 0"])
      s.add_development_dependency(%q<pry-stack_explorer>.freeze, [">= 0"])
      s.add_development_dependency(%q<rb-readline>.freeze, [">= 0"])
      s.add_development_dependency(%q<overcommit>.freeze, ["= 0.33.0"])
      s.add_development_dependency(%q<winrm>.freeze, ["~> 1.6"])
      s.add_development_dependency(%q<winrm-elevated>.freeze, ["~> 0.4.0"])
      s.add_development_dependency(%q<winrm-fs>.freeze, ["~> 0.4.1"])
      s.add_development_dependency(%q<bundler>.freeze, ["~> 1.3"])
      s.add_development_dependency(%q<rake>.freeze, ["~> 10.0"])
      s.add_development_dependency(%q<github_changelog_generator>.freeze, ["= 1.11.3"])
      s.add_development_dependency(%q<aruba>.freeze, ["~> 0.11"])
      s.add_development_dependency(%q<fakefs>.freeze, ["~> 0.4"])
      s.add_development_dependency(%q<minitest>.freeze, ["~> 5.3"])
      s.add_development_dependency(%q<mocha>.freeze, ["~> 1.1"])
      s.add_development_dependency(%q<cucumber>.freeze, ["~> 2.1"])
      s.add_development_dependency(%q<countloc>.freeze, ["~> 0.4"])
      s.add_development_dependency(%q<maruku>.freeze, ["~> 0.6"])
      s.add_development_dependency(%q<simplecov>.freeze, ["~> 0.7"])
      s.add_development_dependency(%q<yard>.freeze, ["~> 0.8"])
      s.add_development_dependency(%q<finstyle>.freeze, ["= 1.5.0"])
      s.add_development_dependency(%q<cane>.freeze, ["= 2.6.2"])
    else
      s.add_dependency(%q<mixlib-shellout>.freeze, ["< 3.0", ">= 1.2"])
      s.add_dependency(%q<net-scp>.freeze, ["~> 1.1"])
      s.add_dependency(%q<net-ssh>.freeze, ["< 4.0", ">= 2.9"])
      s.add_dependency(%q<safe_yaml>.freeze, ["~> 1.0"])
      s.add_dependency(%q<thor>.freeze, ["~> 0.18"])
      s.add_dependency(%q<mixlib-install>.freeze, [">= 1.0.4", "~> 1.0"])
      s.add_dependency(%q<pry>.freeze, [">= 0"])
      s.add_dependency(%q<pry-byebug>.freeze, [">= 0"])
      s.add_dependency(%q<pry-stack_explorer>.freeze, [">= 0"])
      s.add_dependency(%q<rb-readline>.freeze, [">= 0"])
      s.add_dependency(%q<overcommit>.freeze, ["= 0.33.0"])
      s.add_dependency(%q<winrm>.freeze, ["~> 1.6"])
      s.add_dependency(%q<winrm-elevated>.freeze, ["~> 0.4.0"])
      s.add_dependency(%q<winrm-fs>.freeze, ["~> 0.4.1"])
      s.add_dependency(%q<bundler>.freeze, ["~> 1.3"])
      s.add_dependency(%q<rake>.freeze, ["~> 10.0"])
      s.add_dependency(%q<github_changelog_generator>.freeze, ["= 1.11.3"])
      s.add_dependency(%q<aruba>.freeze, ["~> 0.11"])
      s.add_dependency(%q<fakefs>.freeze, ["~> 0.4"])
      s.add_dependency(%q<minitest>.freeze, ["~> 5.3"])
      s.add_dependency(%q<mocha>.freeze, ["~> 1.1"])
      s.add_dependency(%q<cucumber>.freeze, ["~> 2.1"])
      s.add_dependency(%q<countloc>.freeze, ["~> 0.4"])
      s.add_dependency(%q<maruku>.freeze, ["~> 0.6"])
      s.add_dependency(%q<simplecov>.freeze, ["~> 0.7"])
      s.add_dependency(%q<yard>.freeze, ["~> 0.8"])
      s.add_dependency(%q<finstyle>.freeze, ["= 1.5.0"])
      s.add_dependency(%q<cane>.freeze, ["= 2.6.2"])
    end
  else
    s.add_dependency(%q<mixlib-shellout>.freeze, ["< 3.0", ">= 1.2"])
    s.add_dependency(%q<net-scp>.freeze, ["~> 1.1"])
    s.add_dependency(%q<net-ssh>.freeze, ["< 4.0", ">= 2.9"])
    s.add_dependency(%q<safe_yaml>.freeze, ["~> 1.0"])
    s.add_dependency(%q<thor>.freeze, ["~> 0.18"])
    s.add_dependency(%q<mixlib-install>.freeze, [">= 1.0.4", "~> 1.0"])
    s.add_dependency(%q<pry>.freeze, [">= 0"])
    s.add_dependency(%q<pry-byebug>.freeze, [">= 0"])
    s.add_dependency(%q<pry-stack_explorer>.freeze, [">= 0"])
    s.add_dependency(%q<rb-readline>.freeze, [">= 0"])
    s.add_dependency(%q<overcommit>.freeze, ["= 0.33.0"])
    s.add_dependency(%q<winrm>.freeze, ["~> 1.6"])
    s.add_dependency(%q<winrm-elevated>.freeze, ["~> 0.4.0"])
    s.add_dependency(%q<winrm-fs>.freeze, ["~> 0.4.1"])
    s.add_dependency(%q<bundler>.freeze, ["~> 1.3"])
    s.add_dependency(%q<rake>.freeze, ["~> 10.0"])
    s.add_dependency(%q<github_changelog_generator>.freeze, ["= 1.11.3"])
    s.add_dependency(%q<aruba>.freeze, ["~> 0.11"])
    s.add_dependency(%q<fakefs>.freeze, ["~> 0.4"])
    s.add_dependency(%q<minitest>.freeze, ["~> 5.3"])
    s.add_dependency(%q<mocha>.freeze, ["~> 1.1"])
    s.add_dependency(%q<cucumber>.freeze, ["~> 2.1"])
    s.add_dependency(%q<countloc>.freeze, ["~> 0.4"])
    s.add_dependency(%q<maruku>.freeze, ["~> 0.6"])
    s.add_dependency(%q<simplecov>.freeze, ["~> 0.7"])
    s.add_dependency(%q<yard>.freeze, ["~> 0.8"])
    s.add_dependency(%q<finstyle>.freeze, ["= 1.5.0"])
    s.add_dependency(%q<cane>.freeze, ["= 2.6.2"])
  end
end
