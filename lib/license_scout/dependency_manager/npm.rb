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

require "set"
require "ffi_yajl"
require "license_scout/dependency_manager/base"

module LicenseScout
  module DependencyManager
    class NPM < Base

      def name
        "js_npm"
      end

      def detected?
        File.exist?(root_node_modules_path)
      end

      def dependencies
        packages = all_package_json_files.inject(Set.new) do |package_set, package_json_file|
          pkg_info = File.open(package_json_file) do |f|
            FFI_Yajl::Parser.parse(f)
          end

          pkg_name = pkg_info["name"]
          pkg_version = pkg_info["version"]
          package_path = File.dirname(package_json_file)

          license = options.overrides.license_for(name, pkg_name, pkg_version) ||
            normalize_license_data(pkg_info["license"])

          override_license_files = options.overrides.license_files_for(name, pkg_name, pkg_version)
          if override_license_files.empty?
            license_files = find_license_files_in(package_path)
          else
            license_files = override_license_files.resolve_locations(package_path)
          end

          package_set << Dependency.new(
            pkg_name,
            pkg_version,
            license,
            license_files
          )
        end
        packages.to_a
      end

      private

      # List all the package.json files in the project
      #
      # It would be easier to implement this with a dir glob using the `**`
      # metacharacter, but that approach will find "fake" packages that exist
      # as test fixtures inside a package. For example, one of our projects,
      # the 'module-deps' package contains a file
      # `test/files/tr_2dep_module/node_modules/g/package.json` which isn't a
      # "real" package. Therefore we do our own looping to traverse the
      # directories; at each step we look for `$PACKAGE_PATH/node_modules/*` to
      # find the next level of modules. This approach can miss cases where the
      # package authors have vendored packages in a directory not named
      # `node_modules`, but this case is rare and doesn't have a satisfactory
      # general solution (e.g., we cannot detect a vendored package if the
      # package metadata is removed).
      def all_package_json_files
        all_files = []
        package_dirs = [project_dir]
        loop do
          break if package_dirs.empty?

          package_dir = package_dirs.pop
          package_json_path = File.join(package_dir, "package.json")

          all_files << package_json_path if File.exist?(package_json_path)

          node_modules_dir = File.join(package_dir, "node_modules")
          if File.exist?(node_modules_dir)
            # Sort makes deduplication of identical deps deterministic
            package_dirs.concat(Dir[File.join(node_modules_dir, "*")].sort)
          end
        end

        all_files
      end

      def find_license_files_in(dir)
        root_files = Dir["#{dir}/*"]
        root_files.select { |f| POSSIBLE_LICENSE_FILES.include?(File.basename(f)) }
      end

      def normalize_license_data(license_metadata)
        license_string =
          case license_metadata
          when nil
            nil
          when String
            license_metadata
          when Hash
            license_metadata["type"]
          end
        select_best_license(license_string)
      end

      # npm packages use SPDX "expressions" for their licenses; Thus far we've
      # only seen a single license, optional multiple licenses like "(MIT OR Apache-2.0)"
      # or mandatory multiple licenses like "(MIT AND CC-BY-3.0)"
      #
      # If there are multiple options, we want to pick just one to keep it simple.
      def select_best_license(license_string)
        return nil if license_string.nil?
        options = license_string.tr("(", "").tr(")", "").split(" OR ")
        options.inject do |selected_license, license|
          if license_rank(selected_license) < license_rank(license)
            selected_license
          else
            license
          end
        end
      end

      # Rank licenses when selecting one of multiple options. Licenses are
      # converted to integer scores, the lower the better.
      #
      # We prefer Apache-2.0 since it matches our own projects, then MIT, then
      # BSDs. Everything else is considered equal.
      def license_rank(license)
        case license
        when "Apache-2.0"
          0
        when "MIT"
          1
        when /bsd/i
          2
        else
          3
        end
      end

      def root_node_modules_path
        File.join(project_dir, "node_modules")
      end

    end
  end
end
