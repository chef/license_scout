# frozen_string_literal: true

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

require 'license_scout/dependency_manager/base'

module LicenseScout
  module DependencyManager
    class Bundler < Base
      def name
        'ruby_bundler'
      end

      def type
        'ruby'
      end

      def signature
        'Gemfile and Gemfile.lock files'
      end

      def install_command
        'bundle install'
      end

      def detected?
        # We check the existence of both Gemfile and Gemfile.lock. We need both
        # of them to be able to get a concrete set of dependencies which we can
        # search. We used to raise an error when Gemfile.lock did not exist but
        # that created issues with projects like oc_bifrost which is a rebar
        # project but have a Gemfile at its root to be able to run some rake
        # commands.
        File.exist?(gemfile_path) && File.exist?(lockfile_path)
      end

      def dependencies
        dependency_data.map do |gem_data|
          dep_name = gem_data['name']
          dep_version = gem_data['version']
          dep_license = gem_data['license']

          dep_path = case dep_name
                     when 'bundler'
                       # Bundler is weird. It inserts itself as a dependency, but is a
                       # special case, so rubygems cannot correctly report the license.
                       # Additionally, rubygems reports the gem path as a path inside
                       # bundler's lib/ dir, so we have to munge it.
                       'https://github.com/bundler/bundler'
                     when 'json'
                       # json is different weird. When project is using the json that is prepackaged with
                       # Ruby, its included not as a full fledged gem but an *.rb file at:
                       # /opt/opscode/embedded/lib/ruby/2.2.0/json.rb
                       # Because of this its license is reported as nil and its license files can not be
                       # found. That is why we need to provide them manually here.
                       'https://github.com/flori/json'
                     else
                       gem_data['path']
                     end

          dependency = new_dependency(dep_name, dep_version, dep_path)

          # If the gemspec has defined a license, include that as well.
          unless dep_license.nil?
            dependency.add_license(dep_license, "https://rubygems.org/gems/#{dep_name}/versions/#{dep_version}")
          end

          dependency
        end.compact
      end

      private

      def dependency_data
        gemfile_to_json_path = File.expand_path('../../../bin/gemfile_json', File.dirname(__FILE__))

        Dir.chdir(directory) do
          json_dep_data = with_clean_env do
            s = Mixlib::ShellOut.new("#{LicenseScout::Config.ruby_bin} #{gemfile_to_json_path}",
                                     environment: LicenseScout::Config.environment)
            s.run_command
            s.error!
            s.stdout
          end

          FFI_Yajl::Parser.parse(json_dep_data)
        end
      end

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
      def with_clean_env
        original = ENV.to_hash

        ENV.delete('_ORIGINAL_GEM_PATH')
        ENV.delete_if { |k, _| k.start_with?('BUNDLE_') }
        ENV.delete_if { |k, _| k.start_with?('GEM_') }
        ENV.delete_if { |k, _| k.start_with?('RUBY') }

        yield
      ensure
        ENV.replace(original.to_hash)
      end

      def gemfile_path
        File.join(directory, 'Gemfile')
      end

      def lockfile_path
        File.join(directory, 'Gemfile.lock')
      end
    end
  end
end
