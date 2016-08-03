# -*- encoding: utf-8 -*-
# stub: net-ssh 3.2.0 ruby lib

Gem::Specification.new do |s|
  s.name = "net-ssh".freeze
  s.version = "3.2.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Jamis Buck".freeze, "Delano Mandelbaum".freeze, "Mikl\u{f3}s Fazekas".freeze]
  s.cert_chain = ["-----BEGIN CERTIFICATE-----\nMIIDODCCAiCgAwIBAgIBADANBgkqhkiG9w0BAQUFADBCMRAwDgYDVQQDDAduZXQt\nc3NoMRkwFwYKCZImiZPyLGQBGRYJc29sdXRpb3VzMRMwEQYKCZImiZPyLGQBGRYD\nY29tMB4XDTE1MTIwNjIxMDYyNFoXDTE2MTIwNTIxMDYyNFowQjEQMA4GA1UEAwwH\nbmV0LXNzaDEZMBcGCgmSJomT8ixkARkWCXNvbHV0aW91czETMBEGCgmSJomT8ixk\nARkWA2NvbTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAMYnhNtn0f6p\nnTylB8mE8lMdoMLJC8KwpMWsvk73Pe2WVDsH/OSwwwz6oUGk1i70cJyDjIEBNpwT\n88GpVXJSumvqVsf9fCg3mWNeb5t0J+aeNm9MIvYVMTqj5tydoXQiwnILRDYHV9tZ\n1c3o59/VlahSTpZ7YEgzVufpAkvEGkbJiG849exiipK7MN/ZIkMOxYVnyRXk43Xc\n6GYlsHOfSgPwcXwW5g57DCwLQLWrjDsTka28dxDmO7B5Lv5EqzINxVxWsu43OgZG\n21Io/jIyf5PNpeKPKNGDuAQJ8mvdMYBJoDhtCwgsUYbl0BZzA7g4ytl51HtIeP+j\nQp/eAvs/RrECAwEAAaM5MDcwCQYDVR0TBAIwADAdBgNVHQ4EFgQUBfKiwO2eM4NE\niRrVG793qEPLYyMwCwYDVR0PBAQDAgSwMA0GCSqGSIb3DQEBBQUAA4IBAQCfZFdb\np4jzkfIzGDbiOxd0R8sdqJoC4nMLEgnQ7dLulawwA3IXe3sHAKgA5kmH3prsKc5H\nzVmM5NlH2P1nRbegIkQTYiIod1hZQCNxdmVG/fprMqPq0ybpUOjjrP5pj0OtszE1\nF2dQia1hOEstMR+n0nAtWII9HJAEyeZjVV0s2Cl7Pt85XJ3hxFcCKwzqsK5xRI7a\nB3vwh3/JJYrFonIohQ//Lg9qTZASEkoKLlq1/hFeICoCGGIGLq45ZB7CzXLooCKi\ns/ZUKye79ELwFYKJOhjW5g725OL3hy+llhEleytwKRwgXFQBPTC4f5UkdxZVVWGH\ne2C9M1m/2odPZo8h\n-----END CERTIFICATE-----\n".freeze]
  s.date = "2016-06-19"
  s.description = "Net::SSH: a pure-Ruby implementation of the SSH2 client protocol. It allows you to write programs that invoke and interact with processes on remote servers, via SSH2.".freeze
  s.email = "net-ssh@solutious.com".freeze
  s.extra_rdoc_files = ["LICENSE.txt".freeze, "README.rdoc".freeze]
  s.files = ["LICENSE.txt".freeze, "README.rdoc".freeze]
  s.homepage = "https://github.com/net-ssh/net-ssh".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.0".freeze)
  s.rubyforge_project = "net-ssh".freeze
  s.rubygems_version = "2.6.6".freeze
  s.summary = "Net::SSH: a pure-Ruby implementation of the SSH2 client protocol.".freeze

  s.installed_by_version = "2.6.6" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<test-unit>.freeze, [">= 0"])
      s.add_development_dependency(%q<mocha>.freeze, [">= 0"])
    else
      s.add_dependency(%q<test-unit>.freeze, [">= 0"])
      s.add_dependency(%q<mocha>.freeze, [">= 0"])
    end
  else
    s.add_dependency(%q<test-unit>.freeze, [">= 0"])
    s.add_dependency(%q<mocha>.freeze, [">= 0"])
  end
end
