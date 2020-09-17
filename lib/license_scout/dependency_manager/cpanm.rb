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

require "ffi_yajl" unless defined?(FFI_Yajl)
require "psych"
require "mixlib/shellout" unless defined?(Mixlib::ShellOut)

require "license_scout/dependency_manager/base"
require "license_scout/exceptions"
require "license_scout/dependency"

module LicenseScout
  module DependencyManager
    class Cpanm < Base

      class CpanmDependency

        LICENSE_TYPE_MAP = {
          "perl_5" => "Perl-5",
          "perl" => "Perl-5",
          "apache_2_0" => "Apache-2.0",
          "artistic_2" => "Artistic-2.0",
          "gpl_3" => "GPL-3.0",
        }.freeze

        attr_reader :unpack_path
        attr_reader :overrides
        attr_reader :metadata

        def initialize(unpack_path, overrides)
          @unpack_path = unpack_path
          @overrides = overrides
        end

        def to_dep
          parse_metadata!

          Dependency.new(
            name,
            version.to_s,
            license,
            license_files,
            "perl_cpanm"
          )
        end

        def parse_metadata!
          # Packages can contain metadata files named META.yml, META.json,
          # MYMETA.json, MYMETA.yml. META.* files are created by the authors of
          # the plugins whereas MYMETA.* files are created by the build system
          # after dynamic dependencies are resolved. For our purposes META.*
          # files are enough. And for no good reason we prioritize json files
          # over yml files.
          @metadata ||= begin
            json_path = File.join(unpack_path, "META.json")
            yml_path = File.join(unpack_path, "META.yml")

            if File.exist?(json_path)
              FFI_Yajl::Parser.parse(File.read(json_path))
            elsif File.exist?(yml_path)
              Psych.safe_load(File.read(yml_path))
            else
              raise LicenseScout::Exceptions::Error.new("Can not find a metadata file for the perl package at '#{unpack_path}'.")
            end
          end
        end

        def name
          metadata["name"]
        end

        def version
          metadata["version"]
        end

        def license
          @license ||= begin
            override_license = overrides.license_for("perl_cpanm", name, version)

            if override_license
              override_license
            elsif metadata && metadata.key?("license")
              given_type = Array(metadata["license"]).reject { |l| l == "unknown" }.first

              # Normalize the common perl license strings to the strings we commonly use
              LICENSE_TYPE_MAP[given_type] || given_type
            end
          end
        end

        def license_files
          @license_files ||= begin
            override_license_files = overrides.license_files_for("perl_cpanm", name, version)

            if override_license_files.empty?
              find_license_files
            else
              override_license_files.resolve_locations(unpack_path)
            end
          end
        end

        def find_license_files
          Dir["#{unpack_path}/*"].select do |f|
            Cpanm::POSSIBLE_LICENSE_FILES.include?(File.basename(f))
          end
        end

      end

      def name
        "perl_cpanm"
      end

      def cpanm_root
        # By default cpanm downloads all the dependencies into ~/.cpanm directory
        File.expand_path("~/.cpanm")
      end

      def dependencies
        @dependencies ||= begin
          deps = []

          Dir.glob("#{cpanm_root}/latest-build/*").each do |dep_path|
            next unless File.directory?(dep_path)

            deps << CpanmDependency.new(dep_path, options.overrides).to_dep
          end

          deps
        end
      end

      # NOTE: it's possible that projects won't have a META.yml, but the two
      # that we care about for Chef Server do have one. As of 2015, 84% of perl
      # distribution packages have one: http://neilb.org/2015/10/18/spotters-guide.html
      def detected?
        meta_yml_path = File.join(project_dir, "META.yml")
        meta_json_path = File.join(project_dir, "META.json")

        File.exist?(meta_yml_path) || File.exist?(meta_json_path)
      end

    end
  end
end
