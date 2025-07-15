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

require 'license_scout/log'
require 'license_scout/exceptions'
require 'license_scout/dependency_manager'
require 'license_scout/license'

module LicenseScout
  class Collector
    attr_reader :dependencies

    def collect
      @dependencies = Set.new

      if dependency_managers.empty?
        raise LicenseScout::Exceptions::Error, "Failed to find any files associated with known dependency managers in the following directories:\n#{LicenseScout::Config.directories.map do |dir|
                                                                                                                                                      "\t• #{dir}"
                                                                                                                                                    end.join("\n")}\n"
      end

      dependency_managers.each { |d| collect_licenses_from(d) }

      LicenseScout::Log.info('[collector] All licenses successfully collected')
    rescue Exceptions::UpstreamFetchError => e
      LicenseScout::Log.error('[collector] Encountered an error attempting to fetch package metadata from upstream source:')
      LicenseScout::Log.error("[collector] #{e}")
      raise Exceptions::FailExit, e
    rescue Exceptions::PackageNotFound => e
      LicenseScout::Log.error("[collector] One of the project's transitive dependencies could not be found:")
      LicenseScout::Log.error("[collector] #{e}")
      raise Exceptions::FailExit, e
    end

    private

    def collect_licenses_from(dep_mgr)
      LicenseScout::Log.info("[collector] Collecting licenses for #{dep_mgr.type} dependencies found in #{dep_mgr.directory}/#{dep_mgr.signature}")
      dep_mgr.dependencies.each do |dep|
        @dependencies << dep
      end
    rescue LicenseScout::Exceptions::MissingSourceDirectory => e
      raise LicenseScout::Exceptions::Error,
            "#{e.message}\n\n\tPlease try running `#{dep_mgr.install_command}` to download the dependency.\n"
    end

    def dependency_managers
      @dependency_managers ||= LicenseScout::Config.all_directories.map do |dir|
        LicenseScout::DependencyManager.implementations.map do |implementation|
          dep_mgr = implementation.new(File.expand_path(dir))
          if dep_mgr.detected? && !(LicenseScout::Config.exclude_collectors.include? dep_mgr.name)
            LicenseScout::Log.info("[collector] Found #{dep_mgr.signature} in #{dir}")
            dep_mgr
          end
        end
      end.flatten.compact
    end
  end
end
