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

require "bundler"
require "mixlib/shellout"
require "ffi_yajl"
require "pathname"

module LicenseScout
  module DependencyManager
    class Bundler < Base

      def name
        "ruby_bundler"
      end

      def detected?
        # We check the existence of both Gemfile and Gemfile.lock. We need both
        # of them to be able to get a concrete set of dependencies which we can
        # search. We used to raise an error when Gemfile.lock did not exist but
        # that created issues with projects like oc_bifrost which is a rebar
        # project but have a Gemfile at its root to be able to run some rake
        # commands.
        File.exists?(gemfile_path) && File.exists?(lockfile_path)
      end

      def dependency_data
        bundler_script = File.join(File.dirname(__FILE__), "bundler/_bundler_script.rb")

        Dir.chdir(project_dir) do
          json_dep_data = with_clean_env do
            ruby_bin_path = options.ruby_bin || "ruby"
            s = Mixlib::ShellOut.new("#{ruby_bin_path} #{bundler_script}", environment: options.environment)
            s.run_command
            s.error!
            s.stdout
          end
          FFI_Yajl::Parser.parse(json_dep_data)
        end
      end

      def dependencies
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
            dependency_license = options.overrides.license_for(name, dependency_name, dependency_version) || gem_data["license"]

            override_license_files = options.overrides.license_files_for(name, dependency_name, dependency_version)
            if override_license_files.empty?
              dependency_license_files = auto_detect_license_files(gem_data["path"])
            else
              dependency_license_files = override_license_files.resolve_locations(gem_data["path"])
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

      #
      # Execute the given command, removing any Ruby-specific environment
      # variables. This is an "enhanced" version of +Bundler.with_clean_env+,
      # which only removes Bundler-specific values. We need to remove all
      # values, specifically:
      #
      # - _ORIGINAL_GEM_PATH
      # - GEM_PATH
      # - GEM_HOME
      # - GEM_ROOT
      # - BUNDLE_BIN_PATH
      # - BUNDLE_GEMFILE
      # - RUBYLIB
      # - RUBYOPT
      # - RUBY_ENGINE
      # - RUBY_ROOT
      # - RUBY_VERSION
      #
      # The original environment restored at the end of this call.
      #
      # @param [Proc] block
      #   the block to execute with the cleaned environment
      #
      def with_clean_env(&block)
        original = ENV.to_hash

        ENV.delete("_ORIGINAL_GEM_PATH")
        ENV.delete_if { |k, _| k.start_with?("BUNDLE_") }
        ENV.delete_if { |k, _| k.start_with?("GEM_") }
        ENV.delete_if { |k, _| k.start_with?("RUBY") }

        yield
      ensure
        ENV.replace(original.to_hash)
      end

      def auto_detect_license_files(gem_path)
        unless File.exist?(gem_path)
          raise LicenseScout::Exceptions::InaccessibleDependency.new "Autodetected gem path '#{gem_path}' does not exist"
        end

        Dir.glob("#{gem_path}/*").select do |f|
          POSSIBLE_LICENSE_FILES.include?(File.basename(f))
        end
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
