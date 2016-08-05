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
require "license_scout/exceptions"

require "bundler"
require "mixlib/shellout"
require "ffi_yajl"
require "pathname"

module LicenseScout
  module DependencyManager
    class Bundler < Base

      POSSIBLE_LICENSE_FILES = %w{
        LICENSE
        LICENSE.txt
        LICENSE.md
        LICENSE.rdoc
        License
        License.text
        License.txt
        License.md
        License.rdoc
        Licence.rdoc
        Licence.md
        MIT-LICENSE
        MIT-LICENSE.txt
        LICENSE.MIT
        LGPL-2.1
        COPYING.txt
        COPYING
      }

      def name
        "ruby_bundler"
      end

      def detected?
        # We only check for the existence of Gemfile in order to declare a
        # project a Bundler project. If the Gemfile.lock does not exist
        # we will raise a specific error to indicate that "bundle install"
        # needs to be run before proceeding.
        File.exists?(gemfile_path)
      end

      def dependency_data
        bundler_script = File.join(File.dirname(__FILE__), "bundler/_bundler_script.rb")

        Dir.chdir(project_dir) do

          json_dep_data = ::Bundler.with_clean_env do
            s = Mixlib::ShellOut.new("ruby #{bundler_script}")
            s.run_command
            s.error!
            s.stdout
          end
          FFI_Yajl::Parser.parse(json_dep_data)
        end
      end

      def dependencies
        if !File.exists?(lockfile_path)
          raise LicenseScout::Exceptions::DependencyManagerNotRun.new(project_dir, name)
        end

        dependencies = []
        dependency_data.each do |gem_data|
          dependency_name = gem_data["name"]
          dependency_version = gem_data["version"]
          dependency_license = nil
          dependency_license_files = []

          if dependency_name == "bundler"
            # Bundler is weird. It inserts itself as a dependency, but is a
            # special case, so rubygems cannot correctly report the license.
            # Additionally, rubygems reports the gem path as a path inside
            # bundler's lib/ dir, so we have to munge it.
            dependency_license = "MIT"
            dependency_license_files = [File.join(File.dirname(__FILE__), "bundler/LICENSE.md")]
          else
            # Check license override and license_files override separately since
            # only one might be set in the overrides.
            dependency_license = overrides.license_for(name, dependency_name, dependency_version) || gem_data["license"]

            override_license_files = overrides.license_files_for(name, dependency_name, dependency_version)
            if override_license_files.nil? || override_license_files.empty?
              dependency_license_files = auto_detect_license_files(gem_data["path"])
            else
              dependency_license_files = check_override_files(gem_data["path"], override_license_files)
            end
          end

          dependencies << Dependency.new(
            dependency_name,
            dependency_version,
            dependency_license,
            dependency_license_files
          )
        end

        dependencies
      end

      private

      def auto_detect_license_files(gem_path)
        unless File.exist?(gem_path)
          raise LicenseScout::Exceptions::InaccessibleDependency.new "Autodetected gem path '#{gem_path}' does not exist"
        end

        Dir.glob("#{gem_path}/*").select do |f|
          POSSIBLE_LICENSE_FILES.include?(File.basename(f))
        end
      end

      def check_override_files(gem_path, override_license_files)
        license_files = []

        override_license_files.each do |filepath|
          potential_path = Pathname.new(filepath).absolute? ? filepath : File.join(gem_path, filepath)
          unless File.exists?(potential_path)
            raise Exceptions::InvalidOverride, "Provided license file path '#{filepath}' can not be found under detected gem path '#{gem_path}'."
          end

          license_files << potential_path
        end

        license_files
      end

      def gemfile_path
        File.join(project_dir, "Gemfile")
      end

      def lockfile_path
        File.join(project_dir, "Gemfile.lock")
      end
    end
  end
end
