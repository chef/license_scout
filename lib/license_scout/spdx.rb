#
# Copyright:: Copyright 2018 Chef Software, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# This library was inspired by (and pulls some logic from) librariesio/spdx

require "ffi_yajl"
require "fuzzy_match"

module LicenseScout
  class SPDX
    class << self

      # Try to find the SPDX ID that most closely matches the given license ID
      #
      # @param license_id [String, nil] The license ID
      # @return [String, nil, false] Returns either the SPDX ID, false if the
      #   license_id was nil, or nil if we could not find a valid SPDX ID
      def find(license_id, force = false)
        return license_id if force
        return nil if license_id.nil? || %w{ NOASSERTION NONE }.include?(license_id)
        lookup(license_id) || find_by_special_case(license_id) || closest(license_id) || license_id
      end

      # Right now this just returns the license keys that are present in the string.
      # In the future, we should handle a proper compound structure like
      # https://github.com/jslicense/spdx-expression-parse.js
      def parse(license_string)
        license_string.nil? ? [] : (license_string.tr("()", "").split("\s") - spdx_join_words)
      end

      # @return [Hash] The SPDX license data in Hash form
      def licenses
        @@license_data ||= FFI_Yajl::Parser.parse(File.read(File.expand_path("../data/licenses.json", __FILE__)))["licenses"]
      end

      # @return [Hash] The SPDX license data in Hash form
      def exceptions
        @@license_data ||= FFI_Yajl::Parser.parse(File.read(File.expand_path("../data/exceptions.json", __FILE__)))["exceptions"]
      end

      def known_ids
        @@known_ids ||= licenses.map { |l| l["licenseId"] }
      end

      def known_names
        @@known_names ||= licenses.map { |l| l["name"] }
      end

      private

      def lookup(license_id)
        return license_id if known_ids.include?(license_id)
        return spdx_for(license_id) if (Array(license_id) & known_names).any?
        return license_id if (parse(license_id) & known_ids).any?
      end

      def find_by_special_case(license_id)
        gpl = gpl_match(license_id)
        return gpl unless gpl.nil?
        lookup(special_cases[license_id.downcase])
      end

      def closest(license_id)
        spdx_for(FuzzyMatch.new(known_names).find(license_id)) || FuzzyMatch.new(known_ids).find(license_id)
      end

      def gpl_match(license_id)
        match = license_id.match(/^(l|a)?gpl-?\s?_?v?(1|2|3)\.?(\d)?(\+)?$/i)
        return unless match
        lookup("#{match[1]}GPL-#{match[2]}.#{match[3] || 0}#{match[4]}".upcase)
      end

      def spdx_for(license_name)
        licenses.find { |n| n["name"] == license_name }["licenseId"]
      end

      def spdx_join_words
        %w{WITH AND OR}
      end

      def special_cases
        {
          "agpl_3"      => "AGPL-3.0",
          "apache_1_1"  => "Apache-1.1",
          "apache_2_0"  => "Apache-2.0",
          "artistic_1"  => "Artistic-1.0",
          "artistic_2"  => "Artistic-2.0",
          "bsd"         => "BSD-3-Clause",
          "freebsd"     => "BSD-2-Clause-FreeBSD",
          "gfdl_1_2"    => "GFDL-1.2-only",
          "gfdl_1_3"    => "GFDL-1.3-only",
          "lgpl_2_1"    => "LGPL-2.1-only",
          "lgpl_3_0"    => "LGPL-3.0-only",
          "mit"         => "MIT",
          "mozilla_1_0" => "MPL-1.0",
          "mozilla_1_1" => "MPL-1.1",
          "mplv1.0"     => "MPL-1.0",
          "mplv1.1"     => "MPL-1.1",
          "openssl"     => "OpenSSL",
          "qpl_1_0"     => "QPL-1.0",
          "perl"        => "Artistic-1.0-Perl",
          "perl_5"      => "Artistic-1.0-Perl",
          "ssleay"      => "OpenSSL",
          "sun"         => "SISSL",
          "zlib"        => "Zlib",
        }
      end
    end
  end
end
