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
    class Rebar < Base

      attr_reader :packaged_dependencies

      def initialize(directory)
        super(directory)

        @packaged_dependencies = {}
      end

      def name
        "erlang_rebar"
      end

      def type
        "erlang"
      end

      def signature
        "rebar.config file"
      end

      def install_command
        "rebar get-deps"
      end

      def detected?
        File.exist?(rebar_config_path)
      end

      def dependencies
        # Some dependencies are obtained via 'pkg' identifier of rebar. These
        # dependencies include their version in the rebar.lock file. Here we
        # parse the rebar.lock and remember all the versions we find.
        parse_packaged_dependencies

        Dir.glob("#{project_deps_dir}/*").map do |dep_dir|
          next unless File.directory?(dep_dir)

          dep_name = File.basename(dep_dir)

          # First check if this dependency is coming from the parent software.
          # If so we do not need to worry about its version or licenses because
          # it will be covered under the parent software's license.
          next if File.directory?(File.join(directory, "apps", dep_name))

          # Or skip if the dep name is the project name
          next if File.exist?(File.join(directory, "_build/default/rel", dep_name))

          # While determining the dependency version we first check the cache we
          # built from rebar.lock for the dependencies that come via 'pkg'
          # keyword. If this information is not available we try to determine
          # the dependency version via git.
          dep_version = if packaged_dependencies.key?(dep_name)
                          packaged_dependencies[dep_name]
                        else
                          git_rev_parse(dep_dir)
                        end

          new_dependency(dep_name, dep_version, dep_dir)
        end.compact
      end

      private

      # Some of the dependencies or rebar projects are obtained as a package.
      # These have the 'pkg' key in their rebar.lock file. Since we can not
      # determine the version of them via git, we try to parse the rebar.lock
      # file and remember their versions to use it later.
      def parse_packaged_dependencies
        rebar_lock_path = File.join(directory, "rebar.lock")

        return unless File.exist?(rebar_lock_path)

        rebar_lock_to_json_path = File.expand_path("../../../bin/rebar_lock_json", File.dirname(__FILE__))
        s = Mixlib::ShellOut.new("#{LicenseScout::Config.escript_bin} #{rebar_lock_to_json_path} #{rebar_lock_path}", environment: LicenseScout::Config.environment)
        s.run_command
        s.error!

        rebar_lock_content = FFI_Yajl::Parser.parse(s.stdout)

        rebar_lock_content.each do |name, source_info|
          if source_info["type"] == "pkg"
            source_name = source_info["pkg_name"]
            source_version = source_info["pkg_version"]

            @packaged_dependencies[source_name] = source_version
          end
        end
      rescue Mixlib::ShellOut::ShellCommandFailed
        # Continue even if we can not parse the rebar.lock since we can still
        # succeed if all the dependencies are coming from git.
      end

      def git_rev_parse(dependency_dir)
        s = Mixlib::ShellOut.new("git rev-parse HEAD", cwd: dependency_dir)
        s.run_command
        s.error!
        s.stdout.strip
      rescue Mixlib::ShellOut::ShellCommandFailed
        # We wrap the error here in order to be able to learn the cwd, i.e.
        # which dependency is having issues.
        raise LicenseScout::Exceptions::Error.new(
          "Can not determine the git version of rebar dependency at '#{dependency_dir}'."
        )
      end

      def project_deps_dir
        # rebar dependencies can be found in one of these two directories.
        ["deps", "_build/default/lib"].each do |dir|
          dep_dir = File.join(directory, dir)
          return dep_dir if File.exist?(dep_dir)
        end
      end

      def rebar_config_path
        File.join(directory, "rebar.config")
      end
    end
  end
end
