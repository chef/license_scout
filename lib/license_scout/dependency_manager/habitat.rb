# frozen_string_literal: true

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

require 'license_scout/dependency_manager/base'

module LicenseScout
  module DependencyManager
    class Habitat < Base
      DEFAULT_CHANNEL = 'stable'
      FALLBACK_CHANNEL_FOR_FQ = 'unstable'

      def name
        'habitat'
      end

      def type
        'habitat'
      end

      def signature
        File.exist?(habitat_plan_sh_path) ? 'habitat/plan.sh file' : 'plan.sh file'
      end

      def install_command
        ''
      end

      def detected?
        File.exist?(plan_sh_path) || File.exist?(habitat_plan_sh_path)
      end

      def dependencies
        tdeps = Set.new(pkg_deps)

        if pkg_deps.any?
          pkg_deps.each do |pkg_dep|
            pkg_info(pkg_dep)['tdeps'].each { |dep| tdeps << to_ident(dep) } unless pkg_info(pkg_dep).nil?
          end

          tdeps.delete(nil)

          tdeps.sort.map do |tdep|
            o, n, v, r = tdep.split('/')
            dep_name = "#{o}/#{n}"
            dep_version = "#{v}-#{r}"

            dependency = new_dependency(dep_name, dep_version, nil)

            if pkg_info(tdep).nil?
              LicenseScout::Log.warn("Could not find information for #{tdep} -- skipping")
            else
              license_from_manifest(pkg_info(tdep)['manifest']).each do |spdx|
                # We hard code the channel to "unstable" because a package could be
                # demoted from any given channel except unstable in the future and
                # we want the url metadata to be stable in order to give end users
                # the ability to self-audit licenses
                # tl;dr, we want a permalink not a nowlink
                dependency.add_license(spdx, "https://bldr.habitat.sh/v1/depot/channels/#{o}/unstable/pkgs/#{n}/#{v}/#{r}")
              end
            end

            dependency
          end.compact
        end
      end

      private

      def license_from_manifest(manifest_content)
        /^*\s+__License__:\s+(.+)$/.match(manifest_content)[1].strip.split("\s")
      end

      def pkg_deps
        @pkg_deps ||= begin
          plan_path = File.exist?(plan_sh_path) ? plan_sh_path : habitat_plan_sh_path

          c = Mixlib::ShellOut.new(
            "bash -ec 'export PLAN_CONTEXT=\"#{File.dirname(plan_path)}\"; source #{plan_path}; echo ${pkg_deps[*]}'", LicenseScout::Config.environment
          )
          c.run_command
          c.error!
          pkg_deps = c.stdout.split("\s")

          # Fetch the fully-qualified pkg_ident for each pkg
          pkg_deps.map do |dep|
            to_ident(pkg_info(dep)['ident']) unless pkg_info(dep).nil?
          end
        end
      end

      def to_ident(ident_hash)
        "#{ident_hash['origin']}/#{ident_hash['name']}/#{ident_hash['version']}/#{ident_hash['release']}"
      end

      def pkg_info(pkg_ident)
        $habitat_pkg_info ||= {}
        $habitat_pkg_info[pkg_ident] ||= pkg_info_with_channel_fallbacks(pkg_ident)
      end

      def pkg_info_with_channel_fallbacks(pkg_ident)
        unless pkg_ident.nil?
          pkg_origin, pkg_name, pkg_version, pkg_release = pkg_ident.split('/')
          pkg_channel = channel_for_origin(pkg_origin)

          # Channel selection here is similar to the logic that
          # Habitat uses. First, search in the user-provided channel,
          # then search in stable, then use unstable IF it is a fully
          # qualified package
          info = get_pkg_info(pkg_origin, pkg_channel, pkg_name, pkg_version, pkg_release)
          return info if info

          if pkg_channel != DEFAULT_CHANNEL
            LicenseScout::Log.debug("[habitat] Looking for #{pkg_ident} in #{DEFAULT_CHANNEL} channel")
            info = get_pkg_info(pkg_origin, DEFAULT_CHANNEL, pkg_name, pkg_version, pkg_release)
            return info if info
          end

          if !pkg_version.nil? && !pkg_release.nil?
            LicenseScout::Log.debug("[habitat] Looking for #{pkg_ident} in #{FALLBACK_CHANNEL_FOR_FQ} channel since it is fully-qualified")
            info = get_pkg_info(pkg_origin, FALLBACK_CHANNEL_FOR_FQ, pkg_name, pkg_version, pkg_release)
            return info if info
          end

          LicenseScout::Log.warn("Could not find information for #{pkg_ident} -- skipping")
        end
      end

      def get_pkg_info(origin, channel, name, version, release)
        base_api_uri = "https://bldr.habitat.sh/v1/depot/channels/#{origin}/#{channel}/pkgs/#{name}"
        base_api_uri += if version.nil? && release.nil?
                          '/latest'
                        elsif release.nil?
                          "/#{version}/latest"
                        else
                          "/#{version}/#{release}"
                        end

        LicenseScout::Log.debug("[habitat] Fetching pkg_info from #{base_api_uri}")
        response = Net::HTTP.get_response(URI(base_api_uri))

        if response.is_a?(Net::HTTPSuccess)
          FFI_Yajl::Parser.parse(response.body)
        else
          case response.code
          when '404'
            nil
          else
            raise LicenseScout::Exceptions::UpstreamFetchError,
                  "Received \"#{response.code} #{response.msg}\" when attempting to fetch package information for the #{origin}/#{name} Habitat package"
          end
        end
      end

      def channel_for_origin(pkg_origin)
        override = LicenseScout::Config.habitat.channel_for_origin.find { |t| t['origin'] == pkg_origin }
        if override
          override['channel']
        else
          DEFAULT_CHANNEL
        end
      end

      def plan_sh_path
        File.join(directory, 'plan.sh')
      end

      def habitat_plan_sh_path
        File.join(directory, 'habitat', 'plan.sh')
      end
    end
  end
end
