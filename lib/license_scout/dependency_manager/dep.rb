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

require "ffi_yajl"
require "yaml"
require "toml-rb"
require "license_scout/dependency_manager/base"

module LicenseScout
  module DependencyManager
    # dep(https://github.com/golang/dep) is a new dependency manger available from go 1.8
    class Dep < Base

      def name
        "go_dep"
      end

      def detected?
        File.exist?(root_dep_file)
      end

      def dependencies
        deps = File.open(root_dep_file) do |f|
          TomlRB.parse(f)
        end
        return [] unless deps.key?("projects")

        deps["projects"].map do |pkg_info|
          pkg_import_name = pkg_info["name"]
          pkg_file_name = pkg_import_name.tr("/", "_")
          pkg_version = pkg_info["version"] || pkg_info["revision"]
          license = options.overrides.license_for("go", pkg_import_name, pkg_version)

          override_license_files = options.overrides.license_files_for("go", pkg_import_name, pkg_version)
          if override_license_files.empty?
            license_files = find_license_files_for_package_in_gopath_or_vendor_dir(pkg_import_name)
          else
            license_files = override_license_files.resolve_locations(gopath(pkg_import_name))
          end

          if license.nil? && !license_files.empty?
            license = scan_licenses(license_files)
          end

          create_dependency(pkg_file_name, pkg_version, license, license_files)
        end
      end

      private

      def scan_licenses(license_files)
        found_license = LicenseScout::LicenseFileAnalyzer.find_by_text(IO.read(license_files.first))
        found_license && found_license.short_name
      end

      def root_dep_file
        File.join(project_dir, "Gopkg.lock")
      end

      def gopath(pkg)
        "#{ENV["GOPATH"]}/src/#{pkg}"
      end

      def vendor_dir(pkg = nil)
        File.join(project_dir, "vendor/#{pkg}")
      end

      def find_license_files_for_package_in_gopath_or_vendor_dir(pkg)
        root_files = Dir["#{gopath(pkg)}/*"] + Dir["#{vendor_dir(pkg)}/*"]
        root_files.select { |f| POSSIBLE_LICENSE_FILES.include?(File.basename(f)) }
      end
    end
  end
end
