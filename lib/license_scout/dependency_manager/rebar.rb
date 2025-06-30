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
require "open3"


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
        parse_rebar_config
        # Run `rebar get-deps` to ensure dependencies are downloaded
        puts "Running `rebar get-deps` to fetch dependencies..."
        if system("rebar3 get-deps")
          puts "Dependencies downloaded successfully."
        else
          puts "Failed to download dependencies."
        end

        # Loop through the rebar_deps hash and process each dependency
        @rebar_deps.map do |dep_key, dep_info|
          dep_name = dep_info[:source]
          dep_version = dep_info[:version]
          dep_path = File.join(project_deps_dir, dep_key) # Set dep_path to the actual directory

          # Skip if the directory does not exist
          unless File.exist?(dep_path)
            LicenseScout::Log.warn("[rebar] Dependency directory not found: #{dep_path}")
            next
          end

          # Create new dependency entry
          new_dependency(dep_name, dep_version, dep_path)
        end.compact
      end

      def parse_rebar_config
        config_path = File.join(directory, "rebar.config")
        return unless File.exist?(config_path)

        command = <<~EOS
          erl -noshell -eval '
            {ok, Config} = file:consult("#{config_path}"),
            Deps = proplists:get_value(deps, Config),
            Profiles = proplists:get_value(profiles, Config),
            io:format("DEPS:~p~nPROFILES:~p~n", [Deps, Profiles]),
            halt().
          '
        EOS

        stdout, status = Open3.capture2(command)

        unless status.success?
          LicenseScout::Log.error("[rebar] Failed to parse rebar.config with Erlang")
          return
        end

        # Split output to get deps and profiles parts
        deps_str = stdout[/DEPS:(.*?)\nPROFILES:/m, 1]
        profiles_str = stdout[/PROFILES:(.*)/m, 1]

        # Parse top-level deps
        @rebar_deps = parse_erlang_deps(deps_str || "")

        # Parse nested deps inside profiles
        profiles_deps = parse_profiles_deps(profiles_str || "")

        # Merge profile deps into @rebar_deps
        @rebar_deps.merge!(profiles_deps)
      end

      def parse_erlang_deps(deps_str)
        deps = {}
        # Match the Erlang term for each dependency
        deps_str.scan(/\{([^,]+),\s*"(.*?)",\s*\{git,\s*"([^"]+)",\s*\{(branch|ref|tag),\s*"([^"]+)"\}\}\}/).each do |name, version, url, _, ref|
          dep_name = name.strip
          dep_version = ref.strip
          dep_url = url.strip
          # Use the dep_url and version to build a unique path if necessary
          dep_path = dep_url.gsub("https://", "").gsub(/\.git$/, "").strip
          deps[dep_name] = { version: dep_version, source: dep_url }
        end
        deps
      end


      def parse_profiles_deps(profiles_str)
        return {} if profiles_str.nil? || profiles_str.empty?

        deps = {}

        # Debug raw input
        # puts "Raw profiles string:"
        # puts profiles_str

        # # Clean and normalize input
        # cleaned_str = profiles_str.gsub(/%.*$/, '').gsub(/\s+/, ' ')

        # # Debug cleaned input
        # puts "\nCleaned profiles string:"
        # puts cleaned_str

        # # Extract test profile section
        # if test_match = cleaned_str.match(/\{test,\s*\[(.*?{deps,\s*\[(.*?)\].*?}.*?)\]/m)
        #   deps_content = test_match[2]

        #   puts "\nFound deps content:"
        #   puts deps_content

        #   # Parse individual deps
        #   deps_content.scan(/\{([^,]+),\s*\{git,\s*"([^"]+)",\s*\{(?:ref|branch|tag),\s*"([^"]+)"\}\}\}/) do |name, url, version|
        #     dep_name = name.strip
        #     dep_url = url.strip
        #     dep_version = version.strip

        #     puts "\nFound dependency:"
        #     puts "Name: #{dep_name}"
        #     puts "URL: #{dep_url}"
        #     puts "Version: #{dep_version}"

        #     deps[dep_name] = {
        #       version: dep_version,
        #       source: dep_url
        #     }
        #   end
        # end

        # puts "\nFinal deps hash:"
        # puts deps.inspect

        deps
      end


      def parse_packaged_dependencies
        rebar_lock_path = File.join(directory, "rebar.lock")
        return unless File.exist?(rebar_lock_path)

        content = File.read(rebar_lock_path)
        dependencies = {}

        content.scan(/\{<<"(.*?)">>,\s*\{git,\s*"(.*?)",\s*\{(.*?)\}\},\s*(\d+)\}/).each do |pkg_name, pkg_source, pkg_ref_or_branch, _|
          version = parse_version(pkg_ref_or_branch)
          dependencies[pkg_name] = { version: version, source: pkg_source }
        end

        @packaged_dependencies = dependencies
      end

      # def parse_version(ref_info)
      #   if ref_info =~ /ref,"([^"]+)"/
      #     $1
      #   elsif ref_info =~ /branch,"([^"]+)"/
      #     $1
      #   elsif ref_info =~ /tag,"([^"]+)"/
      #     $1
      #   else
      #     ref_info.strip
      #   end
      # end
      #

      def git_rev_parse(dependency_dir)
        LicenseScout::Log.info("[rebar] Running git rev-parse in #{dependency_dir}")
        s = Mixlib::ShellOut.new("git rev-parse HEAD", cwd: dependency_dir)
        s.run_command
        s.error!
        LicenseScout::Log.info("[rebar] Git commit hash for #{dependency_dir}: #{s.stdout.strip}")
        s.stdout.strip
      rescue Mixlib::ShellOut::ShellCommandFailed
        LicenseScout::Log.error("[rebar] Failed to determine git version for #{dependency_dir}")
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
