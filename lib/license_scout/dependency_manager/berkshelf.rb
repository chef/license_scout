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
    class Berkshelf < Base
      def name
        'chef_berkshelf'
      end

      def type
        'chef_cookbook'
      end

      def signature
        'Berksfile and Berksfile.lock files'
      end

      def install_command
        'berks install'
      end

      def detected?
        File.exist?(berksfile_path) && File.exist?(lockfile_path)
      end

      def dependencies
        unless berkshelf_available?
          raise LicenseScout::Exceptions::Error,
                "Project at '#{directory}' is a Berkshelf project but berkshelf gem is not available in your bundle. Add berkshelf to your bundle in order to collect licenses for this project."
        end

        cookbook_dependencies = []

        Dir.chdir(directory) do
          berksfile = ::Berkshelf::Berksfile.from_file('./Berksfile')

          # Berkshelf should not give an error when there are cookbooks in the
          # lockfile that are no longer in the berksfile. It handles this case in
          # the Installer class which we are not using here. So we handle this
          # case in the same way Installer does.
          berksfile.lockfile.reduce!

          cookbook_dependencies = berksfile.list
        end

        cookbook_dependencies.map do |dep|
          new_dependency(dep.name, dep.cached_cookbook.version, dep.cached_cookbook.path.to_s)
        end.compact
      end

      private

      def berkshelf_available?
        begin
          require 'berkshelf'
        rescue LoadError
          return false
        end

        true
      end

      def berksfile_path
        File.join(directory, 'Berksfile')
      end

      def lockfile_path
        File.join(directory, 'Berksfile.lock')
      end
    end
  end
end
