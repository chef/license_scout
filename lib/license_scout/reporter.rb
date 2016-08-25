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

require "ffi_yajl"

require "license_scout/exceptions"

module LicenseScout
  class Reporter

    attr_reader :output_directory

    def initialize(output_directory)
      @output_directory = output_directory
    end

    def report
      report = []

      license_manifest_path = find_license_manifest!

      license_report = FFI_Yajl::Parser.parse(File.read(license_manifest_path))

      license_report["dependency_managers"].each do |dependency_manager, dependencies|
        dependencies.each do |dependency|
          if dependency["name"].nil? || dependency["name"].empty?
            report << "There is a dependency with a missing name in '#{dependency_manager}'."
          end

          if dependency["version"].nil? || dependency["version"].empty?
            report << "Dependency '#{dependency["name"]}' under '#{dependency_manager}' is missing version information."
          end

          if dependency["license"].nil? || dependency["license"].empty?
            report << "Dependency '#{dependency["name"]}' version '#{dependency["version"]}' under '#{dependency_manager}' is missing license information."
          end

          if dependency["license_files"].empty?
            report << "Dependency '#{dependency["name"]}' version '#{dependency["version"]}' under '#{dependency_manager}' is missing license files information."
          else
            dependency["license_files"].each do |license_file|
              if !File.exist?(full_path_for(license_file))
                report << "License file '#{license_file}' for the dependency '#{dependency["name"]}' version '#{dependency["version"]}' under '#{dependency_manager}' is missing."
              end
            end
          end
        end
      end

      report
    end

    def find_license_manifest!
      if !File.exist?(output_directory)
        raise LicenseScout::Exceptions::InvalidOutputReport.new("Output directory '#{output_directory}' does not exist.")
      end

      manifests = Dir.glob("#{output_directory}/*-dependency-licenses.json")

      if manifests.empty?
        raise LicenseScout::Exceptions::InvalidOutputReport.new("Can not find a dependency license manifest under '#{output_directory}'.")
      end

      if manifests.length != 1
        raise LicenseScout::Exceptions::InvalidOutputReport.new("Found multiple manifests '#{manifests.join(", ")}' under '#{output_directory}'.")
      end

      manifests.first
    end

    def full_path_for(license_file_info)
      File.join(output_directory, license_file_info)
    end

  end
end
