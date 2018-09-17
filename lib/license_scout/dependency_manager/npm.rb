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

module LicenseScout
  module DependencyManager
    class Npm < Base

      def name
        "nodejs_npm"
      end

      def type
        "nodejs"
      end

      def signature
        "node_modules directory"
      end

      def install_command
        "npm install"
      end

      def detected?
        File.exist?(root_node_modules_path)
      end

      def dependencies
        all_package_json_files.inject(Set.new) do |uniq_deps, package_json_file|
          pkg_info = File.open(package_json_file) do |f|
            FFI_Yajl::Parser.parse(f)
          end

          dep_name = pkg_info["name"]
          dep_version = pkg_info["version"]
          dep_path = File.dirname(package_json_file)

          dependency = new_dependency(dep_name, dep_version, dep_path)

          license_info = pkg_info["license"] || pkg_info["licenses"]

          case license_info
          when String
            dependency.add_license(license_info, "package.json")
          when Hash
            dependency.add_license(license_info["type"], "package.json", license_info["url"])
          when Array
            license_info.each do |license|
              case license
              when String
                dependency.add_license(license, "package.json")
              when Hash
                dependency.add_license(license["type"], "package.json", license["url"])
              end
            end
          end

          uniq_deps << dependency
        end.to_a
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
        package_dirs = [directory]
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

      def root_node_modules_path
        File.join(directory, "node_modules")
      end
    end
  end
end
