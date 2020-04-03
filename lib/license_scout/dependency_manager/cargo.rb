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
    class Cargo < Base
      def name
        "rust_cargo"
      end

      def type
        "rust"
      end

      def signature
        "Cargo and Cargo.lock files"
      end

      def install_command
        "cargo build"
      end

      def detected?
        File.exist?(cargo_file_path) && File.exist?(cargo_lockfile_path)
      end

      def dependencies
        dependency_data.map do |crate_data|
          dep_name = crate_data["name"]
          dep_version = crate_data["version"]
          dep_license = crate_data["license"]

          dependency = new_dependency(dep_name, dep_version, nil)
          dependency.add_license(dep_license, "https://crates.io/crates/#{dep_name}/#{dep_version}")

          dependency
        end.compact
      end

      private

      def dependency_data
        Dir.chdir(directory) do
          install_cargo_license_crate

          s = Mixlib::ShellOut.new("cargo-license -d -j")
          s.run_command
          s.error!

          json_dep_data = s.stdout
          FFI_Yajl::Parser.parse(json_dep_data)
        end
      end

      def install_cargo_license_crate
        # Attempt to install cargo-license
        s = Mixlib::ShellOut.new("cargo install cargo-license")
        s.run_command

        # If cargo-license is already installed, it will return an error
        # but we can ignore it
        # Any other error, however, should halt the process and be returned
        # to the user
        if s.stderr != "" && s.stderr !~ /binary `cargo-license` already exists/
          s.error!
        end
      end

      def cargo_file_path
        File.join(directory, "Cargo.toml")
      end

      def cargo_lockfile_path
        File.join(directory, "Cargo.lock")
      end

    end
  end
end
