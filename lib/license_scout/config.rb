#
# Copyright:: Copyright 2018, Chef Software Inc.
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

require "mixlib/config"
require "tmpdir"

require "license_scout/exceptions"
require "license_scout/log"
require "license_scout/license"

module LicenseScout
  module Config
    extend Mixlib::Config

    # Inputs
    default :directories, [File.expand_path(Dir.pwd)]
    default :include_subdirectories, false
    default :name, File.basename(directories.first)
    default :config_files, [File.join(File.expand_path(Dir.pwd), ".license_scout.yml")]

    # Output
    default :log_level, :info
    default :output_directory, Dir.pwd
    default :only_show_failures, false

    # Compliance Specifications
    default :allowed_licenses, []
    default :flagged_licenses, []

    config_context :exceptions do
      default :chef_cookbook, []
      default :elixir, []
      default :erlang, []
      default :golang, []
      default :habitat, []
      default :nodejs, []
      default :perl, []
      default :ruby, []
    end

    config_context :fallbacks do
      default :chef_cookbook, []
      default :elixir, []
      default :erlang, []
      default :golang, []
      default :habitat, []
      default :nodejs, []
      default :perl, []
      default :ruby, []
    end

    config_context :habitat do
      default :channel_for_origin, []
    end

    # Runtime Parameters - if you add any bins, make sure to update the habitat/plan.sh
    # to ensure we override the defaults to scope to the Habitat path
    default :environment, {}
    default :ruby_bin, "ruby"
    default :escript_bin, "escript"
    default :cpanm_root, "#{ENV["HOME"]}/.cpanm"

    #
    # Helpers
    #

    class << self

      def all_directories
        if include_subdirectories
          new_directories = []

          directories.each do |old_directory|
            new_directories << old_directory
            Dir.chdir(old_directory) do
              new_directories << Dir.glob("**/*").select { |f| File.directory?(f) }.map { |d| File.join(old_directory, d) }
            end
          end

          new_directories.flatten.compact
        else
          directories
        end
      end

      def validate!
        if !allowed_licenses.empty? && !flagged_licenses.empty?
          raise LicenseScout::Exceptions::ConfigError.new("You may specify a list of licenses to allow or flag. You may not specify both.")
        end

        if (allowed_licenses.empty? && flagged_licenses.empty?) && dependency_exceptions?
          LicenseScout::Log.warn("You have specified one or more dependency exceptions, but no allowed or flagged licenses. License Scout will ignore the depdendency exceptions.")
        end

        directories.each do |dir|
          unless File.directory?(File.expand_path(dir))
            raise LicenseScout::Exceptions::ConfigError.new("The '#{dir}' directory could not be found.")
          end
        end
      end
    end
  end
end
