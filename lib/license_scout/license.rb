#
# Copyright:: Copyright 2018, Chef Software Inc.
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

require "license_scout/spdx"

module LicenseScout
  class License
    # A class that represents the components that make up a license.
    class Record
      attr_reader :id
      attr_reader :parsed_expression
      attr_reader :source
      attr_reader :content
      attr_reader :spdx_license_data

      def initialize(license_id = nil, source = nil, content = nil, options = {})
        @id = LicenseScout::SPDX.find(license_id, options[:force])
        @parsed_expression = LicenseScout::SPDX.parse(id)
        @source = source
        @content = content
      end

      def to_h
        {
          id: id,
          source: source,
          content: content,
        }
      end
    end

    attr_reader :project
    attr_reader :records

    # @param path [String, nil] A path to give to Licensee to search for the license. Could be local path or GitHub URL.
    def initialize(path = nil)
      if path.nil?
        @project = nil
        @records = []
      else
        @project = Licensee.project(path, detect_readme: true)
        @records = []

        project.licenses.each_index do |i|
          record = Record.new(
            project.licenses[i].spdx_id,
            project.matched_files[i].filename,
            project.matched_files[i].content
          )

          # Favor records that have identified a license
          record.id.nil? ? @records.push(record) : @records.unshift(record)
        end
      end
    end

    # Capture a license that was specified in metadata
    #
    # @param license_id [String] The license as specified in the metadata file
    # @param source [String] Where we found the license info
    # @param contents_url [String] Where we can find the contents of the license
    # @param options [Hash] Options to control various behavior
    #
    # @return [void]
    def add_license(license_id, source, contents_url, options)
      content = license_content(license_id, contents_url)
      @records.push(Record.new(license_id, source, content, options))
    end

    # @return [Boolean] Whether or not the license(s) are allowed
    def is_allowed?
      (records.map(&:parsed_expression).flatten.compact & LicenseScout::Config.allowed_licenses).any?
    end

    # @return [Boolean] Whether or not the license(s) are flagged
    def is_flagged?
      (records.map(&:parsed_expression).flatten.compact & LicenseScout::Config.flagged_licenses).any?
    end

    # @return [Boolean] Whether we were unable to determine a license
    def undetermined?
      (records.map(&:parsed_expression).flatten.compact).empty?
    end

    private

    def license_content(license_id, contents_url)
      if contents_url.nil?
        nil
      else
        new_url = raw_github_url(contents_url)

        begin
          LicenseScout::Log.debug("[license] Pulling license content for #{license_id} from #{new_url}")
          URI.open(new_url).read
        rescue RuntimeError => e
          if e.message =~ /redirection forbidden/
            m = /redirection forbidden:\s+(.+)\s+->\s+(.+)/.match(e.message)
            new_https_url = m[2].gsub("http://", "https://")

            LicenseScout::Log.debug("[license] Retrying download of #{license_id} from #{new_https_url}")
            license_content(license_id, new_https_url)
          else
            raise e
          end
        rescue
          LicenseScout::Log.warn("[license] Unable to download license for #{license_id} from #{new_url}")
          nil
        end
      end
    end

    def raw_github_url(url)
      case url
      when %r{github.com/(.+)/blob/(.+)}
        "https://raw.githubusercontent.com/#{$1}/#{$2}"
      else
        url
      end
    end
  end
end
