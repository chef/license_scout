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

require 'license_scout/exporter/csv'

module LicenseScout
  class Exporter
    attr_reader :json_file, :export_format, :exporter

    def initialize(json_file, export_format)
      @json_file = json_file
      @export_format = export_format

      @exporter = case export_format
                  when 'csv'
                    LicenseScout::Exporter::CSV.new(json_file)
                  else
                    # We shouldn't ever hit this, because the CLI filters out unsupported formats. But just in case...
                    raise LicenseScout::Exceptions::UnsupportedExporter,
                          "'#{export_format}' is not a supported format. Please use one of the following: #{supported_formats.join(', ')}"
                  end
    end

    def self.supported_formats
      [
        'csv'
      ]
    end

    def export
      LicenseScout::Log.info("[exporter] Exporting #{json_file} to '#{export_format}'")
      exporter.export
    end
  end
end
