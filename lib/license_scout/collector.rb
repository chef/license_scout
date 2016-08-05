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

require "license_scout/exceptions"
require "license_scout/dependency_manager"

require "ffi_yajl"

module LicenseScout
  class Collector

    attr_reader :project_name
    attr_reader :project_dir
    attr_reader :output_dir
    attr_reader :license_manifest_data
    attr_reader :overrides

    def initialize(project_name, project_dir, output_dir, overrides)
      @project_name = project_name
      @project_dir = project_dir
      @output_dir = output_dir
      @overrides = overrides
    end

    def dependency_managers
      @dependency_managers ||= all_dependency_managers.select { |m| m.detected? }
    end

    def run
      reset_license_manifest

      if !File.exists?(project_dir)
        raise LicenseScout::Exceptions::ProjectDirectoryMissing.new(project_dir)
      end
      FileUtils.mkdir_p(output_dir) unless File.exist?(output_dir)

      if dependency_managers.empty?
        raise LicenseScout::Exceptions::UnsupportedProjectType.new(project_dir)
      end
      dependency_managers.each { |d| collect_licenses_from(d) }

      File.open(license_manifest_path, "w+") do |file|
        file.print(FFI_Yajl::Encoder.encode(license_manifest_data, pretty: true))
      end
    end

    def issue_report
      report = []
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
          end
        end
      end

      report.empty? ? nil : report.join("\n")
    end

    private

    def reset_license_manifest
      @license_manifest_data = {
        license_manifest_version: 1,
        project_name: project_name,
        dependency_managers: {},
      }
    end

    def license_manifest_path
      File.join(output_dir, "#{project_name}-dependency-licenses.json")
    end

    def collect_licenses_from(dependency_manager)
      license_manifest_data[:dependency_managers][dependency_manager.name] = []

      dependency_manager.dependencies.each do |dep|
        license_data = {
          name: dep.name,
          version: dep.version,
          license: dep.license,
          license_files: [],
        }

        dep.license_files.each do |license_file|
          output_license_filename = [
            dependency_manager.name,
            dep.name,
            dep.version,
            File.basename(license_file),
          ].join("-")
          output_license_path = File.join(output_dir, output_license_filename)
          FileUtils.cp(license_file, output_license_path)

          license_data[:license_files] << output_license_filename
        end

        license_manifest_data[:dependency_managers][dependency_manager.name] << license_data

      end
    end

    def all_dependency_managers
      LicenseScout::DependencyManager.implementations.map do |implementation|
        implementation.new(project_dir, overrides)
      end
    end
  end
end