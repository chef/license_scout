#
# Copyright:: Copyright 2017, Chef Software Inc.
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

require "yaml" unless defined?(YAML)
require "license_scout/dependency_manager/base"

module LicenseScout
  module DependencyManager
    class Glide < Base

      def name
        "go_glide"
      end

      def detected?
        File.exist?(glide_yaml)
      end

      def dependencies
        unless File.file?(glide_yaml_locked)
          raise "Detected Go/Glide project that is missing its \"glide.lock\" "\
                "file in #{project_dir}"
        end

        deps = YAML.load(File.read(glide_yaml_locked))
        deps["imports"].map { |i| add_glide_dep(i) }
      end

      private

      def add_glide_dep(import_field)
        pkg_import_name = import_field["name"]
        pkg_file_name = pkg_import_name.tr("/", "_")
        pkg_version = import_field["version"]
        license = options.overrides.license_for("go", pkg_import_name, pkg_version)

        override_license_files = options.overrides.license_files_for("go", pkg_import_name, pkg_version)
        if override_license_files.empty?
          license_files = find_license_files_for_package_in_gopath(pkg_import_name)
        else
          license_files = override_license_files.resolve_locations(gopath(pkg_import_name))
        end

        create_dependency(pkg_file_name, pkg_version, license, license_files)
      end

      def glide_yaml
        File.join(project_dir, "glide.yaml")
      end

      def glide_yaml_locked
        File.join(project_dir, "glide.lock")
      end

      def gopath(pkg)
        "#{ENV["GOPATH"]}/src/#{pkg}"
      end

      def find_license_files_for_package_in_gopath(pkg)
        root_files = Dir["#{gopath(pkg)}/*"]
        root_files.select { |f| POSSIBLE_LICENSE_FILES.include?(File.basename(f)) }
      end
    end
  end
end
