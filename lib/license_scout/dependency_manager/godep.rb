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
    class Godep < Base

      def name
        "golang_godep"
      end

      def type
        "golang"
      end

      def signature
        "Godeps/Godeps.json file"
      end

      def install_command
        "godep restore"
      end

      def detected?
        File.exist?(root_godeps_file)
      end

      def dependencies
        godeps["Deps"].map do |pkg_info|
          dep_name = pkg_info["ImportPath"]
          dep_version = pkg_info["Comment"] || pkg_info["Rev"]
          dep_path = gopath(dep_name)

          new_dependency(dep_name, dep_version, dep_path)
        end.compact
      end

      private

      def godeps
        File.open(root_godeps_file) do |f|
          FFI_Yajl::Parser.parse(f)
        end
      end

      def root_godeps_file
        File.join(directory, "Godeps/Godeps.json")
      end

      def gopath(pkg)
        "#{ENV['GOPATH']}/src/#{pkg}"
      end
    end
  end
end
