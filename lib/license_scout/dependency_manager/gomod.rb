#
# Copyright:: Copyright 2020, Chef Software Inc.
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
    class Gomod < Base

      def name
        "golang_modules"
      end

      def type
        "golang"
      end

      def signature
        "go.sum file"
      end

      def install_command
        "go mod download"
      end

      def detected?
        File.exist?(go_sum_file)
      end

      def dependencies
        go_modules.map do |mod|
          next if mod["Main"] == true

          dep_name = mod["Path"]
          dep_version = mod["Version"]
          dep_path = mod["Dir"]

          new_dependency(dep_name, dep_version, dep_path)
        end.compact
      end

      def go_sum_file
        File.join(directory, "go.sum")
      end

      def vendor_dir
        File.join(directory, "vendor")
      end

      def modules_txt_file
        File.join(vendor_dir, "modules.txt")
      end

      def go_modules
        if vendor_mode
          GoModulesTxtParser.parse(File.read(modules_txt_file), vendor_dir)
        else
          FFI_Yajl::Parser.parse(go_modules_json)
        end
      end

      def vendor_mode
        if @vendor_mode.nil?
          @vendor_mode = File.directory?(vendor_dir)
        end
        @vendor_mode
      end

      def go_modules_json
        s = Mixlib::ShellOut.new("go list -m -json all", cwd: directory, environment: LicenseScout::Config.environment)
        s.run_command
        s.error!
        "[" + s.stdout.gsub("}\n{", "},\n{") + "]"
      end
    end
  end

  module GoModulesTxtParser
    # The modules.txt file has lines that look like:
    #
    #     # gopkg.in/square/go-jose.v2 v2.1.3
    #
    # We parse these lines and return something that looks like `go
    # list -m -json all` output.
    def self.parse(data, base_path)
      data.lines.map do |l|
        if l.start_with?("#")
          parts = l.split
          {
            "Main" => false,
            "Path" => parts[1],
            "Version" => parts[2],
            "Dir" => File.join(base_path, parts[1]),
          }
        end
      end.compact
    end
  end
end
