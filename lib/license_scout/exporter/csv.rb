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

require "csv" unless defined?(CSV)

module LicenseScout
  class Exporter
    class CSV

      attr_reader :json
      attr_reader :output_file

      def initialize(json_file)
        @json = FFI_Yajl::Parser.parse(File.read(json_file))
        @output_file = json_file.gsub("json", "csv")
      end

      def export
        headers = [
          "Type",
          "Name",
          "Version",
          "Has Exception",
          "Exception Reason",
          "License ID",
          "License Source",
          "License Content",
        ]

        ::CSV.open(output_file, "w+") do |csv|
          csv << headers

          json["dependencies"].each do |dependency|
            type = dependency["type"]
            name = dependency["name"]
            version = dependency["version"]
            has_exception = dependency["has_exception"]
            exception_reason = dependency["exception_reason"]
            licenses = dependency["licenses"]

            licenses.each do |license|
              id = license["id"]
              source = license["source"]
              content = license["content"]

              csv << [
                type,
                name,
                version,
                (has_exception.nil? ? "Yes" : "No"),
                (exception_reason.nil? ? "" : exception_reason),
                id,
                source,
                content,
              ]
            end
          end
        end
      end
    end
  end
end
