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

require "license_scout/dependency_manager/base"
require "license_scout/dependency"
require "license_scout/overrides"

module LicenseScout
  module DependencyManager
    class Manual < Base
      def name
        "manual"
      end

      def detected?
        !options.manual_licenses.nil?
      end

      def dependencies
        validate_input!

        options.manual_licenses.map do |d|
          create_dependency(
            d[:name],
            d[:version],
            d[:license],
            resolve_license_file_locations(d[:license_files]),
            d[:dependency_manager]
          )
        end
      end

      def resolve_license_file_locations(license_files)
        LicenseScout::Overrides::OverrideLicenseSet.new(license_files)
          .resolve_locations(project_dir)
      end

      def validate_input!
        if !options.manual_licenses.is_a?(Array)
          raise LicenseScout::Exceptions::InvalidManualDependency.new("Invalid manual dependency is specified. :manual_licenses should be an Array in options.")
        end

        options.manual_licenses.each do |l|
          l.keys.each do |k|
            if ![:name, :version, :license, :license_files, :dependency_manager].include?(k)
              raise LicenseScout::Exceptions::InvalidManualDependency.new("Invalid manual dependency is specified. Key '#{k}' is not supported.")
            end
          end
        end
      end
    end
  end
end
