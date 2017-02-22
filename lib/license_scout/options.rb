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

require "license_scout/overrides"

module LicenseScout
  class Options
    SUPPORTED_OPTIONS = [:overrides, :environment, :ruby_bin, :cpan_cache, :manual_licenses]

    SUPPORTED_OPTIONS.each do |o|
      send(:attr_reader, o)
    end

    def initialize(options = {})
      SUPPORTED_OPTIONS.each do |o|
        data = options[o] || defaults[o]
        instance_variable_set("@#{o}".to_sym, data)
      end
    end

    private

    def defaults
      {
        overrides: Overrides.new,
        environment: {},
        ruby_bin: nil,
        cpan_cache: Dir.tmpdir,
        manual_licenses: nil,
      }
    end
  end
end
