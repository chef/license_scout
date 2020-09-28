#
# Copyright:: Copyright 2016-2020, Chef Software Inc.
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

lib = File.expand_path("lib", __dir__)
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

  spec.files         = Dir["LICENSE", "{bin,erl_src,lib}/**/*"]
  spec.bindir        = "bin"
  spec.executables   = %w{license_scout}
  spec.require_paths = %w{lib}

  spec.required_ruby_version = ">= 2.3"

  spec.add_dependency "ffi-yajl",         "~> 2.2"
  spec.add_dependency "mixlib-shellout",  ">= 2.2", "< 4.0"
  spec.add_dependency "toml-rb",  ">= 1", "< 3"

  spec.add_development_dependency "rake", ">= 10.0", "< 14"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "rb-readline"
  spec.add_development_dependency "chefstyle"

  # We do not have berkshelf as a dependency because some of its dependencies
  # can not be installed on uncommon platforms like Solaris which we need to
  # support. If a project needs to collect license information for a berkshelf
  # project it needs to include it seperately in its gem bundle. We have a nice
  # error message when they do not. But we add berkshelf as a development
  # dependency so that we can run our tests.
  spec.add_development_dependency "berkshelf", "~> 4.3"
end
