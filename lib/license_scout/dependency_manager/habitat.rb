#
# Copyright:: Copyright 2017, Chef Software Inc.
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

require "forwardable"
require "license_scout/dependency_manager/base"

module LicenseScout
  module DependencyManager
    class Habitat < Base
      # Class representing a Habitat Package. Should probably reside in the
      # habitat gem, but putting one with limited functionality here.
      class Package
        class Ident
          attr_reader :parts, :origin, :name, :version, :release

          def initialize(str = "")
            @parts = str.to_s.split("/")
            @origin, @name, @version, @release = parts
          end
        end

        class Manifest
          attr_reader :contents

          def initialize(contents = "")
            @contents = contents
          end

          # Find the License out of the manifest
          def license
            contents.scan(/^\*\s__License__:(.*)/).flatten.first.to_s.strip.split.first
          end
        end

        extend Forwardable

        attr_reader :path
        def_delegators :ident, :origin, :name, :version, :release
        def_delegators :manifest, :license

        HAB_FS_ROOT = "/hab/pkgs".freeze

        def initialize(options_or_ident, options = {})
          if options_or_ident.is_a?(String)
            options[:path] = File.join(HAB_FS_ROOT, options_or_ident)
          else
            options = options_or_ident
          end

          @path = options[:path]
        end

        # The files where the LICENSE can be found. This should be always
        # just LICENSE
        def license_files
          file = File.exist? File.join(path, "LICENSE")
          file ? [file] : []
        end

        def manifest
          @manifest ||= Manifest.new(File.open(File.join(path, "MANIFEST")).read)
        rescue Errno::ENOENT
          Manifest.new
        end

        def transitive_dependencies
          @dependencies ||= open(File.join(path, "TDEPS")).readlines.map do |dep|
            pkg = Package.new(dep.chomp)
            if pkg.ident.name
              pkg
            else
              nil
            end
          end.compact
        rescue Errno::ENOENT
          []
        end

        def ident
          @ident ||= Ident.new(File.open(File.join(path, "IDENT")).read.chomp)
        rescue Errno::ENOENT
          @ident = Ident.new
        end

        def valid?
          !ident.name.nil? && ident.parts.length == 4
        end
      end

      extend Forwardable

      attr_reader :package

      def_delegator :package, :valid?, :detected?

      def initialize(project_dir, options)
        @package = Package.new(path: project_dir)
        super
      end

      def dependencies
        package.transitive_dependencies.map do |dep|
          create_dependency("#{dep.origin}/#{dep.name}",
                            "#{dep.version}/#{dep.release}",
                            dep.license, dep.license_files, name)
        end
      end

      def name
        "habitat"
      end
    end
  end
end
