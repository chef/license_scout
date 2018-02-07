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

require "license_scout/dependency_manager/base"

require "open-uri"
require "mixlib/shellout"

module LicenseScout
  module DependencyManager
    class Habitat < Base

      def name
        "habitat"
      end

      def type
        "habitat"
      end

      def signature
        File.exist?(habitat_plan_sh_path) ? "habitat/plan.sh file" : "plan.sh file"
      end

      def install_command
        ""
      end

      def detected?
        File.exist?(plan_sh_path) || File.exist?(habitat_plan_sh_path)
      end

      def dependencies
        tdeps = Set.new(pkg_deps)

        pkg_deps.each do |pkg_dep|
          pkg_info(pkg_dep)["tdeps"].each { |dep| tdeps << to_ident(dep) }
        end

        tdeps.sort.map do |tdep|
          o, n, v, r = tdep.split("/")
          dep_name = "#{o}/#{n}"
          dep_version = "#{v}-#{r}"

          dependency = new_dependency(dep_name, dep_version, nil)

          license_from_manifest(pkg_info(tdep)["manifest"]).each do |spdx|
            dependency.add_license(spdx, "https://bldr.habitat.sh/v1/depot/channels/#{o}/stable/pkgs/#{n}/#{v}/#{r}")
          end

          dependency
        end.compact
      end

      private

      def license_from_manifest(manifest_content)
        /^*\s+__License__:\s+(.+)$/.match(manifest_content)[1].strip.split("\s")
      end

      def pkg_deps
        @pkg_deps ||= begin
          plan_path = File.exist?(plan_sh_path) ? plan_sh_path : habitat_plan_sh_path

          c = Mixlib::ShellOut.new("bash -ec 'export PLAN_CONTEXT=\"#{File.dirname(plan_path)}\"; source #{plan_path}; echo ${pkg_deps[*]}'", LicenseScout::Config.environment)
          c.run_command
          c.error!
          pkg_deps = c.stdout.split("\s")

          # Fetch the fully-qualified pkg_ident for each pkg
          pkg_deps.map { |dep| to_ident(pkg_info(dep)["ident"]) }
        end
      end

      def to_ident(ident_hash)
        "#{ident_hash["origin"]}/#{ident_hash["name"]}/#{ident_hash["version"]}/#{ident_hash["release"]}"
      end

      def pkg_info(pkg_ident)
        $habitat_pkg_info ||= {}
        $habitat_pkg_info[pkg_ident] ||= begin
          pkg_origin, pkg_name, pkg_version, pkg_release = pkg_ident.split("/")

          base_api_uri = "https://bldr.habitat.sh/v1/depot/channels/#{pkg_origin}/stable/pkgs/#{pkg_name}"
          if pkg_version.nil? && pkg_release.nil?
            base_api_uri += "/latest"
          elsif pkg_release.nil?
            base_api_uri += "/#{pkg_version}/latest"
          else
            base_api_uri += "/#{pkg_version}/#{pkg_release}"
          end

          LicenseScout::Log.debug("[habitat] Fetching pkg_info from #{base_api_uri}")
          FFI_Yajl::Parser.parse(open(base_api_uri).read)
        rescue OpenURI::HTTPError
          pkg_origin, pkg_name, = pkg_ident.split("/")

          LicenseScout::Log.warn("[habitat] Could not find pkg_info for #{pkg_ident} - trying for the latest version of #{pkg_origin}/#{pkg_name}")
          FFI_Yajl::Parser.parse(open("https://bldr.habitat.sh/v1/depot/channels/#{pkg_origin}/stable/pkgs/#{pkg_name}/latest").read)
        end
      end

      def plan_sh_path
        File.join(directory, "plan.sh")
      end

      def habitat_plan_sh_path
        File.join(directory, "habitat", "plan.sh")
      end
    end
  end
end
