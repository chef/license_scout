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

require "license_scout/dependency_manager/bundler"
require "license_scout/dependency_manager/rebar"
require "license_scout/dependency_manager/cpanm"
require "license_scout/dependency_manager/godep"
require "license_scout/dependency_manager/berkshelf"
require "license_scout/dependency_manager/npm"
require "license_scout/dependency_manager/manual"

module LicenseScout
  module DependencyManager
    def self.implementations
      [Bundler, Rebar, Cpanm, Berkshelf, NPM, Godep, Manual]
    end
  end
end
