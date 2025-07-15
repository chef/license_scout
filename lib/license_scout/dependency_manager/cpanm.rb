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
    class Cpanm < Base
      def name
        'perl_cpanm'
      end

      def type
        'perl'
      end

      def signature
        File.exist?(meta_json_path) ? 'META.json file' : 'META.yml file'
      end

      def install_command
        'cpanm --installdeps .'
      end

      # NOTE: it's possible that projects won't have a META.yml, but the two
      # that we care about for Chef Server do have one. As of 2015, 84% of perl
      # distribution packages have one: http://neilb.org/2015/10/18/spotters-guide.html
      def detected?
        File.exist?(meta_json_path) || File.exist?(meta_yml_path)
      end

      def dependencies
        Dir.glob("#{cpanm_root}/latest-build/*").map do |dep_path|
          next unless File.directory?(dep_path)

          dep_data = manifest(dep_path)
          metafile = dep_data['metafile']
          dep_name = dep_data['name']
          dep_version = dep_data['version']

          dependency = new_dependency(dep_name, dep_version, dep_path)

          # CPANM projects contain license metadata - include it!
          unless dep_data['license'].nil?
            Array(dep_data['license']).each do |license|
              next if license == 'unknown'

              dependency.add_license(license, metafile)
            end
          end

          dependency
        end.compact
      end

      private

      def meta_yml_path
        File.join(directory, 'META.yml')
      end

      def meta_json_path
        File.join(directory, 'META.json')
      end

      # Packages can contain metadata files named META.yml, META.json,
      # MYMETA.json, MYMETA.yml. META.* files are created by the authors of
      # the plugins whereas MYMETA.* files are created by the build system
      # after dynamic dependencies are resolved. For our purposes META.*
      # files are enough. And for no good reason we prioritize json files
      # over yml files.
      def manifest(unpack_path)
        json_path = File.join(unpack_path, 'META.json')
        yml_path = File.join(unpack_path, 'META.yml')

        if File.exist?(json_path)
          FFI_Yajl::Parser.parse(File.read(json_path)).merge({ 'metafile' => 'META.json' })
        elsif File.exist?(yml_path)
          Psych.safe_load(File.read(yml_path)).merge({ 'metafile' => 'META.yml' })
        else
          raise LicenseScout::Exceptions::Error,
                "Can not find a metadata file for the perl package at '#{unpack_path}'."
        end
      end

      def cpanm_root
        # By default cpanm downloads all the dependencies into ~/.cpanm directory
        File.expand_path(LicenseScout::Config.cpanm_root)
      end
    end
  end
end
