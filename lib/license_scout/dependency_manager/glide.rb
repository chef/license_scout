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

require "psych"
require "license_scout/dependency_manager/base"

module LicenseScout
  module DependencyManager
    class Glide < Base

      def name
        "golang_glide"
      end

      def type
        "golang"
      end

      def signature
        "glide.lock file"
      end

      def install_command
        "glide install"
      end

      def detected?
        File.exist?(glide_lock_path)
      end

      def dependencies
        # We cannot use YAML.safe_load because Psych throws a fit about the
        # updated field. We should circle back and see what we can do to fix that.
        YAML.load(File.read(glide_lock_path))["imports"].map do |import|
          dep_name = import["name"]
          dep_version = import["version"]
          dep_path = gopath(dep_name)

          new_dependency(dep_name, dep_version, dep_path)
        end.compact
      end

      private

      def glide_lock_path
        File.join(directory, "glide.lock")
      end

      def gopath(pkg)
        "#{ENV['GOPATH']}/src/#{pkg}"
      end
    end
  end
end
