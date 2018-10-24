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
require "terminal-table"

require "license_scout/exceptions"

module LicenseScout
  class Reporter

    class Result
      class << self
        def success(dependency)
          new(dependency, nil, true)
        end

        def failure(dependency, reason)
          new(dependency, reason, false)
        end
      end

      attr_reader :dependency
      attr_reader :reason

      def initialize(dependency, reason, did_succeed)
        @dependency = dependency
        @reason = reason
        @did_succeed = did_succeed
      end

      def <=>(other)
        dependency.path <=> other.dependency.path
      end

      def succeeded?
        @did_succeed
      end

      def dependency_string
        dependency.uid
      end

      def license_string
        dependency.license.records.map(&:id).compact.uniq.join(", ")
      end

      def reason_string
        case reason
        when :not_allowed
          "Not Allowed"
        when :flagged
          "Flagged"
        when :undetermined
          "Undetermined"
        when :missing
          "Missing"
        else
          "OK"
        end
      end
    end

    attr_reader :all_dependencies
    attr_reader :results
    attr_reader :dependency_license_manifest

    def initialize(all_dependencies)
      @all_dependencies = all_dependencies.sort
      @results = {}
      @did_fail = false
      @needs_fallback = false
      @needs_exception = false
    end

    def report
      generate_dependency_license_manifest
      save_manifest_file
      detect_problems
      evaluate_results
    end

    private

    def save_manifest_file
      LicenseScout::Log.info("[reporter] Writing dependency license manifest written to #{license_manifest_path}")
      File.open(license_manifest_path, "w+") do |file|
        file.print(FFI_Yajl::Encoder.encode(dependency_license_manifest, pretty: true))
      end
    end

    def detect_problems
      LicenseScout::Log.info("[reporter] Analyzing dependency's license information against requirements")

      LicenseScout::Log.info("[reporter] Allowed licenses: #{LicenseScout::Config.allowed_licenses.join(", ")}") unless LicenseScout::Config.allowed_licenses.empty?
      LicenseScout::Log.info("[reporter] Flagged licenses: #{LicenseScout::Config.flagged_licenses.join(", ")}") unless LicenseScout::Config.flagged_licenses.empty?

      all_dependencies.each do |dependency|
        @results[dependency.type] ||= []

        if dependency.license.records.empty?
          @results[dependency.type] << Result.failure(dependency, :missing)
          @did_fail = true
          @needs_fallback = true
        elsif dependency.license.undetermined?
          @results[dependency.type] << Result.failure(dependency, :undetermined)
          @did_fail = true
          @needs_fallback = true
        elsif !LicenseScout::Config.allowed_licenses.empty? && !dependency.license.is_allowed?
          unless dependency.has_exception?
            @results[dependency.type] << Result.failure(dependency, :not_allowed)
            @did_fail = true
            @needs_exception = true
          else
            @results[dependency.type] << Result.success(dependency)
          end
        elsif dependency.license.is_flagged?
          unless dependency.has_exception?
            @results[dependency.type] << Result.failure(dependency, :flagged)
            @did_fail = true
            @needs_exception = true
          else
            @results[dependency.type] << Result.success(dependency)
          end
        else
          @results[dependency.type] << Result.success(dependency)
        end
      end
    end

    def evaluate_results
      table = Terminal::Table.new
      table.headings = ["Type", "Dependency", "License(s)", "Results"]
      table.style = { border_bottom: false } # the extra :separator will add this

      results.each do |type, results_for_type|
        type_in_table = false

        results_for_type.each do |result|
          next if LicenseScout::Config.only_show_failures && result.succeeded?

          modified_row = []
          modified_row << (type_in_table ? "" : type)
          modified_row << result.dependency_string
          modified_row << result.license_string
          modified_row << result.reason_string

          type_in_table = true
          table.add_row(modified_row)
        end

        table.add_separator if type_in_table
      end

      puts table unless LicenseScout::Config.only_show_failures && !@did_fail

      puts
      puts "Additional steps are required in order to pass Open Source license compliance:"
      puts "  * Please add fallback licenses for the 'Missing' or 'Undetermined' dependencies"   if @needs_fallback
      puts "         https://github.com/chef/license_scout#fallback-licenses"                    if @needs_fallback
      puts "  * Please add exceptions for the 'Flagged' or 'Not Allowed' dependencies"           if @needs_exception
      puts "         https://github.com/chef/license_scout#dependency-exceptions"                if @needs_exception

      raise Exceptions::FailExit.new("missing or not allowed licenses detected") if @did_fail
    end

    def generate_dependency_license_manifest
      @dependency_license_manifest = {
        license_manifest_version: 2,
        generated_on: DateTime.now.to_s,
        name: LicenseScout::Config.name,
        dependencies: [],
      }

      all_dependencies.each do |dep|
        dependency_license_manifest[:dependencies] << {
          type: dep.type,
          name: dep.name,
          version: dep.version,
          has_exception: dep.has_exception?,
          exception_reason: dep.exception_reason,
          licenses: dep.license.records.map(&:to_h),
        }
      end
    end

    def license_manifest_path
      File.join(LicenseScout::Config.output_directory, "#{LicenseScout::Config.name}-dependency-licenses.json")
    end
  end
end
