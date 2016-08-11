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
require "license_scout/net_fetcher"
require "license_scout/exceptions"
require "license_scout/license_file_analyzer"

require "mixlib/shellout"

module LicenseScout
  module DependencyManager
    class Rebar < Base

      def name
        "erlang_rebar"
      end

      def detected?
        File.exist?(rebar_config_path)
      end

      def dependencies
        dependencies = []

        Dir.glob("#{project_deps_dir}/*").each do |dep_dir|
          next unless File.directory?(dep_dir)

          dep_name = File.basename(dep_dir)
          dep_version = git_rev_parse(dep_dir)

          override_license_files = overrides.license_files_for(name, dep_name, dep_version)
          license_files =
            if override_license_files.nil? || override_license_files.empty?
              Dir.glob("#{dep_dir}/*").select { |f| POSSIBLE_LICENSE_FILES.include?(File.basename(f)) }
            else
              verify_and_normalize_license_file_paths(dep_dir, override_license_files)
            end

          license_name = overrides.license_for(name, dep_name, dep_version) || scan_licenses(license_files)

          dep = Dependency.new(dep_name, dep_version, license_name, license_files)

          dependencies << dep
        end

        dependencies
      end

      private

      def verify_and_normalize_license_file_paths(dep_dir, override_files)
        override_files.map do |filepath|
          if NetFetcher.remote?(filepath)
            NetFetcher.cache(filepath)
          else
            candidate_path = File.expand_path(filepath, dep_dir)

            unless File.exists?(candidate_path)
              raise Exceptions::InvalidOverride, "Provided license file path '#{filepath}' can not be found under detected deps path '#{dep_dir}'."
            end

            candidate_path
          end
        end
      end

      def git_rev_parse(dependency_dir)
        s = Mixlib::ShellOut.new("git rev-parse HEAD", cwd: dependency_dir)
        s.run_command
        s.error!
        s.stdout.strip
      end

      def project_deps_dir
        File.join(project_dir, "deps")
      end

      def rebar_config_path
        File.join(project_dir, "rebar.config")
      end

      def scan_licenses(license_files)
        if license_files.empty?
          nil
        else
          found_license = LicenseScout::LicenseFileAnalyzer.find_by_text(IO.read(license_files.first))
          found_license ? found_license.short_name : nil
        end
      end

    end
  end
end
