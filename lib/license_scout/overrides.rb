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

require "license_scout/net_fetcher"

require "pathname"

module LicenseScout
  class Overrides

    class OverrideLicenseSet

      attr_reader :license_locations

      def initialize(license_locations)
        @license_locations = license_locations || []
      end

      def empty?
        license_locations.empty?
      end

      def resolve_locations(dependency_root_dir)
        license_locations.map do |license_location|
          if NetFetcher.remote?(license_location)
            NetFetcher.cache(license_location)
          else
            normalize_and_verify_path(license_location, dependency_root_dir)
          end
        end
      end

      def normalize_and_verify_path(license_location, dependency_root_dir)
        full_path = File.expand_path(license_location, dependency_root_dir)
        if File.exists?(full_path)
          full_path
        else
          raise Exceptions::InvalidOverride, "Provided license file path '#{license_location}' can not be found under detected dependency path '#{dependency_root_dir}'."
        end
      end

    end

    attr_reader :override_rules

    def initialize(&rules)
      @override_rules = {}
      instance_eval(&rules) if block_given?

      default_overrides
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
      OverrideLicenseSet.new(license_data && license_data[:license_files])
    end

    def have_override_for?(dependency_manager, dependency_name, dependency_version)
      override_rules.key?(dependency_manager) && override_rules[dependency_manager].key?(dependency_name)
    end

    private

    def license_data_for(dependency_manager, dependency_name, dependency_version)
      return nil unless have_override_for?(dependency_manager, dependency_name, dependency_version)
      override_rules[dependency_manager][dependency_name].call(dependency_version)
    end

    def default_overrides
      # Default overrides for ruby_bundler dependency manager.
      [
        ["debug_inspector", "MIT", ["README.md"]],
        ["inifile", "MIT", ["README.md"]],
        ["syslog-logger", "MIT", ["README.rdoc"]],
        ["httpclient", "Ruby", ["README.md"]],
        ["little-plugger", "MIT", ["README.rdoc"]],
        ["logging", "MIT", ["README.md"]],
        ["coderay", nil, ["README_INDEX.rdoc"]],
        ["multipart-post", "MIT", ["README.md"]],
        ["erubis", "MIT", nil],
        ["binding_of_caller", "MIT", nil],
        ["method_source", "MIT", nil],
        ["pry-remote", "MIT", nil],
        ["pry-stack_explorer", "MIT", nil],
        ["plist", "MIT", nil],
        ["proxifier", "MIT", nil],
        ["mixlib-shellout", "Apache-2.0", nil],
        ["mixlib-log", "Apache-2.0", nil],
        ["uuidtools", "Apache-2.0", nil],
        ["cheffish", "Apache-2.0", nil],
        ["chef-provisioning", "Apache-2.0", nil],
        ["chef-provisioning-aws", "Apache-2.0", nil],
        ["chef-rewind", "MIT", nil],
        ["ubuntu_ami", "Apache-2.0", nil],
        ["net-telnet", "Ruby", nil],
        # Overrides that require file fetching from internet
        ["sfl", "Ruby", ["https://raw.githubusercontent.com/ujihisa/spawn-for-legacy/master/LICENCE.md"]],
        ["json_pure", nil, ["https://raw.githubusercontent.com/flori/json/master/README.md"]],
        ["aws-sdk-core", nil, ["https://raw.githubusercontent.com/aws/aws-sdk-ruby/master/README.md"]],
        ["aws-sdk-resources", nil, ["https://raw.githubusercontent.com/aws/aws-sdk-ruby/master/README.md"]],
        ["aws-sdk", nil, ["https://raw.githubusercontent.com/aws/aws-sdk-ruby/master/README.md"]],
        ["fuzzyurl", nil, ["https://raw.githubusercontent.com/gamache/fuzzyurl/master/LICENSE.txt"]],
        ["jwt", nil, ["https://github.com/jwt/ruby-jwt/blob/master/LICENSE"]],
        ["win32-process", nil, ["http://www.perlfoundation.org/attachment/legal/artistic-2_0.txt"]],
        ["win32-api", nil, ["http://www.perlfoundation.org/attachment/legal/artistic-2_0.txt"]],
        ["win32-dir", nil, ["http://www.perlfoundation.org/attachment/legal/artistic-2_0.txt"]],
        ["win32-ipc", nil, ["http://www.perlfoundation.org/attachment/legal/artistic-2_0.txt"]],
        ["win32-event", nil, ["http://www.perlfoundation.org/attachment/legal/artistic-2_0.txt"]],
        ["win32-eventlog", nil, ["http://www.perlfoundation.org/attachment/legal/artistic-2_0.txt"]],
        ["win32-mmap", nil, ["http://www.perlfoundation.org/attachment/legal/artistic-2_0.txt"]],
        ["win32-mutex", nil, ["http://www.perlfoundation.org/attachment/legal/artistic-2_0.txt"]],
        ["win32-service", nil, ["http://www.perlfoundation.org/attachment/legal/artistic-2_0.txt"]],
        ["windows-api", nil, ["http://www.perlfoundation.org/attachment/legal/artistic-2_0.txt"]],
      ].each do |override_data|
        override_license "ruby_bundler", override_data[0] do |version|
          {}.tap do |d|
            d[:license] = override_data[1] if override_data[1]
            d[:license_files] = override_data[2] if override_data[2]
          end
        end
      end
    end

  end
end
