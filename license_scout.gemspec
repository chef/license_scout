#
# Copyright:: Copyright 2016, Chef Software Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "license_scout/version"

Gem::Specification.new do |spec|
  spec.name          = "license_scout"
  spec.version       = LicenseScout::VERSION
  spec.authors       = [ "Serdar Sutay" ]
  spec.email         = [ "serdar@chef.io" ]
  spec.license       = "Apache-2.0"

  spec.summary       = "Discovers license files of a project's dependencies."
  spec.description   = "Discovers license files of a project's dependencies."
  spec.homepage      = "https://github.com/chef/license_scout"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "bin"
  spec.executables   = %w{license_scout}
  spec.require_paths = %w{lib}

  spec.add_dependency "ffi-yajl",         "~> 2.2"
  spec.add_dependency "mixlib-shellout",  "~> 2.2"

  spec.add_development_dependency "bundler", "~> 1.12"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "rb-readline"
end
