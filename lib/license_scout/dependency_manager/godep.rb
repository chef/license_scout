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
    class Godep < Base

      def name
        "go_godep"
      end

      def detected?
        File.exist?(root_godeps_file)
      end

      def dependencies
        godeps = File.open(root_godeps_file) do |f|
          FFI_Yajl::Parser.parse(f)
        end

        godeps["Deps"].map do |pkg_info|
          pkg_name = pkg_info["ImportPath"]
          pkg_version = pkg_info["Comment"] || pkg_info["Rev"]
          license = options.overrides.license_for(name, pkg_name, pkg_version)

          override_license_files = options.overrides.license_files_for(name, pkg_name, pkg_version)
          if override_license_files.empty?
            license_files = find_license_files_for_package_in_gopath(pkg_name)
          else
            license_files = override_license_files.resolve_locations(gopath(pkg_name))
          end

          create_dependency(pkg_name, pkg_version, license, license_files)
        end
      end

      private

      def root_godeps_file
        File.join(project_dir, "Godeps/Godeps.json")
      end

      def gopath(pkg)
        "#{ENV['GOPATH']}/src/#{pkg}"
      end

      def find_license_files_for_package_in_gopath(pkg)
        root_files = Dir["#{gopath(pkg)}/*"]
        root_files.select { |f| POSSIBLE_LICENSE_FILES.include?(File.basename(f)) }
      end
    end
  end
end
