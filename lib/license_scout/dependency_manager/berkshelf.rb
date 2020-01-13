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
    class Berkshelf < Base

      def name
        "chef_berkshelf"
      end

      def berkshelf_available?
        begin
          require "berkshelf"
        rescue LoadError
          return false
        end

        true
      end

      def detected?
        File.exist?(berksfile_path) && File.exist?(lockfile_path)
      end

      def dependencies
        unless berkshelf_available?
          raise LicenseScout::Exceptions::Error.new "Project at '#{project_dir}' is a Berkshelf project but berkshelf gem is not available in your bundle. Add berkshelf to your bundle in order to collect licenses for this project."
        end

        dependencies = []
        cookbook_dependencies = nil

        Dir.chdir(project_dir) do
          berksfile = ::Berkshelf::Berksfile.from_file("./Berksfile")

          # Berkshelf should not give an error when there are cookbooks in the
          # lockfile that are no longer in the berksfile. It handles this case in
          # the Installer class which we are not using here. So we handle this
          # case in the same way Installer does.
          berksfile.lockfile.reduce!

          cookbook_dependencies = berksfile.list
        end

        cookbook_dependencies.each do |dep|
          dependency_name = dep.name
          dependency_version = dep.cached_cookbook.version

          dependency_license_files = auto_detect_license_files(dep.cached_cookbook.path.to_s)

          # Check license override and license_files override separately since
          # only one might be set in the overrides.
          dependency_license = options.overrides.license_for(name, dependency_name, dependency_version) || dep.cached_cookbook.license

          override_license_files = options.overrides.license_files_for(name, dependency_name, dependency_version)
          cookbook_path = dep.cached_cookbook.path.to_s

          if override_license_files.empty?
            dependency_license_files = auto_detect_license_files(cookbook_path)
          else
            dependency_license_files = override_license_files.resolve_locations(cookbook_path)
          end

          dependencies << create_dependency(
            dependency_name,
            dependency_version,
            dependency_license,
            dependency_license_files
          )
        end

        dependencies
      end

      private

      def berksfile_path
        File.join(project_dir, "Berksfile")
      end

      def lockfile_path
        File.join(project_dir, "Berksfile.lock")
      end

      def auto_detect_license_files(cookbook_path)
        unless File.exist?(cookbook_path)
          raise LicenseScout::Exceptions::InaccessibleDependency.new "Autodetected cookbook path '#{cookbook_path}' does not exist"
        end

        Dir.glob("#{cookbook_path}/*").select do |f|
          POSSIBLE_LICENSE_FILES.include?(File.basename(f))
        end
      end

    end
  end
end
