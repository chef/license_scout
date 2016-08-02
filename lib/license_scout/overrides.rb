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

module LicenseScout
  class Overrides

    attr_reader :override_rules

    def initialize(&rules)
      @override_rules = {}
      instance_eval(&rules) if block_given?
    end

    def override_license(dependency_manager, dependency_name, &rule)
      override_rules[dependency_manager] ||= {}
      override_rules[dependency_manager][dependency_name] = rule
    end

    def license_for(dependency_manager, dependency_name, dependency_version)
      license_data = license_data_for(dependency_manager, dependency_name, dependency_version)
      license_data && license_data[:license]
    end

    def license_files_for(dependency_manager, dependency_name, dependency_version)
      license_data = license_data_for(dependency_manager, dependency_name, dependency_version)
      license_data.nil? ? [] : license_data[:license_files]
    end

    private

    def license_data_for(dependency_manager, dependency_name, dependency_version)
      return nil unless override_rules.key?(dependency_manager) &&
       override_rules[dependency_manager].key?(dependency_name)
      override_rules[dependency_manager][dependency_name].call(dependency_version)
    end
  end
end
