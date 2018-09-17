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

require "license_scout/dependency_manager/base"

module LicenseScout
  module DependencyManager
    # dep(https://github.com/golang/dep) is a new dependency manger available from go 1.8
    class Dep < Base

      def name
        "golang_dep"
      end

      def type
        "golang"
      end

      def signature
        "Gopkg.lock file"
      end

      def install_command
        "dep ensure"
      end

      def detected?
        File.exist?(gopkg_lock_path)
      end

      def dependencies
        Array(gopkg.dig("projects")).map do |pkg_info|
          dep_name = pkg_info["name"]
          dep_version = pkg_info["version"] || pkg_info["revision"]
          dep_path = package_path(dep_name)

          new_dependency(dep_name, dep_version, dep_path)
        end.compact
      end

      private

      def gopkg
        File.open(gopkg_lock_path) { |f| TomlRB.parse(f) }
      end

      def gopkg_lock_path
        File.join(directory, "Gopkg.lock")
      end

      def gopath(pkg)
        "#{ENV['GOPATH']}/src/#{pkg}"
      end

      def vendor_dir(pkg = nil)
        File.join(directory, "vendor/#{pkg}")
      end

      def package_path(pkg)
        (Dir[vendor_dir(pkg)] + Dir[gopath(pkg)]).first
      end
    end
  end
end
