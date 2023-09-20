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

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "license_scout/version"

Gem::Specification.new do |spec|
  spec.name          = "license_scout"
  spec.version       = LicenseScout::VERSION
  spec.authors       = [ "Tom Duffield" ]
  spec.email         = [ "tom@chef.io" ]
  spec.license       = "Apache-2.0"

  spec.summary       = "Discovers license files of a project's dependencies."
  spec.description   = "Discovers license files of a project's dependencies."
  spec.homepage      = "https://github.com/chef/license_scout"

  spec.files         = Dir["LICENSE", "README.md", "{bin,lib}/**/*"]
  spec.bindir        = "bin"
  spec.executables   = %w{license_scout}
  spec.require_paths = %w{lib}

  spec.add_runtime_dependency "ffi-yajl",        "~> 2.2"
  spec.add_runtime_dependency "mixlib-shellout", ">= 2.2", "< 4.0"
  spec.add_runtime_dependency "toml-rb",         ">= 1", "< 3"
  spec.add_runtime_dependency "licensee",        "~> 9.8"
  spec.add_runtime_dependency "mixlib-config",   "~> 3.0", "< 4.0"
  spec.add_runtime_dependency "mixlib-cli"
  spec.add_runtime_dependency "mixlib-log"
  spec.add_runtime_dependency "terminal-table"
  spec.add_runtime_dependency "fuzzy_match"
end
